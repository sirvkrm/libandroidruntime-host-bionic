# Phase 6 Success Note: Graphics Stubs, Framework Assets, Input, Perfetto & HWUI

**Date**: 2026-11-24
**Target**: `aarch64-linux-android30` (`arm64-v8a`, NDK r28 Clang `19.0.1`, `c++_static`, `rustc 1.99.1`)
**Build Definitions & Scripts**: `cmake/frameworks_ui.cmake`, `cmake/hwui_srcs.cmake`, `cmake/perfetto_srcs.cmake`, `tools/run_codegen.py`, `tools/gen_aconfig.py`, `tools/build_rust.py`, `patches/03_host_bionic_frameworks_ui.patch`

---

## Summary
Built the native Android graphics stubs (`libhostgraphics`, `libui-types`, `libmath`, `libnativehelper_jvm`), resource/APK parser (`libandroidfw`), Perfetto SDK (`libperfetto_c`, `libtracing_perfetto`), complete `libinput` C++/AIDL/Rust pipeline (including genuine `libbinder_rs` + `inputconstants`), and full Layoutlib software `libhwui` (`HWUI_NULL_GPU`) for `aarch64-linux-android30`.

## Key Engineering Fixes & Decisions

1. **Full `libbinder_rs` & `inputconstants` Rust Stack (`tools/run_codegen.py`, `tools/build_rust.py`)**
   - Added `libbinder_ndk_bindgen` and `libbinder_ndk_compat_bindgen` codegen using `build/host-tools/bin/bindgen` with NDK API 30 sysroot + `-DANDROID_PLATFORM -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__`.
   - Compiled `libbinder_ndk_sys`, `libdowncast_rs`, `libstatic_assertions`, host `libzerocopy_derive` + `libzerocopy`, `libbinder_rs_ndk_compat` (wrapped with C++ `liblibbinder_rs_compat.a`), `libbinder_rs`, and host `libasync_trait` proc-macro.
   - Wrapped AIDL Rust outputs in `build/generated/aidl/inputconstants-rust/lib.rs` with `pub mod aidl::android::os` and linked `libbinder_rs` + `libzerocopy` + `libasync_trait` as crate `inputconstants`, allowing `libinput_rust_ffi.a` (`42M`) and `liblibinput.a` (`26M`) to compile cleanly without stubs.

2. **Perfetto Aconfig Flags & C++20 Compatibility (`tools/gen_aconfig.py`, `cmake/perfetto_srcs.cmake`)**
   - Extracted 145 Perfetto core C++ sources plus 362 `.gen.cc`/`.pbzero.cc` generated files and added `perfetto_flags_c_lib` (`perfetto.flags`, generating `<perfetto_flags.h>`).
   - Built `libperfetto_c` with `CXX_STANDARD 20` (`gnu++20`) to satisfy forward-declared `std::unique_ptr<perfetto::base::TaskRunner>` fields under NDK libc++.

3. **Layoutlib Host Bionic Guards (`patches/03_host_bionic_frameworks_ui.patch`)**
   - **`CRITICAL_JNI_PARAMS` safety catch**: `frameworks/base/libs/hwui/jni/graphics_jni_helpers.h` used `#ifdef __ANDROID__` to strip `JNIEnv*, jclass` from `@CriticalNative` JNI methods. Because OpenJDK / Layoutlib on Termux does not use ART `@CriticalNative` calling conventions, guarded `#if defined(__ANDROID__) && !defined(LAYOUTLIB_HOST)` (alongside matching `jni/PathIterator.cpp`) so every JNI entry keeps `(JNIEnv*, jclass, ...)` for JVM.
   - Guarded GPU/OpenGL/Vulkan/`AHardwareBuffer`/`SurfaceControl`/`Looper`/`statx`/`mallopt(M_PURGE_FAST)`/`statssocket_lazy` code across 36 `frameworks/base/libs/hwui/` files (`Bitmap`, `RenderNode`, `RootRenderNode`, `Tonemapper`, `RenderProxy`, `CanvasContext`, `HardwareBitmapUploader`, `AnimatedImageDrawable`, `HardwareRenderer`, `Typeface`, `StatsUtils`, etc.) so `libhwui` runs cleanly on `HWUI_NULL_GPU` CPU rendering.
   - Guarded `/data/resource-cache/overlays.list` loading in `frameworks/base/libs/androidfw/AssetManager.cpp`, `LoadKernelConfigs()` fatal check in `frameworks/native/libs/input/KeyLayoutMap.cpp`, and `/vendor/etc/motion_predictor_model.tflite` lookup in `TfLiteMotionPredictor.cpp` behind `!defined(LAYOUTLIB_HOST)`.
   - Added `libhardware_headers` (`hardware/libhardware/include`), `frameworks/native/include/private` (`surface_control_private.h`), `art/libdexfile` (`dex/utf-inl.h` for `libnativehelper_jvm`), and `libbinder` link to `libandroidfw` cleanly (`libziparchive_for_incfs` reused to avoid duplicate `ZipArchive` symbols).

## Built Phase 6 Libraries (`build/target-arm64/*.a` & `build/target-libs/*.a`)
- Primitives & JVM Helpers: `libarect` (`INTERFACE`), `libmath` (`INTERFACE`), `libhardware_headers` (`INTERFACE`), `liblibui-types.a` (2.1M), `liblibnativehelper_jvm.a` (425K), `liblibhostgraphics.a` (319K)
- Aconfig C++ Flags: `libandroid.content.res.flags-aconfig-cc-host-ro.a`, `libaconfig_view_accessibility_flags_c_lib.a`, `liblibguiflags.a`, `liblibsurfaceflingerflags.a`, `libhwui_flags_cc_lib.a`, `libcom.android.input.flags-aconfig-cc.a`, `libcom.android.window.flags.window-aconfig_flags_c_lib.a`, `liblibcore_jni_flags_c.a`, `libperfetto_flags_c_lib.a`
- Framework & Tracing: `liblibandroidfw.a` (21M), `liblibperfetto_c.a` (122M), `liblibtracing_perfetto.a` (827K)
- Input & Graphics: `libinputconstants-cpp.a`, `liblibgui_window_info_static.a` (3.3M), `libiinputflinger_aidl_lib_static.a`, `liblibstatslog_libinput_bundled.a`, `liblibbinder_rs_compat.a`, `libinput_rust_ffi.a` (42M), `liblibinput.a` (26M), `liblibhwui.a` (66M)
