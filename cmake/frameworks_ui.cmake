# Phase 6: Native Graphics Stubs, Framework Assets, Input, Perfetto & HWUI (aarch64-linux-android30)

# 1. Shared header-only & geometry primitives
if(NOT TARGET libarect)
    add_library(libarect INTERFACE)
    target_include_directories(libarect INTERFACE
        "${AOSP_SRC}/frameworks/native/libs/arect/include"
    )
endif()

add_library(libhardware_headers INTERFACE)
target_include_directories(libhardware_headers INTERFACE
    "${AOSP_SRC}/hardware/libhardware/include"
)

add_library(libmath INTERFACE)
target_include_directories(libmath INTERFACE
    "${AOSP_SRC}/frameworks/native/libs/math/include"
)

add_library(libui-types STATIC
    "${AOSP_SRC}/frameworks/native/libs/ui/ColorSpace.cpp"
    "${AOSP_SRC}/frameworks/native/libs/ui/Rect.cpp"
    "${AOSP_SRC}/frameworks/native/libs/ui/Region.cpp"
    "${AOSP_SRC}/frameworks/native/libs/ui/Transform.cpp"
)
target_include_directories(libui-types PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/ui/include"
    "${AOSP_SRC}/frameworks/native/libs/ui/include_mock"
    "${AOSP_SRC}/frameworks/native/libs/ui/include_private"
    "${AOSP_SRC}/frameworks/native/libs/ui/include_types"
)
target_link_libraries(libui-types PUBLIC libarect libmath libhardware_headers libbase libutils)

# 2. libnativehelper_jvm (JVM JNI bridge + utf helpers)
add_library(libnativehelper_jvm STATIC
    "${AOSP_SRC}/frameworks/base/libs/nativehelper_jvm/JNIPlatformHelp.c"
    "${AOSP_SRC}/frameworks/base/libs/nativehelper_jvm/JniConstants.c"
    "${AOSP_SRC}/frameworks/base/libs/nativehelper_jvm/file_descriptor_jni.c"
    "${AOSP_SRC}/libnativehelper/DlHelp.c"
    "${AOSP_SRC}/libnativehelper/ExpandableString.c"
    "${AOSP_SRC}/libnativehelper/JNIHelp.c"
    "${AOSP_SRC}/libnativehelper/JniInvocation.c"
    "${AOSP_SRC}/libnativehelper/utf.cpp"
)
target_include_directories(libnativehelper_jvm PUBLIC
    "${AOSP_SRC}/libnativehelper/header_only_include"
    "${AOSP_SRC}/libnativehelper/include"
    "${AOSP_SRC}/libnativehelper/include_jni"
    "${AOSP_SRC}/libnativehelper/include_platform"
    "${AOSP_SRC}/libnativehelper/include_platform_header_only"
)
target_include_directories(libnativehelper_jvm PRIVATE
    "${AOSP_SRC}/art/libdexfile"
)
target_compile_options(libnativehelper_jvm PRIVATE -fvisibility=protected)
target_link_libraries(libnativehelper_jvm PUBLIC liblog dl)

# 3. libhostgraphics (host/Layoutlib ANativeWindow, ADisplay, Fence, HostBufferQueue)
add_library(libhostgraphics STATIC
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/ADisplay.cpp"
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/ANativeWindow.cpp"
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/Fence.cpp"
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/HostBufferQueue.cpp"
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/PublicFormat.cpp"
)
target_include_directories(libhostgraphics PUBLIC
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/include"
    "${AOSP_SRC}/frameworks/native/libs/nativebase/include"
    "${AOSP_SRC}/frameworks/native/libs/nativedisplay/include"
    "${AOSP_SRC}/frameworks/native/libs/nativewindow/include"
    "${AOSP_SRC}/frameworks/native/include"
)
target_link_libraries(libhostgraphics PUBLIC libbase libmath libui-types libutils)

# 4. Aconfig flag C++ libraries generated in Phase 2 (for Phases 6 & 7)
aosp_add_aconfig_lib(android.content.res.flags-aconfig-cc-host-ro "android.content.res.flags-aconfig-cc-host-ro")
aosp_add_aconfig_lib(aconfig_view_accessibility_flags_c_lib "aconfig_view_accessibility_flags_c_lib")
aosp_add_aconfig_lib(libguiflags "libguiflags")
aosp_add_aconfig_lib(libsurfaceflingerflags "libsurfaceflingerflags")
aosp_add_aconfig_lib(hwui_flags_cc_lib "hwui_flags_cc_lib")
aosp_add_aconfig_lib(com.android.input.flags-aconfig-cc "com.android.input.flags-aconfig-cc")
aosp_add_aconfig_lib(com.android.window.flags.window-aconfig_flags_c_lib "com.android.window.flags.window-aconfig_flags_c_lib")
aosp_add_aconfig_lib(libcore_jni_flags_c "libcore_jni_flags_c")
aosp_add_aconfig_lib(perfetto_flags_c_lib "perfetto_flags_c_lib")

# 5. libandroidfw (with PathUtils and libziparchive_for_incfs)
add_library(libandroidfw STATIC
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ApkAssets.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ApkParsing.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/Asset.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/AssetDir.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/AssetManager.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/AssetManager2.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/AssetsProvider.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/AttributeResolution.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/BigBuffer.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/BigBufferStream.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ChunkIterator.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ConfigDescription.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/CursorWindow.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/FileStream.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/Idmap.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/LoadedArsc.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/Locale.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/LocaleData.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/LocaleDataLookup.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/misc.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/NinePatch.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ObbFile.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/PosixUtils.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/Png.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/PngChunkFilter.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/PngCrunch.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ResourceTimer.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ResourceTypes.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ResourceUtils.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/StreamingZipInflater.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/StringPool.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/TypeWrappers.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/Util.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ZipFileRO.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/ZipUtils.cpp"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/PathUtils.cpp"
)
target_include_directories(libandroidfw PUBLIC
    "${AOSP_SRC}/frameworks/base/libs/androidfw/include"
    "${AOSP_SRC}/frameworks/base/libs/androidfw/include_pathutils"
)
target_compile_definitions(libandroidfw PRIVATE STATIC_ANDROIDFW_FOR_TOOLS)
target_link_libraries(libandroidfw PUBLIC
    android.content.res.flags-aconfig-cc-host-ro
    libincfs-utils
    libziparchive_for_incfs
    libbinder
    libpng
    libz
    libbase
    libcutils
    liblog
    libutils
)

# 6. Perfetto (libperfetto_c & libtracing_perfetto)
include("${CMAKE_CURRENT_LIST_DIR}/perfetto_srcs.cmake")
file(GLOB_RECURSE PERFETTO_GEN_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/perfetto/include/*.cc")
add_library(libperfetto_c STATIC
    ${PERFETTO_C_SRCS}
    ${PERFETTO_GEN_SRCS}
)
set_target_properties(libperfetto_c PROPERTIES CXX_STANDARD 20 CXX_EXTENSIONS ON)
target_include_directories(libperfetto_c PUBLIC
    "${AOSP_SRC}/external/perfetto/include"
)
target_include_directories(libperfetto_c PRIVATE
    "${GEN_DIR}/perfetto/include"
    "${AOSP_SRC}/external/perfetto"
    "${AOSP_SRC}/external/perfetto/include/perfetto/base/build_configs/android_tree"
    "${AOSP_SRC}/external/perfetto/src/profiling/memory/include"
)
target_compile_definitions(libperfetto_c PRIVATE PERFETTO_SHLIB_SDK_IMPLEMENTATION)
target_compile_options(libperfetto_c PRIVATE
    -O2
    -Wno-error=return-type
    -Wno-sign-promo
    -fvisibility=hidden
)
target_link_libraries(libperfetto_c PUBLIC perfetto_flags_c_lib libz liblog)

add_library(libtracing_perfetto STATIC
    "${AOSP_SRC}/frameworks/native/libs/tracing_perfetto/tracing_perfetto.cpp"
    "${AOSP_SRC}/frameworks/native/libs/tracing_perfetto/tracing_perfetto_internal.cpp"
    "${AOSP_SRC}/frameworks/native/libs/tracing_perfetto/tracing_sdk.cpp"
)
target_include_directories(libtracing_perfetto PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/tracing_perfetto/include"
)
target_link_libraries(libtracing_perfetto PUBLIC libperfetto_c libbase libcutils)

# 7. Input & WindowInfo & StatsLog & Rust FFI bindings
file(GLOB_RECURSE INPUTCONST_CPP_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/aidl/inputconstants-cpp/src/*.cpp")
add_library(inputconstants-cpp STATIC ${INPUTCONST_CPP_SRCS})
target_include_directories(inputconstants-cpp PUBLIC
    "${GEN_DIR}/aidl/inputconstants-cpp/include"
)
target_link_libraries(inputconstants-cpp PUBLIC libbinder)

file(GLOB_RECURSE GUI_WIN_AIDL_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/aidl/gui_window_info/src/*.cpp")
add_library(libgui_window_info_static STATIC
    "${AOSP_SRC}/frameworks/native/libs/gui/DisplayInfo.cpp"
    "${AOSP_SRC}/frameworks/native/libs/gui/WindowInfo.cpp"
    "${AOSP_SRC}/frameworks/native/libs/gui/WindowInfosUpdate.cpp"
    ${GUI_WIN_AIDL_SRCS}
)
target_include_directories(libgui_window_info_static PUBLIC
    "${AOSP_SRC}/frameworks/native/libs/gui/include"
    "${AOSP_SRC}/frameworks/native/include"
    "${GEN_DIR}/aidl/gui_window_info/include"
)
target_link_libraries(libgui_window_info_static PUBLIC libui-types inputconstants-cpp libbinder)

file(GLOB_RECURSE IINPUTFLINGER_AIDL_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/aidl/iinputflinger/src/*.cpp")
add_library(iinputflinger_aidl_lib_static STATIC ${IINPUTFLINGER_AIDL_SRCS})
target_include_directories(iinputflinger_aidl_lib_static PUBLIC
    "${GEN_DIR}/aidl/iinputflinger/include"
)
target_link_libraries(iinputflinger_aidl_lib_static PUBLIC libgui_window_info_static libbinder)

add_library(libstatslog_libinput_bundled STATIC
    "${GEN_DIR}/statslog/src/statslog_libinput.cpp"
    "${GEN_DIR}/statslog/src/statslog_input.cpp"
)
target_include_directories(libstatslog_libinput_bundled PUBLIC
    "${GEN_DIR}/statslog/include"
)
target_link_libraries(libstatslog_libinput_bundled PUBLIC libstatssocket-fake libstatspull-fake)

add_library(libbinder_rs_compat STATIC
    "${AOSP_SRC}/frameworks/native/libs/binder/rust/src/cpp/binder_rust.cpp"
)
target_compile_options(libbinder_rs_compat PRIVATE
    -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__
    -Wno-unguarded-availability
)
target_link_libraries(libbinder_rs_compat PUBLIC libbinder_ndk)

add_library(libinput_rust_ffi STATIC IMPORTED GLOBAL)
set_target_properties(libinput_rust_ffi PROPERTIES
    IMPORTED_LOCATION "${TARGET_PREBUILTS}/libinput_rust_ffi.a"
)

add_library(libinput STATIC
    "${AOSP_SRC}/frameworks/native/libs/input/AccelerationCurve.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/CoordinateFilter.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/DisplayTopologyGraph.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/Input.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputConsumer.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputConsumerNoResampling.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputDevice.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputEventLabels.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputTransport.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/InputVerifier.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/KeyCharacterMap.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/KeyLayoutMap.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/Keyboard.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/KeyboardClassifier.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/MotionPredictor.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/MotionPredictorMetricsManager.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/OneEuroFilter.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/PrintTools.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/PropertyMap.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/Resampler.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/TfLiteMotionPredictor.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/TouchVideoFrame.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/VelocityControl.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/VelocityTracker.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/VirtualInputDevice.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/VirtualKeyMap.cpp"
    "${AOSP_SRC}/frameworks/native/libs/input/FromRustToCpp.cpp"
    "${GEN_DIR}/cxx/input/input_cxx_bridge_generated.cpp"
)
target_include_directories(libinput PUBLIC
    "${AOSP_SRC}/frameworks/native/include"
    "${AOSP_SRC}/frameworks/native/libs/ftl/include"
    "${AOSP_SRC}/external/eigen"
    "${AOSP_SRC}/external/flatbuffers/include"
    "${AOSP_SRC}/external/tensorflow"
    "${AOSP_SRC}/libnativehelper/include_jni"
    "${GEN_DIR}/cxx/input/include"
)
target_include_directories(libinput PRIVATE
    "${AOSP_SRC}/frameworks/native/libs/input"
    "${GEN_DIR}/toolbox/include"
)
target_compile_definitions(libinput PRIVATE
    ANDROID_UTILS_REF_BASE_DISABLE_IMPLICIT_CONSTRUCTION
)
target_link_libraries(libinput PUBLIC
    libinput_rust_ffi
    libbinder_rs_compat
    cxx_bridge_headers
    libcxxbridge05
    inputconstants-cpp
    iinputflinger_aidl_lib_static
    libgui_window_info_static
    libstatslog_libinput_bundled
    com.android.input.flags-aconfig-cc
    com.android.window.flags.window-aconfig_flags_c_lib
    libPlatformProperties
    libkernelconfigs
    libtflite_static
    libui-types
    libaconfig_storage_read_api_cc
    libbinder
    libbinder_ndk
    libbase
    libcutils
    libutils
    liblog
    libtinyxml2
    libz
    server_configurable_flags
    bionic_uapi_headers
)

# 8. libhwui (Layoutlib HWUI_NULL_GPU host profile)
include("${CMAKE_CURRENT_LIST_DIR}/hwui_srcs.cmake")
add_library(libhwui STATIC ${HWUI_HOST_SRCS})
target_include_directories(libhwui PUBLIC
    "${AOSP_SRC}/frameworks/base/libs/hwui/platform/host"
    "${AOSP_SRC}/frameworks/base/libs/hwui"
    "${AOSP_SRC}/frameworks/base/libs/hwui/apex/include"
    "${AOSP_SRC}/frameworks/base/libs/hwui/jni"
    "${GEN_DIR}/sysprop/hwui/include"
    "${GEN_DIR}/sysprop/hwui/public_include"
)
target_include_directories(libhwui PRIVATE
    "${AOSP_SRC}/frameworks/native/include/private"
    "${AOSP_SRC}/external/skia/include/private"
    "${AOSP_SRC}/external/skia/src/core"
    "${AOSP_SRC}/external/skia/src/codec"
    "${AOSP_SRC}/external/skia/src/utils"
    "${AOSP_SRC}/external/vulkan-headers/include"
    "${AOSP_SRC}/frameworks/av/media/ndk/include"
    "${AOSP_SRC}/external/googletest/googletest/include"
)
target_compile_definitions(libhwui PRIVATE
    HWUI_NULL_GPU
    NULL_GPU_MAX_TEXTURE_SIZE=4096
    ATRACE_TAG=ATRACE_TAG_VIEW
    LOG_TAG="HWUI"
    GL_GLEXT_PROTOTYPES
    EGL_EGLEXT_PROTOTYPES
    U_USING_ICU_NAMESPACE=0
)
target_compile_options(libhwui PRIVATE
    -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__
    -Wno-unguarded-availability
    -Wno-unused-private-field
    -Wno-non-virtual-dtor
    -Wno-free-nonheap-object
    -Wno-implicit-fallthrough
    -fvisibility=hidden
)
target_link_libraries(libhwui PUBLIC
    libui-types
    libandroidfw
    libhostgraphics
    libutils
    libarect
    libwebp-decode
    libwebp-encode
    libwuffs_mirror_release_c
    libdng_sdk
    libziparchive_for_incfs
    libnativehelper_jvm
    hwui_flags_cc_lib
    libsurfaceflingerflags
    aconfig_text_flags_c_lib
    aconfig_view_accessibility_flags_c_lib
    libaconfig_storage_read_api_cc
    libbase
    libharfbuzz_ng
    libminikin
    libcutils
    liblog
    libpng
    libz
    libjpeg
    libpiex
    libexpat
    libft2
    libharfbuzz_subset
    libimage_io
    libultrahdr
    libguiflags
    libtracing_perfetto
    libperfetto_c
    libbinder
    libbinder_ndk
    libskia
    bionic_uapi_headers
)
