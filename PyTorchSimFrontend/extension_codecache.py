import os
import re
import shlex
import subprocess

from PyTorchSimFrontend import extension_config
from torch._inductor.codecache import get_hash, write
from torch._inductor.async_compile import AsyncCompile
from PyTorchSimFrontend.mlir.mlir_caller_codegen import MLIRKernelCallerCodeGen

# Configure logger for extension_codecache module (WARNING level by default)
logger = extension_config.setup_logger()

LOCK_TIMEOUT = 600
CACHE_BACKEND_VERSION = "math-backend-v2"


def cache_hash_extra(**compile_inputs):
    """Return compiler inputs that must invalidate generated artifacts."""
    values = {
        "backend": os.environ.get("TORCHSIM_MATH_BACKEND", CACHE_BACKEND_VERSION),
        "sleef_enabled": os.environ.get("TORCHSIM_SLEEF_RVV", "0"),
        "sleef_version": os.environ.get("TORCHSIM_SLEEF_VERSION", "unset"),
        "sleef_variant": os.environ.get("TORCHSIM_SLEEF_RVV_VARIANT", "rvvm1"),
        "sleef_lib": os.environ.get("TORCHSIM_SLEEF_RVV_LIB", "unset"),
        "llvm_path": extension_config.CONFIG_TORCHSIM_LLVM_PATH,
        "riscv_march": os.environ.get("TORCHSIM_RISCV_MARCH", "rv64gcv"),
        "riscv_mabi": os.environ.get("TORCHSIM_RISCV_MABI", "default"),
        "sleef_source": os.environ.get("TORCHSIM_SLEEF_SOURCE", "unset"),
    }
    values.update({key: str(value) for key, value in compile_inputs.items()})
    return "|".join(f"{key}={values[key]}" for key in sorted(values))

def hash_prefix(hash_value):
    return hash_value[1:12]

def get_write_path(src_code, extra=None):
    if extra is None:
        extra = cache_hash_extra()
    return os.path.join(
        extension_config.CONFIG_TORCHSIM_DUMP_PATH,
        hash_prefix(get_hash(src_code.strip(), extra=extra)),
    )


def get_lock_path(write_path):
    """Return lock file path for the given write_path (per-source_code lock)."""
    return os.path.join(write_path, ".compile.lock")

def dump_metadata(args, arg_attributes, path):
    meta_path = os.path.join(path, "meta.txt")
    if os.path.isfile(meta_path):
        return

    with open(meta_path, "a") as file:
        for (arg_name, arg_attribute), arg in zip(arg_attributes, args):
            file.write(f'{arg_name}=({arg_attribute[0]}, {arg.dtype}, {arg.shape})\n')
    return

def mlir_compile_command(filename, vectorlane_size, vlen=256):
    return [re.sub(r"[ \n]+", " ",
        f"""
            {extension_config.CONFIG_TORCHSIM_LLVM_PATH}/mlir-opt \
            -test-loop-padding \
            -dma-fine-grained='systolic-array-size={vectorlane_size}' \
            -global-idx='vlen={vlen}' \
            -test-pytorchsim-to-vcix='systolic-array-size={vectorlane_size} vlen={vlen}' \
            -test-memref-to-gemmini="vectorlane={vectorlane_size}" \
            -convert-linalg-to-loops \
            -convert-vector-to-scf='full-unroll' \
            -lower-affine \
            -finalize-memref-to-llvm \
            -lower-vector-multi-reduction \
            -convert-vector-to-llvm \
            -convert-arith-to-llvm \
            -convert-math-to-llvm \
            -convert-scf-to-cf \
            -convert-cf-to-llvm \
            -convert-func-to-llvm \
            -convert-index-to-llvm \
            -reconcile-unrealized-casts \
            {'--mlir-print-ir-after-all' if extension_config.CONFIG_TORCHSIM_DUMP_MLIR_IR else ''} \
            {filename}.mlir -o {filename}_llvm.mlir
        """,
    ).strip(),
            re.sub(r"[ \n]+", " ",
        f"""
            {extension_config.CONFIG_TORCHSIM_LLVM_PATH}/mlir-translate -mlir-to-llvmir {filename}_llvm.mlir -o {filename}.ll
        """,
    ).strip(),
            re.sub(r"[ \n]+", " ",
        f"""
            {extension_config.CONFIG_TORCHSIM_LLVM_PATH}/llc \
                -relocation-model=pic -march=riscv64 -O3 --stack-size-section \
                -mattr=+m,+f,+d,+a,+c,+v,+zvfh,+xsfvcp,zvl{vlen}b \
                -filetype=obj \
                {'--print-after-all' if extension_config.CONFIG_TORCHSIM_DUMP_LLVM_IR else ''} \
                -O2 {filename}.ll -o {filename}.o
        """,
    ).strip(),
            re.sub(r"[ \n]+", " ",
        f"""
            {extension_config.CONFIG_TORCHSIM_LLVM_PATH}/llc \
                -relocation-model=pic -march=riscv64 -O3 --stack-size-section \
                -mattr=+m,+f,+d,+a,+c,+v,+zvfh,+xsfvcp,zvl{vlen}b \
                -O2 {filename}.ll -o {filename}.s
        """,
    ).strip()]


class SpadOverflowError(Exception):
    def __init__(self, message="SPAD overflow occurred."):
        super().__init__(message)

class TileSizeError(Exception):
    def __init__(self, message="SPAD overflow occurred."):
        super().__init__(message)

class MLIRCodeCache:
    cache = dict()
    clear = staticmethod(cache.clear)   # Todo: Cache

    @staticmethod
    def _load_library(path):
        pass

    @classmethod
    def load(cls, source_code,
             validation_wrapper_name="validation_wrapper",
             validation_binary_name="validation_bin",
             arg_attributes=[], vectorlane_size=16,
             spad_info=None, origins=None, silent_mode=False, **kwargs):
        """Compile MLIR to LLVM IR, assembly, and an optional RISC-V binary.

        This method deliberately has no execution side effects.  In particular,
        it has no simulator or runtime side effects.  DMA
        operations remain in the MLIR and are lowered by the target compiler.
        """
        del origins, silent_mode
        vlen = kwargs.get("vlen", 256)
        vlenb = vlen // 8
        cache_extra = cache_hash_extra(vlen=vlen, vectorlane_size=vectorlane_size)
        write_path = get_write_path(source_code, extra=cache_extra)
        key, input_path = write(
            source_code, "mlir", extra=cache_extra, specified_dir=write_path
        )
        new_input_path = os.path.splitext(input_path)[0]
        validation_binary_path = os.path.join(write_path, validation_binary_name)

        from filelock import FileLock
        os.makedirs(write_path, exist_ok=True)
        lock = FileLock(get_lock_path(write_path), timeout=LOCK_TIMEOUT)
        with lock:
            cmds = mlir_compile_command(new_input_path, vectorlane_size, vlen=vlen)
            for command in cmds:
                try:
                    subprocess.check_call(shlex.split(command))
                except subprocess.CalledProcessError as exc:
                    logger.error("Compiler command failed with exit code %s", exc.returncode)
                    raise

            # The wrapper is a compiler artifact, not a simulator launcher. It
            # is useful for producing a linked target binary for deployment.
            if arg_attributes:
                spad_header = os.path.join(write_path, "global_var.h")
                spad_size = (spad_info or {}).get("spad_size", 0)
                with open(spad_header, "w") as header:
                    header.write("int spad_end[0] __attribute__((section(\".spad\")));\n")
                    if spad_size:
                        header.write(
                            "int spad_section_end[0] __attribute__((section(\".spad\"), "
                            f"aligned({spad_size * vectorlane_size})));\n"
                        )
                link_option = ""
                if spad_info and spad_info.get("spad_vaddr") is not None:
                    link_option = f"-Wl,--section-start=.spad=0x{spad_info['spad_vaddr']:x}"
                caller = MLIRKernelCallerCodeGen(True, arg_attributes)
                caller.generate_wrapper_file(write_path, validation_wrapper_name)
                caller.compile_wih_kernel(
                    write_path, key, validation_wrapper_name,
                    validation_binary_name, link_option
                )
                if spad_info and spad_info.get("spad_size") is not None:
                    stack_size = caller.parse_stack_sizes(
                        f"{write_path}/{key}.s", vlenb=vlenb
                    ) or 0
                    used_spad = stack_size + caller.get_spad_size(validation_binary_path)
                    if used_spad > spad_info["spad_size"]:
                        raise SpadOverflowError(
                            f"Scratchpad size exceeded: required {used_spad} bytes, "
                            f"available {spad_info['spad_size']} bytes"
                        )
        return key

class CustomAsyncCompile(AsyncCompile):
    def __init__(self):
        self.validation_wrapper_name = "validation_wrapper"
        self.validation_binary_name = "validation_binary"

    def mlir(self, source_code, arg_attributes=[], vectorlane_size=16,
             tile_size=[], spad_info=None, origins=None, silent_mode=False, **kwargs):
        """Schedule compilation and return a non-executing artifact handle."""
        del tile_size, silent_mode
        def task():
            return MLIRCodeCache.load(
                source_code,
                validation_wrapper_name=self.validation_wrapper_name,
                validation_binary_name=self.validation_binary_name,
                arg_attributes=arg_attributes,
                vectorlane_size=vectorlane_size,
                spad_info=spad_info,
                origins=origins,
                **kwargs,
            )
        future = self.submit(task)

        def compiled_artifact(*args, **call_kwargs):
            del args, call_kwargs
            # Calling a compiler-only handle cannot execute target code. Waiting
            # here still provides the same asynchronous compilation guarantee.
            return future.result()

        return compiled_artifact
