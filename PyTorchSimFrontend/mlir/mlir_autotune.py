"""Compiler-candidate compatibility types for the Inductor integration.

This module only schedules compilation and never executes generated code.
"""
import dataclasses
from typing import Any, Callable, Iterable, List, Optional, Union

from torch._inductor.autotune_process import TensorMeta


@dataclasses.dataclass
class MLIRBenchmarkRequest:
    def __init__(
        self,
        kernel_name: str,
        input_tensor_meta: Union[TensorMeta, List[TensorMeta]],
        output_tensor_meta: Union[TensorMeta, List[TensorMeta]],
        extra_args: Iterable[Any],
        source_code: str,
    ):
        self.kernel_name = kernel_name
        self.input_tensor_meta = ([input_tensor_meta] if isinstance(input_tensor_meta, TensorMeta)
                                  else input_tensor_meta)
        self.output_tensor_meta = ([output_tensor_meta] if isinstance(output_tensor_meta, TensorMeta)
                                   else output_tensor_meta)
        self.source_code = source_code
        self.workspace_size: int = 0
        self.workspace: Optional[Any] = None
        self.hash_key: str = ""
        self.source_file: str = ""
        self.extra_args = extra_args

    def __str__(self) -> str:
        return f"{self.kernel_name=}, {self.source_file=}, {self.hash_key=}"

    def make_run_fn(self, input_tensors: Any, output_tensors: Any) -> Callable[[], str]:
        del input_tensors, output_tensors
        from PyTorchSimFrontend.extension_codecache import CustomAsyncCompile

        compiler = CustomAsyncCompile()
        handle = compiler.mlir(
            self.source_code,
            vectorlane_size=self.extra_args["vector_lane"],
            loop_size=self.extra_args["loop_size"],
            spad_info=self.extra_args["spad_info"],
            vlen=self.extra_args["vlen"],
            arg_attributes=self.extra_args["arg_attributes"],
            origins=self.extra_args["origins"],
        )

        def compile_candidate(**kwargs):
            del kwargs
            return handle()

        return compile_candidate

    def update_workspace_size(self) -> None:
        return
