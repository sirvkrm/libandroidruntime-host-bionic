#!/usr/bin/env python3
"""
Phase 2 Host Codegen Runner for AndroidRuntimeHostBionic.
Generates all non-aconfig derived sources and headers into build/generated/:
  1. toolbox input labels (input.h-labels.h)
  2. cxxbridge C++ headers & bridge sources (cxx/rust.h, minikin, input, skia, aconfig, libflags)
  3. sysprop_cpp properties (HWUIProperties, PlatformProperties)
  4. hidl-gen C++ headers & sources (android.hidl.base@1.0, android.hidl.manager@1.0..1.2)
  5. aidl C++ & Rust bindings (inputconstants, iinputflinger, libgui_window_info, libbinder, deviceproductinfo)
  6. bindgen Rust FFI bindings (libinput_bindgen)
  7. perfetto protos & version header (cppgen_plugin, protozero_plugin, ipc_plugin)
  8. flatc mutable FlatBuffers schema (tflite schema_generated.h)
  9. stats-log-api-gen C++ metrics helpers (statslog_input, statslog_libinput)
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
GEN = ROOT / "build" / "generated"
BIN = ROOT / "build" / "host-tools" / "bin"

sys.path.insert(0, str(ROOT / "tools"))
from bp_parser import parse_bp_file  # noqa: E402


def run(cmd: list[str], cwd: Path | None = None, env: dict[str, str] | None = None, stdout_path: Path | None = None) -> None:
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    if stdout_path is not None:
        stdout_path.parent.mkdir(parents=True, exist_ok=True)
        res = subprocess.run(cmd, cwd=cwd, env=merged_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            print(f"FAILED: {' '.join(cmd)}\n{res.stderr}", file=sys.stderr)
            sys.exit(res.returncode)
        stdout_path.write_text(res.stdout, encoding="utf-8")
    else:
        res = subprocess.run(cmd, cwd=cwd, env=merged_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            print(f"FAILED: {' '.join(cmd)}\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}", file=sys.stderr)
            sys.exit(res.returncode)


def gen_toolbox_labels() -> None:
    out = GEN / "toolbox" / "include" / "input.h-labels.h"
    script = SRC / "system" / "core" / "toolbox" / "generate-input.h-labels.py"
    hdrs = [
        SRC / "bionic" / "libc" / "kernel" / "uapi" / "linux" / "input.h",
        SRC / "bionic" / "libc" / "kernel" / "uapi" / "linux" / "input-event-codes.h",
    ]
    run([sys.executable, str(script)] + [str(h) for h in hdrs], stdout_path=out)
    print(f"[ok] toolbox_input_labels -> {out.relative_to(ROOT)}")


def gen_cxxbridge() -> None:
    cxxbridge = str(BIN / "cxxbridge")
    # Global rust/cxx.h
    run([cxxbridge, "--header"], stdout_path=GEN / "cxx" / "include" / "rust" / "cxx.h")

    bridges = [
        (
            "minikin",
            SRC / "frameworks" / "minikin" / "rust" / "minikin.rs",
            GEN / "cxx" / "minikin" / "include" / "minikin_cxx_bridge.rs.h",
            GEN / "cxx" / "minikin" / "minikin_cxx_bridge_generated.cpp",
        ),
        (
            "input",
            SRC / "frameworks" / "native" / "libs" / "input" / "rust" / "lib.rs",
            GEN / "cxx" / "input" / "include" / "input_cxx_bridge.rs.h",
            GEN / "cxx" / "input" / "input_cxx_bridge_generated.cpp",
        ),
        (
            "skia",
            SRC / "external" / "skia" / "src" / "ports" / "fontations" / "src" / "ffi.rs",
            GEN / "cxx" / "skia" / "include" / "src" / "ports" / "fontations" / "src" / "ffi.rs.h",
            GEN / "cxx" / "skia" / "src" / "ports" / "fontations" / "src" / "ffi.cpp",
        ),
        (
            "aconfig_storage_read_api",
            SRC / "build" / "make" / "tools" / "aconfig" / "aconfig_storage_read_api" / "src" / "lib.rs",
            GEN / "cxx" / "aconfig_storage_read_api" / "include" / "aconfig_storage" / "lib.rs.h",
            GEN / "cxx" / "aconfig_storage_read_api" / "aconfig_storage" / "lib.rs.cc",
        ),
        (
            "libflags",
            SRC / "system" / "server_configurable_flags" / "libflags" / "lib.rs",
            GEN / "cxx" / "libflags" / "include" / "rust_libflags_cxx_generated.rs.h",
            GEN / "cxx" / "libflags" / "rust_libflags_cxx_generated.cc",
        ),
    ]
    for name, rs_src, hdr_out, cc_out in bridges:
        run([cxxbridge, str(rs_src), "--header"], stdout_path=hdr_out)
        run([cxxbridge, str(rs_src)], stdout_path=cc_out)
        print(f"[ok] cxxbridge ({name}) -> {hdr_out.name}, {cc_out.name}")


def gen_sysprop() -> None:
    sysprop_cpp = str(BIN / "sysprop_cpp")
    # 1. HWUIProperties.sysprop
    hwui_out = GEN / "sysprop" / "hwui"
    (hwui_out / "include").mkdir(parents=True, exist_ok=True)
    (hwui_out / "public_include").mkdir(parents=True, exist_ok=True)
    (hwui_out / "src").mkdir(parents=True, exist_ok=True)
    run([
        sysprop_cpp,
        "--header-dir", str(hwui_out / "include"),
        "--public-header-dir", str(hwui_out / "public_include"),
        "--source-dir", str(hwui_out / "src"),
        "--include-name", "HWUIProperties.sysprop.h",
        str(SRC / "frameworks" / "base" / "libs" / "hwui" / "HWUIProperties.sysprop"),
    ])
    print("[ok] sysprop_cpp -> HWUIProperties")

    # 2. PlatformProperties (system/libsysprop/srcs/android/sysprop/*.sysprop)
    plat_out = GEN / "sysprop" / "platform"
    hdr_dir = plat_out / "include" / "android" / "sysprop"
    pub_dir = plat_out / "public_include" / "android" / "sysprop"
    src_dir = plat_out / "src"
    hdr_dir.mkdir(parents=True, exist_ok=True)
    pub_dir.mkdir(parents=True, exist_ok=True)
    src_dir.mkdir(parents=True, exist_ok=True)
    sysprops = sorted((SRC / "system" / "libsysprop" / "srcs" / "android" / "sysprop").glob("*.sysprop"))
    for sp in sysprops:
        inc_name = f"android/sysprop/{sp.name}.h"
        run([
            sysprop_cpp,
            "--header-dir", str(hdr_dir),
            "--public-header-dir", str(pub_dir),
            "--source-dir", str(src_dir),
            "--include-name", inc_name,
            str(sp),
        ])
    print(f"[ok] sysprop_cpp -> libPlatformProperties ({len(sysprops)} .sysprop files)")


def gen_hidl() -> None:
    hidl_gen = str(BIN / "hidl-gen")
    pkgs = [
        "android.hidl.base@1.0",
        "android.hidl.manager@1.0",
        "android.hidl.manager@1.1",
        "android.hidl.manager@1.2",
    ]
    inc_out = GEN / "hidl" / "include"
    src_out = GEN / "hidl" / "src"
    inc_out.mkdir(parents=True, exist_ok=True)
    src_out.mkdir(parents=True, exist_ok=True)
    for pkg in pkgs:
        run([
            hidl_gen,
            "-o", str(inc_out),
            "-L", "c++-headers",
            "-r", f"android.hidl:{SRC / 'system' / 'libhidl' / 'transport'}",
            pkg,
        ])
        run([
            hidl_gen,
            "-o", str(src_out),
            "-L", "c++-sources",
            "-r", f"android.hidl:{SRC / 'system' / 'libhidl' / 'transport'}",
            pkg,
        ])
    print(f"[ok] hidl-gen -> {len(pkgs)} HIDL transport packages")


def gen_aidl() -> None:
    aidl = str(BIN / "aidl")

    # 1. inputconstants-cpp & inputconstants-rust
    inp_aidl_dir = SRC / "frameworks" / "native" / "libs" / "input"
    inp_consts = sorted((inp_aidl_dir / "android" / "os").glob("*.aidl"))
    # inputconstants_aidl excludes IInputFlinger & InputChannelCore
    inp_const_files = [
        f for f in inp_consts
        if f.name not in ("IInputFlinger.aidl", "InputChannelCore.aidl")
    ]
    out_ic_cpp = GEN / "aidl" / "inputconstants-cpp"
    (out_ic_cpp / "include").mkdir(parents=True, exist_ok=True)
    (out_ic_cpp / "src").mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=cpp", "--structured",
        "-I", str(inp_aidl_dir),
        "-h", str(out_ic_cpp / "include"),
        "-o", str(out_ic_cpp / "src"),
    ] + [str(f) for f in inp_const_files])

    out_ic_rust = GEN / "aidl" / "inputconstants-rust"
    out_ic_rust.mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=rust", "--structured",
        "-I", str(inp_aidl_dir),
        "-o", str(out_ic_rust),
    ] + [str(f) for f in inp_const_files])
    print(f"[ok] aidl -> inputconstants-cpp & inputconstants-rust ({len(inp_const_files)} aidls)")

    # 2. iinputflinger_aidl_lib_static
    out_iif = GEN / "aidl" / "iinputflinger"
    (out_iif / "include").mkdir(parents=True, exist_ok=True)
    (out_iif / "src").mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=cpp",
        "-I", str(inp_aidl_dir),
        "-I", str(SRC / "frameworks" / "native" / "libs" / "gui"),
        "-I", str(SRC / "frameworks" / "native" / "aidl" / "binder"),
        "-h", str(out_iif / "include"),
        "-o", str(out_iif / "src"),
        str(inp_aidl_dir / "android" / "os" / "IInputFlinger.aidl"),
        str(inp_aidl_dir / "android" / "os" / "InputChannelCore.aidl"),
    ])
    print("[ok] aidl -> iinputflinger_aidl_lib_static")

    # 3. libgui_window_info_static
    gui_dir = SRC / "frameworks" / "native" / "libs" / "gui"
    gui_aidls = sorted((gui_dir / "android" / "gui").glob("*.aidl"))
    out_gui = GEN / "aidl" / "gui_window_info"
    (out_gui / "include").mkdir(parents=True, exist_ok=True)
    (out_gui / "src").mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=cpp",
        "-I", str(gui_dir),
        "-I", str(inp_aidl_dir),
        "-I", str(SRC / "frameworks" / "native" / "aidl" / "binder"),
        "-h", str(out_gui / "include"),
        "-o", str(out_gui / "src"),
    ] + [str(f) for f in gui_aidls])
    print(f"[ok] aidl -> libgui_window_info_static ({len(gui_aidls)} aidls)")

    # 4. libbinder aidls
    binder_aidl_dir = SRC / "frameworks" / "native" / "libs" / "binder" / "aidl"
    binder_aidls = [
        binder_aidl_dir / "android" / "os" / "ConnectionInfo.aidl",
        binder_aidl_dir / "android" / "os" / "IClientCallback.aidl",
        binder_aidl_dir / "android" / "os" / "IServiceCallback.aidl",
        binder_aidl_dir / "android" / "os" / "IServiceManager.aidl",
        binder_aidl_dir / "android" / "os" / "Service.aidl",
        binder_aidl_dir / "android" / "os" / "ServiceWithMetadata.aidl",
        binder_aidl_dir / "android" / "os" / "ServiceDebugInfo.aidl",
        binder_aidl_dir / "android" / "os" / "IAccessor.aidl",
    ]
    fw_java_dir = SRC / "frameworks" / "base" / "core" / "java"
    fw_binder_aidls = [
        fw_java_dir / "android" / "os" / "binder" / "IBinderStatsConsumerService.aidl",
        fw_java_dir / "android" / "os" / "binder" / "BinderCallsStats.aidl",
        fw_java_dir / "android" / "os" / "binder" / "BinderSpamStats.aidl",
        fw_java_dir / "android" / "os" / "binder" / "SingleSecondBinderStats.aidl",
        fw_java_dir / "android" / "app" / "privatecompute" / "IPccSandboxManagerNative.aidl",
    ]
    out_binder = GEN / "aidl" / "libbinder"
    (out_binder / "include").mkdir(parents=True, exist_ok=True)
    (out_binder / "src").mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=cpp",
        "-I", str(binder_aidl_dir),
        "-I", str(fw_java_dir),
        "-I", str(SRC / "frameworks" / "native" / "aidl" / "binder"),
        "-h", str(out_binder / "include"),
        "-o", str(out_binder / "src"),
    ] + [str(f) for f in binder_aidls + fw_binder_aidls])
    print(f"[ok] aidl -> libbinder ({len(binder_aidls) + len(fw_binder_aidls)} aidls)")

    # 5. deviceproductinfoconstants_aidl (needed by core/jni/android_view_SurfaceControl.cpp)
    dpi_dir = SRC / "frameworks" / "native" / "aidl"
    out_dpi = GEN / "aidl" / "deviceproductinfoconstants"
    (out_dpi / "include").mkdir(parents=True, exist_ok=True)
    (out_dpi / "src").mkdir(parents=True, exist_ok=True)
    run([
        aidl, "--lang=cpp",
        "-I", str(dpi_dir),
        "-h", str(out_dpi / "include"),
        "-o", str(out_dpi / "src"),
        str(dpi_dir / "android" / "hardware" / "display" / "IDeviceProductInfoConstants.aidl"),
    ])
    print("[ok] aidl -> deviceproductinfoconstants_aidl")


def gen_bindgen() -> None:
    bindgen = str(BIN / "bindgen")
    inp_bp = parse_bp_file(SRC / "frameworks" / "native" / "libs" / "input" / "Android.bp")
    bg_mod = next(m for m in inp_bp if m.name == "libinput_bindgen")
    flags = [f for f in bg_mod.props.get("bindgen_flags", []) if f != "--verbose"]

    out_dir = GEN / "bindgen" / "libinput_bindgen"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_rs = out_dir / "bindings.rs"

    ndk_prebuilt = Path("/home/ubuntu/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64")
    ndk_sysroot = ndk_prebuilt / "sysroot"
    wrapper = SRC / "frameworks" / "native" / "libs" / "input" / "InputWrapper.hpp"
    inc_dirs = [
        SRC / "frameworks" / "native" / "include",
        SRC / "frameworks" / "native" / "libs" / "ftl" / "include",
        SRC / "frameworks" / "native" / "libs" / "math" / "include",
        SRC / "frameworks" / "native" / "libs" / "arect" / "include",
        SRC / "frameworks" / "native" / "libs" / "binder" / "include",
        SRC / "frameworks" / "native" / "libs" / "ui" / "include",
        SRC / "frameworks" / "native" / "libs" / "ui" / "include_types",
        SRC / "frameworks" / "native" / "libs" / "nativewindow" / "include",
        SRC / "frameworks" / "native" / "libs" / "nativebase" / "include",
        SRC / "system" / "libbase" / "include",
        SRC / "external" / "fmtlib" / "include",
        SRC / "system" / "core" / "libutils" / "include",
        SRC / "system" / "core" / "libutils" / "binder" / "include",
        SRC / "system" / "core" / "libcutils" / "include",
        SRC / "system" / "core" / "libsystem" / "include",
        SRC / "system" / "core" / "include",
        SRC / "system" / "logging" / "liblog" / "include",
        SRC / "bionic" / "libc" / "kernel" / "uapi",
        SRC / "bionic" / "libc" / "kernel" / "android" / "uapi",
        GEN / "aidl" / "inputconstants-cpp" / "include",
        GEN / "aidl" / "libbinder" / "include",
    ]
    clang_args = [
        "--target=aarch64-linux-android30",
        f"--sysroot={ndk_sysroot}",
        "-x", "c++",
        "-std=gnu++20",
        "-isystem", str(ndk_sysroot / "usr" / "include" / "c++" / "v1"),
        "-isystem", str(ndk_prebuilt / "lib" / "clang" / "19" / "include"),
        "-isystem", str(ndk_sysroot / "usr" / "include" / "aarch64-linux-android"),
        "-isystem", str(ndk_sysroot / "usr" / "include"),
    ]
    for d in inc_dirs:
        if d.exists():
            clang_args.extend(["-I", str(d)])

    run(
        [bindgen, str(wrapper), "--output", str(out_rs)]
        + flags
        + ["--"]
        + clang_args,
        env={"LIBCLANG_PATH": "/usr/lib/llvm-21/lib"},
    )
    print(f"[ok] bindgen -> {out_rs.relative_to(ROOT)}")

    # 2. libbinder_ndk_bindgen & libbinder_ndk_compat_bindgen
    binder_bp = parse_bp_file(SRC / "frameworks" / "native" / "libs" / "binder" / "rust" / "Android.bp")
    binder_ndk_incs = [
        SRC / "frameworks" / "native" / "libs" / "binder" / "ndk" / "include_ndk",
        SRC / "frameworks" / "native" / "libs" / "binder" / "ndk" / "include_cpp",
        SRC / "frameworks" / "native" / "libs" / "binder" / "ndk" / "include_platform",
        SRC / "libnativehelper" / "include_jni",
    ]
    binder_clang_args = [
        "--target=aarch64-linux-android30",
        f"--sysroot={ndk_sysroot}",
        "-x", "c++",
        "-std=gnu++20",
        "-DANDROID_PLATFORM",
        "-D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__",
        "-Wno-unguarded-availability",
        "-isystem", str(ndk_sysroot / "usr" / "include" / "c++" / "v1"),
        "-isystem", str(ndk_prebuilt / "lib" / "clang" / "19" / "include"),
        "-isystem", str(ndk_sysroot / "usr" / "include" / "aarch64-linux-android"),
        "-isystem", str(ndk_sysroot / "usr" / "include"),
    ]
    for d in binder_ndk_incs:
        binder_clang_args.extend(["-I", str(d)])

    # libbinder_ndk_bindgen
    b_flags_file = SRC / "frameworks" / "native" / "libs" / "binder" / "rust" / "libbinder_ndk_bindgen_flags.txt"
    b_flags = [l.strip() for l in b_flags_file.read_text().splitlines() if l.strip()]
    b_def = next(m for m in binder_bp if m.name == "libbinder_ndk_bindgen_defaults")
    b_flags.extend([f for f in b_def.props.get("bindgen_flags", []) if f != "--verbose"])
    out_bnd = GEN / "bindgen" / "libbinder_ndk_bindgen"
    out_bnd.mkdir(parents=True, exist_ok=True)
    run(
        [bindgen, str(SRC / "frameworks/native/libs/binder/rust/sys/BinderBindings.hpp"),
         "--output", str(out_bnd / "bindings.rs")] + b_flags + ["--"] + binder_clang_args,
        env={"LIBCLANG_PATH": "/usr/lib/llvm-21/lib"},
    )
    print(f"[ok] bindgen -> {(out_bnd / 'bindings.rs').relative_to(ROOT)}")

    # libbinder_ndk_compat_bindgen
    bc_mod = next(m for m in binder_bp if m.name == "libbinder_ndk_compat_bindgen")
    bc_flags = [f for f in bc_mod.props.get("bindgen_flags", []) if f != "--verbose"]
    out_cmp = GEN / "bindgen" / "libbinder_ndk_compat_bindgen"
    out_cmp.mkdir(parents=True, exist_ok=True)
    run(
        [bindgen, str(SRC / "frameworks/native/libs/binder/rust/src/cpp/include/binder_rust.hpp"),
         "--output", str(out_cmp / "bindings.rs")] + bc_flags + ["--"] + binder_clang_args,
        env={"LIBCLANG_PATH": "/usr/lib/llvm-21/lib"},
    )
    print(f"[ok] bindgen -> {(out_cmp / 'bindings.rs').relative_to(ROOT)}")


def gen_perfetto() -> None:
    perf_dir = SRC / "external" / "perfetto"
    out_inc = GEN / "perfetto" / "include"
    if out_inc.exists():
        shutil.rmtree(out_inc)
    out_inc.mkdir(parents=True, exist_ok=True)

    # 1. perfetto_version.gen.h
    run([
        sys.executable,
        str(perf_dir / "tools" / "write_version_header.py"),
        "--no_git",
        "--changelog", str(perf_dir / "CHANGELOG"),
        "--cpp_out", str(out_inc / "perfetto_version.gen.h"),
    ])

    # 2. All proto genrules required by graph_host_linux.json
    g = json.load(open(ROOT / "map" / "graph_host_linux.json"))
    needed_gens = {
        k for k, v in g["nodes"].items()
        if k.startswith("perfetto_protos_") and v.get("module_type") == "genrule"
    }
    bp_mods = {m.name: m for m in parse_bp_file(perf_dir / "Android.bp")}

    filegroups = {
        name: m.props.get("srcs", [])
        for name, m in bp_mods.items()
        if m.module_type == "filegroup"
    }

    protoc = str(BIN / "protoc")
    seen_invocations: set[tuple[str, str, tuple[str, ...]]] = set()
    proto_count = 0

    for gen_name in sorted(needed_gens):
        m = bp_mods.get(gen_name)
        if not m:
            continue
        cmd = m.props.get("cmd", "")
        if "cppgen_plugin" in cmd:
            plugin = str(BIN / "cppgen_plugin")
            wrapper_ns = "gen"
        elif "protozero_plugin" in cmd:
            plugin = str(BIN / "protozero_plugin")
            wrapper_ns = "pbzero"
        elif "ipc_plugin" in cmd:
            plugin = str(BIN / "ipc_plugin")
            wrapper_ns = "gen"
        else:
            continue

        # Only expand the filegroups explicitly passed to protoc in $(locations :...)
        target_fgs = re.findall(r"\$\(locations\s+:([^)\s]+)\)", cmd)
        fg_files: list[str] = []
        if target_fgs:
            for fg in target_fgs:
                for item in filegroups.get(fg, []):
                    if item.endswith(".proto") and item not in fg_files:
                        fg_files.append(item)
        else:
            for s in m.props.get("srcs", []):
                if s.startswith(":"):
                    for item in filegroups.get(s[1:], []):
                        if item.endswith(".proto") and item not in fg_files:
                            fg_files.append(item)
                elif s.endswith(".proto") and s not in fg_files:
                    fg_files.append(s)

        key = (plugin, wrapper_ns, tuple(fg_files))
        if key in seen_invocations or not fg_files:
            continue
        seen_invocations.add(key)

        proto_paths = [str(perf_dir / f) for f in fg_files]
        run([
            protoc,
            f"--proto_path={perf_dir}",
            f"--plugin=protoc-gen-plugin={plugin}",
            f"--plugin_out=wrapper_namespace={wrapper_ns}:{out_inc}",
        ] + proto_paths)
        proto_count += len(proto_paths)

    print(f"[ok] perfetto -> version header + {len(seen_invocations)} protoc batches ({proto_count} proto invocations)")


def gen_flatc() -> None:
    flatc = str(BIN / "flatc")
    out_dir = GEN / "flatc" / "include" / "tensorflow" / "lite" / "schema" / "mutable"
    out_dir.mkdir(parents=True, exist_ok=True)
    run([
        flatc,
        "--cpp",
        "--no-union-value-namespacing",
        "--gen-object-api",
        "--gen-mutable",
        "--keep-prefix",
        "-o", str(out_dir),
        str(SRC / "external" / "tensorflow" / "tensorflow" / "lite" / "schema" / "schema.fbs"),
    ])
    print(f"[ok] flatc -> {out_dir / 'schema_generated.h'}")


def gen_statslog() -> None:
    tool = str(BIN / "stats-log-api-gen")
    out_inc = GEN / "statslog" / "include"
    out_src = GEN / "statslog" / "src"
    out_inc.mkdir(parents=True, exist_ok=True)
    out_src.mkdir(parents=True, exist_ok=True)

    atoms_proto = "frameworks/proto_logging/stats/atoms.proto"
    ext_protos = [
        "frameworks/proto_logging/stats/atoms/framework/framework_extension_atoms.proto",
        "frameworks/proto_logging/stats/atoms/input/input_extension_atoms.proto",
    ]
    # Note: --proto accepts atoms.proto plus extension files
    specs = [
        ("input", "android::input", "statslog_input.h", "statslog_input.cpp"),
        ("libinput", "android::libinput", "statslog_libinput.h", "statslog_libinput.cpp"),
    ]
    for mod, ns, hdr_name, cpp_name in specs:
        run(
            [
                tool,
                "--module", mod,
                "--namespace", ns,
                "--importHeader", hdr_name,
                "--header", str(out_inc / hdr_name),
                "--cpp", str(out_src / cpp_name),
                "--proto", atoms_proto,
            ] + ext_protos + ["--omitExtraSrcs"],
            cwd=SRC,
            env={"ANDROID_BUILD_TOP": str(SRC)},
        )
        print(f"[ok] stats-log-api-gen -> {hdr_name}, {cpp_name}")


def main() -> None:
    GEN.mkdir(parents=True, exist_ok=True)
    gen_toolbox_labels()
    gen_cxxbridge()
    gen_sysprop()
    gen_hidl()
    gen_aidl()
    gen_bindgen()
    gen_perfetto()
    gen_flatc()
    gen_statslog()
    print("\nAll Phase 2 codegen targets succeeded!")


if __name__ == "__main__":
    main()
