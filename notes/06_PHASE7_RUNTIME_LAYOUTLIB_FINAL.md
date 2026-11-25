# Phase 7 Success Note: `libandroid_runtime.so` & `layoutlib_jni.so` (Host Bionic)

**Date**: 2026-11-24
**Target**: `aarch64-linux-android30` (`arm64-v8a`, Android NDK r28 `28.2.13676358`, Clang `19.0.1`, `c++_static`, `rustc 1.99.1`)
**Build Definitions & Patches**: `cmake/runtime.cmake`, `cmake/frameworks_ui.cmake`, `tools/build_rust.py`, `tools/termux/`, `patches/03_host_bionic_frameworks_ui.patch`, `patches/04_host_bionic_core_jni.patch`, `patches/05_host_bionic_libbase_properties.patch`

---

## Summary
Compiled and linked the final top-level Android Studio Layoutlib shared libraries natively for Termux (`aarch64-linux-android30`, Bionic):
- **`build/target-arm64/libandroid_runtime.so`** (`335M` unstripped) / **`build/target-arm64/stripped/libandroid_runtime.so`** (`20M` stripped)
- **`build/target-arm64/layoutlib_jni.so`** (`5.6M` unstripped) / **`build/target-arm64/stripped/layoutlib_jni.so`** (`427K` stripped)

---

## Key Engineering Fixes & Decisions

1. **Host Graphics Include Precedence (`cmake/runtime.cmake`)**
   - Transitive `libhwui` -> `libui-types` propagation placed `frameworks/native/libs/ui/include` before `frameworks/base/libs/hostgraphics/include`, causing `android_view_Surface.cpp`, `android_media_ImageReader.cpp`, and `android_media_Utils.cpp` to pull device `ui/GraphicBuffer.h` -> `ui/GraphicTypes.h` -> missing HAL `aidl/android/hardware/graphics/common/BlendMode.h`.
   - Added `target_include_directories(... BEFORE PRIVATE "${AOSP_SRC}/frameworks/base/libs/hostgraphics/include")` on both `android_runtime` and `layoutlib_jni` so host mock `ui/GraphicBuffer.h` and `gui/Surface.h` take precedence over device HAL headers.
   - Linked `libnativehelper_jvm` and `libhostgraphics` into `layoutlib_jni`, removed explicit `-lpthread` (provided by Bionic `libc.so`), dropped unsupported Clang 19 flag `-Wno-cast-function-type-mismatch`, and added `-Wl,-rpath,$ORIGIN` (`DT_RUNPATH: [$ORIGIN]`) on `layoutlib_jni.so` so `System.load` resolves sibling `libandroid_runtime.so` automatically in Termux.

2. **StatsLog Input Bundle Fix (`cmake/frameworks_ui.cmake`)**
   - `InputConsumer.cpp` calls `android::input::stats_write(...)`, whereas `libstatslog_libinput_bundled` only compiled `statslog_libinput.cpp` (`android::libinput`). Added `${GEN_DIR}/statslog/src/statslog_input.cpp` to `libstatslog_libinput_bundled` (matching `frameworks/native/libs/input/Android.bp`).

3. **CXX Bridge ABI Version Synchronization (`tools/build_rust.py`, `build/host-tools/bin/cxxbridge`)**
   - Phase 2's manual `cxxbridge` (`0.1.0`) emitted `cxxbridge1$0$...` C++ bridge symbols while `libcxxbridge_macro` (`cargo_pkg_version: "1.0.119"`) emitted `cxxbridge1$119$...` in all 4 Rust FFI `.a` archives (`libaconfig_storage_read_api_cxx_bridge.a`, `libminikin_rust_ffi.a`, `libskia_rust_ffi.a`, `libinput_rust_ffi.a`).
   - Added `src/external/rust/cxx/gen/cmd/Android.bp` to `tools/build_rust.py`, rebuilt `build/host-tools/bin/cxxbridge` (`cxxbridge 1.0.119`), and regenerated all 5 CXX bridge `.cpp`/`.cc` files (`minikin`, `input`, `skia` fontations, `aconfig_storage_read_api`, `libflags`) so `$119$` matches cleanly across C++ and Rust.

4. **Core JNI Guards & RTTI Export (`patches/04_host_bionic_core_jni.patch`)**
   - Guarded device-only paths with `#if defined(__ANDROID__) && !defined(LAYOUTLIB_HOST)` across `core_jni_helpers.h` (`CRITICAL_JNI_PARAMS`), `android_os_Parcel.cpp`, `android_media_ImageReader.cpp`, `android_media_Utils.cpp`, `android_text_Hyphenator.cpp`, and `android_view_Surface.cpp`.
   - Exported `AndroidRuntime` RTTI and vtable (`_ZTIN7android14AndroidRuntime*;`, `_ZTSN7android14AndroidRuntime*;`, `_ZTVN7android14AndroidRuntime*;`) in `frameworks/base/core/jni/platform/linux/libandroid_runtime_export.txt` so `LayoutlibRuntime` subclasses `AndroidRuntime` cleanly across DSO boundaries under NDK RTTI-enabled C++ compilation.

5. **In-Process HostProperties on Bionic (`patches/05_host_bionic_libbase_properties.patch`)**
   - `src/system/libbase/properties.cpp` previously gated its in-memory `HostProperties` map behind `#if !defined(__BIONIC__)`. Because Termux defines `__BIONIC__`, `Bridge.setSystemProperties()` -> `__system_property_set("ro.icu.data.path", ...)` would otherwise fail talking to Android `init`'s `/dev/socket/property_service` (`EACCES`).
   - Enabled `HostProperties` under `#if !defined(__BIONIC__) || defined(LAYOUTLIB_HOST)` with strong C linkage definitions for all `__system_property_*` accessors (`_set`, `_get`, `_find`, `_read`, `_read_callback`, `_area_serial`, `_serial`, `_wait`, `_foreach`), eliminating all `libc.so` `__system_property_*` imports from both `.so` binaries.

6. **Cross-Version Layoutlib Compatibility & Termux Test Tooling (`tools/termux/`)**
   - Guarded Android 17's `android/content/res/XmlBlock$FlagInfo` lookup inside `android_util_XmlBlock.cpp` (`LAYOUTLIB_HOST`) and updated `HostRuntime.cpp` / `hwui/apex/LayoutlibLoader.cpp` `register_jni_procs` to warn and skip unmapped legacy JNI class entries (such as `android.os.Trace`) rather than aborting subsequent `register_android_graphics_classes()`.
   - Saved Termux installer and CLI test harness sources (`install.sh`, `layoutlib_native_probe.cpp`, `smoke_java/`, `RenderXmlTest.java`, `test_layout.xml`) under `tools/termux/`.
   - Verified on real Termux device (`aarch64 Android`):
     - `layoutlib-test smoke`: `dlopen(..., RTLD_NOW)` resolved `libandroid_runtime.so` via `$ORIGIN`, `JNI_OnLoad` initialized in Termux OpenJDK, `HostProperties` `ro.*` set/get succeeded, and `android.util.Log` JNI succeeded.
     - `layoutlib-test xml` (using `~/android-studio-latest` with `icudt78l.dat` + `android-37.0` resources + `~/android-studio/jbr/bin/java` v25): initialized `Bridge.init()`, inflated & rendered `test_layout.xml` via `RecyclableImage.getCopy()`, and wrote `/data/data/com.termux/files/usr/tmp/test_render.png` (`1080x1920` RGBA PNG, `55,760` bytes, `959` unique colors, in `2,811–2,914 ms`).
     - Note: older `~/android-studio` (`icudt72l.dat`) fails JNI registration at `android.view.KeyCharacterMap.nativeObtainMapWithOverlay` because our AOSP 17 (`android-17.0.0_r1`) native runtime targets the Android 17 Java API present in `~/android-studio-latest`.

---

## ELF, Dynamic & API 30 Verification Results

Verified with NDK r28 `llvm-readelf` and `llvm-nm` against `sysroot/usr/lib/aarch64-linux-android/30/{libc,libm,libdl}.so`:

- **`libandroid_runtime.so`**:
  - `ELF64` / `AArch64` / `DYN (Shared object file)` / `SONAME: libandroid_runtime.so`
  - `DT_NEEDED`: ONLY `[libm.so]`, `[libdl.so]`, `[libc.so]`
  - Defined dynamic exports: `229` (`JNI_OnLoad`, 17 `ANativeWindow_*`, `AndroidRuntime*`, `VectorImpl`, `BufferQueue`, `KeyCharacterMap`, `InputDeviceInfo`, `android_view_InputDevice_create`, `android_view_Surface_createFromIGraphicBufferProducer`, `android::base::*`, etc.)
  - Undefined dynamic symbols: `313` total, **`0` missing strong symbols** at Android API 30 (`6` guarded weak symbols: `AFileDescriptor_{create,getFd,setFd}`, `android::CallStack::*`)
  - Stripped size (`--strip-unneeded`): **`20M`** (`335M` unstripped)

- **`layoutlib_jni.so`**:
  - `ELF64` / `AArch64` / `DYN (Shared object file)` / `SONAME: layoutlib_jni.so` / `DT_RUNPATH: [$ORIGIN]`
  - `DT_NEEDED`: ONLY `[libandroid_runtime.so]`, `[libdl.so]`, `[libm.so]`, `[libc.so]`
  - Defined dynamic exports: `2` (`JNI_OnLoad`, `JNI_OnUnload`)
  - Undefined dynamic symbols: `90` total, **`0` missing strong symbols** against API 30 + `libandroid_runtime.so` (`0` weak)
  - Stripped size (`--strip-unneeded`): **`427K`** (`5.6M` unstripped)
