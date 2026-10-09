# syntax=docker/dockerfile:1.4
ARG BASE_IMAGE=ghcr.io/psal-postech/torchsim_base:latest
FROM ${BASE_IMAGE}

# Prepare PyTorchSim project
COPY . /workspace/PyTorchSim

# Validate the compiler-only source contract without importing a device runtime.
RUN python3 /workspace/PyTorchSim/tests/test_compiler_only.py

# The image contains compiler frontend code only. Runtime deployment components
# are outside this image and are not built or imported here.

# Install the Python frontend only; the optional device/runtime package is not
# part of compiler-only image construction.