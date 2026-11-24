# Graph Report - AndroidRuntimeHostBionic  (2026-11-24)

## Corpus Check
- Corpus is ~4,534 words - fits in a single context window. You may not need a graph.

## Summary
- 375 nodes · 1130 edges · 16 communities
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 12 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Mapper & Source Fetcher Tools
- Rust Crates, CXX & Aconfig Storage
- Skia, Image Codecs & Graphics Primitives
- Abseil Containers & Utilities
- AndroidRuntime, Layoutlib JNI & HWUI Host
- Blueprint Android.bp Parser
- Input, TFLite & Motion Prediction
- Abseil Hash & CRC Core
- Abseil Base & Synchronization
- System Core, Bionic & Binder NDK
- AndroidFW, Base, Zip & Freetype
- ICU, HarfBuzz & SQLite Text Stack
- HIDL & HwBinder Transport
- Binder IPC & Window Info
- Abseil Cordz Telemetry
- Abseil Strings & Formatting

## God Nodes (most connected - your core abstractions)
1. `absl_base_config (cc_library_static)` - 83 edges
2. `libandroid_runtime (cc_library_shared)` - 59 edges
3. `absl_base_core_headers (cc_library_static)` - 58 edges
4. `libhwui (cc_library)` - 45 edges
5. `absl_meta_type_traits (cc_library_static)` - 29 edges
6. `libinput (cc_library)` - 28 edges
7. `liblog (cc_library)` - 28 edges
8. `absl_container_raw_hash_set (cc_library_static)` - 27 edges
9. `absl_strings (cc_library_static)` - 26 edges
10. `libbase (cc_library)` - 26 edges

## Surprising Connections (you probably didn't know these)
- `SoongIndex` --uses--> `BpModule`  [INFERRED]
  tools/bp_mapper.py → tools/bp_parser.py
- `merge_props()` --calls--> `combine_values()`  [EXTRACTED]
  tools/bp_mapper.py → tools/bp_parser.py
- `flatten_module()` --uses--> `BpModule`  [INFERRED]
  tools/bp_mapper.py → tools/bp_parser.py
- `flatten_module()` --calls--> `resolve_select()`  [EXTRACTED]
  tools/bp_mapper.py → tools/bp_parser.py
- `is_module_host_enabled()` --uses--> `BpModule`  [INFERRED]
  tools/bp_mapper.py → tools/bp_parser.py

## Import Cycles
- None detected.

## Communities (16 total, 0 thin omitted)

### Community 0 - "Mapper & Source Fetcher Tools"
Cohesion: 0.08
Nodes (21): collect_deps(), compute_sccs_and_layers(), get_depth(), strongconnect(), extract_module_ref(), flatten_module(), apply_layer(), is_module_host_enabled() (+13 more)

### Community 1 - "Rust Crates, CXX & Aconfig Storage"
Cohesion: 0.07
Nodes (45): inputconstants-rust (aidl_interface), libaconfig_storage_file (rust_library), libaconfig_storage_protos (rust_protobuf), libaconfig_storage_read_api_cxx_bridge (rust_ffi_static), libaho_corasick (rust_library), libanstyle (rust_library), libanyhow (rust_library), libbitflags (rust_library) (+37 more)

### Community 2 - "Skia, Image Codecs & Graphics Primitives"
Cohesion: 0.11
Nodes (32): android_graphics_apex_headers (cc_library_headers), hwui_flags (aconfig_declarations), hwui_flags_cc_lib (cc_aconfig_library), libandroid_headers_private (cc_library_headers), libarect (cc_library_static), libbytemuck (rust_library), libbytemuck_derive (rust_proc_macro), libcompiler_rt-extras (cc_library_static) (+24 more)

### Community 3 - "Abseil Containers & Utilities"
Cohesion: 0.20
Nodes (31): absl_algorithm (cc_library_static), absl_algorithm_container (cc_library_static), absl_base_iterator_traits_internal (cc_library_static), absl_container_common (cc_library_static), absl_container_common_policy_traits (cc_library_static), absl_container_compressed_tuple (cc_library_static), absl_container_container_memory (cc_library_static), absl_container_fixed_array (cc_library_static) (+23 more)

### Community 4 - "AndroidRuntime, Layoutlib JNI & HWUI Host"
Cohesion: 0.10
Nodes (28): aconfig_text_flags_c_lib (cc_aconfig_library), aconfig_view_accessibility_flags_c_lib (cc_aconfig_library), android_graphics_jni_headers (cc_library_headers), android.view.accessibility.flags-aconfig (aconfig_declarations), com.android.text.flags-aconfig (aconfig_declarations), core_jni_flags (aconfig_declarations), layoutlib_jni (cc_library_host_shared), libandroid_runtime (cc_library_shared) (+20 more)

### Community 5 - "Blueprint Android.bp Parser"
Cohesion: 0.24
Nodes (11): AddExpr, combine_values(), eval_expr(), IdentRef, LexerError, parse_bp_text(), ParseError, Parser (+3 more)

### Community 6 - "Input, TFLite & Motion Prediction"
Cohesion: 0.08
Nodes (27): com.android.input.flags-aconfig (aconfig_declarations), com.android.input.flags-aconfig-cc (cc_aconfig_library), com.android.window.flags.window-aconfig (aconfig_declarations), com.android.window.flags.window-aconfig_flags_c_lib (cc_aconfig_library), flatbuffer_headers (cc_library_headers), fp16_headers (cc_library_headers), inputconstants-cpp (aidl_interface), jni_headers (cc_library_headers) (+19 more)

### Community 7 - "Abseil Hash & CRC Core"
Cohesion: 0.18
Nodes (25): absl_base_config (cc_library_static), absl_base_endian (cc_library_static), absl_base_nullability (cc_library_static), absl_base_prefetch (cc_library_static), absl_container_hashtable_control_bytes (cc_library_static), absl_container_hashtable_debug_hooks (cc_library_static), absl_container_raw_hash_set_resize_impl (cc_library_static), absl_crc_cpu_detect (cc_library_static) (+17 more)

### Community 8 - "Abseil Base & Synchronization"
Cohesion: 0.29
Nodes (24): absl_base (cc_library_static), absl_base_atomic_hook (cc_library_static), absl_base_base_internal (cc_library_static), absl_base_core_headers (cc_library_static), absl_base_cycleclock_internal (cc_library_static), absl_base_dynamic_annotations (cc_library_static), absl_base_errno_saver (cc_library_static), absl_base_log_severity (cc_library_static) (+16 more)

### Community 9 - "System Core, Bionic & Binder NDK"
Cohesion: 0.18
Nodes (24): fmtlib_headers (cc_library_headers), libandroid_runtime_lazy (cc_library), libasync_safe (cc_library_static), libbase_headers (cc_library_headers), libbinder_headers (cc_library_headers), libbinder_ndk (cc_library), libc_headers (cc_library_headers), libc_uapi_headers (cc_library_headers) (+16 more)

### Community 10 - "AndroidFW, Base, Zip & Freetype"
Cohesion: 0.21
Nodes (15): android.content.res.flags-aconfig (aconfig_declarations), android.content.res.flags-aconfig-cc-host-ro (cc_aconfig_library), fmtlib (cc_library_static), libandroidfw (cc_library), libandroidfw_pathutils (cc_library_static), libbase (cc_library), libft2 (cc_library), libgtest_prod_headers (cc_library_headers) (+7 more)

### Community 11 - "ICU, HarfBuzz & SQLite Text Stack"
Cohesion: 0.30
Nodes (12): icu4c_extra_headers (cc_library_headers), libandroidicuinit (cc_library_static), libicu (cc_library_shared), libicu_static (cc_library_static), libicui18n (cc_library), libicui18n_headers (cc_library_headers), libicuuc (cc_library), libicuuc_headers (cc_library_headers) (+4 more)

### Community 12 - "HIDL & HwBinder Transport"
Cohesion: 0.18
Nodes (11): android.hidl.base@1.0_genc++ (hidl_interface), android.hidl.base@1.0_genc++_headers (hidl_interface), android.hidl.manager@1.0_genc++ (hidl_interface), android.hidl.manager@1.0_genc++_headers (hidl_interface), android.hidl.manager@1.1_genc++ (hidl_interface), android.hidl.manager@1.1_genc++_headers (hidl_interface), android.hidl.manager@1.2_genc++ (hidl_interface), android.hidl.manager@1.2_genc++_headers (hidl_interface) (+3 more)

### Community 13 - "Binder IPC & Window Info"
Cohesion: 0.29
Nodes (8): android.os.binder.flags-aconfig (aconfig_declarations), android.os.binder.flags-aconfig-cc (cc_aconfig_library), iinputflinger_aidl_lib_static (cc_library_static), libbinder (cc_library), libbinder_headers_base (cc_library_headers), libbinder_headers_platform_shared (cc_library_headers), libbinder_internal_headers (cc_library_headers), libgui_window_info_static (cc_library_static)

### Community 14 - "Abseil Cordz Telemetry"
Cohesion: 0.48
Nodes (7): absl_base_no_destructor (cc_library_static), absl_strings_cord_internal (cc_library_static), absl_strings_cordz_handle (cc_library_static), absl_strings_cordz_info (cc_library_static), absl_strings_cordz_statistics (cc_library_static), absl_strings_cordz_update_scope (cc_library_static), absl_strings_cordz_update_tracker (cc_library_static)

### Community 15 - "Abseil Strings & Formatting"
Cohesion: 0.62
Nodes (7): absl_base_throw_delegate (cc_library_static), absl_strings (cc_library_static), absl_strings_append_and_overwrite (cc_library_static), absl_strings_cord (cc_library_static), absl_strings_internal (cc_library_static), absl_strings_resize_and_overwrite (cc_library_static), absl_types_compare (cc_library_static)

## Knowledge Gaps
- **62 isolated node(s):** `android.content.res.flags-aconfig (aconfig_declarations)`, `android.hidl.base@1.0_genc++ (hidl_interface)`, `android.hidl.base@1.0_genc++_headers (hidl_interface)`, `android.hidl.manager@1.0_genc++ (hidl_interface)`, `android.hidl.manager@1.0_genc++_headers (hidl_interface)` (+57 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 77 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `libregex_re2 (cc_library_static)` connect `Abseil Containers & Utilities` to `Abseil Base & Synchronization`, `Abseil Strings & Formatting`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **What connects `android.content.res.flags-aconfig (aconfig_declarations)`, `android.hidl.base@1.0_genc++ (hidl_interface)`, `android.hidl.base@1.0_genc++_headers (hidl_interface)` to the rest of the system?**
  _62 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Mapper & Source Fetcher Tools` be split into smaller, more focused modules?**
  _Cohesion score 0.08235294117647059 - nodes in this community are weakly interconnected._
- **Why does `absl_strings (cc_library_static)` connect `Abseil Strings & Formatting` to `Abseil Base & Synchronization`, `Abseil Containers & Utilities`, `Abseil Hash & CRC Core`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **Should `Rust Crates, CXX & Aconfig Storage` be split into smaller, more focused modules?**
  _Cohesion score 0.06767676767676768 - nodes in this community are weakly interconnected._
- **Why does `absl_synchronization (cc_library_static)` connect `Abseil Base & Synchronization` to `Abseil Containers & Utilities`, `Abseil Hash & CRC Core`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **Should `Skia, Image Codecs & Graphics Primitives` be split into smaller, more focused modules?**
  _Cohesion score 0.10887096774193548 - nodes in this community are weakly interconnected._