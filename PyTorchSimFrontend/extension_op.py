"""Compiler-facing external operation registrations.

Runtime simulation and sparse trace generation are intentionally excluded from
this module.  Sparse operations use a regular PyTorch fallback when a target
compiler implementation is unavailable.
"""
import torch
from torch._inductor.select_algorithm import ExternKernelChoice


class MLIRExternKernelChoice(ExternKernelChoice):
    def call_name(self):
        return f"torch.ops.extension_op.{self.name}"


custom_lib = torch.library.Library("extension_op", "DEF")


def sparse_mm_outer(a, b, out):
    """Return a functional fallback without launching a simulator."""
    out.copy_(torch.matmul(a, b))
    return out


def sparse_mm_compiler_fallback(a, b, out):
    """Compatibility fallback used by generated wrappers during compilation."""
    out.copy_(torch.matmul(a, b))
    return out


custom_lib.define("_sparse_mm(Tensor a, Tensor b, Tensor out) -> Tensor")
custom_lib.impl("_sparse_mm", sparse_mm_outer, "PrivateUse1")
custom_lib.impl("_sparse_mm", sparse_mm_outer, "AutogradPrivateUse1")
