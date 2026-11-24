# Phase 2 Success Note: Host Codegen Tools, Generated Sources & NDK r28 CMake Toolchain

**Date**: 2026-11-24
**Target Tag**: `android-17.0.0_r1`
**Toolchain**: Ubuntu Clang 21.1.8 (host tools) + Android NDK r28 (`28.2.13676358`, Clang 19.0.1, `arm64-v8a`, `android-30`, `c++_static`)

---

## 1. Host Build & Codegen Tools Built (`build/host-tools/bin/`)

All host code-generation tools required by the 656-module `host_linux` DAG were compiled cleanly offline from `src/` without Soong:

1. **Abseil-CPP + Protobuf (`protoc 33.5`)**:
   - Built `abseil-cpp` (`build/host-absl-inst`) and `protobuf` with `-Dprotobuf_BUILD_LIBUPB=ON` (`build/host-protobuf-inst`).
   - Binary: `build/host-tools/bin/protoc` (`libprotoc 33.5`).
2. **CXX Bridge (`cxxbridge 0.1.0`)**:
   - Built offline from `src/external/rust/cxx/gen/cmd` using vendored crates in `src/external/rust/android-crates-io/crates/`.
3. **Rust Bindgen (`bindgen 0.72.1`)**:
   - Built from `src/external/rust/android-crates-io/crates/bindgen-cli` (uses system `/usr/lib/llvm-21/lib/libclang-21.so.1`). Note: `bindgen-cli` requires non-offline dependency resolution for `itertools` (`<0.14`).
4. **CMake Host Codegen Suite (`tools/host_tools_cmake/CMakeLists.txt`)**:
   - Compiled with `/usr/bin/clang` / `/usr/bin/clang++` (`21.1.8`) to satisfy C++23 and `aidl/code_writer.h` compatibility.
   - **Fix 1 — Scoped standard-header includes (`SHELL:-include`)**: Passing global `-include cstring` broke `system/libbase/posix_strerror_r.cpp` which must `#undef _GNU_SOURCE` before `#include <string.h>`. Fixed by applying `"SHELL:-include cstdint" "SHELL:-include algorithm" "SHELL:-include cstring"` only via `target_compile_options` on `sysprop_cpp` and `hidl-gen`.
   - **Fix 2 — `hidl-gen` private `hidl-util` include dirs**: `Formatter.cpp`, `StringHelper.cpp`, `FQName.cpp`, and `FqInstance.cpp` use local `#include "Formatter.h"` etc. Added `${SRC}/system/tools/hidl/host_utils/include/hidl-util` and `${SRC}/system/tools/hidl/utils/include/hidl-util`.
   - **Fix 3 — `aidl` gtest link dependency**: `aidl_checkapi.cpp` references `testing::AssertionResult` / `testing::internal::EqFailure`. Added `host_gtest` (`external/googletest/googletest/src/gtest-all.cc`) and linked it to `aidl`.
   - **Fix 4 — `flatc` (`25.1.24`)**: Built from `src/external/flatbuffers` (`src/*.cpp` excluding `flathash.cpp`, `include/codegen/python.cc`, `grpc/src/compiler/*.cc`) for `libtflite_mutable_schema`.
   - **Fix 5 — `stats-log-api-gen` + `host_stats_proto`**: Compiled all 329 stats `.proto` definitions (`atoms.proto`, `atom_field_options.proto`, `attribution_node.proto`, `message/`, `enums/`, `atoms/`) via `protoc` into `host_stats_proto` and built `stats-log-api-gen` with `-DWITH_VENDOR` (omitting `CC_INCLUDE_HDRS_DIR`/`CC_INCLUDE_SRCS_DIR` so `--omitExtraSrcs` operates standalone without runtime `tools/out/etc` paths).
   - Verified binaries in `build/host-tools/bin/`:
     `aidl`, `bindgen`, `cppgen_plugin`, `cxxbridge`, `flatc`, `hidl-gen`, `ipc_plugin`, `protoc`, `protozero_plugin`, `stats-log-api-gen`, `sysprop_cpp`.

---

## 2. Derived Sources & Headers Generated (`build/generated/`)

### 2a. Aconfig Flags (`tools/gen_aconfig.py`)
- Loaded 5,847 `cp2a` release flag overrides across 12 release configs and parsed `.aconfig` declarations for all 11 aconfig modules:
  `aconfig_text_flags_c_lib`, `aconfig_view_accessibility_flags_c_lib`, `android.content.res.flags-aconfig-cc-host-ro`, `android.os.binder.flags-aconfig-cc`, `com.android.input.flags-aconfig-cc`, `com.android.window.flags.window-aconfig_flags_c_lib`, `hwui_flags_cc_lib`, `libcore_jni_flags_c`, `libguiflags`, `libsurfaceflingerflags`, `libinput_flags_rust`.
- Emits standalone C++ (`include/*.h`, `*.cc`) and Rust (`src/lib.rs`) flag providers into `build/generated/aconfig/`.

### 2b. Unified Host Codegen (`tools/run_codegen.py`)
Verified end-to-end exit code `0`:
1. **`toolbox_input_labels`**: `generate-input.h-labels.py` over `bionic/libc/kernel/uapi/linux/{input,input-event-codes}.h` -> `build/generated/toolbox/include/input.h-labels.h`.
2. **`cxxbridge`**: `rust/cxx.h` plus bridge `.rs.h`/`.cpp` pairs for `minikin`, `input`, `skia` (fontations `src/ports/fontations/src/ffi.{rs.h,cpp}`), `aconfig_storage_read_api`, and `libflags`.
3. **`sysprop_cpp`**: `HWUIProperties.sysprop` (`build/generated/sysprop/hwui`) and all 30 `.sysprop` files of `PlatformProperties` (`build/generated/sysprop/platform`, `--include-name android/sysprop/<Name>.sysprop.h`).
4. **`hidl-gen`**: C++ headers & sources for `android.hidl.base@1.0` and `android.hidl.manager@1.0..1.2` (`-r android.hidl:src/system/libhidl/transport`).
5. **`aidl`**:
   - `inputconstants-cpp` & `inputconstants-rust` (7 structured AIDLs under `frameworks/native/libs/input/android/os/`).
   - `iinputflinger_aidl_lib_static` (`IInputFlinger.aidl`, `InputChannelCore.aidl`).
   - `libgui_window_info_static` (19 `android/gui/*.aidl` files; `inputconstants_aidl` excluded to avoid duplicate symbols when linking with `inputconstants-cpp`).
   - `libbinder` (8 binder/accessor AIDLs + 4 `android/os/binder/*.aidl` stats consumer AIDLs + `IPccSandboxManagerNative.aidl`).
   - `deviceproductinfoconstants_aidl` (`IDeviceProductInfoConstants.aidl` required by `android_view_SurfaceControl.cpp`).
6. **`bindgen`**: `libinput_bindgen` (`bindings.rs` generated against NDK r28 `aarch64-linux-android30` sysroot, C++20 libc++ headers, `libui`, `ftl`, `libutils`, `binder`, and `inputconstants-cpp` generated headers).
7. **`perfetto`**: `perfetto_version.gen.h` + 63 `protoc` plugin batches (362 proto invocations across `cppgen_plugin`, `protozero_plugin`, and `ipc_plugin`). Fixed genrule filegroup expansion to parse exact `$(locations :...)` targets from `cmd` so `ipc_plugin` only runs on IPC protos rather than all transitive imported protos.
8. **`flatc`**: `tensorflow/lite/schema/mutable/schema_generated.h` (`--gen-object-api --gen-mutable`).
9. **`stats-log-api-gen`**: `statslog_input.{h,cpp}` and `statslog_libinput.{h,cpp}` (including both `input_extension_atoms.proto` and `framework_extension_atoms.proto` so atom `718` `STYLUS_PREDICTION_METRICS_REPORTED` resolves cleanly).

---

## 3. Target Cross-Compile CMake Architecture (`cmake/`)

- **`cmake/toolchain.cmake`**: Wraps NDK r28 `android.toolchain.cmake` locking `ANDROID_ABI=arm64-v8a`, `ANDROID_PLATFORM=android-30`, `ANDROID_STL=c++_static`, and exports `ANDROID_NDK_API_CC` / `ANDROID_RUST_TARGET=aarch64-linux-android` for Rust static FFI builds.
- **`cmake/platform.cmake`**: Configures PIC, `_FILE_OFFSET_BITS=64`, `LAYOUTLIB_HOST=1` (**preserving** `__ANDROID__` for Bionic sysroot and NDK `libc++` headers while distinguishing host Layoutlib paths cleanly), permissive Clang 19 warning flags, `aosp_add_aconfig_lib()`, and UAPI/system interface targets.
- **`CMakeLists.txt`**: Root project verified configuring cleanly with NDK r28 Clang `19.0.1` (`build/target-arm64`).
