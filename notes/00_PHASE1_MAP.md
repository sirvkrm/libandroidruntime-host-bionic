# Phase 1: Dependency Mapping & Knowledge Graph

- **AOSP Version**: `android-17.0.0_r1` (`cp2a` release configuration)
- **Target**: `aarch64-linux-android30` (Termux Bionic NDK r28), `host_linux` Layoutlib profile
- **Artifacts Generated**:
  - `tools/bp_parser.py`: Complete Blueprint (`Android.bp`) lexer/parser supporting variables, `+=`, `+`, tuple select keys, `@` bindings, `select()`, and `soong_config_module_type`.
  - `tools/bp_mapper.py`: Recursive Soong dependency tracer, release-flag resolver (`build/release/flag_values/cp2a`), Tarjan SCC cycle analyzer, topological bottom-to-top layer builder, and `host_linux` vs `host_windows` diff generator.
  - `tools/get_source.py`: Selective AOSP `android-17.0.0_r1` shallow repo downloader (`lzhiyong/android-sdk-tools` style).
  - `map/DEPENDENCY_TREE.md`, `map/ARCHITECTURE_MAP.md`, `map/graph_host_linux.json`, `map/graph_host_windows.json`, `map/repos_needed.json`.
  - `graphify-out/GRAPH_REPORT.md`, `graphify-out/graph.json`, `graphify-out/graph.html`.
- **Key Metrics**:
  - Parsed `4,678` `.bp` files (`16,201` module definitions) with `0` errors.
  - Resolved `656` nodes, `2,414` edges, `28` topological build layers, `0` unresolved modules, `0` dependency cycles.
  - Identified `53` minimal dependency repos + `10` header/codegen repos.
  - Identified the critical `__ANDROID__` guard issue: NDK Clang defines `__ANDROID__` for Bionic sysroot/libc++, while `frameworks/base/core/jni` & `libhwui` use `#ifdef __ANDROID__` to pull in device-OS SurfaceFlinger/HAL code instead of `host` layoutlib (`libhostgraphics` + `HWUI_NULL_GPU`).
