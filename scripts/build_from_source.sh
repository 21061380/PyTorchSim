#!/bin/bash
home="/workspace"
cd $home

# LLVM
git clone https://github.com/PSAL-POSTECH/llvm-project.git --branch ispass2026
cd llvm-project && git apply $home/PyTorchSim/scripts/patches/llvm-project-pytorchsim-internal-accumulator.patch && mkdir build && cd build && \
  cmake -DLLVM_ENABLE_PROJECTS=mlir -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/riscv-llvm -DLLVM_TARGETS_TO_BUILD=RISCV -G "Unix Makefiles" ../llvm && \
  make -j && make install
cd $home

cd $home
