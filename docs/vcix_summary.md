# VCIX 指令汇总

本文汇总 PyTorchSim 所依赖的 SiFive VCIX（Vector Coprocessor Interface）指令形式、RISC-V 机器码布局、MLIR 表示和项目自定义语义。

> **范围说明**：本文区分 VCIX 的通用硬件指令格式和 PyTorchSim 当前分配的 `opcode` 语义。`opcode` 是 VCIX 指令内部传给协处理器的功能字段，不是 RISC-V 指令的低 7 位 opcode。项目使用的 RISC-V 基础 opcode 是 `CUSTOM_2 = 0x5b`。

## 1. 来源和术语

主要实现位置：

- [VCIXOps.td](../llvm-project-ispass2026/mlir/include/mlir/Dialect/LLVMIR/VCIXOps.td)：MLIR VCIX operation 定义。
- [RISCVInstrInfoXSf.td](../llvm-project-ispass2026/llvm/lib/Target/RISCV/RISCVInstrInfoXSf.td)：机器码字段和汇编指令族定义。
- [IntrinsicsRISCVXsf.td](../llvm-project-ispass2026/llvm/include/llvm/IR/IntrinsicsRISCVXsf.td)：LLVM intrinsic 参数和副作用定义。
- [TestPyTorchSimToVCIXConversion.cpp](../llvm-project-ispass2026/mlir/test/lib/Conversion/PyTorchSimToVCIX/TestPyTorchSimToVCIXConversion.cpp)：PyTorchSim 自定义 lowering 和 opcode 分配。
- [custom_hardware_data_scheduling.md](custom_hardware_data_scheduling.md)：VCIX 字段作为 NPU dcache 地址的项目约定。

本文使用下列缩写：

| 缩写 | 含义 |
|---|---|
| `X` | 整数标量寄存器输入 `xs1` |
| `I` | 5 位有符号立即数输入 `simm5` |
| `V` | 向量寄存器输入 |
| `F` | 浮点标量寄存器输入 `fs1` |
| `v.` | 有向量目的寄存器 `vd` |
| 无 `v.` | 无向量目的寄存器，通常用于 side-effect 操作 |
| `W` | 宽化向量结果，结果元素宽度通常为输入的两倍 |
| `SE` | 带 side effect，并显式携带 `vl` |

## 2. 通用 32 位机器码格式

VCIX 使用 `CUSTOM_2` 指令空间。除浮点标量输入形式外，普通 VCIX 指令的编码布局为：

```text
31       28 27 26 25 24       20 19       15 14   12 11        7 6       0
+-----------+-----+--+-----------+-----------+-------+-----------+---------+
| funct6_hi4| lo2 |vm|    rs2    |    rs1    | funct3|     rd    | CUSTOM_2|
+-----------+-----+--+-----------+-----------+-------+-----------+---------+
```

精确编码公式如下：

```text
insn = (funct6_hi4 << 28)
     | (funct6_lo2 << 26)
     | (vm          << 25)
     | (rs2         << 20)
     | (rs1         << 15)
     | (funct3      << 12)
     | (rd          <<  7)
     | 0x5b
```

其中：

| 位段 | 字段 | 说明 |
|---|---|---|
| `31:28` | `funct6_hi4` | VCIX 操作类别高四位 |
| `27:26` | `funct6_lo2` | 非浮点形式使用的两位功能字段 |
| `25` | `vm` | `1` 表示无目的向量结果，`0` 表示有 `vd` |
| `24:20` | `rs2` | 向量源寄存器或自定义 5 位字段 |
| `19:15` | `rs1` | 向量/整数/浮点源寄存器或 `simm5` |
| `14:12` | `funct3` | `rs1` 的类型编码 |
| `11:7` | `rd` | 向量目的寄存器或自定义 5 位字段 |
| `6:0` | `opcode` | 固定为 `0b1011011`，即 `0x5b` |

对于 `F` 后缀，LLVM 后端使用单独的浮点编码类：bit 27 固定为 `1`，bit 26 使用一位 `funct6_lo1`，其余字段布局相同。其公式为：

```text
insn = (funct6_hi4 << 28)
     | (1            << 27)
     | (funct6_lo1   << 26)
     | (vm           << 25)
     | (rs2          << 20)
     | (rs1          << 15)
     | (funct3       << 12)
     | (rd           <<  7)
     | 0x5b
```

因此，表中 `FV`、`FVV` 和 `FVW` 的基准值仍然有效，但它们的可变功能字段只能取一位。该例外对应后端的 `RVInstVCFCustom2` 定义。

### 2.1 `funct6_hi4` 编码

| 指令族 | `funct6_hi4` | 十六进制高字段 | 说明 |
|---|---:|---:|---|
| `X` | `0000` | `0x0` | 标量/无向量输入族 |
| `XV` | `0010` | `0x2` | 单向量输入族 |
| `XVV` | `1010` | `0xa` | 双向量输入、宽结果族 |
| `XVW` | `1111` | `0xf` | 宽化操作族 |

### 2.2 `funct3` 编码

| `funct3` | `rs1` 内容 | 适用后缀 |
|---:|---|---|
| `000` | `vs1` | `V` |
| `011` | `simm5` | `I` |
| `100` | `xs1` | `X` |
| `101` | `fs1` | `F` |

## 3. VCIX 指令机器码总表

下表的“基准机器码”将 `funct6_lo2`、寄存器和立即数字段全部置零，只保留指令形式的固定字段。它不是带有具体功能码的完整实例。实际机器码必须在基准值上加入 `opcode << 26`、寄存器字段和立即数字段。

为避免歧义，下面的所有示例都假定：

```text
rs2 = 0，rs1/imm = 0，rd = 0
```

在这个前提下，非浮点 VCIX 形式的功能码对应关系是：

| 高层 `opcode` | `funct6_lo2` | 加入机器码的值 |
|---:|---:|---:|
| `0` | `00` | `0x00000000` |
| `1` | `01` | `0x04000000` |
| `2` | `10` | `0x08000000` |
| `3` | `11` | `0x0c000000` |

例如，`sf.vc.iv` 的基准值为 `0x2200305b`。因此在上述零操作数前提下：

| `sf.vc.iv` 的 `opcode` | 完整机器码 |
|---:|---:|
| `0` | `0x2200305b` |
| `1` | `0x2600305b` |
| `2` | `0x2a00305b` |
| `3` | `0x2e00305b` |

同样，常用于 PyTorchSim 的四种形式为：

| MLIR operation | VCIX 形式 | `opcode=0` | `opcode=1` | `opcode=2` | `opcode=3` |
|---|---|---:|---:|---:|---:|
| `vcix.iv` | `sf.vc.iv` | `0x2200305b` | `0x2600305b` | `0x2a00305b` | `0x2e00305b` |
| `vcix.i` | `sf.vc.i` | `0x0200305b` | `0x0600305b` | `0x0a00305b` | `0x0e00305b` |
| `vcix.v.i` | `sf.vc.v.i` | `0x0000305b` | `0x0400305b` | `0x0800305b` | `0x0c00305b` |
| `vcix.v.iv` | `sf.vc.v.iv` | `0x2000305b` | `0x2400305b` | `0x2800305b` | `0x2c00305b` |

同一行中的 `无目的形式` 和 `有目的形式` 只在 `vm` 和 `rd` 语义上不同：

- 无目的形式：`vm = 1`，`rd` 是自定义字段或保留字段。
- 有目的形式：`vm = 0`，`rd = vd`。

| 指令形式 | 汇编助记符 | `funct6_hi4` | `funct3` | `vm` | 基准机器码 | 操作数和结果 |
|---|---|---:|---:|---:|---:|---|
| `X` 无目的 | `sf.vc.x` | `0000` | `100` | `1` | `0x0200405b` | `xs1`，无向量结果 |
| `X` 有目的 | `sf.vc.v.x` | `0000` | `100` | `0` | `0x0000405b` | `xs1`，结果 `vd` |
| `I` 无目的 | `sf.vc.i` | `0000` | `011` | `1` | `0x0200305b` | `simm5`，无向量结果 |
| `I` 有目的 | `sf.vc.v.i` | `0000` | `011` | `0` | `0x0000305b` | `simm5`，结果 `vd` |
| `XV` 无目的 | `sf.vc.xv` | `0010` | `100` | `1` | `0x2200405b` | `vs2`、`xs1`，无结果 |
| `XV` 有目的 | `sf.vc.v.xv` | `0010` | `100` | `0` | `0x2000405b` | `vs2`、`xs1`，结果 `vd` |
| `IV` 无目的 | `sf.vc.iv` | `0010` | `011` | `1` | `0x2200305b` | `vs2`、`simm5`，无结果 |
| `IV` 有目的 | `sf.vc.v.iv` | `0010` | `011` | `0` | `0x2000305b` | `vs2`、`simm5`，结果 `vd` |
| `VV` 无目的 | `sf.vc.vv` | `0010` | `000` | `1` | `0x2200005b` | `vs2`、`vs1`，无结果 |
| `VV` 有目的 | `sf.vc.v.vv` | `0010` | `000` | `0` | `0x2000005b` | `vs2`、`vs1`，结果 `vd` |
| `FV` 无目的 | `sf.vc.fv` | `0010` | `101` | `1` | `0x2200505b` | `vs2`、`fs1`，无结果 |
| `FV` 有目的 | `sf.vc.v.fv` | `0010` | `101` | `0` | `0x2000505b` | `vs2`、`fs1`，结果 `vd` |
| `XVV` 无目的 | `sf.vc.xvv` | `1010` | `100` | `1` | `0xa200405b` | 两个向量和 `xs1`，无结果 |
| `XVV` 有目的 | `sf.vc.v.xvv` | `1010` | `100` | `0` | `0xa000405b` | 两个向量和 `xs1`，宽结果 |
| `IVV` 无目的 | `sf.vc.ivv` | `1010` | `011` | `1` | `0xa200305b` | 两个向量和 `simm5`，无结果 |
| `IVV` 有目的 | `sf.vc.v.ivv` | `1010` | `011` | `0` | `0xa000305b` | 两个向量和 `simm5`，宽结果 |
| `VVV` 无目的 | `sf.vc.vvv` | `1010` | `000` | `1` | `0xa200005b` | 三个向量，无结果 |
| `VVV` 有目的 | `sf.vc.v.vvv` | `1010` | `000` | `0` | `0xa000005b` | 三个向量，宽结果 |
| `FVV` 无目的 | `sf.vc.fvv` | `1010` | `101` | `1` | `0xa200505b` | 两个向量和 `fs1`，无结果 |
| `FVV` 有目的 | `sf.vc.v.fvv` | `1010` | `101` | `0` | `0xa000505b` | 两个向量和 `fs1`，宽结果 |
| `XVW` 无目的 | `sf.vc.xvw` | `1111` | `100` | `1` | `0xf200405b` | 两个向量和 `xs1`，无结果 |
| `XVW` 有目的 | `sf.vc.v.xvw` | `1111` | `100` | `0` | `0xf000405b` | 两个向量和 `xs1`，宽化结果 |
| `IVW` 无目的 | `sf.vc.ivw` | `1111` | `011` | `1` | `0xf200305b` | 两个向量和 `simm5`，无结果 |
| `IVW` 有目的 | `sf.vc.v.ivw` | `1111` | `011` | `0` | `0xf000305b` | 两个向量和 `simm5`，宽化结果 |
| `VVW` 无目的 | `sf.vc.vvw` | `1111` | `000` | `1` | `0xf200005b` | 三个向量，无结果 |
| `VVW` 有目的 | `sf.vc.v.vvw` | `1111` | `000` | `0` | `0xf000005b` | 三个向量，宽化结果 |
| `FVW` 无目的 | `sf.vc.fvw` | `1111` | `101` | `1` | `0xf200505b` | 两个向量和 `fs1`，无结果 |
| `FVW` 有目的 | `sf.vc.v.fvw` | `1111` | `101` | `0` | `0xf000505b` | 两个向量和 `fs1`，宽化结果 |

> **注意**：`base` 值不是一条可直接执行的完整指令。它假设 `funct6_lo2=rs2=rs1=rd=0`。例如，`sf.vc.v.iv` 的真实机器码为：
>
> ```text
> 0x2000305b | (opcode[1:0] << 26) | (vs2 << 20) | (simm5 << 15) | (vd << 7)
> ```

## 4. MLIR operation 到机器码形式的对应关系

项目 MLIR 方言只暴露以下五种 operation：

| MLIR operation | 实际指令族 | 关键参数 | 结果 |
|---|---|---|---|
| `vcix.x` | `sf.vc.x` | `opcode, rs2, rd, rs1, sew, lmul, vl` | 无结果 |
| `vcix.i` | `sf.vc.i` | `opcode, rs2, imm, rd, sew, lmul, vl` | 无结果 |
| `vcix.v.i` | `sf.vc.v.i` | `opcode, rs2, imm, vl` | 向量 |
| `vcix.iv` | `sf.vc.iv` | `opcode, vs2, imm, rd, vl` | 无结果 |
| `vcix.v.iv` | `sf.vc.v.iv` | `opcode, vs2, imm, vl` | 向量 |
| `vcix.v.sv` | `sf.vc.v.xv`、`sf.vc.v.fv` 或 `sf.vc.v.vv` | `opcode, vs2, op, vl` | 向量 |

`vcix.v.sv` 的选择规则为：

```text
op 是向量       -> sf.vc.v.vv, funct3 = 000
op 是整数标量   -> sf.vc.v.xv, funct3 = 100
op 是浮点标量   -> sf.vc.v.fv, funct3 = 101
```

固定长度向量没有显式 `vl` 时，LLVM lowering 使用向量元素个数生成 `vl`。可伸缩向量必须显式传入 `vl`。

## 5. PyTorchSim 自定义 opcode

PyTorchSim 在 GEMM/卷积 lowering 中使用以下自定义功能码：

```cpp
vipush_opcode  = 0b000000;
vwpush_opcode  = 0b000001;
compute_opcode = 0b000001;
vpop_opcode    = 0b000010;
```

这些值进入机器码的 `funct6_lo2` 以及项目协处理器约定的功能字段。由于 VCIX 的 TableGen 指令接口使用 `opcode` 作为高层功能参数，实际硬件解码时应以芯片协议规定的完整字段解释；不能把它误认为 RISC-V 的 `0x5b`。

| 自定义功能 | 使用的 VCIX operation | `opcode` | 机器码族 | 自定义语义 |
|---|---|---:|---|---|
| 输入 push | `vcix.iv` | `0b000000` | `sf.vc.iv` | 将输入激活向量送入 NPU/脉动阵列输入侧 |
| 权重 push | `vcix.iv` | `0b000001` | `sf.vc.iv` | 将权重向量送入 NPU/脉动阵列权重侧 |
| 启动计算 | `vcix.i` | `0b000001` | `sf.vc.i` | 启动脉动阵列计算，`imm` 携带计算周期 |
| 弹出结果 | `vcix.v.i` | `0b000010` | `sf.vc.v.i` | 从 VCIX 内部累加器取出一个向量结果 |

### 5.1 输入 push 的机器码模板

`vcix.iv` 属于 `IV` 无目的形式，因此机器码为：

```text
机器码 = 0x2200305b
       | (opcode[1:0] << 26)
       | (vs2         << 20)
       | (imm5        << 15)
       | (rd_field    <<  7)
```

当 `vs2=0`、`imm5=0`、`rd_field=0` 时，输入 push 使用 `opcode=0`，完整机器码为：

```text
0x2200305b
```

### 5.2 权重 push 的机器码模板

权重 push 也使用 `vcix.iv`，因此机器码布局完全相同：

```text
机器码 = 0x2200305b
       | (opcode[1:0] << 26)
       | (vs2         << 20)
       | (imm5        << 15)
       | (rd_field    <<  7)
```

项目使用 `opcode=1`。当 `vs2=0`、`imm5=0`、`rd_field=0` 时，权重 push 的完整机器码为：

```text
0x2600305b
```

它与启动计算使用相同的 `opcode` 数值，但二者的 VCIX 指令形式不同：一个是 `IV`，另一个是 `I`。

### 5.3 启动计算的机器码模板

`vcix.i` 属于 `I` 无目的形式：

```text
机器码 = 0x0200305b
       | (opcode[1:0] << 26)
       | (rs2_field    << 20)
       | (compute_cycle << 15)
       | (rd_field      <<  7)
```

当 `rs2_field=0`、`compute_cycle=0`、`rd_field=0` 时，项目使用 `opcode=1`，启动计算的完整机器码为：

```text
0x0600305b
```

项目使用：

```text
opcode = 1
imm    = compute_cycle
sew    = element bit width
lmul   = vector length multiplier encoding
vl     = runtime vector length
```

需要注意，`sew` 和 `lmul` 是 LLVM intrinsic/MLIR lowering 的附加控制参数。标准 32 位 RISC-V VCIX 指令本身没有额外的 `sew` 和 `lmul` 位段，它们通过向量状态和项目约定传递给硬件。

### 5.4 弹出结果的机器码模板

`vcix.v.i` 属于 `I` 有目的形式：

```text
机器码 = 0x0000305b
       | (opcode[1:0] << 26)
       | (rs2_field    << 20)
       | (imm5         << 15)
       | (vd            <<  7)
```

当 `rs2_field=0`、`imm5=0`、`vd=0` 时，项目使用 `opcode=2`，弹出结果的完整机器码为：

```text
0x0800305b
```

项目自定义语义在零寄存器、零立即数的示例下对应如下完整机器码：

| 操作 | VCIX 形式 | `opcode` | 示例机器码 |
|---|---|---:|---:|
| 输入 push | `vcix.iv` | `0` | `0x2200305b` |
| 权重 push | `vcix.iv` | `1` | `0x2600305b` |
| 启动计算 | `vcix.i` | `1` | `0x0600305b` |
| 弹出结果 | `vcix.v.i` | `2` | `0x0800305b` |

如果 `vs2`、`vd`、`imm` 或硬件地址字段不为零，必须继续按照模板加入对应字段；因此真实二进制指令通常不会等于上面的零操作数示例。

#### GEMM

```text
vcix.iv opcode=0   // push input
vcix.iv opcode=1   // push weight
vcix.i  opcode=1   // start compute
...                 // 在内部累加器中保留 K 维部分和
vcix.v.i opcode=2   // pop final accumulator result
```

GEMM 的 K 维累加可以让部分和留在 VCIX 内部，K 维完成后再统一弹出。

#### 卷积

```text
vcix.iv opcode=0   // push input
vcix.iv opcode=1   // push weight
vcix.i  opcode=1   // start one compute
vcix.v.i opcode=2   // pop current partial result
arith.add*          // 与 SRAM 中的已有结果相加
vector.transfer_write // 写回输出 tile
```

卷积当前按每次计算弹出结果，并在软件/向量侧完成归约，不跨卷积归约循环长期保留内部部分和。

## 6. 数学函数的自定义语义

PyTorchSim 还把部分 `math` operation lower 到 `vcix.v.iv`。这些映射是项目自定义协处理器协议，不是标准 RISC-V 数学指令编码。

| 源 operation | VCIX operation | `opcode` | `imm` | 自定义语义 |
|---|---|---:|---:|---|
| `math.exp` | `vcix.v.iv` | `0b000011`（3） | `0` | 向量指数 |
| `math.erf` | `vcix.v.iv` | `0b000000`（0） | `0` | 向量误差函数 |
| `math.tanh` | `vcix.v.iv` | `0b000001`（1） | `0` | 向量双曲正切 |
| `math.sin` | `vcix.v.iv` | `0b000010`（2） | `0` | 向量正弦 |
| `math.cos` | `vcix.v.iv` | `0b000010`（2） | `1` | 使用同一 opcode 和 `imm=1` 区分余弦 |
| `math.exp2` | 预留 | 未启用 | 未固定 | 源码中的 lowering 目前被注释 |

这些指令属于 `IV` 有目的形式，机器码模板为：

```text
0x2000305b
| (opcode[1:0] << 26)
| (vs2         << 20)
| (imm5        << 15)
| (vd          <<  7)
```

> 例如在 `vs2=0`、`vd=0` 时：`math.exp`（`opcode=3, imm=0`）为 `0x2c00305b`；`math.sin`（`opcode=2, imm=0`）为 `0x2800305b`；`math.cos`（`opcode=2, imm=1`）为 `0x2800b05b`。
>
> 上述计算依据后端当前显式建模的 `opcode[1:0]`。如果芯片协议另行规定完整的六位功能码，则必须按照芯片解码器将完整功能码映射到 `funct6_hi4` 和 `funct6_lo2`，不能仅凭高层属性名推断。

## 7. VCIX 字段的地址语义

项目文档规定，VCIX 的寄存器字段可以被 NPU 解释为 dcache 地址，而不是普通 RISC-V 物理寄存器号。最终 lowering 时应把实际 dcache 地址编码到硬件规定的字段。

建议保持以下编译器内部映射：

```text
tile_ref -> dcache slot -> physical dcache address -> VCIX field
```

编译器内部还可以维护以下元数据：

- tensor ID；
- tile 坐标；
- shape、stride 和 layout；
- element type；
- dcache slot 和 bank；
- buffer epoch；
- producer、consumer 和 ready token；
- release token 和访问模式。

这些调度元数据不应与标准 VCIX 位段混淆。机器码表描述的是最终 32 位指令编码，tile 生命周期和地址重定位属于编译器/运行时层语义。

## 8. 重要实现注意事项

1. `0x5b` 是 RISC-V `CUSTOM_2` 基础 opcode，不是 PyTorchSim 的 `compute_opcode`。
2. `opcode=1` 在 `vcix.iv` 中表示权重 push，在 `vcix.i` 中表示启动计算，语义由指令形式共同决定。
3. `vm=1` 表示无向量目的结果，`vm=0` 表示存在向量目的寄存器；不要仅根据 `opcode` 判断是否写回向量。
4. `sew`、`lmul` 和 `vl` 是向量状态或 intrinsic 参数；它们不等于机器码中额外的独立字段。
5. `rs2`、`rs1`、`rd` 在本项目硬件协议中可能承载 dcache 地址或地址片段，不能默认解释为普通寄存器编号。
6. 对于 `xvv`、`ivv`、`vvv`、`fvv`、`xvw`、`ivw`、`vvw` 和 `fvw`，LLVM 后端已经定义了通用形式，但当前 PyTorchSim lowering 主要使用 `x`、`i`、`iv` 和 `v.i`/`v.sv` 这些形式。
