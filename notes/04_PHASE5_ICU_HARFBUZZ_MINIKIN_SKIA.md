# Phase 5 Success Note: ICU, HarfBuzz, SQLite, Minikin & Skia

**Date**: 2026-11-24
**Target**: `aarch64-linux-android30` (`arm64-v8a`, NDK r28 Clang `19.0.1`, `c++_static`, `rustc 1.99.1`)
**Build Definitions & Scripts**: `cmake/graphics_text.cmake`, `cmake/skia_srcs.cmake`, `tools/gen_aconfig.py`, `tools/build_rust.py`, `patches/02_host_bionic_icu.patch`

---

## Summary
Built the complete text, Unicode, font shaping, database, and 2D software/PDF/SVG/codec rendering stack (`ICU4C`, `HarfBuzz`, `SQLite`, `Minikin`, `Skia` + Rust `libminikin_rust_ffi` & Fontations `libskia_rust_ffi`) for `aarch64-linux-android30`.

## Key Engineering Fixes & Decisions

1. **Runtime-Safe Host ICU4C Initialization (`patches/02_host_bionic_icu.patch`)**
   - `external/icu/android_icu4c/include/uconfig_local.h` fails compilation under `__ANDROID__` unless `ANDROID_LINK_SHARED_ICU4C` is defined; exported `-DANDROID_LINK_SHARED_ICU4C` publicly from `libicuuc_stubdata` / `libicuuc`.
   - Crucially, `external/icu/icu4c/source/common/udata.cpp` calls `android_icu_init()` on first ICU access. In `external/icu/libandroidicuinit/android_icu_init.cpp`, `#ifdef __ANDROID__` previously forced `runAndroidInit = true`, which calls `abort()` when device APEX variables `ANDROID_I18N_ROOT` / `ANDROID_TZDATA_ROOT` are absent (on Termux host Layoutlib, ICU `.dat` is loaded directly via `HostRuntime.cpp` -> `udata_setCommonData()`). Guarded line 26 with `#if defined(__ANDROID__) && !defined(LAYOUTLIB_HOST)` so host behavior (init only when all env vars are explicitly provided) applies cleanly on Termux Bionic.
   - Kept `external/icu/libicu/ndk_headers` private to `libicu` (`shim.cpp`) so its NDK C wrapper headers do not shadow full `icu4c` headers in `libharfbuzz_ng` and `libminikin`.

2. **Minikin C++ & Rust Hyphenator Stack (`cmake/graphics_text.cmake`, `tools/gen_aconfig.py`, `tools/build_rust.py`)**
   - Added `libandroid_text_flags_rust` generation to `tools/gen_aconfig.py` alongside `aconfig_text_flags_c_lib` (`com.android.text.flags`, 38 flags via `cp2a`).
   - Built `libminikin_rust_ffi.a` (`40M`) via `tools/build_rust.py` (`libcxx`, `liblibc`, `liblogger` -> `libandroid_logger` + `libandroid_log_sys`, `libflags_rust`, `libandroid_text_flags_rust`) and wrapped `IcuBridge.cpp` + `minikin_cxx_bridge_generated.cpp` in `liblibminikin_from_rust_to_cpp.a`.
   - Added `${AOSP_SRC}/external/googletest/googletest/include` publicly to `libminikin` for `<gtest/gtest_prod.h>` required by `minikin/Layout.h`.

3. **Skia `host_linux` Software Stack & C++20 Dialect (`cmake/skia_srcs.cmake`, `cmake/graphics_text.cmake`)**
   - Built `libskia_rust_ffi.a` (`39M`) with Fontations crates (`libbytemuck` + host `libbytemuck_derive`, `libfont_types`, `libread_fonts`, `libskrifa`, `libcxx`).
   - Extracted all 583 `host_linux` C++ sources (`580` core/codec/PDF/SVG/SkSL + `SkRawCodec.cpp`, `SkLog_stdio.cpp`, `SkOSFile_posix.cpp`), omitting the 329 device-OS Ganesh/OpenGL/Vulkan GPU & AVIF files.
   - Ordered `${AOSP_SRC}/external/skia/linux` before `${AOSP_SRC}/external/skia` in include dirs so `linux/include/config/SkUserConfig.h` undefines `SK_BUILD_FOR_ANDROID` and sets `SK_BUILD_FOR_UNIX`, `SK_HAS_WUFFS_LIBRARY`, `SK_FONTMGR_FONTATIONS_AVAILABLE`, and `SK_SUPPORT_PDF`.
   - Scoped `CXX_STANDARD 20` (`gnu++20`) specifically on `libskia`: NDK r28 libc++ in `gnu++23` marks `std::unique_ptr::~unique_ptr()` `constexpr`, triggering incomplete-type instantiation errors in `SkCaptureManager.h` (`SkCaptureCanvas`) and `SkPDFDevice.h` (`SkPDFFont`). Under `gnu++20` (AOSP's Soong default for Skia), all 616 Skia translation units compiled cleanly without patching upstream Skia headers.

## Built Phase 5 Libraries (`build/target-arm64/*.a` & `build/target-libs/*.a`)
- Header-only shared helper: `libarect` (`INTERFACE`)
- Flags: `libaconfig_text_flags_c_lib.a`
- ICU4C: `liblibicuuc_stubdata.a` (9.8K), `liblibandroidicuinit.a` (307K), `liblibicuuc.a` (25M), `liblibicui18n.a` (40M), `liblibicu.a` (288K)
- HarfBuzz: `liblibharfbuzz_ng.a` (61M), `liblibharfbuzz_subset.a` (97M)
- SQLite: `liblibsqlite.a` (15M, with ICU + Android `PhoneNumberUtils`)
- Minikin: `libminikin_rust_ffi.a` (40M), `liblibminikin_from_rust_to_cpp.a` (130K), `liblibminikin.a` (17M)
- Skia: `libskia_rust_ffi.a` (39M), `liblibskia.a` (158M)
