"""Compiler-only smoke checks that do not require a device or simulator."""
from pathlib import Path
import ast

ROOT = Path(__file__).resolve().parents[1]


def test_frontend_sources_parse():
    for path in (ROOT / "PyTorchSimFrontend").rglob("*.py"):
        ast.parse(path.read_text(), filename=str(path))


def test_compiler_configuration_is_deterministic():
    config = (ROOT / "configs" / "compiler_only.yml").read_text()
    assert "codegen_mapping_strategy: heuristic" in config
    assert "codegen_compiler_optimization: all" in config
    assert "TOGSIM" not in config.upper()


def test_compiler_cache_has_no_runtime_launchers():
    source = (ROOT / "PyTorchSimFrontend" / "extension_codecache.py").read_text()
    forbidden = ("TOGSimulator", "gem5", "spike", "qemu", "torch.npu.launch_kernel")
    assert not any(token in source for token in forbidden)


if __name__ == "__main__":
    test_frontend_sources_parse()
    test_compiler_configuration_is_deterministic()
    test_compiler_cache_has_no_runtime_launchers()
    print("compiler-only smoke checks passed")
