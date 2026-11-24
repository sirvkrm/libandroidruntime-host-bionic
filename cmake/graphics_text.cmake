# Phase 5: ICU, HarfBuzz, SQLite, Minikin & Skia (aarch64-linux-android30)

# Shared header-only rect definitions used by Skia and frameworks UI
if(NOT TARGET libarect)
    add_library(libarect INTERFACE)
    target_include_directories(libarect INTERFACE
        "${AOSP_SRC}/frameworks/native/libs/arect/include"
    )
endif()

# 1. ICU4C (stubdata, androidicuinit, icuuc, icui18n, libicu NDK shim)
add_library(libicuuc_stubdata STATIC
    "${AOSP_SRC}/external/icu/icu4c/source/stubdata/stubdata.cpp"
)
target_include_directories(libicuuc_stubdata PUBLIC
    "${AOSP_SRC}/external/icu/icu4c/source/common"
    "${AOSP_SRC}/external/icu/android_icu4c/include"
)
target_compile_definitions(libicuuc_stubdata PUBLIC ANDROID_LINK_SHARED_ICU4C)

file(GLOB ANDROIDICUINIT_SRCS CONFIGURE_DEPENDS "${AOSP_SRC}/external/icu/libandroidicuinit/*.cpp")
add_library(libandroidicuinit STATIC ${ANDROIDICUINIT_SRCS})
target_include_directories(libandroidicuinit PUBLIC
    "${AOSP_SRC}/external/icu/libandroidicuinit/include"
)
target_include_directories(libandroidicuinit PRIVATE
    "${AOSP_SRC}/external/icu/libandroidicuinit"
)
target_compile_options(libandroidicuinit PRIVATE
    -Wno-unnecessary-virtual-specifier
)
target_link_libraries(libandroidicuinit PUBLIC libicuuc_stubdata libbase liblog)

file(GLOB ICUUC_SRCS CONFIGURE_DEPENDS "${AOSP_SRC}/external/icu/icu4c/source/common/*.cpp")
add_library(libicuuc STATIC ${ICUUC_SRCS})
target_include_directories(libicuuc PUBLIC
    "${AOSP_SRC}/external/icu/icu4c/source/common"
    "${AOSP_SRC}/external/icu/android_icu4c/include"
    "${AOSP_SRC}/external/icu/libandroidicuinit/include"
)
target_compile_definitions(libicuuc PRIVATE
    _REENTRANT
    U_COMMON_IMPLEMENTATION
    UCONFIG_USE_ML_PHRASE_BREAKING=1
)
target_compile_definitions(libicuuc PUBLIC ANDROID_LINK_SHARED_ICU4C)
target_compile_options(libicuuc PRIVATE
    -O3
    -fvisibility=hidden
    -frtti
    -Wno-ambiguous-reversed-operator
    -Wno-unnecessary-virtual-specifier
    -Wno-unneeded-internal-declaration
)
target_link_libraries(libicuuc PUBLIC libicuuc_stubdata libandroidicuinit libbase liblog)

file(GLOB ICUI18N_SRCS CONFIGURE_DEPENDS "${AOSP_SRC}/external/icu/icu4c/source/i18n/*.cpp")
add_library(libicui18n STATIC ${ICUI18N_SRCS})
target_include_directories(libicui18n PUBLIC
    "${AOSP_SRC}/external/icu/icu4c/source/i18n"
)
target_compile_definitions(libicui18n PRIVATE
    _REENTRANT
    U_I18N_IMPLEMENTATION
    UCONFIG_USE_ML_PHRASE_BREAKING=1
)
target_compile_options(libicui18n PRIVATE
    -O3
    -fvisibility=hidden
    -frtti
    -Wno-ambiguous-reversed-operator
    -Wno-unnecessary-virtual-specifier
    -Wno-unneeded-internal-declaration
    -Wno-unreachable-code-loop-increment
)
target_link_libraries(libicui18n PUBLIC libicuuc)

# libicu provides NDK C ABI shims (u_*_android) from shim.cpp.
# Keep ndk_headers PRIVATE to avoid unicode/uchar.h conflicts with full ICU4C headers.
add_library(libicu STATIC
    "${AOSP_SRC}/external/icu/libicu/src/shim.cpp"
)
target_compile_definitions(libicu PRIVATE
    U_SHOW_CPLUSPLUS_API=0
    U_SHOW_CPLUSPLUS_HEADER_API=0
    UCONFIG_USE_ML_PHRASE_BREAKING=1
)
target_compile_options(libicu PRIVATE
    -Wno-unnecessary-virtual-specifier
)
target_link_libraries(libicu PUBLIC libicui18n libicuuc)

# 2. HarfBuzz (libharfbuzz_ng & libharfbuzz_subset)
add_library(libharfbuzz_ng STATIC
    "${AOSP_SRC}/external/harfbuzz_ng/src/OT/Var/VARC/VARC.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-aat-layout.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-aat-map.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-blob.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-buffer-serialize.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-buffer-verify.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-buffer.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-common.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-draw.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-face-builder.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-face.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-fallback-shape.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-font.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-map.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-number.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-cff1-table.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-cff2-table.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-color.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-face.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-font.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-layout.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-map.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-math.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-meta.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-metrics.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-name.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shape-fallback.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shape-normalize.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shape.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-arabic.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-default.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-hangul.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-hebrew.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-indic-table.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-indic.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-khmer.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-myanmar.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-syllabic.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-thai.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-use.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-shaper-vowel-constraints.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-tag.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-var.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-outline.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-paint-bounded.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-paint-extents.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-paint.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-set.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-shape-plan.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-shape.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-shaper.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-static.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-style.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ucd.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-unicode.cc"
)
target_include_directories(libharfbuzz_ng PUBLIC
    "${AOSP_SRC}/external/harfbuzz_ng/src"
)
target_compile_definitions(libharfbuzz_ng PRIVATE
    HAVE_ICU
    HAVE_ICU_BUILTIN
    HAVE_OT
    HAVE_PTHREAD
    HB_NO_PRAGMA_GCC_DIAGNOSTIC
)
target_compile_options(libharfbuzz_ng PRIVATE -Wno-implicit-fallthrough)
target_link_libraries(libharfbuzz_ng PUBLIC libcutils libutils libicu liblog)

add_library(libharfbuzz_subset STATIC
    "${AOSP_SRC}/external/harfbuzz_ng/src/graph/gsubgpos-context.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-number.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-cff1-table.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-ot-cff2-table.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-static.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-cff-common.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-cff1.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-cff2.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-input.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-instancer-iup.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-instancer-solver.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-plan-layout.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-plan-var.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-plan.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-serialize.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-table-cff.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-table-color.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-table-layout.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-table-other.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset-table-var.cc"
    "${AOSP_SRC}/external/harfbuzz_ng/src/hb-subset.cc"
)
target_compile_definitions(libharfbuzz_subset PRIVATE
    HAVE_ICU
    HAVE_ICU_BUILTIN
    HAVE_OT
    HAVE_PTHREAD
    HB_NO_PRAGMA_GCC_DIAGNOSTIC
)
target_compile_options(libharfbuzz_subset PRIVATE -Wno-implicit-fallthrough)
target_link_libraries(libharfbuzz_subset PUBLIC libharfbuzz_ng)

# 3. SQLite (with Android PhoneNumberUtils + ICU collation)
add_library(libsqlite STATIC
    "${AOSP_SRC}/external/sqlite/dist/sqlite-default/sqlite3.c"
    "${AOSP_SRC}/external/sqlite/android/PhoneNumberUtils.cpp"
    "${AOSP_SRC}/external/sqlite/android/OldPhoneNumberUtils.cpp"
    "${AOSP_SRC}/external/sqlite/android/sqlite3_android.cpp"
)
target_include_directories(libsqlite PUBLIC
    "${AOSP_SRC}/external/sqlite/dist/sqlite-default"
    "${AOSP_SRC}/external/sqlite/android"
)
target_compile_definitions(libsqlite PRIVATE
    NDEBUG=1
    HAVE_USLEEP=1
    SQLITE_HAVE_ISNAN
    SQLITE_DEFAULT_JOURNAL_SIZE_LIMIT=1048576
    SQLITE_THREADSAFE=2
    SQLITE_TEMP_STORE=3
    SQLITE_POWERSAFE_OVERWRITE=1
    SQLITE_DEFAULT_FILE_FORMAT=4
    SQLITE_DEFAULT_AUTOVACUUM=1
    SQLITE_ENABLE_DBSTAT_VTAB
    SQLITE_ENABLE_MEMORY_MANAGEMENT=1
    SQLITE_ENABLE_FTS3
    SQLITE_ENABLE_FTS3_BACKWARDS
    SQLITE_ENABLE_FTS4
    SQLITE_OMIT_BUILTIN_TEST
    SQLITE_OMIT_COMPILEOPTION_DIAGS
    SQLITE_OMIT_LOAD_EXTENSION
    SQLITE_DEFAULT_FILE_PERMISSIONS=0600
    SQLITE_SECURE_DELETE
    SQLITE_ENABLE_BATCH_ATOMIC_WRITE
    BIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD
    SQLITE_DEFAULT_LEGACY_ALTER_TABLE
    SQLITE_ALLOW_ROWID_IN_VIEW
    SQLITE_ENABLE_BYTECODE_VTAB
    SQLITE_ENABLE_ICU
    HAVE_POSIX_FALLOCATE=1
    USE_PREAD64
    HAVE_MALLOC_H=1
    fdatasync=fdatasync
)
target_compile_options(libsqlite PRIVATE -fno-unique-internal-linkage-names -ftrivial-auto-var-init=pattern)
target_link_libraries(libsqlite PUBLIC libicui18n libicuuc liblog)

# 4. Minikin (text shaping, line breaking, Rust hyphenator)
aosp_add_aconfig_lib(aconfig_text_flags_c_lib "aconfig_text_flags_c_lib")

add_library(libminikin_rust_ffi STATIC IMPORTED GLOBAL)
set_target_properties(libminikin_rust_ffi PROPERTIES
    IMPORTED_LOCATION "${TARGET_PREBUILTS}/libminikin_rust_ffi.a"
)

add_library(libminikin_from_rust_to_cpp STATIC
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/ffi/IcuBridge.cpp"
    "${GEN_DIR}/cxx/minikin/minikin_cxx_bridge_generated.cpp"
)
target_include_directories(libminikin_from_rust_to_cpp PUBLIC
    "${GEN_DIR}/cxx/minikin/include"
)
target_include_directories(libminikin_from_rust_to_cpp PRIVATE
    "${AOSP_SRC}/frameworks/minikin/libs/minikin"
)
target_link_libraries(libminikin_from_rust_to_cpp PUBLIC
    cxx_bridge_headers
    libcxxbridge05
    libicui18n
    libicuuc
)

add_library(libminikin STATIC
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/BidiUtils.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/CmapCoverage.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Emoji.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Font.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontCollection.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontFakery.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontFamily.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontFeatureUtils.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontFileParser.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/FontUtils.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/GraphemeBreak.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/GreedyLineBreaker.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Hyphenator.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/HyphenatorMap.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Layout.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/LayoutCore.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/LayoutUtils.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/LineBreaker.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/LineBreakerUtil.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Locale.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/LocaleListCache.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/MeasuredText.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/Measurement.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/MinikinFontFactory.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/MinikinInternal.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/OptimalLineBreaker.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/ScriptUtils.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/SparseBitSet.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/SystemFonts.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/U16StringPiece.cpp"
    "${AOSP_SRC}/frameworks/minikin/libs/minikin/WordBreaker.cpp"
)
target_include_directories(libminikin PUBLIC
    "${AOSP_SRC}/frameworks/minikin/include"
    "${AOSP_SRC}/external/googletest/googletest/include"
)
target_include_directories(libminikin PRIVATE
    "${AOSP_SRC}/frameworks/minikin/libs/minikin"
)
target_compile_options(libminikin PRIVATE -Wno-unused-function)
target_link_libraries(libminikin PUBLIC
    libminikin_from_rust_to_cpp
    libminikin_rust_ffi
    libflags_rust_cpp_bridge
    server_configurable_flags
    aconfig_text_flags_c_lib
    libharfbuzz_ng
    libicui18n
    libicuuc
    libcutils
    libutils
    libbase
    liblog
)

# 5. Skia (host_linux CPU/PDF/SVG/Codec/Fontations profile)
add_library(libskia_rust_ffi STATIC IMPORTED GLOBAL)
set_target_properties(libskia_rust_ffi PROPERTIES
    IMPORTED_LOCATION "${TARGET_PREBUILTS}/libskia_rust_ffi.a"
)

include("${CMAKE_CURRENT_LIST_DIR}/skia_srcs.cmake")
add_library(libskia STATIC
    ${SKIA_HOST_SRCS}
    "${GEN_DIR}/cxx/skia/src/ports/fontations/src/ffi.cpp"
)
# Skia headers (SkCaptureManager/SkPDFDevice) rely on pre-C++23 non-constexpr unique_ptr/pair destructors
set_target_properties(libskia PROPERTIES CXX_STANDARD 20 CXX_EXTENSIONS ON)
target_include_directories(libskia PUBLIC
    "${AOSP_SRC}/external/skia/linux"
    "${AOSP_SRC}/external/skia"
    "${AOSP_SRC}/external/skia/client_utils/android"
    "${AOSP_SRC}/external/skia/include/android"
    "${AOSP_SRC}/external/skia/include/codec"
    "${AOSP_SRC}/external/skia/include/config"
    "${AOSP_SRC}/external/skia/include/core"
    "${AOSP_SRC}/external/skia/include/docs"
    "${AOSP_SRC}/external/skia/include/effects"
    "${AOSP_SRC}/external/skia/include/encode"
    "${AOSP_SRC}/external/skia/include/gpu"
    "${AOSP_SRC}/external/skia/include/pathops"
    "${AOSP_SRC}/external/skia/include/ports"
    "${AOSP_SRC}/external/skia/include/svg"
    "${AOSP_SRC}/external/skia/include/utils"
    "${AOSP_SRC}/external/skia/include/utils/mac"
    "${AOSP_SRC}/external/skia/modules/skottie/include"
    "${AOSP_SRC}/external/skia/modules/skparagraph/include"
    "${AOSP_SRC}/external/skia/modules/skshaper/include"
    "${AOSP_SRC}/external/skia/modules/svg/include"
    "${GEN_DIR}/cxx/skia/include"
)
target_include_directories(libskia PRIVATE
    "${AOSP_SRC}/external/skia/modules/skcms"
)
target_compile_definitions(libskia PRIVATE
    ATRACE_TAG=ATRACE_TAG_VIEW
    SKIA_DLL
    SKIA_IMPLEMENTATION=1
    SK_PDF_USE_HARFBUZZ_SUBSET
)
target_compile_options(libskia PRIVATE
    -fexceptions
    -frtti
    -fvisibility=hidden
    -Wno-attributes
    -Wno-implicit-fallthrough
    -Wno-psabi
    -Wno-sign-conversion
    -Wno-thread-safety-analysis
    -Wno-unknown-warning-option
)
target_link_libraries(libskia PUBLIC
    libarect
    libskia_rust_ffi
    libcxxbridge05
    cxx_bridge_headers
    libwebp-decode
    libwebp-encode
    libwuffs_mirror_release_c
    libdng_sdk
    libpiex
    libjpeg
    libpng
    libexpat
    libft2
    libz
    libharfbuzz_subset
    libharfbuzz_ng
    libcutils
    liblog
)
