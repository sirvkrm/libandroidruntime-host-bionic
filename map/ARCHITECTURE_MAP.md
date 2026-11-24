# Architecture & Bottom-Up Build Map: Android 17 (`android-17.0.0_r1`) Host `libandroid_runtime.so` + `layoutlib_jni.so`

## Target Environment
- **Source Tag**: AOSP `android-17.0.0_r1` (release config `aosp_current` -> `cp2a`)
- **Build Method**: Selective AOSP shallow repo fetch + CMake + Ninja + Android NDK r28 (`28.2.13676358`, Clang 19.0.1) — modeled after `lzhiyong/android-sdk-tools`
- **Target ABI**: `aarch64-linux-android30` (`arm64-v8a`, Android API 30+, Bionic libc, `c++_static` STL)
- **Host Profile**: `host_linux` (Layoutlib host mode, NOT device OS Android HAL mode)
- **Primary Outputs**:
  1. `libandroid_runtime.so` (fully self-contained via static deps + `libc++_static`, symbol exports via `platform/linux/libandroid_runtime_export.txt`)
  2. `layoutlib_jni.so` (links dynamically against `libandroid_runtime.so`, symbol exports via `jni/linux/layoutlib_jni_export.txt`)

## Key Compatibility Finding: `__ANDROID__` vs `host_linux` on Termux Bionic
- Android NDK Clang automatically defines `__ANDROID__` and `__BIONIC__`.
- In AOSP `frameworks/base/core/jni` and `frameworks/base/libs/hwui`, `#ifdef __ANDROID__` is overloaded to mean **device Android OS** (pulling in `SurfaceFlinger`, `libgui`, `libui`, `gralloc`, `EGL`, `Vulkan`), whereas `host` layoutlib compiles with `#ifndef __ANDROID__` + `libhostgraphics` + `HWUI_NULL_GPU`.
- Meanwhile, Bionic NDK sysroot headers (`<sys/cdefs.h>`, `<c++/v1/__config>`, `<android/...>`) require `__ANDROID__` and `__ANDROID_API__ >= 30`.
- Therefore, low-level libraries build with standard NDK `__ANDROID__`, while Layoutlib host-only layers (`libhwui`, `frameworks/base/core/jni`, and selective host guards) are patched explicitly so `host` layoutlib paths are selected instead of device-OS hardware/SurfaceFlinger paths.
- Upstream Soong `linux_glibc_x86_64` passes `-static-libgcc` (not needed / inapplicable under NDK Clang + `c++_static` + `libunwind`/compiler-rt).

## `host_linux` vs `host_windows` Differences
- **20 modules in `host_linux` absent from `host_windows`**:
  - `libbinder`, `libbinder_ndk`, `libbinderthreadstateutils`, `libhidlbase`, `libhwbinder-impl-internal`, `libhwbinder_headers`, `libfmq-base`, `android.hidl.base@1.0`, `android.hidl.manager@1.0..1.2`
  - `libcore_jni_flags_c`, `core_jni_flags`
  - `libasync_safe`, `libc_headers`, `libc_uapi_headers`, `libcompiler_rt-extras`, `libandroidicuinit`
- **0 modules strictly exclusive to `host_windows`** in the resolved dependency graph.
- On `host_linux`, `HostRuntime.cpp` registers `android.os.Binder`, `android.os.FileObserver`, `android.os.MessageQueue`, `android.os.Parcel`, `android.view.InputChannel`, `android.view.InputEventReceiver`, `android.view.InputEventSender` under `#ifdef __linux__`.

## Dependency Communities & Bottom-Up Build Order

### Community 1: Host Codegen Tools (x86_64 build machine)
1. `protoc` (protobuf compiler)
2. `cxxbridge` (`external/rust/cxx`)
3. `aconfig` (`build/make/tools/aconfig`, or release-resolved generator from `cp2a` `.val` + `.aconfig`)
4. `aidl` / `aidl-cpp` (`system/tools/aidl`)
5. `hidl-gen` (`system/tools/hidl`)
6. `sysprop_cpp` (`system/tools/sysprop`)
7. `stats-log-api-gen` (or generated `libstatslog_input` / `libstatslog_libinput`)
8. `bindgen` / `inputconstants` / `toolbox_input_labels`

### Community 2: Compression, Primitives & Third-Party C/C++ Leaves (Layers 0-4)
- `libz` (`external/zlib`)
- `libpng` (`external/libpng`)
- `libjpeg` (`external/libjpeg-turbo`)
- `libexpat` (`external/expat`)
- `libtinyxml2` (`external/tinyxml2`)
- `fmtlib` (`external/fmtlib`)
- `libwebp-decode`, `libwebp-encode` (`external/webp`)
- `libwuffs_mirror_release_c` (`external/wuffs-mirror-release-c`)
- `libft2` (`external/freetype`)
- `zuid_md5`, `xmp_toolkit_sdk` (`external/XMP-Toolkit-SDK`)
- `libbinary_parse`, `libimage_type_recognition`, `libtiff_directory`, `libpiex` (`external/piex`)
- `libmodpb64` (`external/modp_b64`)
- `libimage_io` (`external/image_io`)
- `libjpegdecoder`, `libjpegencoder`, `libultrahdr` (`external/libultrahdr`)
- `libdng_sdk` (`external/dng_sdk`)
- `libfft2d` (`external/fft2d`)
- `libruy_static` (`external/ruy`)
- `libtextclassifier_hash_static` (`external/libtextclassifier/native`)
- `absl_*` (`external/abseil-cpp`) -> `libregex_re2` (`external/regex-re2`) -> `libtflite_static` (`external/tensorflow`)

### Community 3: Android System Core, Logging, Binder & HIDL (Layers 2-10)
- `liblog` (`system/logging/liblog`)
- `libbase` (`system/libbase`)
- `libasync_safe` (`bionic/libc/async_safe`)
- `libcutils_sockets`, `libcutils` (`system/core/libcutils`)
- `libutils_binder`, `libutils` (`system/core/libutils`)
- `libziparchive`, `libziparchive_for_incfs` (`system/libziparchive`)
- `libincfs-utils` (`system/incremental_delivery/incfs`)
- `libkernelconfigs` (`system/libvintf`)
- `libPlatformProperties` (`system/libsysprop/srcs`)
- `libstatssocket-fake`, `libstatspull-fake` (`packages/modules/StatsD`)
- `server_configurable_flags` (`system/server_configurable_flags/libflags`)
- `libaconfig_storage_read_api_cxx_bridge` + `libaconfig_storage_read_api_cc` (`build/make/tools/aconfig/aconfig_storage_read_api`)
- `libandroid_runtime_lazy` (`frameworks/native/libs/android_runtime_lazy`)
- `libbinder` (`frameworks/native/libs/binder`)
- `libbinder_ndk` (`frameworks/native/libs/binder/ndk`)
- `libhwbinder-impl-internal` (`system/libhwbinder`) -> `libhidlbase` (`system/libhidl`)
- `libbinderthreadstateutils` (`frameworks/native/libs/binderthreadstate`)

### Community 4: ICU, HarfBuzz, Minikin & Skia (Layers 2-11)
- `libandroidicuinit`, `libicuuc_stubdata`, `libicuuc`, `libicui18n`, `libicu` (`external/icu`)
- `libharfbuzz_ng`, `libharfbuzz_subset` (`external/harfbuzz_ng`)
- `libsqlite3_android`, `libsqlite` (`external/sqlite`)
- `libminikin_rust_ffi`, `libminikin_from_rust_to_cpp`, `libminikin` (`frameworks/minikin`)
- `libskia_rust_ffi` (fontations / skrifa / read-fonts / font-types), `libskia` (`external/skia`)

### Community 5: Native Graphics Stubs, Framework Assets, Input, Perfetto & HWUI (Layers 8-25)
- `libarect`, `libmath`, `libui-types` (`frameworks/native/libs/{arect,math,ui}`)
- `libnativehelper_any_vm`, `libnativehelper_jvm` (`libnativehelper`, `frameworks/base/libs/nativehelper_jvm`)
- `libhostgraphics` (`frameworks/base/libs/hostgraphics`)
- `libandroidfw_pathutils`, `libandroidfw` (`frameworks/base/libs/androidfw`)
- `libperfetto_c` (`external/perfetto`) -> `libtracing_perfetto` (`frameworks/native/libs/tracing_perfetto`)
- `libgui_window_info_static`, `libguiflags` (`frameworks/native/libs/gui`) -> `iinputflinger_aidl_lib_static`
- `libinput_bindgen`, `libinput_rust_ffi`, `libinput` (`frameworks/native/libs/input`)
- `libhwui` (`frameworks/base/libs/hwui`)

### Community 6: Top-Level Runtime Shared Libraries (Layers 26-27)
- `libandroid_runtime.so` (`frameworks/base/core/jni`)
- `layoutlib_jni.so` (`frameworks/layoutlib`)
