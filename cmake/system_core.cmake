# Phase 4: Android System Core, Binder, HIDL & Aconfig Support (aarch64-linux-android30)

# 1. liblog (host-profile stderr logging preserving Bionic properties & abort msg)
add_library(liblog STATIC
    "${AOSP_SRC}/system/logging/liblog/log_event_list.cpp"
    "${AOSP_SRC}/system/logging/liblog/log_event_write.cpp"
    "${AOSP_SRC}/system/logging/liblog/logger_name.cpp"
    "${AOSP_SRC}/system/logging/liblog/logger_read.cpp"
    "${AOSP_SRC}/system/logging/liblog/logger_write.cpp"
    "${AOSP_SRC}/system/logging/liblog/logprint.cpp"
    "${AOSP_SRC}/system/logging/liblog/properties.cpp"
    "${AOSP_SRC}/system/logging/liblog/event_tag_map.cpp"
)
target_include_directories(liblog PUBLIC
    "${AOSP_SRC}/system/logging/liblog/include"
)
target_include_directories(liblog PRIVATE
    "${AOSP_SRC}/system/core/libcutils/include"
    "${AOSP_SRC}/system/core/libutils/include"
    "${AOSP_SRC}/system/core/include"
    "${AOSP_SRC}/system/libbase/include"
)
target_compile_definitions(liblog PRIVATE
    LIBLOG_LOG_TAG=1006
    SNET_EVENT_LOG_TAG=1397638484
    ANDROID_DEBUGGABLE=0
    FAKE_LOG_DEVICE=1
)
target_compile_options(liblog PRIVATE
    -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__
    -Wno-unguarded-availability
)

# 2. libbase
add_library(libbase STATIC
    "${AOSP_SRC}/system/libbase/chrono_utils.cpp"
    "${AOSP_SRC}/system/libbase/cmsg.cpp"
    "${AOSP_SRC}/system/libbase/errors_unix.cpp"
    "${AOSP_SRC}/system/libbase/file.cpp"
    "${AOSP_SRC}/system/libbase/hex.cpp"
    "${AOSP_SRC}/system/libbase/logging.cpp"
    "${AOSP_SRC}/system/libbase/mapped_file.cpp"
    "${AOSP_SRC}/system/libbase/parsebool.cpp"
    "${AOSP_SRC}/system/libbase/parsenetaddress.cpp"
    "${AOSP_SRC}/system/libbase/posix_strerror_r.cpp"
    "${AOSP_SRC}/system/libbase/process.cpp"
    "${AOSP_SRC}/system/libbase/properties.cpp"
    "${AOSP_SRC}/system/libbase/result.cpp"
    "${AOSP_SRC}/system/libbase/stringprintf.cpp"
    "${AOSP_SRC}/system/libbase/strings.cpp"
    "${AOSP_SRC}/system/libbase/test_utils.cpp"
    "${AOSP_SRC}/system/libbase/threads.cpp"
)
target_include_directories(libbase PUBLIC
    "${AOSP_SRC}/system/libbase/include"
)
target_link_libraries(libbase PUBLIC fmtlib liblog)

# 3. libasync_safe (linux_bionic dep of libcutils)
add_library(libasync_safe STATIC
    "${AOSP_SRC}/bionic/libc/async_safe/async_safe_log.cpp"
)
target_include_directories(libasync_safe PUBLIC
    "${AOSP_SRC}/bionic/libc/async_safe/include"
)
target_include_directories(libasync_safe PRIVATE
    "${AOSP_SRC}/system/logging/liblog/include"
)
target_compile_options(libasync_safe PRIVATE
    "SHELL:-idirafter ${AOSP_SRC}/bionic/libc"
)

# 4. libcutils (host/linux_bionic/not_windows sources)
add_library(libcutils STATIC
    "${AOSP_SRC}/system/core/libcutils/sockets.cpp"
    "${AOSP_SRC}/system/core/libcutils/socket_inaddr_any_server_unix.cpp"
    "${AOSP_SRC}/system/core/libcutils/socket_local_client_unix.cpp"
    "${AOSP_SRC}/system/core/libcutils/socket_local_server_unix.cpp"
    "${AOSP_SRC}/system/core/libcutils/socket_network_client_unix.cpp"
    "${AOSP_SRC}/system/core/libcutils/sockets_utils.cpp"
    "${AOSP_SRC}/system/core/libcutils/sockets_unix.cpp"
    "${AOSP_SRC}/system/core/libcutils/config_utils.cpp"
    "${AOSP_SRC}/system/core/libcutils/iosched_policy.cpp"
    "${AOSP_SRC}/system/core/libcutils/load_file.cpp"
    "${AOSP_SRC}/system/core/libcutils/native_handle.cpp"
    "${AOSP_SRC}/system/core/libcutils/properties.cpp"
    "${AOSP_SRC}/system/core/libcutils/record_stream.cpp"
    "${AOSP_SRC}/system/core/libcutils/strlcpy.c"
    "${AOSP_SRC}/system/core/libcutils/trace-host.cpp"
    "${AOSP_SRC}/system/core/libcutils/ashmem-host.cpp"
    "${AOSP_SRC}/system/core/libcutils/canned_fs_config.cpp"
    "${AOSP_SRC}/system/core/libcutils/fs_config.cpp"
    "${AOSP_SRC}/system/core/libcutils/fs.cpp"
    "${AOSP_SRC}/system/core/libcutils/hashmap.cpp"
    "${AOSP_SRC}/system/core/libcutils/multiuser.cpp"
    "${AOSP_SRC}/system/core/libcutils/str_parms.cpp"
)
target_include_directories(libcutils PUBLIC
    "${AOSP_SRC}/system/core/libcutils/include"
    "${AOSP_SRC}/system/core/libprocessgroup/include"
)
target_link_libraries(libcutils PUBLIC liblog libbase libasync_safe aosp_system_headers)

# 5. libutils (with libutils_binder + host Looper.cpp)
add_library(libutils STATIC
    "${AOSP_SRC}/system/core/libutils/FileMap.cpp"
    "${AOSP_SRC}/system/core/libutils/JenkinsHash.cpp"
    "${AOSP_SRC}/system/core/libutils/LightRefBase.cpp"
    "${AOSP_SRC}/system/core/libutils/NativeHandle.cpp"
    "${AOSP_SRC}/system/core/libutils/Printer.cpp"
    "${AOSP_SRC}/system/core/libutils/StopWatch.cpp"
    "${AOSP_SRC}/system/core/libutils/SystemClock.cpp"
    "${AOSP_SRC}/system/core/libutils/Threads.cpp"
    "${AOSP_SRC}/system/core/libutils/Timers.cpp"
    "${AOSP_SRC}/system/core/libutils/Tokenizer.cpp"
    "${AOSP_SRC}/system/core/libutils/misc.cpp"
    "${AOSP_SRC}/system/core/libutils/Looper.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/Errors.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/RefBase.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/SharedBuffer.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/String16.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/String8.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/StrongPointer.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/Unicode.cpp"
    "${AOSP_SRC}/system/core/libutils/binder/VectorImpl.cpp"
)
target_include_directories(libutils PUBLIC
    "${AOSP_SRC}/system/core/libutils/include"
    "${AOSP_SRC}/system/core/libutils/binder/include"
    "${AOSP_SRC}/system/core/libsystem/include"
)
target_compile_definitions(libutils PRIVATE
    ANDROID_UTILS_REF_BASE_DISABLE_IMPLICIT_CONSTRUCTION
)
target_link_libraries(libutils PUBLIC libbase libcutils liblog aosp_system_headers)

# 6. libziparchive_for_incfs & libincfs-utils
add_library(libziparchive_for_incfs STATIC
    "${AOSP_SRC}/system/libziparchive/zip_archive.cc"
    "${AOSP_SRC}/system/libziparchive/zip_archive_stream_entry.cc"
    "${AOSP_SRC}/system/libziparchive/zip_cd_entry_map.cc"
    "${AOSP_SRC}/system/libziparchive/zip_error.cpp"
    "${AOSP_SRC}/system/libziparchive/zip_writer.cc"
    "${AOSP_SRC}/system/libziparchive/incfs_support/signal_handling.cpp"
)
target_include_directories(libziparchive_for_incfs PUBLIC
    "${AOSP_SRC}/system/libziparchive/include"
    "${AOSP_SRC}/system/libziparchive/incfs_support/include"
    "${AOSP_SRC}/external/googletest/googletest/include"
)
target_compile_definitions(libziparchive_for_incfs PRIVATE
    ZLIB_CONST
    ZIPARCHIVE_DISABLE_CALLBACK_API=1
)
target_link_libraries(libziparchive_for_incfs PUBLIC libbase liblog libz)

add_library(libincfs-utils STATIC
    "${AOSP_SRC}/system/incremental_delivery/incfs/util/map_ptr.cpp"
)
target_include_directories(libincfs-utils PUBLIC
    "${AOSP_SRC}/system/incremental_delivery/incfs/util/include"
)
target_link_libraries(libincfs-utils PUBLIC libbase libutils libziparchive_for_incfs)

# 7. libkernelconfigs
add_library(libkernelconfigs STATIC
    "${AOSP_SRC}/system/libvintf/KernelConfigs.cpp"
    "${AOSP_SRC}/system/libvintf/KernelConfigParser.cpp"
)
target_include_directories(libkernelconfigs PUBLIC
    "${AOSP_SRC}/system/libvintf/include"
)
target_include_directories(libkernelconfigs PRIVATE
    "${AOSP_SRC}/system/libvintf/include/vintf"
)
target_link_libraries(libkernelconfigs PUBLIC libbase libtinyxml2 libutils)

# 8. libPlatformProperties
file(GLOB PLAT_PROP_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/sysprop/platform/src/*.cpp")
add_library(libPlatformProperties STATIC ${PLAT_PROP_SRCS})
target_include_directories(libPlatformProperties PUBLIC
    "${GEN_DIR}/sysprop/platform/include"
    "${GEN_DIR}/sysprop/platform/public_include"
)
target_link_libraries(libPlatformProperties PUBLIC libbase libcutils liblog)

# 9. libstatssocket-fake & libstatspull-fake
add_library(libstatssocket-fake STATIC
    "${AOSP_SRC}/packages/modules/StatsD/lib/libstatssocket/fake/libstatssocket.c"
)
target_include_directories(libstatssocket-fake PUBLIC
    "${AOSP_SRC}/packages/modules/StatsD/lib/libstatssocket/include"
)

add_library(libstatspull-fake STATIC
    "${AOSP_SRC}/packages/modules/StatsD/lib/libstatspull/fake/libstatspull.c"
)
target_include_directories(libstatspull-fake PUBLIC
    "${AOSP_SRC}/packages/modules/StatsD/lib/libstatspull/include"
)
target_link_libraries(libstatspull-fake PUBLIC libstatssocket-fake)

# 10. server_configurable_flags, libcxxbridge05, libflags_rust_cpp_bridge
add_library(server_configurable_flags STATIC
    "${AOSP_SRC}/system/server_configurable_flags/libflags/server_configurable_flags.cc"
)
target_include_directories(server_configurable_flags PUBLIC
    "${AOSP_SRC}/system/server_configurable_flags/libflags/include"
)
target_link_libraries(server_configurable_flags PUBLIC libbase libcutils)

add_library(libcxxbridge05 STATIC
    "${AOSP_SRC}/external/rust/cxx/src/cxx.cc"
)
target_compile_definitions(libcxxbridge05 PRIVATE RUST_CXX_NO_EXCEPTIONS)
target_link_libraries(libcxxbridge05 PUBLIC cxx_bridge_headers)

add_library(libflags_rust_cpp_bridge STATIC
    "${AOSP_SRC}/system/server_configurable_flags/libflags/rust_get_flags.cpp"
    "${GEN_DIR}/cxx/libflags/rust_libflags_cxx_generated.cc"
)
target_include_directories(libflags_rust_cpp_bridge PRIVATE
    "${AOSP_SRC}/system/server_configurable_flags/libflags"
)
target_link_libraries(libflags_rust_cpp_bridge PUBLIC server_configurable_flags libcxxbridge05 cxx_bridge_headers)

# 11. Aconfig flags static C++ libs used in Phase 4 & later
aosp_add_aconfig_lib(libbinder_flags "android.os.binder.flags-aconfig-cc")

# 12. libbinder (host profile)
file(GLOB_RECURSE BINDER_AIDL_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/aidl/libbinder/src/*.cpp")
add_library(libbinder STATIC
    "${AOSP_SRC}/frameworks/native/libs/binder/Binder.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/BpBinder.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Debug.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/FdTrigger.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IInterface.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IResultReceiver.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/JavaBBinderBase.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Parcel.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ParcelFileDescriptor.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/RecordedTransaction.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/RpcSession.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/RpcServer.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/RpcState.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/RpcTransportRaw.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Stability.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Status.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/TextOutput.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Utils.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/file.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/OS_android.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/OS_unix_base.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/PersistableBundle.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/UtilsHost.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/BufferedTextOutput.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/BackendUnifiedServiceManager.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IPCThreadState.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IServiceManager.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IServiceManagerFFI.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ProcessState.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/Static.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IMemory.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/IShellCallback.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/LazyServiceRegistrar.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/MemoryBase.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/MemoryDealer.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/MemoryHeapBase.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ParcelableHolder.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/observer/BinderObserver.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/observer/BinderObserverConfig.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/observer/BinderStatsPusher.cpp"
    ${BINDER_AIDL_SRCS}
)
target_include_directories(libbinder PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/binder/include"
    "${AOSP_SRC}/frameworks/native/libs/binder/include_private"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/include_cpp"
    "${GEN_DIR}/aidl/libbinder/include"
)
target_include_directories(libbinder PRIVATE
    "${AOSP_SRC}/frameworks/native/libs/binder"
    "${AOSP_SRC}/frameworks/native/libs/binder/observer"
    "${AOSP_SRC}/libnativehelper/include_jni"
)
target_compile_definitions(libbinder PRIVATE
    BUILDING_LIBBINDER
    BINDER_WITH_KERNEL_IPC
    NO_LIBBINDER_BINDER_OBSERVER
    ANDROID_BASE_UNIQUE_FD_DISABLE_IMPLICIT_CONVERSION
)
target_link_libraries(libbinder PUBLIC
    libbinder_flags
    libbase
    libcutils
    libutils
    liblog
    bionic_uapi_headers
)

# 13. libandroid_runtime_lazy & libbinder_ndk
add_library(libandroid_runtime_lazy STATIC
    "${AOSP_SRC}/frameworks/native/libs/android_runtime_lazy/android_runtime_lazy.cpp"
)
target_include_directories(libandroid_runtime_lazy PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/android_runtime_lazy/include"
)
target_include_directories(libandroid_runtime_lazy PRIVATE
    "${AOSP_SRC}/libnativehelper/include_jni"
)
target_link_libraries(libandroid_runtime_lazy PUBLIC libbinder libutils liblog)

add_library(libbinder_ndk STATIC
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/ibinder.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/libbinder.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/parcel.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/stability.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/status.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/ibinder_jni.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/parcel_jni.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/persistable_bundle.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/process.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/service_manager.cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/binder_rpc.cpp"
)
target_include_directories(libbinder_ndk PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/include_cpp"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/include_ndk"
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk/include_platform"
    "${AOSP_SRC}/libnativehelper/include_jni"
)
target_include_directories(libbinder_ndk PRIVATE
    "${AOSP_SRC}/frameworks/native/libs/binder/ndk"
)
target_compile_definitions(libbinder_ndk PRIVATE BINDER_WITH_KERNEL_IPC)
target_compile_options(libbinder_ndk PRIVATE
    -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__
    -Wno-unguarded-availability
)
target_link_libraries(libbinder_ndk PUBLIC libandroid_runtime_lazy libbinder libbase libutils liblog)

# 14. libhwbinder-impl-internal, libhidlbase & libbinderthreadstateutils
add_library(libhwbinder-impl-internal STATIC
    "${AOSP_SRC}/system/libhwbinder/Binder.cpp"
    "${AOSP_SRC}/system/libhwbinder/BpHwBinder.cpp"
    "${AOSP_SRC}/system/libhwbinder/BufferedTextOutput.cpp"
    "${AOSP_SRC}/system/libhwbinder/Debug.cpp"
    "${AOSP_SRC}/system/libhwbinder/IInterface.cpp"
    "${AOSP_SRC}/system/libhwbinder/IPCThreadState.cpp"
    "${AOSP_SRC}/system/libhwbinder/Parcel.cpp"
    "${AOSP_SRC}/system/libhwbinder/ProcessState.cpp"
    "${AOSP_SRC}/system/libhwbinder/Static.cpp"
    "${AOSP_SRC}/system/libhwbinder/TextOutput.cpp"
    "${AOSP_SRC}/system/libhwbinder/Utils.cpp"
)
target_include_directories(libhwbinder-impl-internal PUBLIC
    "${AOSP_SRC}/system/libhwbinder/include"
)
target_link_libraries(libhwbinder-impl-internal PUBLIC
    bionic_uapi_headers
    libbase
    libcutils
    libutils
    liblog
)

file(GLOB_RECURSE HIDL_GEN_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/hidl/src/*.cpp")
add_library(libhidlbase STATIC
    "${AOSP_SRC}/system/libhidl/base/HidlInternal.cpp"
    "${AOSP_SRC}/system/libhidl/base/HidlSupport.cpp"
    "${AOSP_SRC}/system/libhidl/base/Status.cpp"
    "${AOSP_SRC}/system/libhidl/base/TaskRunner.cpp"
    "${AOSP_SRC}/system/libhidl/transport/HidlBinderSupport.cpp"
    "${AOSP_SRC}/system/libhidl/transport/HidlLazyUtils.cpp"
    "${AOSP_SRC}/system/libhidl/transport/HidlPassthroughSupport.cpp"
    "${AOSP_SRC}/system/libhidl/transport/HidlTransportSupport.cpp"
    "${AOSP_SRC}/system/libhidl/transport/HidlTransportUtils.cpp"
    "${AOSP_SRC}/system/libhidl/transport/LegacySupport.cpp"
    "${AOSP_SRC}/system/libhidl/transport/ServiceManagement.cpp"
    "${AOSP_SRC}/system/libhidl/transport/Static.cpp"
    ${HIDL_GEN_SRCS}
)
target_include_directories(libhidlbase PUBLIC
    "${GEN_DIR}/hidl/include"
    "${AOSP_SRC}/system/libhidl/base/include"
    "${AOSP_SRC}/system/libhidl/transport/include"
    "${AOSP_SRC}/system/libfmq/include"
    "${AOSP_SRC}/system/libfmq/base"
)
target_link_libraries(libhidlbase PUBLIC
    libhwbinder-impl-internal
    libbase
    libcutils
    libutils
    liblog
)

add_library(libbinderthreadstateutils INTERFACE)
target_include_directories(libbinderthreadstateutils INTERFACE
    "${AOSP_SRC}/frameworks/native/libs/binderthreadstate/include"
)
target_link_libraries(libbinderthreadstateutils INTERFACE libbinder libhidlbase)

# 15. libaconfig_storage_read_api_cc (wraps Rust libaconfig_storage_read_api_cxx_bridge.a)
add_library(libaconfig_storage_read_api_cxx_bridge STATIC IMPORTED GLOBAL)
set_target_properties(libaconfig_storage_read_api_cxx_bridge PROPERTIES
    IMPORTED_LOCATION "${TARGET_PREBUILTS}/libaconfig_storage_read_api_cxx_bridge.a"
)

add_library(libaconfig_storage_read_api_cc STATIC
    "${AOSP_SRC}/build/make/tools/aconfig/aconfig_storage_read_api/aconfig_storage_read_api.cpp"
    "${GEN_DIR}/cxx/aconfig_storage_read_api/aconfig_storage/lib.rs.cc"
)
target_include_directories(libaconfig_storage_read_api_cc PUBLIC
    "${AOSP_SRC}/build/make/tools/aconfig/aconfig_storage_read_api/include"
    "${GEN_DIR}/cxx/aconfig_storage_read_api/include"
)
target_link_libraries(libaconfig_storage_read_api_cc PUBLIC
    libbase
    cxx_bridge_headers
    libcxxbridge05
    libaconfig_storage_read_api_cxx_bridge
)
