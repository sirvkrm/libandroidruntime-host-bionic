#!/usr/bin/env python3
"""Generate AOSP 17 aconfig C++ and Rust flag libraries from .aconfig + cp2a release values."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
RELEASE_DIR = SRC / "build/release"


def get_cp2a_chain() -> list[str]:
    cfg_dir = RELEASE_DIR / "release_configs"
    order: list[str] = []
    seen: set[str] = set()

    def visit(name: str) -> None:
        if name in seen:
            return
        seen.add(name)
        p = cfg_dir / f"{name}.textproto"
        if p.exists():
            txt = p.read_text(encoding="utf-8", errors="replace")
            for inh in re.findall(r'^inherits:\s*"([^"]+)"', txt, re.M):
                visit(inh)
        order.append(name)

    visit("cp2a")
    return order


def load_aconfig_release_values(chain: list[str]) -> dict[tuple[str, str], tuple[bool, str]]:
    """Map (package, flag_name) -> (default_bool, permission)."""
    values: dict[tuple[str, str], tuple[bool, str]] = {}
    base = RELEASE_DIR / "aconfig"
    for cfg in chain:
        cfg_dir = base / cfg
        if not cfg_dir.exists():
            continue
        for tp in sorted(cfg_dir.rglob("*.textproto")):
            txt = tp.read_text(encoding="utf-8", errors="replace")
            for block in re.findall(r"flag_value\s*\{([^}]*)\}", txt, re.S):
                pm = re.search(r'package:\s*"([^"]+)"', block)
                nm = re.search(r'name:\s*"([^"]+)"', block)
                if not pm or not nm:
                    continue
                state = "ENABLED" in block
                perm = "READ_ONLY" if "READ_ONLY" in block else ("READ_WRITE" if "READ_WRITE" in block else "READ_ONLY")
                values[(pm.group(1), nm.group(1))] = (state, perm)
    return values


def parse_aconfig_files(paths: list[Path]) -> tuple[str, str, list[dict]]:
    pkg = ""
    container = "system"
    flags: list[dict] = []
    for p in paths:
        txt = p.read_text(encoding="utf-8", errors="replace")
        # Strip # comments
        lines = []
        for line in txt.splitlines():
            # Keep # outside quotes simply by stripping leading/trailing # comments
            in_q = False
            out_chars = []
            for ch in line:
                if ch == '"':
                    in_q = not in_q
                if ch == "#" and not in_q:
                    break
                out_chars.append(ch)
            lines.append("".join(out_chars))
        clean = "\n".join(lines)
        pm = re.search(r'package:\s*"([^"]+)"', clean)
        if pm:
            pkg = pm.group(1)
        cm = re.search(r'container:\s*"([^"]+)"', clean)
        if cm:
            container = cm.group(1)
        # Extract flag { ... } blocks (handling nested metadata { ... })
        i = 0
        while True:
            m = re.search(r"\bflag\s*\{", clean[i:])
            if not m:
                break
            start = i + m.end()
            depth = 1
            j = start
            while j < len(clean) and depth > 0:
                if clean[j] == "{":
                    depth += 1
                elif clean[j] == "}":
                    depth -= 1
                j += 1
            block = clean[start:j - 1]
            i = j
            nm = re.search(r'\bname:\s*"([^"]+)"', block)
            if not nm:
                continue
            fixed_ro = bool(re.search(r"\bis_fixed_read_only:\s*true\b", block))
            flags.append({
                "name": nm.group(1),
                "is_fixed_read_only": fixed_ro,
            })
    return pkg, container, flags


def generate_cpp(pkg: str, container: str, flags: list[dict], rel_vals: dict, mode: str, out_dir: Path) -> None:
    header = pkg.replace(".", "_")
    pkg_macro = header.upper()
    cpp_ns = pkg.replace(".", "::")
    is_test = (mode == "test")
    force_ro = (mode == "force-read-only")

    inc_dir = out_dir / "include"
    inc_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    elems = []
    rw_idx = 0
    for f in flags:
        fname = f["name"]
        state, perm = rel_vals.get((pkg, fname), (False, "READ_ONLY"))
        default_val = "true" if state else "false"
        is_fixed_ro = f["is_fixed_read_only"]
        if force_ro or is_fixed_ro:
            readwrite = False
        elif perm == "READ_WRITE":
            readwrite = True
        else:
            readwrite = False
        elems.append({
            "flag_name": fname,
            "flag_macro": fname.upper(),
            "default_value": default_val,
            "is_fixed_read_only": is_fixed_ro,
            "readwrite": readwrite,
            "rw_idx": rw_idx if readwrite else -1,
            "flag_offset": rw_idx,
        })
        if readwrite:
            rw_idx += 1

    any_rw = rw_idx > 0
    any_fixed_ro = any(e["is_fixed_read_only"] for e in elems)

    # Header (.h) matching cpp_exported_header.template
    h = ["#pragma once", ""]
    if not is_test and any_rw:
        h += [
            "#if defined(__clang__)",
            "#ifndef ACONFIG_NO_DESTROY",
            "#define ACONFIG_NO_DESTROY [[clang::no_destroy]]",
            "#endif",
            "#else",
            "#ifndef ACONFIG_NO_DESTROY",
            "#define ACONFIG_NO_DESTROY",
            "#endif",
            "#endif",
            "",
        ]
    if not is_test and any_fixed_ro:
        h += [f"#ifndef {pkg_macro}", f"#define {pkg_macro}(FLAG) {pkg_macro}_##FLAG", "#endif"]
        for e in elems:
            if e["is_fixed_read_only"]:
                h += [
                    f"#ifndef {pkg_macro}_{e['flag_macro']}",
                    f"#define {pkg_macro}_{e['flag_macro']} {e['default_value']}",
                    "#endif",
                ]
        h.append("")

    h += ["#ifdef __cplusplus", "", "#include <memory>", "", f"namespace {cpp_ns} {{", "", "class flag_provider_interface {", "public:", "    virtual ~flag_provider_interface() = default;"]
    for e in elems:
        h.append(f"    virtual bool {e['flag_name']}() = 0;")
    if is_test:
        for e in elems:
            h.append(f"    virtual void {e['flag_name']}(bool val) = 0;")
        h.append("    virtual void reset_flags() {}")
    h += ["};", ""]
    no_destroy = "ACONFIG_NO_DESTROY " if (not is_test and any_rw) else ""
    h += [f"{no_destroy}extern std::unique_ptr<flag_provider_interface> provider_;", ""]
    for e in elems:
        ce = "constexpr " if (not is_test and e["is_fixed_read_only"]) else ""
        h.append(f"{ce}inline bool {e['flag_name']}() {{")
        if is_test or e["readwrite"]:
            h.append(f"    return provider_->{e['flag_name']}();")
        elif e["is_fixed_read_only"]:
            h.append(f"    return {pkg_macro}_{e['flag_macro']};")
        else:
            h.append(f"    return {e['default_value']};")
        h.append("}")
        if is_test:
            h += [
                f"inline void {e['flag_name']}(bool val) {{",
                f"    provider_->{e['flag_name']}(val);",
                "}",
            ]
    if is_test:
        h += ["inline void reset_flags() {", "    return provider_->reset_flags();", "}"]
    h += ["", "}", "", 'extern "C" {', "#endif // __cplusplus", ""]
    for e in elems:
        h.append(f"bool {header}_{e['flag_name']}();")
        if is_test:
            h.append(f"void set_{header}_{e['flag_name']}(bool val);")
    if is_test:
        h.append(f"void {header}_reset_flags();")
    h += ["", "#ifdef __cplusplus", "} // extern \"C\"", "#endif", ""]
    (inc_dir / f"{header}.h").write_text("\n".join(h), encoding="utf-8")

    # Source (.cc) matching cpp_source_file.template
    # Note: In Layoutlib host_linux mode on Termux Bionic, storage files in /metadata/aconfig
    # do not exist, so readwrite host builds safely return default cp2a values without reading
    # system storage (#if !defined(__ANDROID__) || defined(LAYOUTLIB_HOST)).
    c = [f'#include "{header}.h"', ""]
    if is_test:
        c += ["#include <unordered_map>", "#include <string>", ""]
    c += [f"namespace {cpp_ns} {{", "", "class flag_provider : public flag_provider_interface {"]
    if is_test:
        c += ["private:", "    std::unordered_map<std::string, bool> overrides_;", ""]
    c += ["public:"]
    if is_test:
        c += ["    flag_provider() : overrides_() {}"]
    for e in elems:
        if is_test:
            c += [
                f"    bool {e['flag_name']}() override {{",
                f'        auto it = overrides_.find("{e["flag_name"]}");',
                f"        return it != overrides_.end() ? it->second : {e['default_value']};",
                "    }",
                f"    void {e['flag_name']}(bool val) override {{",
                f'        overrides_["{e["flag_name"]}"] = val;',
                "    }",
            ]
        elif e["is_fixed_read_only"]:
            c += [
                f"    bool {e['flag_name']}() override {{",
                f"        return {pkg_macro}_{e['flag_macro']};",
                "    }",
            ]
        else:
            c += [
                f"    bool {e['flag_name']}() override {{",
                f"        return {e['default_value']};",
                "    }",
            ]
    if is_test:
        c += ["    void reset_flags() override {", "        overrides_.clear();", "    }"]
    c += [
        "};",
        "",
        "static flag_provider_interface* get_provider_instance() {",
        "    static flag_provider* instance_ = new flag_provider();",
        "    return instance_;",
        "}",
        "",
        "std::unique_ptr<flag_provider_interface> provider_(get_provider_instance());",
        "",
        "}",
        "",
    ]
    for e in elems:
        c += [f"bool {header}_{e['flag_name']}() {{"]
        if is_test or e["readwrite"]:
            c.append(f"    return {cpp_ns}::{e['flag_name']}();")
        elif e["is_fixed_read_only"]:
            c.append(f"    return {pkg_macro}_{e['flag_macro']};")
        else:
            c.append(f"    return {e['default_value']};")
        c.append("}")
        if is_test:
            c += [
                f"void set_{header}_{e['flag_name']}(bool val) {{",
                f"    {cpp_ns}::{e['flag_name']}(val);",
                "}",
            ]
    if is_test:
        c += [f"void {header}_reset_flags() {{", f"    {cpp_ns}::reset_flags();", "}"]
    c.append("")
    (out_dir / f"{header}.cc").write_text("\n".join(c), encoding="utf-8")


def generate_rust(pkg: str, flags: list[dict], rel_vals: dict, out_file: Path) -> None:
    out_file.parent.mkdir(parents=True, exist_ok=True)
    r = [
        "//! codegenerated rust flag lib (host cp2a defaults)",
        "pub struct FlagProvider;",
        "impl FlagProvider {",
    ]
    for f in flags:
        fname = f["name"]
        state, _ = rel_vals.get((pkg, fname), (False, "READ_ONLY"))
        dval = "true" if state else "false"
        r += [f"    pub fn {fname}(&self) -> bool {{ {dval} }}"]
    r += ["}", "pub static PROVIDER: FlagProvider = FlagProvider;"]
    for f in flags:
        fname = f["name"]
        state, _ = rel_vals.get((pkg, fname), (False, "READ_ONLY"))
        dval = "true" if state else "false"
        r += [f"#[inline(always)]", f"pub fn {fname}() -> bool {{ {dval} }}"]
    r.append("")
    out_file.write_text("\n".join(r), encoding="utf-8")


def main() -> None:
    chain = get_cp2a_chain()
    rel_vals = load_aconfig_release_values(chain)
    print(f"Loaded {len(rel_vals)} aconfig flag overrides from cp2a chain ({len(chain)} configs)")

    targets = [
        ("aconfig_text_flags_c_lib", "production", list((SRC / "frameworks/base/core/java/android/text/flags").glob("*.aconfig"))),
        ("aconfig_view_accessibility_flags_c_lib", "production", list((SRC / "frameworks/base/core/java/android/view/accessibility/flags").glob("*.aconfig"))),
        ("android.content.res.flags-aconfig-cc-host-ro", "force-read-only", list((SRC / "frameworks/base/core/java/android/content/res").glob("*.aconfig"))),
        ("android.os.binder.flags-aconfig-cc", "force-read-only", [SRC / "frameworks/native/libs/binder/flags.aconfig"]),
        ("com.android.input.flags-aconfig-cc", "test", [SRC / "frameworks/native/libs/input/input_flags.aconfig"]),
        ("com.android.window.flags.window-aconfig_flags_c_lib", "production", list((SRC / "frameworks/base/core/java/android/window/flags").glob("*.aconfig"))),
        ("hwui_flags_cc_lib", "production", [SRC / "frameworks/base/libs/hwui/aconfig/hwui_flags.aconfig"]),
        ("libcore_jni_flags_c", "production", [SRC / "frameworks/base/core/jni/flags.aconfig"]),
        ("libguiflags", "production", [SRC / "frameworks/native/libs/gui/libgui_flags.aconfig"]),
        ("libsurfaceflingerflags", "production", [
            SRC / "frameworks/native/services/surfaceflinger/surfaceflinger_flags.aconfig",
            SRC / "frameworks/native/services/surfaceflinger/surfaceflinger_flags_new.aconfig",
        ]),
    ]
    gen_root = ROOT / "build/generated/aconfig"
    for name, mode, files in targets:
        pkg, container, flags = parse_aconfig_files(sorted(files))
        generate_cpp(pkg, container, flags, rel_vals, mode, gen_root / name)
        print(f"  {name}: pkg={pkg}, {len(flags)} flags, mode={mode}")

    # Rust aconfig lib: libinput_flags_rust
    pkg, container, flags = parse_aconfig_files([SRC / "frameworks/native/libs/input/input_flags.aconfig"])
    generate_rust(pkg, flags, rel_vals, gen_root / "libinput_flags_rust/src/lib.rs")
    print(f"  libinput_flags_rust: pkg={pkg}, {len(flags)} flags")


if __name__ == "__main__":
    main()
