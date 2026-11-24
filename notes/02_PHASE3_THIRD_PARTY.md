# Phase 3 Success Note: Foundation Third-Party, Image, Codec & ML Libraries

**Date**: 2026-11-24
**Target**: `aarch64-linux-android30` (`arm64-v8a`, NDK r28 Clang `19.0.1`, `-fPIC`, `c++_static`)
**Build Definition**: `cmake/third_party.cmake`

---

## Summary
Built all 32 third-party static libraries plus the full `abseil-cpp` CMake target suite for `aarch64-linux-android30` cleanly without modifying AOSP upstream C/C++ sources. Verified relocatable object format (`ELF64`, `Machine: AArch64`) via `llvm-readelf`.

## Built Libraries (`build/target-arm64/*.a`)

| Group | Targets Built | Key Configurations & Fixes |
|---|---|---|
| Compression & XML | `libz` (`liblibz.a`), `libpng`, `libexpat`, `libtinyxml2`, `fmtlib` | `libz` uses AOSP ARM64 NEON + ARMv8 CRC32 flags (`-DADLER32_SIMD_NEON -DCRC32_ARMV8_CRC32 -DARMV8_OS_LINUX`). `libexpat` includes `"SHELL:-include stdio.h"` so `__BIONIC__` is defined before `expat_config.h`. `libtinyxml2` uses `host` config (omitting `-DDEBUG -DANDROID_NDK`). |
| JPEG & WebP & GIF | `libjpeg`, `libwebp-decode`, `libwebp-encode`, `libwuffs_mirror_release_c` | `libjpeg` builds 52 core C files + 15 ARM64 NEON files (`simd/arm/aarch64/{jchuff-neon.c,jsimd.c}`, `simd/arm/*.c`, `-DNEON_INTRINSICS`). `libwebp-*` keep `-DWEBP_USE_THREAD`. `wuffs-v0.3.c` compiled with `WUFFS_CONFIG__MODULE__{BASE,GIF,LZW}`. |
| Fonts | `libft2` | FreeType 2 with system zlib & libpng (`-DFT_CONFIG_OPTION_USE_PNG -DFT_CONFIG_OPTION_USE_ZLIB -DFT_CONFIG_OPTION_SYSTEM_ZLIB`). |
| Metadata & RAW / HDR | `zuid_md5`, `xmp_toolkit_sdk`, `libbinary_parse`, `libimage_type_recognition`, `libtiff_directory`, `libpiex`, `libmodpb64`, `libimage_io`, `libjpegdecoder`, `libjpegencoder`, `libultrahdr` | `zuid_md5` required private include `${AOSP_SRC}/external/XMP-Toolkit-SDK`. `xmp_toolkit_sdk` built as static Linux host profile (`-DUNIX_ENV=1 -DXMP_StaticBuild=1`, `OS_Utils_Linux.cpp`, `"SHELL:--include=warning_override_overrider.h"`, RTTI + exceptions enabled). `libjpegdecoder`/`libjpegencoder` required `${AOSP_SRC}/external/libultrahdr` in public includes for `"ultrahdr_api.h"`. `libultrahdr` includes ARM64 NEON DSP sources (`editorhelper_neon.cpp`, `gainmapmath_neon.cpp`). |
| JXL & DNG SDK | `libbrotli`, `libhwy`, `libskia_skcms`, `libjxl`, `libcompiler_rt-extras`, `libdng_sdk` | Discovered `libdng_sdk` DNG 1.7.1 unconditionally requires `libjxl` (`dng_deprecated_flags.h` forbids disabling `qDNGSupportJXL`). Added shallow clones of `external/google-highway` and `external/libjxl` (plus already-present `external/brotli`) in `tools/get_source.py`. `libjxl` built with `-DJPEGXL_ENABLE_SKCMS=1` against `libskia_skcms`, `libhwy`, `libbrotli`. `libdng_sdk` built with C++20, exceptions, RTTI, `ubsan_throwing_runtime.cpp`, and `libcompiler_rt-extras` (`mulodi4.c`, `comparedf2.c`). |
| ML & Regex | `abseil-cpp` (`absl::*`), `libfft2d`, `libruy_static`, `libtextclassifier_hash_static`, `libregex_re2`, `libtflite_static` | `abseil-cpp` built directly via `add_subdirectory(.../external/abseil-cpp EXCLUDE_FROM_ALL)` with `ABSL_PROPAGATE_CXX_STD=ON`. `libregex_re2` links `absl::{strings,flat_hash_map,flat_hash_set,synchronization,optional}`. `libtflite_static` resolved from `tflite_static.bp` (`tflite_src` + `:tensorflow_tsl_logging_srcs` + `FP16`, `eigen`, `gemmlowp`, generated mutable FlatBuffers schema `${GEN_DIR}/flatc/include`, `-DTF_LITE_DISABLE_X86_NEON`). |
