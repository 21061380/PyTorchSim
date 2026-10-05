# CPU/NPU/VPU 自研芯片数据调度方案

本文总结使用 PyTorchSim 适配自研 CPU/NPU/VPU 芯片时的数据调度建议、当前模拟器能力、关键限制和实施路线。

## 1. 芯片抽象

建议将芯片抽象为四类资源：

```text
CPU：调度器、依赖管理、描述符提交
DMA：DDR → dcache 或片上共享 SRAM
NPU：GEMM、卷积、矩阵累加
VPU：Softmax、ReLU、LayerNorm、量化和逐元素操作
```

总体数据流为：

```text
DDR → DMA → shared dcache / scratchpad → NPU / VPU
```

CPU 不应在每个 tile 上阻塞等待，而应提交带有依赖 token 的 DMA、NPU 和 VPU 描述符，让不同资源并行推进。

## 2. VCIX 寄存器号和 tile 地址语义

芯片已经规定 VCIX 指令中的寄存器字段是 NPU 读取 dcache 的地址，因此不建议强行把它重新定义为普通向量寄存器或物理寄存器。

推荐在编译器和运行时中维护以下映射：

```text
tile_ref → dcache slot → physical dcache address
```

最终 lowering 时，把实际 dcache 地址编码到 VCIX 字段。

编译器内部可以维护独立的 tile reference 或 address token，其中记录：

- tensor ID；
- tile 坐标；
- layout、shape 和 stride；
- element type 和字节数；
- dcache slot 和 bank；
- buffer epoch；
- producer 和 consumer；
- ready token 和 release token。

这样既保留硬件已有的地址语义，又可以支持双缓冲、slot 重定位、生命周期管理和 NPU/VPU 共享读取。

## 3. Tile identity 和生命周期

当前 PyTorchSim 的 tag 不能直接作为最终的 dcache tile identity。

`Instruction::prepare_tag_key()` 会构造包含 address-name ID、累加维度和加权 tag offset 的 key。`TileGraphParser::calc_tag()` 计算的 key 本身不包含 address ID，因为 tag table 已经按 subgraph 分层。当前语义仍缺少：

```text
physical address
shape
stride
element type
layout
version
buffer slot
epoch
access mode
```

建议新增完整的运行时 TileKey：

```text
TileKey = (
    tensor_id,
    tile_coordinate,
    layout,
    shape,
    stride,
    element_type,
    version,
    buffer_epoch
)
```

每个 tile 维护如下状态：

```text
EMPTY → FETCHING → READY → IN_USE → DRAINING → EMPTY
```

推荐的生命周期规则：

1. 第一个请求创建 `FETCHING` entry 并发起 DMA。
2. 相同 TileKey 的后续请求加入 waiter，不重复发起 DMA。
3. DMA 完成后转为 `READY`，唤醒所有 waiter。
4. 每个 NPU/VPU consumer acquire 一次并增加 reader count。
5. consumer 完成后 release 一次。
6. reader count 归零后，slot 才能被覆盖或回收。

合并两个 DMA 请求前，必须检查完整 descriptor：

```text
address、shape、stride、bytes、element type、access mode、epoch
```

即使当前 tag 相同，只要上述字段有任何不一致，也不能合并。

## 4. 推荐的数据复用和流水线

### 4.1 双缓冲

第一版建议使用双缓冲：

```text
A0 / A1
B0 / B1
C0 / C1
```

典型时间线为：

```text
DMA：预取 tile[i+1]
NPU：计算 tile[i]
VPU：消费输出 tile[i-1]
```

对应的逻辑为：

```text
prefetch(tile[i+1])
wait(tile[i])
NPU_compute(tile[i])
VPU_consume(output[i-1])
release(tile[i-1])
```

如果 DDR 延迟抖动明显，或者 DMA burst 不稳定，再考虑三缓冲。预取距离 `p` 至少应满足：

```text
p × Tcompute >= Tfill + Tdma_latency
```

缓冲数量至少约为：

```text
buffer_count >= p + 1
```

但缓冲数量受到 dcache 容量约束：

```text
Sbuffer >= K × (SA + SB + SC)
```

其中 `K` 为双缓冲或三缓冲深度，`SA`、`SB`、`SC` 分别为 A、B、C tile 大小。

### 4.2 GEMM

对于：

```text
C[M,N] = A[M,K] × B[K,N]
```

划分为：

```text
A：Tm × Tk
B：Tk × Tn
C：Tm × Tn
```

首选 output-stationary：

```text
for m_tile:
    for n_tile:
        clear accumulator
        for k_tile:
            prefetch A[m,k] and B[k,n]
            wait A[m,k] and B[k,n]
            NPU_GEMM(A_tile, B_tile, accumulator)
        store accumulator → C_tile
        VPU_RELU(C_tile)
```

这样可以让 C tile 和 partial sum 在 K 循环期间驻留，减少中间结果写回。芯片已有 NPU internal accumulator 时，该策略尤其合适。

可以根据复用条件选择其他数据流：

| 数据流 | 适用场景 |
|---|---|
| Output-stationary | K 较大，需要减少 partial sum 写回 |
| Weight-stationary | 权重 tile 较小，跨多个 M tile 复用 |
| Activation-stationary | batch 较小，输入激活跨多个输出复用 |

近似计算量为：

```text
Operations = 2 × Tm × Tn × Tk
```

### 4.3 卷积

建议使用 tiled implicit GEMM，而不是生成完整 im2col：

```text
输入 tile + halo → NPU convolution → 输出 tile → VPU activation
```

输入 tile 应包含 halo：

```text
Hinput = Houtput × stride_h + KH - 1
Winput = Woutput × stride_w + KW - 1
```

相邻输出 tile 之间共享 halo。调度器应保留仍有消费者的输入边界，并合并相同输入 tile 的 DMA 请求。

卷积输出如果紧接 ReLU，应采用：

```text
NPU_DONE(C_tile) → VPU_RELU(C_tile) → writeback
```

避免先写回 DDR，再由 VPU 重新读取。

### 4.4 Attention 和 Softmax

建议按 Q、K、V block 调度，并避免将完整 score matrix 写回 DDR：

```text
for each Q block:
    initialize m, l, O
    for each K,V block:
        NPU：S = Q_block × K_block^T
        VPU：更新 online softmax 状态
        NPU：累加 softmax(S) × V_block
    VPU：完成 O
```

在线 Softmax 至少需要维护：

```text
m：当前最大值
l：指数和
O：累积输出
```

Softmax 不能像 ReLU 一样简单地对每个独立元素单遍处理。建议保留一个 row 或 row block，完成最大值、指数和、归一化等阶段。

## 5. PyTorchSim 当前能力

相关实现位于：

- [TOGSim/src/Core.cc](../TOGSim/src/Core.cc)
- [TOGSim/src/DMA.cc](../TOGSim/src/DMA.cc)
- [TOGSim/include/DMA.h](../TOGSim/include/DMA.h)
- [TOGSim/include/Instruction.h](../TOGSim/include/Instruction.h)
- [TOGSim/src/TileGraphParser.cc](../TOGSim/src/TileGraphParser.cc)
- [PyTorchSimFrontend/mlir/mlir_template.py](../PyTorchSimFrontend/mlir/mlir_template.py)
- [PyTorchSimFrontend/mlir/mlir_codegen_backend.py](../PyTorchSimFrontend/mlir/mlir_codegen_backend.py)
- [AsmParser/tog_generator.py](../AsmParser/tog_generator.py)

现有机制可以直接原型验证：

- GEMM、卷积和向量算子的 tile 划分；
- M、N、K 或卷积空间循环顺序；
- 异步 `MOVIN` 预取；
- `BAR` 等待 DMA 完成；
- tile graph 中的父子依赖；
- DMA 与 systolic/VPU 计算的初步重叠；
- GEMM 输出到 VPU 的静态依赖。

当前常用的指令语义可以映射为：

| PyTorchSim 指令 | 自研芯片语义 |
|---|---|
| `MOVIN` | DDR 到片上存储的 DMA |
| 异步 `MOVIN` | DMA prefetch |
| `BAR` | 等待 ready token |
| `COMP` + `MATMUL` | NPU GEMM 或卷积 |
| `COMP` + `VECTOR_UNIT` | VPU 运算 |
| `MOVOUT` | 写回 DDR |

最适合的编译器插入点是：

```text
mlir_template.py:def_dma_op
    ↓
mlir_codegen_backend.py:get_dma_code
    ↓
memref.dma_start
    ↓
AsmParser/onnx_utility.py
    ↓
AsmParser/tog_generator.py
    ↓
TileGraphParser
```

第一版可以在这里生成“下一 tile 异步预取、当前 tile 延迟等待”的 DAG。

## 6. 当前模型的边界

不能将现有 `l2d_type: datacache` 直接等同为自研芯片的共享 dcache。当前模型缺少：

- 独立 CPU、NPU、VPU command ring；
- 显式共享 dcache slot；
- tile reader count 和 release；
- epoch-safe token；
- 多 outstanding DMA；
- DMA 请求合并表；
- dcache 容量、bank、端口和 eviction；
- NPU→VPU FIFO 和 backpressure；
- NPU accumulator 的真实 ownership 和生命周期；
- DDR unique bytes、cache hit、merge 和 slot stall 统计。

当前 DMA 只有一个 `_current_inst`，更接近单 DMA 引擎、单当前搬运操作的模型。`Core::dma_cycle()` 还会优先处理 load queue，再处理 store queue。因此它不能准确评估：

```text
独立 NPU/VPU DMA
多个 outstanding prefetch
load/store 并行
DMA channel 之间的带宽竞争
```

当前 tag 主要用于 tile graph 内的异步完成通知和重复请求跳过，不是完整的 cache 命中模型。`mlir_codegen_backend.py` 中的 `dma_read_cache` 也只是编译期 code-generation CSE，不代表运行时 cache 命中、refcount 或 slot 生命周期。

## 7. 推荐的 PyTorchSim 扩展

### 7.1 指令和 TOG 元数据

增加以下元数据：

```text
tensor_id
tile_coordinate
layout
shape
stride
element_type
bytes
buffer_slot
buffer_epoch
producer_engine
consumer_mask
ready_token
release_token
```

现有的 VCIX 地址字段仍然编码实际 dcache 地址。上述字段用于编译、调度和仿真，不必直接替换硬件地址语义。

### 7.2 DMA 和 tile cache

增加：

```text
TileKey → inflight request
slot allocator
reader count
ready/release state
pin and eviction
request merge
```

tag 状态不应继续用简单的 `uint32_t` 兼容多种生命周期和 sparse sentinel。建议使用显式枚举，例如：

```text
EMPTY
FETCHING
READY
IN_USE
DRAINING
STALE
```

### 7.3 多资源执行模型

将资源拆分为：

```text
CPU issue queue
DMA queue
NPU queue
VPU queue
NPU→VPU FIFO
```

增加：

```text
multiple outstanding DMA
DDR bandwidth arbitration
bank/port contention
credit/backpressure
```

### 7.4 NPU accumulator

为 accumulator 增加明确的：

- output tile ownership；
- K reduction epoch；
- clear、accumulate、finalize 状态；
- 写回 fence；
- VPU 消费前的 ready token。

前端已有 GEMM accumulator 相关 lowering 支持，但 TOGSim 仍需要补充真实的 accumulator 生命周期模型。

## 8. 性能模型和自动调优

每个候选 mapping 至少计算：

```text
Tload = DDR_bytes / Bdma + DMA_latency
Tnpu  = Operations / Pnpu
Tvpu  = VPU_operations / Pvpu
```

独立资源下，稳定流水阶段可以近似为：

```text
Tstage = max(Tload, Tnpu, Tvpu, Tstore)
```

如果共享 dcache 带宽有限，还需要加入：

```text
Tdcache = dcache_bytes / Bdcache
Tstage >= max(Tload, Tnpu, Tvpu, Tstore, Tdcache)
```

可使用 roofline 下界：

```text
T >= max(
    Operations / Pcompute,
    DDR_bytes / BDDR,
    dcache_bytes / Bdcache
)
```

建议搜索以下参数：

```text
Tm、Tn、Tk
OH_tile、OW_tile、Cin_tile、Cout_tile
loop order
OS/WS/AS dataflow
buffer depth
prefetch distance
DMA burst size
VPU vector stride
NPU/VPU fusion
dcache bank/coloring
```

先用容量、对齐和 bank 冲突约束过滤候选，再用解析模型筛选 top-k，最后调用 TOGSim 做周期级仿真。

建议记录：

```text
total cycles
DDR read/write bytes
actual DMA requests
merged DMA requests
dcache hit/miss
slot reuse count
DMA active/idle cycles
NPU/VPU busy cycles
wait-for-DMA cycles
wait-for-NPU/VPU cycles
FIFO full cycles
```

可以定义：

```text
engine_utilization = busy_cycles / makespan
```

```text
overlap_ratio = 1 - makespan / sum(engine_busy_time)
```

```text
reuse_efficiency = ideal_DDR_bytes / actual_DDR_bytes
```

这些指标应基于真实 DDR 请求和实际资源忙闲状态，而不是逻辑 load 指令数量。

## 9. 分阶段实施路线

### 阶段一：静态 GEMM 基线

使用现有机制实现：

```text
output-stationary GEMM
A/B 双缓冲
async MOVIN
BAR wait
NPU K 方向 accumulator
NPU → VPU producer-consumer dependency
```

首个验证算子建议为 GEMM + ReLU。

### 阶段二：异步 DMA 微基准

验证：

```text
async MOVIN
DMA_DONE/tag/BAR 唤醒
重复 tile 请求合并
地址、shape、stride、elem_bits 校验
```

### 阶段三：TileKey 和生命周期

增加：

```text
TileKey
slot_id
epoch
refcount
ready_token
release_token
consumer_mask
```

确保只有最后一个 consumer 完成后才能复用 slot。

### 阶段四：显式共享 dcache

增加：

```text
容量
bank
端口
slot allocator
pin/eviction
writeback
cache hit
request merge
```

这一阶段之后，才可以较可信地评估 DDR 访问减少量。

### 阶段五：多资源并发

增加：

```text
CPU、DMA、NPU、VPU 独立队列
multiple outstanding DMA
NPU→VPU FIFO
credit/backpressure
DDR bandwidth arbitration
```

### 阶段六：自动调优和端到端验证

从 GEMM + ReLU 扩展到：

```text
卷积 + ReLU
GEMM + Softmax
Attention
LayerNorm
完整 Transformer block
```

同时保持 functional Spike 验证和 timing TOGSim 仿真分离，避免为了改变时序模型而破坏功能验证路径。

## 10. 首个推荐实验

首个垂直实验应采用：

```text
GEMM + ReLU
output-stationary
A/B 双缓冲
NPU internal accumulator
异步 DMA 预取下一 tile
NPU_DONE → VPU_START
```

理想调度序列为：

```text
prefetch A[i+1], B[i+1]
wait A[i], B[i]
NPU_GEMM(A[i], B[i], accumulator)
NPU_DONE(C[i])
VPU_RELU(C[i-1])
release C[i-1]
```

这个实验能够同时验证：

- 数据复用是否真实发生；
- DDR 访问是否减少；
- DMA 是否与 NPU 计算重叠；
- VPU 是否能够及时消费 NPU 输出；
- K 方向 partial sum 是否避免中间写回；
- slot 生命周期是否正确。

## 11. 核心结论

1. 第一版应采用“编译期静态 tile DAG + 运行时 TileKey 去重”的双层方案。
2. VCIX 地址字段保留为 NPU 读取 dcache 的地址，编译器内部另行维护 tile reference 和生命周期元数据。
3. GEMM 优先使用 output-stationary 和 internal accumulator，卷积采用带 halo 的 tiled implicit GEMM。
4. ReLU 可以直接采用 NPU producer 到 VPU consumer 的 tile 级事件；Softmax 需要保留 row 或 row block 状态。
5. 现有 async DMA、tag、BAR 和 tile graph 适合验证静态调度，但不等同于真实共享 dcache。
6. 只有增加 slot、epoch、reader count、release、容量和 DMA 仲裁后，才能可信地评估最少 DDR 访问和真实 overlap。
7. 最优先实现 GEMM + ReLU、A/B 双缓冲、NPU accumulator 和 NPU→VPU token 依赖这一条垂直路径。
