# PyTorchSim compiler

PyTorchSim is a compiler frontend for generating RISC-V vector artifacts from PyTorch programs. The repository contains the compiler only. It does not include or launch a simulator, device runtime, or cycle model.

## Compiler pipeline

The frontend lowers generated MLIR through the project MLIR passes, LLVM IR, RISC-V/RVV assembly, and object code. It preserves explicit `memref.dma_start` operations, custom VCIX instructions, scratchpad section metadata, and static scratchpad checks. A compile produces cached `.mlir`, lowered MLIR, `.ll`, `.s`, `.o`, and optional linked target binaries.

DMA is compiler output. Hardware control software and DMA engines consume the generated instructions outside this repository.

## Requirements

- Python and the PyTorch version used by the selected Inductor frontend.
- The patched RISC-V LLVM/MLIR toolchain, installed at `/riscv-llvm` in the supplied image.
- A RISC-V bare-metal compiler when linked wrappers are requested.

The compiler has no simulator or device-runtime dependency.

## Quick start

Build the compiler image:

```bash
docker build -f Dockerfile.base -t torchsim-base .
docker build -f Dockerfile --build-arg BASE_IMAGE=torchsim-base -t torchsim .
```

For a local toolchain build, run:

```bash
bash scripts/build_from_source.sh
```

Select a compiler-only hardware description with `TORCHSIM_CONFIG`, or use the default in `configs/compiler_only.yml`. The configuration contains vector lanes, vector length, scratchpad capacity, mapping strategy, and compiler optimization settings. Supported mapping strategies are `heuristic` and `external-then-heuristic`.

## Repository layout

- `PyTorchSimFrontend/` contains MLIR generation, lowering, caching, and wrapper compilation.
- `configs/compiler_only.yml` contains the minimal compiler target configuration.
- `scripts/` contains compiler and continuous-integration helpers.
- `thirdparty/github-releases.json` pins reproducible compiler dependencies.

Generated artifacts are compiler products. Runtime execution, performance measurement, and hardware deployment are outside the compiler package.

## License and citation

See the repository license and the PyTorchSim research paper at <https://doi.org/10.1145/3725843.3756045>.
