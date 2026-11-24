#!/usr/bin/env python3
"""
Cross-compile AOSP 17 Rust proc-macros (host x86_64), crates (.rlib),
host tools (protoc-gen-rs), and rust_ffi_static (.a) archives for aarch64-linux-android.
Reads crate specs directly from Android.bp using tools/bp_parser.py.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
GEN = ROOT / "build" / "generated"
HOST_BIN = ROOT / "build" / "host-tools" / "bin"
TARGET_LIBS = ROOT / "build" / "target-libs"
RUST_BUILD = ROOT / "build" / "rust"

NDK_ROOT = Path(os.environ.get("ANDROID_NDK_HOME", "/home/ubuntu/Android/Sdk/ndk/28.2.13676358"))
NDK_LLVM_BIN = NDK_ROOT / "toolchains" / "llvm" / "prebuilt" / "linux-x86_64" / "bin"
TARGET_CC = NDK_LLVM_BIN / "aarch64-linux-android30-clang"
TARGET_AR = NDK_LLVM_BIN / "llvm-ar"

HOST_TRIPLE = "x86_64-unknown-linux-gnu"
ANDROID_TRIPLE = "aarch64-linux-android"

sys.path.insert(0, str(ROOT / "tools"))
from bp_parser import BpModule, eval_expr, parse_bp_file, resolve_select  # noqa: E402


def find_rustc() -> Path:
    for cand in [
        Path.home() / ".cargo" / "bin" / "rustc",
        Path(shutil.which("rustc") or ""),
    ]:
        if cand and cand.is_file():
            return cand
    raise FileNotFoundError("rustc not found in ~/.cargo/bin or PATH")


def get_rustc_version(rustc: Path) -> str:
    res = subprocess.run([str(rustc), "--version"], capture_output=True, text=True, check=True)
    m = re.search(r"rustc\s+(\d+\.\d+\.\d+)", res.stdout)
    if not m:
        raise RuntimeError(f"Could not parse rustc version from: {res.stdout!r}")
    return m.group(1)


class RustBuilder:
    def __init__(self, rustc: Path, force: bool = False):
        self.rustc = rustc
        self.rustc_version = get_rustc_version(rustc)
        self.force = force
        self.modules: dict[str, BpModule] = {}
        self.defaults: dict[str, BpModule] = {}
        self.built: dict[tuple[str, bool], Path] = {}
        self._load_bps()

    def _load_bps(self) -> None:
        crates_dir = SRC / "external" / "rust" / "android-crates-io" / "crates"
        bp_paths = sorted(crates_dir.glob("*/Android.bp")) + [
            SRC / "external" / "rust" / "cxx" / "Android.bp",
            SRC / "external" / "rust" / "cxx" / "macro" / "Android.bp",
            SRC / "system" / "logging" / "rust" / "Android.bp",
            SRC / "system" / "server_configurable_flags" / "libflags" / "Android.bp",
            SRC / "build" / "make" / "tools" / "aconfig" / "aconfig_storage_file" / "Android.bp",
            SRC / "build" / "make" / "tools" / "aconfig" / "aconfig_storage_read_api" / "Android.bp",
            SRC / "frameworks" / "minikin" / "rust" / "Android.bp",
            SRC / "frameworks" / "native" / "libs" / "input" / "rust" / "Android.bp",
            SRC / "frameworks" / "native" / "libs" / "input" / "Android.bp",
            SRC / "frameworks" / "native" / "libs" / "binder" / "rust" / "Android.bp",
            SRC / "external" / "skia" / "Android.bp",
        ]
        for bp in bp_paths:
            if not bp.exists():
                continue
            for m in parse_bp_file(bp, root_dir=SRC):
                if not m.name:
                    continue
                if m.module_type == "rust_defaults":
                    self.defaults[m.name] = m
                elif m.module_type.startswith("rust_") or m.module_type == "aconfig_library":
                    self.modules[m.name] = m

    def _collect_defaults(self, mod: BpModule) -> list[BpModule]:
        chain: list[BpModule] = []
        seen: set[str] = set()

        def visit(m: BpModule) -> None:
            for dname in resolve_select(m.props.get("defaults", [])) or []:
                if dname in seen:
                    continue
                seen.add(dname)
                dm = self.defaults.get(dname)
                if dm:
                    visit(dm)
                    chain.append(dm)

        visit(mod)
        chain.append(mod)
        return chain

    def _extract_props(self, mod: BpModule, is_host: bool) -> dict[str, Any]:
        merged: dict[str, Any] = {
            "features": [],
            "cfgs": [],
            "flags": [],
            "rustlibs": [],
            "proc_macros": [],
            "aliases": [],
            "srcs": [],
            "edition": None,
            "crate_name": None,
            "crate_root": None,
            "cargo_pkg_version": None,
            "cargo_env_compat": False,
        }
        if is_host:
            active_targets = {"host", "not_windows", "linux", "linux_glibc", "linux_x86_64"}
        else:
            active_targets = {"android", "not_windows", "linux", "linux_bionic", "arm64", "android_arm64"}

        list_keys = ("features", "cfgs", "flags", "rustlibs", "proc_macros", "aliases", "srcs")
        scalar_keys = ("edition", "crate_name", "crate_root", "cargo_pkg_version", "cargo_env_compat")

        def apply_block(blk: dict[str, Any]) -> None:
            for k in list_keys:
                if k in blk:
                    val = resolve_select(blk[k])
                    if isinstance(val, list):
                        for item in val:
                            if isinstance(item, str) and item not in merged[k]:
                                merged[k].append(item)
            for k in scalar_keys:
                if k in blk:
                    val = resolve_select(blk[k])
                    if val is not None:
                        merged[k] = val

        for layer in self._collect_defaults(mod):
            apply_block(layer.props)
            tgt = layer.props.get("target")
            if isinstance(tgt, dict):
                for tkey, tblk in tgt.items():
                    if tkey in active_targets and isinstance(tblk, dict):
                        apply_block(tblk)

        return merged

    def ensure_aconfig_storage_protos(self) -> Path:
        out_dir = GEN / "rust_protos" / "libaconfig_storage_protos"
        mod_rs = out_dir / "mod.rs"
        gen_rs = out_dir / "aconfig_storage_metadata.rs"
        proto_dir = SRC / "build" / "make" / "tools" / "aconfig" / "aconfig_storage_file" / "protos"
        proto_file = proto_dir / "aconfig_storage_metadata.proto"

        if not self.force and mod_rs.exists() and gen_rs.exists():
            if mod_rs.stat().st_mtime >= proto_file.stat().st_mtime:
                return mod_rs

        protoc_gen_rs = self.build_module("protoc-gen-rs", is_host=True)
        protoc = HOST_BIN / "protoc"
        out_dir.mkdir(parents=True, exist_ok=True)
        cmd = [
            str(protoc),
            f"--plugin=protoc-gen-rs={protoc_gen_rs}",
            f"--rs_out={out_dir}",
            f"-I{proto_dir}",
            str(proto_file),
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            raise RuntimeError(f"protoc-gen-rs failed:\n{res.stderr}")
        if not mod_rs.exists():
            mod_rs.write_text("pub mod aconfig_storage_metadata;\n", encoding="utf-8")
        print(f"[ok] protoc-gen-rs -> {mod_rs.relative_to(ROOT)}")
        return mod_rs

    def _resolve_special_crate(self, name: str, is_host: bool) -> dict[str, Any] | None:
        if name == "libaconfig_storage_protos":
            mod_rs = self.ensure_aconfig_storage_protos()
            return {
                "crate_name": "aconfig_storage_protos",
                "crate_root": mod_rs,
                "edition": "2021",
                "rustlibs": ["libprotobuf"],
                "proc_macros": [],
                "features": [],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": mod_rs.parent,
            }
        if name == "libinput_bindgen":
            rs = GEN / "bindgen" / "libinput_bindgen" / "bindings.rs"
            return {
                "crate_name": "input_bindgen",
                "crate_root": rs,
                "edition": "2021",
                "rustlibs": [],
                "proc_macros": [],
                "features": [],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": rs.parent,
            }
        if name == "libinput_flags_rust":
            rs = GEN / "aconfig" / "libinput_flags_rust" / "src" / "lib.rs"
            return {
                "crate_name": "input_flags",
                "crate_root": rs,
                "edition": "2021",
                "rustlibs": [],
                "proc_macros": [],
                "features": [],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": rs.parent,
            }
        if name == "libandroid_text_flags_rust":
            rs = GEN / "aconfig" / "libandroid_text_flags_rust" / "src" / "lib.rs"
            return {
                "crate_name": "android_text_flags_rust",
                "crate_root": rs,
                "edition": "2021",
                "rustlibs": [],
                "proc_macros": [],
                "features": [],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": rs.parent,
            }
        if name == "libbinder_ndk_compat_bindgen":
            rs = GEN / "bindgen" / "libbinder_ndk_compat_bindgen" / "bindings.rs"
            return {
                "crate_name": "binder_ndk_compat_bindgen",
                "crate_root": rs,
                "edition": "2021",
                "rustlibs": ["libbinder_ndk_sys"],
                "proc_macros": [],
                "features": [],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": rs.parent,
            }
        if name == "inputconstants-rust":
            rs = self._ensure_inputconstants_rust_root()
            return {
                "crate_name": "inputconstants",
                "crate_root": rs,
                "edition": "2021",
                "rustlibs": ["libbinder_rs", "libzerocopy"],
                "proc_macros": ["libasync_trait"],
                "features": ["std"],
                "cfgs": [],
                "flags": [],
                "aliases": [],
                "cargo_pkg_version": "0.1.0",
                "mod_dir": rs.parent,
            }
        return None

    def _ensure_inputconstants_rust_root(self) -> Path:
        base = GEN / "aidl" / "inputconstants-rust"
        lib_rs = base / "lib.rs"
        os_dir = base / "android" / "os"
        mods = sorted(p.stem for p in os_dir.glob("*.rs") if p.stem != "mod")
        os_mod = os_dir / "mod.rs"
        os_mod.write_text("\n".join(f"pub mod {m};" for m in mods) + "\n", encoding="utf-8")
        (base / "android" / "mod.rs").write_text("pub mod os;\n", encoding="utf-8")
        desired = '#![allow(warnings)]\nextern crate alloc;\npub mod aidl {\n    #[path = "../android/mod.rs"]\n    pub mod android;\n}\n'
        # Put mod.rs inside aidl/ for canonical path resolution
        aidl_dir = base / "aidl"
        aidl_dir.mkdir(parents=True, exist_ok=True)
        (aidl_dir / "mod.rs").write_text('#[path = "../android/mod.rs"]\npub mod android;\n', encoding="utf-8")
        root_txt = "#![allow(warnings)]\nextern crate alloc;\npub mod aidl;\n"
        if not lib_rs.exists() or lib_rs.read_text(encoding="utf-8") != root_txt:
            lib_rs.write_text(root_txt, encoding="utf-8")
        return lib_rs

    def build_module(self, name: str, is_host: bool) -> Path:
        key = (name, is_host)
        if key in self.built:
            return self.built[key]

        special = self._resolve_special_crate(name, is_host)
        if special is not None:
            mod_type = "rust_library"
            props = special
            mod_dir = special["mod_dir"]
        else:
            mod = self.modules.get(name)
            if not mod:
                raise KeyError(f"Unknown Rust module: {name}")
            mod_type = mod.module_type
            # rust_proc_macro and *_host always compile for host
            if mod_type == "rust_proc_macro" or mod_type.endswith("_host"):
                is_host = True
                key = (name, True)
                if key in self.built:
                    return self.built[key]
            props = self._extract_props(mod, is_host=is_host)
            mod_dir = SRC / mod.rel_dir
            crate_root_rel = props["crate_root"]
            if not crate_root_rel:
                rs_srcs = [s for s in props["srcs"] if isinstance(s, str) and s.endswith(".rs") and not s.startswith(":")]
                crate_root_rel = rs_srcs[0] if rs_srcs else "src/lib.rs"
            props["crate_root"] = mod_dir / crate_root_rel
            if not props["crate_name"]:
                props["crate_name"] = name.removeprefix("lib").replace("-", "_")

        # 1. Build dependencies recursively
        alias_map: dict[str, str] = {}
        for a in props.get("aliases", []):
            if ":" in a:
                orig, new = a.split(":", 1)
                alias_map[orig] = new

        extern_args: list[str] = []
        for dep in props.get("rustlibs", []):
            dep_path = self.build_module(dep, is_host=is_host)
            dep_special = self._resolve_special_crate(dep, is_host)
            if dep_special:
                dep_cname = dep_special["crate_name"]
            else:
                dep_mod = self.modules[dep]
                dep_props = self._extract_props(dep_mod, is_host=is_host)
                dep_cname = dep_props["crate_name"] or dep.removeprefix("lib").replace("-", "_")
            ext_name = alias_map.get(dep, alias_map.get(dep_cname, dep_cname))
            # Check alias keyed by module name
            if dep in alias_map:
                ext_name = alias_map[dep]
            elif dep_cname in alias_map:
                ext_name = alias_map[dep_cname]
            extern_args.extend(["--extern", f"{ext_name}={dep_path}"])

        for pm in props.get("proc_macros", []):
            pm_path = self.build_module(pm, is_host=True)
            pm_mod = self.modules[pm]
            pm_props = self._extract_props(pm_mod, is_host=True)
            pm_cname = pm_props["crate_name"] or pm.removeprefix("lib").replace("-", "_")
            extern_args.extend(["--extern", f"{pm_cname}={pm_path}"])

        # 2. Output artifact path & crate-type
        arch_tag = "host" if is_host else "arm64"
        deps_dir = RUST_BUILD / arch_tag / "deps"
        host_deps_dir = RUST_BUILD / "host" / "deps"
        deps_dir.mkdir(parents=True, exist_ok=True)
        host_deps_dir.mkdir(parents=True, exist_ok=True)
        HOST_BIN.mkdir(parents=True, exist_ok=True)
        TARGET_LIBS.mkdir(parents=True, exist_ok=True)

        cname = props["crate_name"]
        safe_id = name.replace("-", "_")

        if mod_type == "rust_proc_macro":
            crate_type = "proc-macro"
            out_path = host_deps_dir / f"lib{cname}-{safe_id}.so"
        elif mod_type == "rust_ffi_static":
            crate_type = "staticlib"
            out_path = TARGET_LIBS / f"{name}.a"
        elif mod_type == "rust_binary_host":
            crate_type = "bin"
            out_path = HOST_BIN / name
        else:
            crate_type = "rlib"
            out_path = deps_dir / f"lib{cname}-{safe_id}.rlib"

        # 3. Build rustc command
        triple = HOST_TRIPLE if is_host else ANDROID_TRIPLE
        cmd = [
            str(self.rustc),
            str(props["crate_root"]),
            "--crate-name", cname,
            "--crate-type", crate_type,
            "--edition", str(props["edition"] or "2021"),
            "--target", triple,
            "-C", "opt-level=2",
            "--cap-lints=allow",
            "-L", f"dependency={deps_dir}",
        ]
        if not is_host:
            cmd.extend(["-L", f"dependency={host_deps_dir}"])
            cmd.extend(["-C", f"linker={TARGET_CC}"])
            cmd.extend(["-C", "relocation-model=pic"])

        if mod_type == "rust_proc_macro":
            cmd.extend(["--extern", "proc_macro"])

        if crate_type in ("rlib", "proc-macro"):
            cmd.extend(["-C", f"metadata={safe_id}", "-C", f"extra-filename=-{safe_id}"])
            cmd.extend(["--out-dir", str(out_path.parent)])
        else:
            cmd.extend(["-o", str(out_path)])

        for feat in props.get("features", []):
            cmd.extend(["--cfg", f'feature="{feat}"'])
        for cfg in props.get("cfgs", []):
            cmd.extend(["--cfg", cfg])
        if name == "librustversion":
            cmd.extend(["--cfg", "soong"])

        for fl in props.get("flags", []):
            if fl.startswith("-l") or fl.startswith("-L"):
                continue
            cmd.append(fl)

        cmd.extend(extern_args)

        # Skip rebuild if up to date (check root mtime vs output mtime)
        root_mtime = Path(props["crate_root"]).stat().st_mtime
        if not self.force and out_path.exists() and out_path.stat().st_mtime >= root_mtime:
            # Also check if any dep is newer than out_path
            deps_ok = True
            for i, tok in enumerate(extern_args):
                if tok == "--extern" and "=" in extern_args[i + 1]:
                    dp = Path(extern_args[i + 1].split("=", 1)[1])
                    if dp.exists() and dp.stat().st_mtime > out_path.stat().st_mtime:
                        deps_ok = False
                        break
            if deps_ok:
                self.built[key] = out_path
                return out_path

        env = os.environ.copy()
        env["RUSTC_BOOTSTRAP"] = "1"
        env["ANDROID_RUST_VERSION"] = self.rustc_version
        env["CARGO_MANIFEST_DIR"] = str(mod_dir)
        env["CARGO_PKG_NAME"] = name.removeprefix("lib")
        ver = props.get("cargo_pkg_version") or "0.1.0"
        env["CARGO_PKG_VERSION"] = ver
        parts = (ver.split("+")[0].split("-")[0].split(".") + ["0", "0", "0"])[:3]
        env["CARGO_PKG_VERSION_MAJOR"] = parts[0]
        env["CARGO_PKG_VERSION_MINOR"] = parts[1]
        env["CARGO_PKG_VERSION_PATCH"] = parts[2]
        out_subdir = mod_dir / "out"
        if out_subdir.is_dir():
            env["OUT_DIR"] = str(out_subdir)
        elif name == "libaconfig_storage_file":
            env["OUT_DIR"] = str(GEN / "rust_protos")
        elif name == "libbinder_ndk_sys":
            env["OUT_DIR"] = str(GEN / "bindgen" / "libbinder_ndk_bindgen")

        res = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if res.returncode != 0:
            raise RuntimeError(
                f"rustc failed for {name} ({arch_tag}):\n"
                f"CMD: {' '.join(cmd)}\n"
                f"STDERR:\n{res.stderr}"
            )
        if crate_type in ("rlib", "proc-macro"):
            # rustc names file lib<cname>-<safe_id>.{rlib,so}
            if not out_path.exists():
                raise FileNotFoundError(f"Expected rustc output missing: {out_path}")
        print(f"[ok] rust ({arch_tag}, {crate_type}) {name} -> {out_path.relative_to(ROOT)}")
        self.built[key] = out_path
        return out_path


def main() -> None:
    parser = argparse.ArgumentParser(description="Build AOSP Rust targets for host/arm64-bionic")
    parser.add_argument("targets", nargs="+", help="Module names to build (e.g. protoc-gen-rs libaconfig_storage_read_api_cxx_bridge)")
    parser.add_argument("--host", action="store_true", help="Build for x86_64 host instead of aarch64-linux-android")
    parser.add_argument("--force", action="store_true", help="Force rebuild ignoring timestamps")
    args = parser.parse_args()

    rustc = find_rustc()
    builder = RustBuilder(rustc, force=args.force)
    for tgt in args.targets:
        builder.build_module(tgt, is_host=args.host)


if __name__ == "__main__":
    main()
