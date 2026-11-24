# Phase 7: Top-Level Shared Libraries (libandroid_runtime.so & layoutlib_jni.so)

file(GLOB_RECURSE DPI_AIDL_SRCS CONFIGURE_DEPENDS "${GEN_DIR}/aidl/deviceproductinfoconstants/src/*.cpp")

add_library(android_runtime SHARED
    "${AOSP_SRC}/frameworks/base/core/jni/android_animation_PropertyValuesHolder.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_content_res_ApkAssets.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_CursorWindow.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_SQLiteCommon.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_SQLiteConnection.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_SQLiteGlobal.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_SQLiteDebug.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_database_SQLiteRawStatement.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_media_ImageReader.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_media_PublicFormatUtils.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_media_Utils.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_os_SystemClock.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_os_SystemProperties.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_text_AndroidCharacter.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_text_Hyphenator.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_AssetManager.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_EventLog.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_Log.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_StringBlock.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_XmlBlock.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_jar_StrictJarFile.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_InputDevice.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_KeyCharacterMap.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_KeyEvent.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_MotionEvent.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_MotionPredictor.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_Surface.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_VelocityTracker.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_VerifiedKeyEvent.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_VerifiedMotionEvent.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/com_android_internal_util_VirtualRefBasePtr.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/core_jni_helpers.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/platform/host/HostRuntime.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/platform/host/native_window_jni.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_hardware_input_InputApplicationHandle.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_os_MessageQueue.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_os_Parcel.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_InputChannel.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_InputEventReceiver.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_view_InputEventSender.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_Binder.cpp"
    "${AOSP_SRC}/frameworks/base/core/jni/android_util_FileObserver.cpp"
    ${DPI_AIDL_SRCS}
)
set_target_properties(android_runtime PROPERTIES
    OUTPUT_NAME "android_runtime"
)
target_include_directories(android_runtime BEFORE PRIVATE
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/include"
)
target_include_directories(android_runtime PUBLIC
    "${AOSP_SRC}/frameworks/base/core/jni"
    "${AOSP_SRC}/frameworks/base/core/jni/include"
)
target_include_directories(android_runtime PRIVATE
    "${AOSP_SRC}/frameworks/base/media/jni"
    "${AOSP_SRC}/system/media/camera/include"
    "${AOSP_SRC}/system/media/private/camera/include"
    "${AOSP_SRC}/frameworks/native/libs/binder/include_private"
    "${AOSP_SRC}/external/skia/include/private"
    "${AOSP_SRC}/external/vulkan-headers/include"
    "${AOSP_SRC}/external/flatbuffers/include"
    "${AOSP_SRC}/external/tensorflow"
    "${GEN_DIR}/aidl/deviceproductinfoconstants/include"
)
target_compile_definitions(android_runtime PRIVATE
    GL_GLEXT_PROTOTYPES
    EGL_EGLEXT_PROTOTYPES
    U_USING_ICU_NAMESPACE=0
    ANDROID_UTILS_REF_BASE_DISABLE_IMPLICIT_CONSTRUCTION
)
target_compile_options(android_runtime PRIVATE
    -D__ANDROID_UNAVAILABLE_SYMBOLS_ARE_WEAK__
    -Wno-unguarded-availability
    -Wno-non-virtual-dtor
    -Wno-conversion-null
)
target_link_options(android_runtime PRIVATE
    "-Wl,--version-script=${AOSP_SRC}/frameworks/base/core/jni/platform/linux/libandroid_runtime_export.txt"
    "-Wl,--undefined-version"
    "-Wl,--gc-sections"
    "-static-libstdc++"
)
target_link_libraries(android_runtime PRIVATE
    libhwui
    libminikin
    libskia
    libinput
    libandroidfw
    libhostgraphics
    libnativehelper_jvm
    libui-types
    libtracing_perfetto
    libperfetto_c
    libsqlite
    libharfbuzz_subset
    libharfbuzz_ng
    libicu
    libicui18n
    libicuuc
    libicuuc_stubdata
    libandroidicuinit
    libbinderthreadstateutils
    libgui_window_info_static
    libhidlbase
    libhwbinder-impl-internal
    libbinder_ndk
    libandroid_runtime_lazy
    libbinder
    libaconfig_storage_read_api_cc
    libcore_jni_flags_c
    android.content.res.flags-aconfig-cc-host-ro
    aconfig_text_flags_c_lib
    aconfig_view_accessibility_flags_c_lib
    libguiflags
    libsurfaceflingerflags
    hwui_flags_cc_lib
    com.android.input.flags-aconfig-cc
    com.android.window.flags.window-aconfig_flags_c_lib
    server_configurable_flags
    libPlatformProperties
    libkernelconfigs
    libincfs-utils
    libziparchive_for_incfs
    libultrahdr
    libimage_io
    libjpegdecoder
    libjpegencoder
    libpiex
    libtiff_directory
    libimage_type_recognition
    libbinary_parse
    libdng_sdk
    libft2
    libwebp-decode
    libwebp-encode
    libwuffs_mirror_release_c
    libjpeg
    libpng
    libexpat
    libtinyxml2
    libtflite_static
    libz
    libutils
    libcutils
    libasync_safe
    libbase
    liblog
    libstatssocket-fake
    libstatspull-fake
    m
    dl
)

add_library(layoutlib_jni SHARED
    "${AOSP_SRC}/frameworks/layoutlib/jni/LayoutlibLoader.cpp"
)
set_target_properties(layoutlib_jni PROPERTIES
    PREFIX ""
    OUTPUT_NAME "layoutlib_jni"
    BUILD_RPATH "\$ORIGIN"
)
target_link_options(layoutlib_jni PRIVATE
    "-Wl,--version-script=${AOSP_SRC}/frameworks/layoutlib/jni/linux/layoutlib_jni_export.txt"
    "-Wl,--undefined-version"
    "-Wl,--gc-sections"
    "-Wl,-rpath,\$ORIGIN"
    "-static-libstdc++"
)
target_include_directories(layoutlib_jni BEFORE PRIVATE
    "${AOSP_SRC}/frameworks/base/libs/hostgraphics/include"
)
target_link_libraries(layoutlib_jni PRIVATE
    android_runtime
    libnativehelper_jvm
    libhostgraphics
    libinput
    libui-types
    libbinder
    libcutils
    libutils
    libbase
    liblog
    dl
)
