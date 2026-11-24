#!/usr/bin/env python3
"""Recursive Soong Android.bp dependency mapper for Android 17 host layoutlib / libandroid_runtime."""

from __future__ import annotations

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict, deque
from pathlib import Path
from typing import Any

from bp_parser import BpModule, SelectCall, combine_values, parse_bp_file, resolve_select

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "src"


def load_release_flags(release_dir: Path, config_name: str = "cp2a") -> dict[str, Any]:
    """Load Android 17 release flag values following release_configs inheritance."""
    flags: dict[str, Any] = {}
    decl_dir = release_dir / "flag_declarations"
    if decl_dir.exists():
        for p in sorted(decl_dir.glob("*.textproto")):
            txt = p.read_text(encoding="utf-8", errors="replace")
            m_name = re.search(r'^name:\s*"([^"]+)"', txt, re.M)
            if not m_name:
                continue
            fname = m_name.group(1)
            if "bool_value: true" in txt:
                flags[fname] = True
            elif "bool_value: false" in txt:
                flags[fname] = False
            else:
                m_str = re.search(r'string_value:\s*"([^"]*)"', txt)
                if m_str:
                    flags[fname] = m_str.group(1)

    # Build inheritance chain
    cfg_dir = release_dir / "release_configs"
    order: list[str] = []
    seen: set[str] = set()

    def visit_cfg(name: str) -> None:
        if name in seen:
            return
        seen.add(name)
        p = cfg_dir / f"{name}.textproto"
        if p.exists():
            txt = p.read_text(encoding="utf-8", errors="replace")
            for inh in re.findall(r'^inherits:\s*"([^"]+)"', txt, re.M):
                visit_cfg(inh)
        order.append(name)

    visit_cfg(config_name)
    val_dir = release_dir / "flag_values"
    for cfg in order:
        d = val_dir / cfg
        if not d.exists():
            continue
        for p in sorted(d.glob("*.textproto")):
            txt = p.read_text(encoding="utf-8", errors="replace")
            m_name = re.search(r'^name:\s*"([^"]+)"', txt, re.M)
            if not m_name:
                continue
            fname = m_name.group(1)
            if "bool_value: true" in txt:
                flags[fname] = True
            elif "bool_value: false" in txt:
                flags[fname] = False
            else:
                m_str = re.search(r'string_value:\s*"([^"]*)"', txt)
                if m_str:
                    flags[fname] = m_str.group(1)
    return flags


def parse_manifest(manifest_path: Path) -> list[tuple[str, str]]:
    tree = ET.parse(manifest_path)
    out = []
    for el in tree.getroot().findall("project"):
        p = el.attrib.get("path", "")
        n = el.attrib.get("name", "")
        if p and n:
            out.append((p, n))
    out.sort(key=lambda x: len(x[0]), reverse=True)
    return out


class SoongIndex:
    def __init__(self, src_dir: Path, manifest_path: Path):
        self.src_dir = src_dir
        self.manifest = parse_manifest(manifest_path)
        self.modules: dict[str, list[BpModule]] = defaultdict(list)
        self.module_types: dict[str, str] = {}
        self.parse_errors: list[tuple[str, str]] = []
        self.bp_count = 0

    def repo_for_relpath(self, rel_path: str) -> str:
        for proj_path, _ in self.manifest:
            if rel_path == proj_path or rel_path.startswith(proj_path + "/"):
                return proj_path
        return rel_path.split("/")[0] if "/" in rel_path else rel_path

    def scan(self) -> None:
        for bp_path in sorted(self.src_dir.rglob("Android.bp")):
            rel_dir = str(bp_path.parent.relative_to(self.src_dir))
            repo_path = self.repo_for_relpath(rel_dir)
            self._load_bp(bp_path, repo_path)
        # Also load top-level *.bp files like AconfigFlags.bp / ProtoLibraries.bp in repo roots
        for bp_path in sorted(self.src_dir.rglob("*.bp")):
            if bp_path.name == "Android.bp":
                continue
            rel_dir = str(bp_path.parent.relative_to(self.src_dir))
            repo_path = self.repo_for_relpath(rel_dir)
            self._load_bp(bp_path, repo_path)

    def _load_bp(self, bp_path: Path, repo_path: str) -> None:
        self.bp_count += 1
        try:
            mods = parse_bp_file(bp_path, root_dir=self.src_dir, repo_path=repo_path)
        except Exception as e:
            self.parse_errors.append((str(bp_path), str(e)))
            return
        for m in mods:
            if m.module_type == "soong_config_module_type":
                cname = m.props.get("name")
                btype = m.props.get("module_type")
                if isinstance(cname, str) and isinstance(btype, str):
                    self.module_types[cname] = btype
            if m.name:
                self.modules[m.name].append(m)

    def base_type(self, mtype: str) -> str:
        seen = set()
        cur = mtype
        while cur in self.module_types and cur not in seen:
            seen.add(cur)
            cur = self.module_types[cur]
        return cur

    def get_module(self, name: str, prefer_host: bool = True) -> BpModule | None:
        cands = self.modules.get(name)
        if not cands:
            return None
        if len(cands) == 1:
            return cands[0]
        # Prefer non-prebuilt, non-ndk_library cc_* over prebuilt/ndk stubs when building from source
        for c in cands:
            bt = self.base_type(c.module_type)
            if not bt.startswith("cc_prebuilt") and not bt.endswith("_prebuilt") and bt != "ndk_library":
                return c
        return cands[0]


PROFILE_TARGET_KEYS = {
    "host_linux": ["host", "not_windows", "linux", "host_linux", "linux_bionic", "linux_glibc"],
    "host_linux_arm64": ["host", "not_windows", "linux", "host_linux", "linux_bionic", "linux_glibc", "host_linux_arm64", "linux_bionic_arm64"],
    "host_windows": ["host", "windows", "mingw", "windows_x86_64"],
    "host_darwin": ["host", "not_windows", "darwin"],
    "android_arm64": ["android", "linux", "android_arm64"],
}


def merge_props(base: dict[str, Any], extra: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for k, v in extra.items():
        if k in ("name", "defaults", "target", "arch"):
            continue
        if k in out:
            out[k] = combine_values(out[k], v)
        else:
            out[k] = v
    return out


def flatten_module(
    index: SoongIndex,
    mod: BpModule,
    flags: dict[str, Any],
    profile: str,
    arch: str = "arm64",
    _seen_defaults: set[str] | None = None,
) -> dict[str, Any]:
    """Flatten defaults, select(), target.*, and arch.* into effective properties."""
    seen = set(_seen_defaults or ())
    raw_props = resolve_select(mod.props, flags)
    merged: dict[str, Any] = {}

    defaults = raw_props.get("defaults") or []
    if isinstance(defaults, list):
        for dname in defaults:
            if not isinstance(dname, str) or dname in seen:
                continue
            seen.add(dname)
            dmod = index.get_module(dname)
            if dmod:
                dflat = flatten_module(index, dmod, flags, profile, arch, seen)
                merged = merge_props(merged, dflat)

    def apply_layer(layer: dict[str, Any]) -> None:
        nonlocal merged
        merged = merge_props(merged, layer)
        target_map = layer.get("target")
        if isinstance(target_map, dict):
            for tkey in PROFILE_TARGET_KEYS.get(profile, []):
                sub = target_map.get(tkey)
                if isinstance(sub, dict):
                    merged = merge_props(merged, sub)
                    sub_arch = sub.get("arch")
                    if isinstance(sub_arch, dict) and isinstance(sub_arch.get(arch), dict):
                        merged = merge_props(merged, sub_arch[arch])
        arch_map = layer.get("arch")
        if isinstance(arch_map, dict) and isinstance(arch_map.get(arch), dict):
            merged = merge_props(merged, arch_map[arch])

    apply_layer(raw_props)
    merged["_module_type"] = index.base_type(mod.module_type)
    merged["_orig_type"] = mod.module_type
    merged["_rel_dir"] = mod.rel_dir
    merged["_repo_path"] = mod.repo_path
    merged["_file_path"] = mod.file_path
    merged["_defaults"] = defaults
    return merged


DEP_FIELDS = [
    ("static_libs", "static"),
    ("whole_static_libs", "whole_static"),
    ("shared_libs", "shared"),
    ("header_libs", "header"),
    ("export_static_lib_headers", "export_static_header"),
    ("export_shared_lib_headers", "export_shared_header"),
    ("export_header_lib_headers", "export_header"),
    ("generated_headers", "gen_header"),
    ("generated_sources", "gen_src"),
    ("libs", "aidl_or_lib"),
    ("imports", "aidl_import"),
]


def extract_module_ref(item: str) -> str | None:
    if not isinstance(item, str):
        return None
    if item.startswith(":"):
        # Strip {:tag} suffix e.g. :foo{.h}
        ref = item[1:].split("{", 1)[0]
        return ref
    return None


def is_module_host_enabled(flat: dict[str, Any], mod: BpModule, profile: str) -> bool:
    mtype = flat["_module_type"]
    if mtype in ("cc_library_host_static", "cc_library_host_shared", "cc_binary_host"):
        return True
    if mtype in ("filegroup", "genrule", "gensrcs", "cc_genrule", "aconfig_declarations", "aidl_interface", "sysprop_library"):
        return True
    if "enabled" in flat and flat["enabled"] is False:
        return False
    if mtype in ("cc_library", "cc_library_static", "cc_library_shared", "cc_library_headers", "cc_aconfig_library", "rust_ffi_static", "rust_library"):
        if profile.startswith("host"):
            # Explicit target.<profile>.enabled overrides host_supported
            raw_target = mod.props.get("target") or {}
            for k in PROFILE_TARGET_KEYS.get(profile, []):
                if isinstance(raw_target, dict) and isinstance(raw_target.get(k), dict):
                    if "enabled" in raw_target[k]:
                        return bool(raw_target[k]["enabled"])
            return bool(flat.get("host_supported", False))
    return True


def collect_deps(
    index: SoongIndex,
    mod: BpModule,
    flat: dict[str, Any],
) -> list[tuple[str, str]]:
    deps: list[tuple[str, str]] = []
    mtype = flat["_module_type"]

    for field, kind in DEP_FIELDS:
        vals = flat.get(field)
        if isinstance(vals, list):
            for v in vals:
                if isinstance(v, str):
                    # Handle prebuilt/renamed suffix? Keep raw module name
                    deps.append((v, kind))

    # srcs / local_include_dirs / export_include_dirs colon references
    for src_field in ("srcs", "exclude_srcs", "tools"):
        vals = flat.get(src_field)
        if isinstance(vals, list) and src_field != "exclude_srcs":
            for v in vals:
                if isinstance(v, str):
                    ref = extract_module_ref(v)
                    if ref:
                        deps.append((ref, f"ref_{src_field}"))
                    elif v.endswith(".sysprop") and mtype != "sysprop_library":
                        pass

    if mtype == "cc_aconfig_library":
        decl = flat.get("aconfig_declarations")
        if isinstance(decl, str):
            deps.append((decl, "aconfig_decl"))

    if mtype == "rust_ffi_static" or mtype == "rust_library":
        for rf in ("rustlibs", "proc_macros", "rlibs", "dylibs", "static_libs", "shared_libs"):
            vals = flat.get(rf)
            if isinstance(vals, list):
                for v in vals:
                    if isinstance(v, str):
                        deps.append((v, f"rust_{rf}"))

    if mtype == "aidl_interface":
        # aidl_interface auto-generates <name>-V<ver>-cpp / -ndk / etc.
        pass

    # Also record defaults
    for d in flat.get("_defaults") or []:
        if isinstance(d, str):
            deps.append((d, "default"))

    return deps


def resolve_aidl_virtual(index: SoongIndex, name: str) -> str | None:
    """Map generated AIDL/HIDL/aconfig/sysprop module names back to their defining modules."""
    # AIDL C++/NDK/Rust generated modules: foo-V1-cpp, foo-V1-ndk, foo-rust, etc.
    m = re.match(r"^(.+?)(?:-V\d+)?-(cpp|ndk|ndk_platform|cpp-analyzer|rust)$", name)
    if m:
        base = m.group(1)
        if index.get_module(base):
            return base
    # HIDL generated modules: android.hidl.base@1.0_genc++ / _genc++_headers
    m_hidl = re.match(r"^(.+?)(?:_genc\+\+_headers|_genc\+\+)$", name)
    if m_hidl:
        base = m_hidl.group(1)
        if index.get_module(base):
            return base
    # Aconfig variants: foo-aconfig-cc or foo-aconfig-cc-host-ro
    m2 = re.match(r"^(.+?)-aconfig-cc.*$", name)
    if m2:
        cand = m2.group(1)
        if index.get_module(cand):
            return cand
    # Sysprop C++ library: lib<SyspropName> -> <SyspropName>
    if name.startswith("lib"):
        cand = name[3:]
        m_sys = index.get_module(cand)
        if m_sys and index.base_type(m_sys.module_type) == "sysprop_library":
            return cand
    return None


def trace_graph(
    index: SoongIndex,
    roots: list[str],
    flags: dict[str, Any],
    profile: str,
    arch: str = "arm64",
) -> dict[str, Any]:
    visited: dict[str, dict[str, Any]] = {}
    edges: list[dict[str, str]] = []
    unresolved: dict[str, list[tuple[str, str]]] = defaultdict(list)
    queue: deque[str] = deque(roots)

    while queue:
        name = queue.popleft()
        if name in visited:
            continue
        mod = index.get_module(name)
        resolved_via = None
        if not mod:
            v = resolve_aidl_virtual(index, name)
            if v:
                mod = index.get_module(v)
                resolved_via = v
        if not mod:
            continue

        flat = flatten_module(index, mod, flags, profile, arch)
        host_ok = is_module_host_enabled(flat, mod, profile)
        deps = collect_deps(index, mod, flat)

        # Deduplicate while preserving order
        seen_e = set()
        clean_deps: list[tuple[str, str]] = []
        for dep_name, kind in deps:
            if (dep_name, kind) not in seen_e:
                seen_e.add((dep_name, kind))
                clean_deps.append((dep_name, kind))

        visited[name] = {
            "name": name,
            "resolved_via": resolved_via,
            "module_type": flat["_module_type"],
            "orig_type": flat["_orig_type"],
            "repo_path": flat["_repo_path"],
            "rel_dir": flat["_rel_dir"],
            "host_enabled": host_ok,
            "stl": flat.get("stl"),
            "srcs_count": len(flat.get("srcs") or []) if isinstance(flat.get("srcs"), list) else 0,
            "has_sysprop": any(
                isinstance(s, str) and s.endswith(".sysprop")
                for s in (flat.get("srcs") or [])
            ) if isinstance(flat.get("srcs"), list) else False,
            "has_proto": any(
                isinstance(s, str) and s.endswith(".proto")
                for s in (flat.get("srcs") or [])
            ) if isinstance(flat.get("srcs"), list) else False,
            "deps": [{"target": d, "kind": k} for d, k in clean_deps],
        }

        for dep_name, kind in clean_deps:
            edges.append({"source": name, "target": dep_name, "kind": kind})
            if kind == "default":
                continue
            if dep_name in ("libc++", "libc++_static", "libm", "libc", "libdl"):
                continue
            if dep_name not in visited:
                if index.get_module(dep_name) or resolve_aidl_virtual(index, dep_name):
                    queue.append(dep_name)
                else:
                    unresolved[dep_name].append((name, kind))

    return {
        "profile": profile,
        "roots": roots,
        "nodes": visited,
        "edges": edges,
        "unresolved": {k: v for k, v in sorted(unresolved.items())},
    }


def compute_sccs_and_layers(graph: dict[str, Any]) -> tuple[list[list[str]], list[list[str]]]:
    """Tarjan SCC + topological layering from bottom (leaves) to top (roots)."""
    nodes = graph["nodes"]
    adj: dict[str, list[str]] = {k: [] for k in nodes}
    for e in graph["edges"]:
        if e["kind"] == "default":
            continue
        s, t = e["source"], e["target"]
        if s in nodes and t in nodes and s != t:
            adj[s].append(t)

    # Tarjan's SCC
    index_counter = 0
    indices: dict[str, int] = {}
    lowlink: dict[str, int] = {}
    stack: list[str] = []
    on_stack: set[str] = set()
    sccs: list[list[str]] = []

    sys.setrecursionlimit(max(sys.getrecursionlimit(), len(nodes) + 500))

    def strongconnect(v: str) -> None:
        nonlocal index_counter
        indices[v] = index_counter
        lowlink[v] = index_counter
        index_counter += 1
        stack.append(v)
        on_stack.add(v)
        for w in adj[v]:
            if w not in indices:
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif w in on_stack:
                lowlink[v] = min(lowlink[v], indices[w])
        if lowlink[v] == indices[v]:
            comp = []
            while True:
                w = stack.pop()
                on_stack.remove(w)
                comp.append(w)
                if w == v:
                    break
            sccs.append(sorted(comp))

    for v in sorted(nodes):
        if v not in indices:
            strongconnect(v)

    node_to_scc = {}
    for idx, comp in enumerate(sccs):
        for v in comp:
            node_to_scc[v] = idx

    # DAG edges: dependency -> dependent (bottom-to-top)
    scc_deps: dict[int, set[int]] = {i: set() for i in range(len(sccs))}
    for s, targets in adj.items():
        si = node_to_scc[s]
        for t in targets:
            ti = node_to_scc[t]
            if si != ti:
                scc_deps[si].add(ti)

    depth: dict[int, int] = {}

    def get_depth(i: int) -> int:
        if i in depth:
            return depth[i]
        if not scc_deps[i]:
            depth[i] = 0
        else:
            depth[i] = 1 + max(get_depth(d) for d in scc_deps[i])
        return depth[i]

    for i in range(len(sccs)):
        get_depth(i)

    max_d = max(depth.values(), default=0)
    layers: list[list[str]] = [[] for _ in range(max_d + 1)]
    for i, comp in enumerate(sccs):
        layers[depth[i]].extend(comp)
    layers = [sorted(layer) for layer in layers]
    cyclic_sccs = [c for c in sccs if len(c) > 1]
    return cyclic_sccs, layers


def write_report(
    linux_graph: dict[str, Any],
    windows_graph: dict[str, Any],
    report_path: Path,
    repos_path: Path,
) -> None:
    sccs, layers = compute_sccs_and_layers(linux_graph)
    nodes = linux_graph["nodes"]
    win_nodes = windows_graph["nodes"]

    linux_only = sorted(set(nodes) - set(win_nodes))
    win_only = sorted(set(win_nodes) - set(nodes))
    not_host_enabled = sorted(n for n, d in nodes.items() if not d.get("host_enabled", True))

    by_type: dict[str, list[str]] = defaultdict(list)
    by_repo: dict[str, list[str]] = defaultdict(list)
    for n, d in sorted(nodes.items()):
        by_type[d["module_type"]].append(n)
        by_repo[d["repo_path"]].append(n)

    # Repos needed JSON (for selective cloning like lzhiyong/android-sdk-tools repository.json)
    manifest_map = {
        p: n for p, n in parse_manifest(ROOT / "map/aosp-17-default.xml")
    }
    repos_needed = []
    for rp in sorted(by_repo):
        if rp in manifest_map:
            repos_needed.append({
                "path": f"src/{rp}",
                "aosp_path": rp,
                "url": f"https://android.googlesource.com/{manifest_map[rp]}",
                "tag": "android-17.0.0_r1",
                "module_count": len(by_repo[rp]),
            })
    repos_path.write_text(json.dumps(repos_needed, indent=2), encoding="utf-8")

    lines: list[str] = [
        "# Android 17 (`android-17.0.0_r1`) Host `libandroid_runtime` & `layoutlib_jni` Dependency Map",
        "",
        f"- **Profile**: `{linux_graph['profile']}` (Termux `aarch64-linux-android30` Bionic NDK target)",
        f"- **Roots**: `{', '.join(linux_graph['roots'])}`",
        f"- **Total Resolved Modules**: `{len(nodes)}`",
        f"- **Total Dependency Edges**: `{len(linux_graph['edges'])}`",
        f"- **Unresolved Modules**: `{len(linux_graph['unresolved'])}`",
        f"- **Dependency Cycles (SCCs > 1)**: `{len(sccs)}`",
        f"- **Topological Build Layers (bottom-to-top)**: `{len(layers)}` (Layer 0 leaves -> Layer {len(layers)-1} roots)",
        f"- **Minimal AOSP Repos Needed**: `{len(repos_needed)}`",
        "",
        "## 1. Module Types Summary",
        "",
        "| Module Type | Count |",
        "| --- | ---: |",
    ]
    for mt, ms in sorted(by_type.items(), key=lambda x: (-len(x[1]), x[0])):
        lines.append(f"| `{mt}` | {len(ms)} |")

    lines.extend([
        "",
        "## 2. Strongly Connected Components (Cycles / Dead-ends)",
        "",
    ])
    if not sccs:
        lines.append("None — the dependency graph is a strict DAG.")
    else:
        for i, comp in enumerate(sccs, 1):
            lines.append(f"- **SCC {i}** ({len(comp)} modules): " + ", ".join(f"`{m}`" for m in comp))

    lines.extend([
        "",
        "## 3. `host_linux` vs `host_windows` Comparison",
        "",
        f"### Modules ONLY in `host_linux` ({len(linux_only)})",
        "*(Used by `host_linux` / Termux Bionic — includes binder, MessageQueue, InputChannel, FileObserver, HIDL base)*",
        "",
    ])
    for m in linux_only:
        d = nodes[m]
        lines.append(f"- `{m}` (`{d['module_type']}`, `{d['rel_dir']}`)")

    lines.extend([
        "",
        f"### Modules ONLY in `host_windows` ({len(win_only)})",
        "*(Windows-only modules/stubs that are NOT needed on Linux/Bionic or replaced by Linux equivalents)*",
        "",
    ])
    for m in win_only:
        d = win_nodes[m]
        lines.append(f"- `{m}` (`{d['module_type']}`, `{d['rel_dir']}`)")

    if not_host_enabled:
        lines.extend([
            "",
            f"### Modules with `host_enabled == False` ({len(not_host_enabled)})",
            "*(Require checking whether they are header-only, conditional, or need host patching)*",
            "",
        ])
        for m in not_host_enabled:
            d = nodes[m]
            lines.append(f"- `{m}` (`{d['module_type']}`, `{d['rel_dir']}`)")

    if linux_graph["unresolved"]:
        lines.extend(["", "## 4. Unresolved Modules", ""])
        for u, callers in linux_graph["unresolved"].items():
            cstr = ", ".join(f"`{c}` ({k})" for c, k in callers[:5])
            lines.append(f"- `{u}` <- {cstr}")

    lines.extend([
        "",
        "## 5. Bottom-to-Top Topological Build Order (Leaves -> `libandroid_runtime` -> `layoutlib_jni`)",
        "",
    ])
    # Focus on linkable/header/codegen modules (skip pure filegroup/defaults noise if needed, or tag everything)
    for idx, layer in enumerate(layers):
        compiled = [
            m for m in layer
            if nodes[m]["module_type"] not in ("filegroup", "cc_defaults", "rust_defaults")
        ]
        other = [
            m for m in layer
            if nodes[m]["module_type"] in ("filegroup", "cc_defaults", "rust_defaults")
        ]
        lines.append(f"### Layer {idx} ({len(compiled)} build/header/codegen modules, {len(other)} filegroups/defaults)")
        for m in compiled:
            d = nodes[m]
            deps_str = ", ".join(
                f"{dep['target']}({dep['kind']})"
                for dep in d["deps"]
                if dep["kind"] != "default"
            )
            extra = []
            if d.get("has_sysprop"):
                extra.append("sysprop")
            if d.get("has_proto"):
                extra.append("proto")
            if d.get("resolved_via"):
                extra.append(f"via `{d['resolved_via']}`")
            if not d.get("host_enabled", True):
                extra.append("HOST_DISABLED")
            ex_str = f" [{' '.join(extra)}]" if extra else ""
            lines.append(f"- **`{m}`** (`{d['module_type']}`, `{d['rel_dir']}`){ex_str}" + (f" -> {deps_str}" if deps_str else ""))
        lines.append("")

    lines.extend([
        "## 6. Minimal AOSP 17 Repositories Required",
        "",
        "| Repo Path | AOSP Project | Modules Referenced |",
        "| --- | --- | ---: |",
    ])
    for r in sorted(repos_needed, key=lambda x: (-x["module_count"], x["aosp_path"])):
        lines.append(f"| `{r['path']}` | `{r['aosp_path']}` | {r['module_count']} |")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--roots", nargs="+", default=["layoutlib_jni", "libandroid_runtime"])
    parser.add_argument("--profile", default="host_linux", choices=list(PROFILE_TARGET_KEYS.keys()))
    parser.add_argument("--out", default=str(ROOT / "map/dependency_graph.json"))
    parser.add_argument("--report", default="")
    parser.add_argument("--repos-out", default=str(ROOT / "map/repos_needed.json"))
    args = parser.parse_args()

    flags = load_release_flags(SRC_DIR / "build/release", "cp2a")
    index = SoongIndex(SRC_DIR, ROOT / "map/aosp-17-default.xml")
    index.scan()
    print(f"Indexed {index.bp_count} .bp files, {len(index.modules)} module names, {len(index.parse_errors)} errors")
    for fp, err in index.parse_errors[:10]:
        print("  PARSE ERR:", fp, err)

    graph = trace_graph(index, args.roots, flags, args.profile)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(graph, indent=2), encoding="utf-8")

    sccs, layers = compute_sccs_and_layers(graph)
    print(f"Profile: {args.profile}")
    print(f"Resolved nodes: {len(graph['nodes'])}, Edges: {len(graph['edges'])}, Layers: {len(layers)}, SCCs(>1): {len(sccs)}")
    print(f"Unresolved modules ({len(graph['unresolved'])}):")
    for u, callers in graph["unresolved"].items():
        cstr = ", ".join(f"{c}({k})" for c, k in callers[:3])
        print(f"  - {u}  <- {cstr}")

    if args.report:
        win_graph = trace_graph(index, args.roots, flags, "host_windows")
        (ROOT / "map/graph_host_windows.json").write_text(json.dumps(win_graph, indent=2), encoding="utf-8")
        write_report(graph, win_graph, Path(args.report), Path(args.repos_out))
        print(f"Wrote report to {args.report} and {args.repos_out}")


if __name__ == "__main__":
    main()
