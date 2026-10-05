# 7B Decode GEMV Assembly

These files were generated with the `torchsim-ci:internal-accumulator` Docker image and disassembled inside the container with `/riscv-llvm/bin/llvm-objdump`.

All kernels use `M=1`, so PyTorchSim represents decode GEMV as a GEMM-shaped operation:

```text
[1 x K] x [K x N] = [1 x N]
```

| File suffix | GEMV shape | Typical 7B decode use |
|---|---|---|
| `4096x4096` | `[1 x 4096] x [4096 x 4096]` | Attention projections, including Q/K/V/O variants |
| `4096x11008` | `[1 x 4096] x [4096 x 11008]` | MLP up or gate projection |
| `11008x4096` | `[1 x 11008] x [11008 x 4096]` | MLP down projection |
| `4096x32000` | `[1 x 4096] x [4096 x 32000]` | Representative vocabulary projection / LM head |

Each size has these artifacts:

- `.mlir`: PyTorchSim GEMM MLIR input, with `M=1`, `N`, and `K` in the header.
- `.s`: RISC-V assembly generated with `+xsfvcp` and `zvl256b`.
- `.o`: RISC-V ELF relocatable object.
- `.disasm`: Docker-side `llvm-objdump -d --source` output.
- `.sections`: Docker-side `llvm-objdump -h` output.

The unqualified `gemv.*` files are copies of the `4096x4096` representative kernel.

The generated kernels use `TILE_M=8`, `TILE_N=128`, `TILE_K=128`, and `SUB_TILE_M=8`, `SUB_TILE_N=128`. The static kernel contains the VCIX push, compute, and pop instructions inside loops whose runtime trip counts depend on `N` and `K`.
