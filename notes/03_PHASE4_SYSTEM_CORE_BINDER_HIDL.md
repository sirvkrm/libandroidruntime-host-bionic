# Phase 4 Success Note: System Core, Binder, HIDL, Aconfig & Rust FFI Bridge

**Date**: 2026-11-24
**Target**: `aarch64-linux-android30` (`arm64-v8a`, NDK r28 Clang `19.0.1`, `c++_static`, `gnu++23`, `rustc 1.99.1`)
**Build Definitions & Scripts**: `cmake/system_core.cmake`, `tools/build_rust.py`, `patches/01_host_bionic_system_core.patch`

---

## Summary
Built all 21 Android system core, IPC, properties, stats stubs, HIDL, binder, and Rust-bridged aconfig storage static libraries for `aarch64-linux-android30`, plus the host `protoc-gen-rs` codegen tool and the reusable `tools/build_rust.py` cross-compilation pipeline. Also verified all Phase 3 + Phase 4 C/C++ targets compile cleanly under `gnu++23`.

## Key Engineering Fixes & Decisions

1. **C++23 Upgrade (`cmake/platform.cmake`)**
   - Upgraded default `CMAKE_CXX_STANDARD` from `20` to `23` (`gnu++23`), required by AOSP 17 `system/libbase/file.cpp` (`std::string::resize_and_overwrite`) while re-verifying all 32 Phase 3 libs and `abseil-cpp`.

2. **Private `RefBase` Macro Isolation (`cmake/system_core.cmake`)**
   - Moved `ANDROID_UTILS_REF_BASE_DISABLE_IMPLICIT_CONSTRUCTION` from `PUBLIC` to `PRIVATE` on `libutils` (matching Soong where it is a private `cflag`), resolving `sp<>` / `wp<>` compilation errors across `libhwbinder-impl-internal`, `libhidlbase`, and `libbinder_ndk`.

3. **Missing Internal Header Paths & Dependencies (`cmake/system_core.cmake`)**
   - `libasync_safe`: added private include `system/logging/liblog/include` and `-idirafter ${AOSP_SRC}/bionic/libc` (for `private/ErrnoRestorer.h`).
   - `libkernelconfigs`: added `libutils` link (`<utils/Errors.h>`).
   - `libincfs-utils`: linked `libutils` (`<utils/FileMap.h>`).

4. **API 30 Bionic Compatibility & Host Guarding (`patches/01_host_bionic_system_core.patch`)**
   - Preserved `__ANDROID__` globally for NDK sysroot/libc++ headers while gating device-OS-only services/checks cleanly with `!defined(LAYOUTLIB_HOST)`:
     - `system/core/libutils/misc.cpp`, `system/logging/liblog/{logger_write,logger_read}.cpp`, `system/libbase/logging.cpp`, `system/libhidl/transport/ServiceManagement.cpp`, `frameworks/native/libs/binder/ProcessState.cpp`: host Bionic / `FAKE_LOG_DEVICE=1` / no `/dev/binder` assertion on host.
     - `frameworks/native/libs/binder/IServiceManager.cpp`: guarded `#include <android/apexsupport.h>`, `<vndksupport/linker.h>`, and `openDeclaredPassthroughHal()` device SPHAL loading under `!defined(LAYOUTLIB_HOST)`.
     - `frameworks/native/libs/binder/ndk/stability.cpp`: allowed NDK toolchain build under `LAYOUTLIB_HOST` (`#if defined(__ANDROID_NDK__) && !defined(LAYOUTLIB_HOST)`).
     - `system/incremental_delivery/incfs/util/map_ptr.cpp`: used standard POSIX `base::MappedFile` path under `LAYOUTLIB_HOST` (avoiding kernel IncFS `libincfs` / `libselinux` runtime dependency).
     - `frameworks/native/libs/binder/Utils.h` & `system/libhwbinder/Utils.h`: guarded `memset_explicit()` behind `#if defined(__BIONIC__) && __ANDROID_API__ >= 35` so API 30 Termux Bionic uses the `memset` + compiler memory-barrier fallback.
   - `liblog` & `libbinder_ndk`: scoped `-D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__ -Wno-unguarded-availability` ONLY to those two in-tree AOSP implementations (which annotate API 33/37 symbols in their own headers) without relaxing strict API 30 checking globally.

5. **Offline Rust Cross-Compiler Pipeline (`tools/build_rust.py`)**
   - Built host `x86_64` `protoc-gen-rs` (`build/host-tools/bin/protoc-gen-rs`) from 37 AOSP crates (`protobuf-codegen`, `protobuf-parse`, `syn`, `regex`, etc.) using `bp_parser.py`.
   - Generated `aconfig_storage_metadata.rs` + `mod.rs` for `libaconfig_storage_protos` (`build/generated/rust_protos/libaconfig_storage_protos/`).
   - Cross-compiled `libaconfig_storage_read_api_cxx_bridge` (`staticlib` `.a`, `aarch64-linux-android` + NDK `aarch64-linux-android30-clang` linker, host proc-macros `librustversion`, `libcxxbridge_macro`, `libclap_derive`) -> `build/target-libs/libaconfig_storage_read_api_cxx_bridge.a` (47 MB) and wrapped it into `liblibaconfig_storage_read_api_cc.a`.

## Built Phase 4 Libraries (`build/target-arm64/lib*.a` & `build/target-libs/*.a`)
- Logging & Base: `libliblog.a`, `liblibbase.a`, `liblibasync_safe.a`, `liblibcutils.a`, `liblibutils.a`, `liblibcxxbridge05.a`
- Storage & Config: `liblibziparchive_for_incfs.a`, `liblibincfs-utils.a`, `liblibkernelconfigs.a`, `liblibPlatformProperties.a`, `libserver_configurable_flags.a`, `liblibflags_rust_cpp_bridge.a`, `liblibbinder_flags.a`, `libaconfig_storage_read_api_cxx_bridge.a`, `liblibaconfig_storage_read_api_cc.a`
- Metrics Stubs: `liblibstatssocket-fake.a`, `liblibstatspull-fake.a`
- IPC (Binder / HIDL): `liblibbinder.a`, `liblibandroid_runtime_lazy.a`, `liblibbinder_ndk.a`, `liblibhwbinder-impl-internal.a`, `liblibhidlbase.a` (`+ libbinderthreadstateutils` interface target)
