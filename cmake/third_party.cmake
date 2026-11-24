# Phase 3: Foundation Third-Party & Compression/Image/ML Static Libraries (aarch64-linux-android30)

# Abseil-cpp (built from official CMakeLists.txt for regex-re2)
set(ABSL_PROPAGATE_CXX_STD ON CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
add_subdirectory("${AOSP_SRC}/external/abseil-cpp" "${CMAKE_BINARY_DIR}/abseil-cpp" EXCLUDE_FROM_ALL)

add_library(libz STATIC
    "${AOSP_SRC}/external/zlib/adler32.c"
    "${AOSP_SRC}/external/zlib/adler32_simd.c"
    "${AOSP_SRC}/external/zlib/compress.c"
    "${AOSP_SRC}/external/zlib/cpu_features.c"
    "${AOSP_SRC}/external/zlib/crc32.c"
    "${AOSP_SRC}/external/zlib/crc32_simd.c"
    "${AOSP_SRC}/external/zlib/crc_folding.c"
    "${AOSP_SRC}/external/zlib/deflate.c"
    "${AOSP_SRC}/external/zlib/gzclose.c"
    "${AOSP_SRC}/external/zlib/gzlib.c"
    "${AOSP_SRC}/external/zlib/gzread.c"
    "${AOSP_SRC}/external/zlib/gzwrite.c"
    "${AOSP_SRC}/external/zlib/infback.c"
    "${AOSP_SRC}/external/zlib/inffast.c"
    "${AOSP_SRC}/external/zlib/inflate.c"
    "${AOSP_SRC}/external/zlib/inftrees.c"
    "${AOSP_SRC}/external/zlib/trees.c"
    "${AOSP_SRC}/external/zlib/uncompr.c"
    "${AOSP_SRC}/external/zlib/zutil.c"
)
target_include_directories(libz PUBLIC
    "${AOSP_SRC}/external/zlib"
)
target_compile_options(libz PRIVATE
    "-DHAVE_HIDDEN"
    "-DZLIB_CONST"
    "-DCHROMIUM_ZLIB_NO_CASTAGNOLI"
    "-O3"
    "-DADLER32_SIMD_NEON"
    "-DCRC32_ARMV8_CRC32"
    "-DDEFLATE_CHUNK_WRITE_64LE"
    "-DINFLATE_CHUNK_READ_64LE"
    "-DARMV8_OS_LINUX"
)

add_library(libpng STATIC
    "${AOSP_SRC}/external/libpng/png.c"
    "${AOSP_SRC}/external/libpng/pngerror.c"
    "${AOSP_SRC}/external/libpng/pngget.c"
    "${AOSP_SRC}/external/libpng/pngmem.c"
    "${AOSP_SRC}/external/libpng/pngpread.c"
    "${AOSP_SRC}/external/libpng/pngread.c"
    "${AOSP_SRC}/external/libpng/pngrio.c"
    "${AOSP_SRC}/external/libpng/pngrtran.c"
    "${AOSP_SRC}/external/libpng/pngrutil.c"
    "${AOSP_SRC}/external/libpng/pngset.c"
    "${AOSP_SRC}/external/libpng/pngtrans.c"
    "${AOSP_SRC}/external/libpng/pngwio.c"
    "${AOSP_SRC}/external/libpng/pngwrite.c"
    "${AOSP_SRC}/external/libpng/pngwtran.c"
    "${AOSP_SRC}/external/libpng/pngwutil.c"
    "${AOSP_SRC}/external/libpng/arm/arm_init.c"
    "${AOSP_SRC}/external/libpng/arm/filter_neon_intrinsics.c"
    "${AOSP_SRC}/external/libpng/arm/palette_neon_intrinsics.c"
)
target_include_directories(libpng PUBLIC
    "${AOSP_SRC}/external/libpng"
)
target_compile_options(libpng PRIVATE
    "-std=gnu89"
    "-O3"
)
target_link_libraries(libpng PUBLIC
    libz
)

add_library(libjpeg STATIC
    "${AOSP_SRC}/external/libjpeg-turbo/jaricom.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcapimin.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcapistd.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcarith.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jccoefct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jccolor.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcdctmgr.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jchuff.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcicc.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcinit.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcmainct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcmarker.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcmaster.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcomapi.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcparam.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcphuff.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcprepct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jcsample.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jctrans.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdapimin.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdapistd.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdarith.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdatadst.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdatasrc.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdcoefct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdcolor.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jddctmgr.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdhuff.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdicc.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdinput.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdmainct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdmarker.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdmaster.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdmerge.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdphuff.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdpostct.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdsample.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jdtrans.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jerror.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jfdctflt.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jfdctfst.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jfdctint.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jidctflt.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jidctfst.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jidctint.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jidctred.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jmemmgr.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jmemnobs.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jpeg_nbits_table.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jquant1.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jquant2.c"
    "${AOSP_SRC}/external/libjpeg-turbo/jutils.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/aarch64/jchuff-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/aarch64/jsimd.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jccolor-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jcgray-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jcphuff-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jcsample-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jdcolor-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jdmerge-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jdsample-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jfdctfst-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jfdctint-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jidctfst-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jidctint-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jidctred-neon.c"
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm/jquanti-neon.c"
)
target_include_directories(libjpeg PUBLIC
    "${AOSP_SRC}/external/libjpeg-turbo"
)
target_include_directories(libjpeg PRIVATE
    "${AOSP_SRC}/external/libjpeg-turbo/simd/arm"
)
target_compile_options(libjpeg PRIVATE
    "-DWITH_SIMD"
    "-DNO_GETENV"
    "-DNEON_INTRINSICS"
    "-O3"
    "-fstrict-aliasing"
)

add_library(libexpat STATIC
    "${AOSP_SRC}/external/expat/expat/lib/xmlparse.c"
    "${AOSP_SRC}/external/expat/expat/lib/xmlrole.c"
    "${AOSP_SRC}/external/expat/expat/lib/xmltok.c"
)
target_include_directories(libexpat PUBLIC
    "${AOSP_SRC}/external/expat"
    "${AOSP_SRC}/external/expat/lib"
    "${AOSP_SRC}/external/expat/expat/lib"
)
target_compile_options(libexpat PRIVATE
    "-fno-strict-aliasing"
    "-DHAVE_EXPAT_CONFIG_H"
    "-UWIN32_LEAN_AND_MEAN"
    "SHELL:-include stdio.h"
)

add_library(libtinyxml2 STATIC
    "${AOSP_SRC}/external/tinyxml2/tinyxml2.cpp"
)
target_include_directories(libtinyxml2 PUBLIC
    "${AOSP_SRC}/external/tinyxml2"
)

add_library(fmtlib STATIC
    "${AOSP_SRC}/external/fmtlib/src/format.cc"
)
target_include_directories(fmtlib PUBLIC
    "${AOSP_SRC}/external/fmtlib/include"
)
target_compile_options(fmtlib PRIVATE
    "-fno-exceptions"
    "-UNDEBUG"
)

add_library(libwebp-decode STATIC
    "${AOSP_SRC}/external/webp/src/dec/alpha_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/buffer_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/frame_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/idec_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/io_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/quant_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/tree_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/vp8_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/vp8l_dec.c"
    "${AOSP_SRC}/external/webp/src/dec/webp_dec.c"
    "${AOSP_SRC}/external/webp/src/demux/anim_decode.c"
    "${AOSP_SRC}/external/webp/src/demux/demux.c"
    "${AOSP_SRC}/external/webp/src/dsp/alpha_processing.c"
    "${AOSP_SRC}/external/webp/src/dsp/alpha_processing_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/alpha_processing_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/alpha_processing_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/cpu.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_clip_tables.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/dec_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/filters.c"
    "${AOSP_SRC}/external/webp/src/dsp/filters_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/filters_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/filters_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/filters_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/rescaler_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/upsampling.c"
    "${AOSP_SRC}/external/webp/src/dsp/upsampling_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/upsampling_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/upsampling_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/upsampling_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/yuv.c"
    "${AOSP_SRC}/external/webp/src/dsp/yuv_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/yuv_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/yuv_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/yuv_sse2.c"
    "${AOSP_SRC}/external/webp/src/utils/bit_reader_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/color_cache_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/filters_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/huffman_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/palette.c"
    "${AOSP_SRC}/external/webp/src/utils/quant_levels_dec_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/random_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/rescaler_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/thread_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/utils.c"
)
target_include_directories(libwebp-decode PUBLIC
    "${AOSP_SRC}/external/webp/src"
    "${AOSP_SRC}/external/webp"
)
target_compile_options(libwebp-decode PRIVATE
    "-DANDROID"
    "-DWEBP_SWAP_16BIT_CSP"
    "-DWEBP_USE_THREAD"
    "-O2"
)

add_library(libwebp-encode STATIC
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_cpu.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_csp.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_dsp.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_gamma.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_neon.c"
    "${AOSP_SRC}/external/webp/sharpyuv/sharpyuv_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/cost.c"
    "${AOSP_SRC}/external/webp/src/dsp/cost_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/cost_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/cost_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/cost_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/cpu.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/enc_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc_mips32.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc_mips_dsp_r2.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc_msa.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc_neon.c"
    "${AOSP_SRC}/external/webp/src/dsp/lossless_enc_sse2.c"
    "${AOSP_SRC}/external/webp/src/dsp/ssim.c"
    "${AOSP_SRC}/external/webp/src/dsp/ssim_sse2.c"
    "${AOSP_SRC}/external/webp/src/enc/alpha_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/analysis_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/backward_references_cost_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/backward_references_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/config_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/cost_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/filter_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/frame_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/histogram_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/iterator_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/near_lossless_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/picture_csp_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/picture_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/picture_psnr_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/picture_rescale_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/picture_tools_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/predictor_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/quant_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/syntax_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/token_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/tree_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/vp8l_enc.c"
    "${AOSP_SRC}/external/webp/src/enc/webp_enc.c"
    "${AOSP_SRC}/external/webp/src/mux/anim_encode.c"
    "${AOSP_SRC}/external/webp/src/mux/muxedit.c"
    "${AOSP_SRC}/external/webp/src/mux/muxinternal.c"
    "${AOSP_SRC}/external/webp/src/mux/muxread.c"
    "${AOSP_SRC}/external/webp/src/utils/bit_writer_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/huffman_encode_utils.c"
    "${AOSP_SRC}/external/webp/src/utils/quant_levels_utils.c"
)
target_include_directories(libwebp-encode PUBLIC
    "${AOSP_SRC}/external/webp/src"
    "${AOSP_SRC}/external/webp"
)
target_compile_options(libwebp-encode PRIVATE
    "-DANDROID"
    "-DWEBP_SWAP_16BIT_CSP"
    "-DWEBP_USE_THREAD"
    "-O2"
)

add_library(libwuffs_mirror_release_c STATIC
    "${AOSP_SRC}/external/wuffs-mirror-release-c/release/c/wuffs-v0.3.c"
)
target_include_directories(libwuffs_mirror_release_c PUBLIC
    "${AOSP_SRC}/external/wuffs-mirror-release-c/release/c"
)
target_compile_options(libwuffs_mirror_release_c PRIVATE
    "-DWUFFS_IMPLEMENTATION"
    "-DWUFFS_CONFIG__MODULES"
    "-DWUFFS_CONFIG__MODULE__BASE"
    "-DWUFFS_CONFIG__MODULE__GIF"
    "-DWUFFS_CONFIG__MODULE__LZW"
)

add_library(libft2 STATIC
    "${AOSP_SRC}/external/freetype/src/autofit/autofit.c"
    "${AOSP_SRC}/external/freetype/src/base/ftbase.c"
    "${AOSP_SRC}/external/freetype/src/base/ftbbox.c"
    "${AOSP_SRC}/external/freetype/src/base/ftbitmap.c"
    "${AOSP_SRC}/external/freetype/src/base/ftdebug.c"
    "${AOSP_SRC}/external/freetype/src/base/ftfstype.c"
    "${AOSP_SRC}/external/freetype/src/base/ftgasp.c"
    "${AOSP_SRC}/external/freetype/src/base/ftglyph.c"
    "${AOSP_SRC}/external/freetype/src/base/ftinit.c"
    "${AOSP_SRC}/external/freetype/src/base/ftmm.c"
    "${AOSP_SRC}/external/freetype/src/base/ftstroke.c"
    "${AOSP_SRC}/external/freetype/src/base/fttype1.c"
    "${AOSP_SRC}/external/freetype/src/base/ftsynth.c"
    "${AOSP_SRC}/external/freetype/src/base/ftsystem.c"
    "${AOSP_SRC}/external/freetype/src/cid/type1cid.c"
    "${AOSP_SRC}/external/freetype/src/cff/cff.c"
    "${AOSP_SRC}/external/freetype/src/gzip/ftgzip.c"
    "${AOSP_SRC}/external/freetype/src/psaux/psaux.c"
    "${AOSP_SRC}/external/freetype/src/pshinter/pshinter.c"
    "${AOSP_SRC}/external/freetype/src/psnames/psnames.c"
    "${AOSP_SRC}/external/freetype/src/raster/raster.c"
    "${AOSP_SRC}/external/freetype/src/sdf/sdf.c"
    "${AOSP_SRC}/external/freetype/src/sfnt/sfnt.c"
    "${AOSP_SRC}/external/freetype/src/smooth/smooth.c"
    "${AOSP_SRC}/external/freetype/src/svg/svg.c"
    "${AOSP_SRC}/external/freetype/src/truetype/truetype.c"
    "${AOSP_SRC}/external/freetype/src/type1/type1.c"
)
target_include_directories(libft2 PUBLIC
    "${AOSP_SRC}/external/freetype/include"
)
target_compile_options(libft2 PRIVATE
    "-DDARWIN_NO_CARBON"
    "-DFT2_BUILD_LIBRARY"
    "-O2"
    "-DFT_CONFIG_OPTION_USE_PNG"
    "-DFT_CONFIG_OPTION_USE_ZLIB"
    "-DFT_CONFIG_OPTION_SYSTEM_ZLIB"
    "-DPIC"
)
target_link_libraries(libft2 PUBLIC
    libpng
    libz
)

add_library(zuid_md5 STATIC
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/third-party/zuid/interfaces/MD5.cpp"
)
target_include_directories(zuid_md5 PRIVATE
    "${AOSP_SRC}/external/XMP-Toolkit-SDK"
)
target_compile_options(zuid_md5 PRIVATE
    "-DUNIX_ENV=1"
)

add_library(xmp_toolkit_sdk STATIC
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/Host_IO-POSIX.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/IOUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/PerfUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/UnicodeConversions.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/XIO.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/XML_Node.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/XMPFiles_IO.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/XMP_LibUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/source/XMP_ProgressTracker.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/ExpatAdapter.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/ParseRDF.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/WXMPIterator.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/WXMPMeta.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/WXMPUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPCore_Impl.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPIterator.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPMeta-GetSet.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPMeta-Parse.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPMeta-Serialize.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPMeta.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPUtils-FileInfo.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPCore/source/XMPUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FileHandlers/Basic_Handler.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FileHandlers/Scanner_Handler.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FileHandlers/Trivial_Handler.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FormatSupport/ID3_Support.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FormatSupport/ISOBaseMedia_Support.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FormatSupport/Reconcile_Impl.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/FormatSupport/XMPScanner.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/HandlerRegistry.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/NativeMetadataSupport/IMetadata.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/NativeMetadataSupport/IReconcile.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/NativeMetadataSupport/MetadataSet.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/FileHandlerInstance.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/HostAPIImpl.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/Module.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/PluginManager.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/XMPAtoms.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/WXMPFiles.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/XMPFiles.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/XMPFiles_Impl.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/PluginTemplate/source/Template_Handler.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source/HostAPIAccess.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source/PluginAPIImpl.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source/PluginBase.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source/PluginRegistry.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source/PluginUtils.cpp"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFiles/source/PluginHandler/OS_Utils_Linux.cpp"
)
target_include_directories(xmp_toolkit_sdk PUBLIC
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/public/include"
)
target_include_directories(xmp_toolkit_sdk PRIVATE
    "${AOSP_SRC}/external/XMP-Toolkit-SDK"
    "${AOSP_SRC}/external/XMP-Toolkit-SDK/XMPFilesPlugins/api/source"
)
target_compile_options(xmp_toolkit_sdk PRIVATE
    "-DkBigEndianHost=0"
    "-DEnablePhotoHandlers=0"
    "-DEnableDynamicMediaHandlers=0"
    "-DEnableMiscHandlers=0"
    "-DUNIX_ENV=1"
    "-DXMP_StaticBuild=1"
    "-Wno-bitwise-instead-of-logical"
    "-Wno-nontrivial-memcall"
    "-Wno-null-conversion"
    "-Wno-reorder-ctor"
    "-Wno-user-defined-warnings"
    "SHELL:--include=warning_override_overrider.h"
)
target_compile_options(xmp_toolkit_sdk PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-fexceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-frtti>
)
target_link_libraries(xmp_toolkit_sdk PUBLIC
    libexpat
    zuid_md5
)

add_library(libbinary_parse STATIC
    "${AOSP_SRC}/external/piex/src/binary_parse/cached_paged_byte_array.cc"
    "${AOSP_SRC}/external/piex/src/binary_parse/range_checked_byte_ptr.cc"
)
target_include_directories(libbinary_parse PUBLIC
    "${AOSP_SRC}/external/piex"
)

add_library(libimage_type_recognition STATIC
    "${AOSP_SRC}/external/piex/src/image_type_recognition/image_type_recognition_lite.cc"
)
target_include_directories(libimage_type_recognition PUBLIC
    "${AOSP_SRC}/external/piex"
)
target_link_libraries(libimage_type_recognition PUBLIC
    libbinary_parse
)

add_library(libtiff_directory STATIC
    "${AOSP_SRC}/external/piex/src/tiff_directory/tiff_directory.cc"
)
target_include_directories(libtiff_directory PUBLIC
    "${AOSP_SRC}/external/piex"
)
target_link_libraries(libtiff_directory PUBLIC
    libbinary_parse
)

add_library(libpiex STATIC
    "${AOSP_SRC}/external/piex/src/piex.cc"
    "${AOSP_SRC}/external/piex/src/piex_cr3.cc"
    "${AOSP_SRC}/external/piex/src/tiff_parser.cc"
)
target_include_directories(libpiex PUBLIC
    "${AOSP_SRC}/external/piex"
)
target_link_libraries(libpiex PUBLIC
    libbinary_parse
    libimage_type_recognition
    libtiff_directory
)

add_library(libmodpb64 STATIC
    "${AOSP_SRC}/external/modp_b64/modp_b64.cc"
)
target_include_directories(libmodpb64 PUBLIC
    "${AOSP_SRC}/external/modp_b64"
)
target_include_directories(libmodpb64 PRIVATE
    "${AOSP_SRC}/external/modp_b64/modp_b64"
)

add_library(libimage_io STATIC
    "${AOSP_SRC}/external/image_io/src/base/byte_array_decoder.cc"
    "${AOSP_SRC}/external/image_io/src/base/byte_array_encoder.cc"
    "${AOSP_SRC}/external/image_io/src/base/byte_buffer.cc"
    "${AOSP_SRC}/external/image_io/src/base/byte_pointer_data_destination.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_context.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_line_map.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_range_tracking_destination.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_scanner.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_segment.cc"
    "${AOSP_SRC}/external/image_io/src/base/data_segment_data_source.cc"
    "${AOSP_SRC}/external/image_io/src/base/istream_ref_data_source.cc"
    "${AOSP_SRC}/external/image_io/src/base/message_handler.cc"
    "${AOSP_SRC}/external/image_io/src/base/message_writer.cc"
    "${AOSP_SRC}/external/image_io/src/base/ostream_ref_data_destination.cc"
    "${AOSP_SRC}/external/image_io/src/base/string_ref_data_source.cc"
    "${AOSP_SRC}/external/image_io/src/extras/base64_decoder_data_destination.cc"
    "${AOSP_SRC}/external/image_io/src/gcontainer/gcontainer.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_atom.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_base_descriptor.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_decoder.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_encoder.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_gain_map_metadata_decoder.cc"
    "${AOSP_SRC}/external/image_io/src/iso/iso_gain_map_metadata_encoder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_apple_depth_builder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_exif_decoder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_image_extractor.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_info_builder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_marker.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_scanner.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_segment.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_segment_builder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_segment_lister.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_xmp_data_extractor.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_xmp_info.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_xmp_info_builder.cc"
    "${AOSP_SRC}/external/image_io/src/jpeg/jpeg_xmp_segment_writer.cc"
    "${AOSP_SRC}/external/image_io/src/mpf/mpf_info_decoder.cc"
    "${AOSP_SRC}/external/image_io/src/mpf/mpf_info_encoder.cc"
    "${AOSP_SRC}/external/image_io/src/mpf/mpf_xmp_helpers.cc"
    "${AOSP_SRC}/external/image_io/src/utils/file_utils.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_attribute_rule.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_cdata_and_comment_rules.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_element_rules.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_handler.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_pi_rule.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_reader.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_rule.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_token_context.cc"
    "${AOSP_SRC}/external/image_io/src/xml/xml_writer.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_container_metadata_reader.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_container_metadata_writer.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_content_handler.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_dispatch_handler.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_element_handler.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_errors.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_gain_map_metadata.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_gain_map_metadata_reader.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_gain_map_metadata_writer.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_gimage_metadata_reader.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_gimage_metadata_writer.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_listing_builder.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_reader.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_reader_data_destination.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_rule.cc"
    "${AOSP_SRC}/external/image_io/src/xmp/xmp_writer.cc"
)
target_include_directories(libimage_io PUBLIC
    "${AOSP_SRC}/external/image_io/includes"
)
target_compile_options(libimage_io PRIVATE
    "-DUNIX_ENV=1"
    "-Wno-reorder"
)
target_compile_options(libimage_io PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-frtti>
)
target_link_libraries(libimage_io PUBLIC
    libmodpb64
)

add_library(libjpegdecoder STATIC
    "${AOSP_SRC}/external/libultrahdr/lib/src/jpegdecoderhelper.cpp"
)
target_include_directories(libjpegdecoder PUBLIC
    "${AOSP_SRC}/external/libultrahdr"
    "${AOSP_SRC}/external/libultrahdr/lib/include"
)
target_include_directories(libjpegdecoder PRIVATE
    "${AOSP_SRC}/system/logging/liblog/include"
)
target_link_libraries(libjpegdecoder PUBLIC
    libjpeg
)

add_library(libjpegencoder STATIC
    "${AOSP_SRC}/external/libultrahdr/lib/src/jpegencoderhelper.cpp"
)
target_include_directories(libjpegencoder PUBLIC
    "${AOSP_SRC}/external/libultrahdr"
    "${AOSP_SRC}/external/libultrahdr/lib/include"
)
target_include_directories(libjpegencoder PRIVATE
    "${AOSP_SRC}/system/logging/liblog/include"
)
target_link_libraries(libjpegencoder PUBLIC
    libjpeg
)

add_library(libultrahdr STATIC
    "${AOSP_SRC}/external/libultrahdr/lib/src/icc.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/jpegr.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/gainmapmath.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/gainmapmetadata.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/jpegrutils.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/multipictureformat.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/editorhelper.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/ultrahdr_api.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/dsp/arm/editorhelper_neon.cpp"
    "${AOSP_SRC}/external/libultrahdr/lib/src/dsp/arm/gainmapmath_neon.cpp"
)
target_include_directories(libultrahdr PUBLIC
    "${AOSP_SRC}/external/libultrahdr"
    "${AOSP_SRC}/external/libultrahdr/lib/include"
)
target_include_directories(libultrahdr PRIVATE
    "${AOSP_SRC}/system/logging/liblog/include"
)
target_compile_options(libultrahdr PRIVATE
    "-DUHDR_ENABLE_INTRINSICS"
    "-DUHDR_WRITE_XMP"
)
target_compile_options(libultrahdr PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-frtti>
)
target_link_libraries(libultrahdr PUBLIC
    libimage_io
    libjpeg
    libjpegencoder
    libjpegdecoder
)

add_library(libbrotli STATIC
    "${AOSP_SRC}/external/brotli/c/common/constants.c"
    "${AOSP_SRC}/external/brotli/c/common/context.c"
    "${AOSP_SRC}/external/brotli/c/common/dictionary.c"
    "${AOSP_SRC}/external/brotli/c/common/platform.c"
    "${AOSP_SRC}/external/brotli/c/common/shared_dictionary.c"
    "${AOSP_SRC}/external/brotli/c/common/transform.c"
    "${AOSP_SRC}/external/brotli/c/dec/bit_reader.c"
    "${AOSP_SRC}/external/brotli/c/dec/decode.c"
    "${AOSP_SRC}/external/brotli/c/dec/huffman.c"
    "${AOSP_SRC}/external/brotli/c/dec/state.c"
    "${AOSP_SRC}/external/brotli/c/enc/backward_references.c"
    "${AOSP_SRC}/external/brotli/c/enc/backward_references_hq.c"
    "${AOSP_SRC}/external/brotli/c/enc/bit_cost.c"
    "${AOSP_SRC}/external/brotli/c/enc/block_splitter.c"
    "${AOSP_SRC}/external/brotli/c/enc/brotli_bit_stream.c"
    "${AOSP_SRC}/external/brotli/c/enc/cluster.c"
    "${AOSP_SRC}/external/brotli/c/enc/command.c"
    "${AOSP_SRC}/external/brotli/c/enc/compound_dictionary.c"
    "${AOSP_SRC}/external/brotli/c/enc/compress_fragment.c"
    "${AOSP_SRC}/external/brotli/c/enc/compress_fragment_two_pass.c"
    "${AOSP_SRC}/external/brotli/c/enc/dictionary_hash.c"
    "${AOSP_SRC}/external/brotli/c/enc/encode.c"
    "${AOSP_SRC}/external/brotli/c/enc/encoder_dict.c"
    "${AOSP_SRC}/external/brotli/c/enc/entropy_encode.c"
    "${AOSP_SRC}/external/brotli/c/enc/fast_log.c"
    "${AOSP_SRC}/external/brotli/c/enc/histogram.c"
    "${AOSP_SRC}/external/brotli/c/enc/literal_cost.c"
    "${AOSP_SRC}/external/brotli/c/enc/memory.c"
    "${AOSP_SRC}/external/brotli/c/enc/metablock.c"
    "${AOSP_SRC}/external/brotli/c/enc/static_dict.c"
    "${AOSP_SRC}/external/brotli/c/enc/utf8_util.c"
)
target_include_directories(libbrotli PUBLIC
    "${AOSP_SRC}/external/brotli/c/include"
)
target_compile_options(libbrotli PRIVATE
    "-O2"
)

add_library(libhwy STATIC
    "${AOSP_SRC}/external/google-highway/hwy/contrib/image/image.cc"
    "${AOSP_SRC}/external/google-highway/hwy/contrib/thread_pool/topology.cc"
    "${AOSP_SRC}/external/google-highway/hwy/abort.cc"
    "${AOSP_SRC}/external/google-highway/hwy/aligned_allocator.cc"
    "${AOSP_SRC}/external/google-highway/hwy/nanobenchmark.cc"
    "${AOSP_SRC}/external/google-highway/hwy/per_target.cc"
    "${AOSP_SRC}/external/google-highway/hwy/print.cc"
    "${AOSP_SRC}/external/google-highway/hwy/targets.cc"
    "${AOSP_SRC}/external/google-highway/hwy/timer.cc"
)
target_include_directories(libhwy PUBLIC
    "${AOSP_SRC}/external/google-highway"
)

add_library(libskia_skcms STATIC
    "${AOSP_SRC}/external/skia/modules/skcms/skcms.cc"
    "${AOSP_SRC}/external/skia/modules/skcms/src/skcms_TransformBaseline.cc"
)
target_include_directories(libskia_skcms PUBLIC
    "${AOSP_SRC}/external/skia/modules/skcms"
)

add_library(libjxl STATIC
    "${AOSP_SRC}/external/libjxl/lib/jxl/ac_strategy.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/alpha.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/ans_common.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/blending.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/chroma_from_luma.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/coeff_order.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/color_encoding_internal.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/compressed_dc.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/convolve_slow.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/convolve_symmetric5.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dct_scales.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_ans.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_bit_reader.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_cache.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_context_map.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_external_image.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_frame.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_group.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_group_border.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_huffman.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_modular.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_noise.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_patch_dictionary.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/dec_xyb.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/decode.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/entropy_coder.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/epf.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/fields.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/frame_header.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/headers.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/huffman_table.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/icc_codec.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/icc_codec_common.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/image.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/image_bundle.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/image_metadata.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/image_ops.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/loop_filter.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/luminance.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/memory_manager_internal.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/encoding/dec_ma.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/encoding/encoding.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/modular_image.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/palette.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/rct.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/squeeze.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/squeeze_params.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/transform.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/opsin_params.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/passes_state.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/quant_weights.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/quantizer.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/low_memory_render_pipeline.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/render_pipeline.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/render_pipeline_stage.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/simple_render_pipeline.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_blending.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_chroma_upsampling.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_cms.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_epf.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_from_linear.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_gaborish.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_noise.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_patches.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_splines.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_spot.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_to_linear.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_tone_mapping.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_upsampling.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_write.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_xyb.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/render_pipeline/stage_ycbcr.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/simd_util.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/splines.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/toc.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/box_content_decoder.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/decode_to_jpeg.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/dec_jpeg_data.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/dec_jpeg_data_writer.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/jpeg_data.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/butteraugli/butteraugli.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_ac_strategy.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_adaptive_quantization.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_ans.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_aux_out.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_bit_writer.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_butteraugli_comparator.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_cache.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_chroma_from_luma.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_cluster.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_coeff_order.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_comparator.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_context_map.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_convolve_separable5.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_debug_image.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_detect_dots.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_dot_dictionary.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_entropy_coder.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_external_image.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_fast_lossless.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_fields.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_frame.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_gaborish.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_group.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_heuristics.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_huffman.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_huffman_tree.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_icc_codec.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_image_bundle.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_linalg.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_lz77.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_modular.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_noise.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_patch_dictionary.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_photon_noise.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_progressive_split.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_quant_weights.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_splines.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_toc.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_transforms.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/enc_xyb.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/encode.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/enc_jpeg_data.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/enc_jpeg_data_reader.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/jpeg/enc_jpeg_huffman_decode.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/encoding/enc_debug_tree.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/encoding/enc_encoding.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/encoding/enc_ma.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/enc_palette.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/enc_rct.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/enc_squeeze.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/modular/transform/enc_transform.cc"
    "${AOSP_SRC}/external/libjxl/lib/threads/resizable_parallel_runner.cc"
    "${AOSP_SRC}/external/libjxl/lib/threads/thread_parallel_runner.cc"
    "${AOSP_SRC}/external/libjxl/lib/threads/thread_parallel_runner_internal.cc"
    "${AOSP_SRC}/external/libjxl/lib/jxl/cms/jxl_cms.cc"
)
target_include_directories(libjxl PUBLIC
    "${AOSP_SRC}/external/libjxl/lib/include"
    "${AOSP_SRC}/external/libjxl/gen/include"
)
target_include_directories(libjxl PRIVATE
    "${AOSP_SRC}/external/libjxl"
)
target_compile_options(libjxl PRIVATE
    "-DJPEGXL_ENABLE_SKCMS=1"
)
target_link_libraries(libjxl PUBLIC
    libhwy
    libbrotli
    libskia_skcms
)

add_library(libcompiler_rt-extras STATIC
    "${AOSP_SRC}/external/compiler-rt/lib/builtins/mulodi4.c"
    "${AOSP_SRC}/external/compiler-rt/lib/builtins/comparedf2.c"
)
target_compile_options(libcompiler_rt-extras PRIVATE
    "-Wno-visibility"
    "-Wno-incompatible-pointer-types"
)

add_library(libdng_sdk STATIC
    "${AOSP_SRC}/external/dng_sdk/source/dng_1d_function.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_1d_table.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_abort_sniffer.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_area_task.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_bad_pixels.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_big_table.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_bmff.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_bottlenecks.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_camera_profile.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_color_space.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_color_spec.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_date_time.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_exceptions.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_exif.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_file_stream.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_filter_task.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_fingerprint.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_gain_map.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_globals.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_host.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_hue_sat_map.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_ifd.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_image.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_image_writer.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_info.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_iptc.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_jpeg_image.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_jpeg_memory_source.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_jxl.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_lens_correction.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_linearization_info.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_local_string.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_lossless_jpeg.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_lossless_jpeg_shared.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_matrix.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_memory.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_memory_stream.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_misc_opcodes.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_mosaic_info.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_mutex.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_negative.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_opcode_list.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_opcodes.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_orientation.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_parse_utils.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_pixel_buffer.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_point.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_preview.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_pthread.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_rational.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_read_image.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_rect.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_ref_counted_block.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_reference.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_render.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_resample.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_safe_arithmetic.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_shared.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_simple_image.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_spline.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_stream.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_string.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_string_list.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_tag_types.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_temperature.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_tile_iterator.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_tone_curve.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_utils.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_xmp.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_xmp_sdk.cpp"
    "${AOSP_SRC}/external/dng_sdk/source/dng_xy_coord.cpp"
    "${AOSP_SRC}/external/dng_sdk/ubsan-replacement/ubsan_throwing_runtime.cpp"
)
set_target_properties(libdng_sdk PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON)
target_include_directories(libdng_sdk PUBLIC
    "${AOSP_SRC}/external/dng_sdk/source"
)
target_compile_options(libdng_sdk PRIVATE
    "-DqDNGBigEndian=0"
    "-DqDNGThreadSafe=1"
    "-DqDNGUseLibJPEG=1"
    "-DqDNGUseXMP=1"
    "-DqDNGValidateTarget=1"
    "-DqDNGUsingSanitizer=1"
    "-DqUltraHighResolution=1"
    "-DqDNGValidate=0"
    "-DqLinux=1"
    "-DUNIX_ENV=1"
    "-fsanitize=signed-integer-overflow,unsigned-integer-overflow"
    "-fno-sanitize-link-runtime"
    "-Wno-reorder"
    "-Wno-ignored-qualifiers"
    "-Wno-implicit-fallthrough"
)
target_compile_options(libdng_sdk PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-fexceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-frtti>
)
target_link_libraries(libdng_sdk PUBLIC
    libcompiler_rt-extras
    xmp_toolkit_sdk
    libjxl
    libjpeg
    libz
    libexpat
)

add_library(libfft2d STATIC
    "${AOSP_SRC}/external/fft2d/src/fft2d/fft2d/fftsg.c"
    "${AOSP_SRC}/external/fft2d/src/fft2d/fft2d/fftsg2d.c"
    "${AOSP_SRC}/external/fft2d/src/fft2d/fft2d/alloc.c"
    "${AOSP_SRC}/external/fft2d/src/fft2d/fft2d/shrtdct.c"
)
target_include_directories(libfft2d PUBLIC
    "${AOSP_SRC}/external/fft2d/src/fft2d"
)

add_library(libruy_static STATIC
    "${AOSP_SRC}/external/ruy/ruy/allocator.cc"
    "${AOSP_SRC}/external/ruy/ruy/apply_multiplier.cc"
    "${AOSP_SRC}/external/ruy/ruy/block_map.cc"
    "${AOSP_SRC}/external/ruy/ruy/blocking_counter.cc"
    "${AOSP_SRC}/external/ruy/ruy/context.cc"
    "${AOSP_SRC}/external/ruy/ruy/context_get_ctx.cc"
    "${AOSP_SRC}/external/ruy/ruy/cpuinfo.cc"
    "${AOSP_SRC}/external/ruy/ruy/ctx.cc"
    "${AOSP_SRC}/external/ruy/ruy/denormal.cc"
    "${AOSP_SRC}/external/ruy/ruy/frontend.cc"
    "${AOSP_SRC}/external/ruy/ruy/have_built_path_for_avx.cc"
    "${AOSP_SRC}/external/ruy/ruy/have_built_path_for_avx2_fma.cc"
    "${AOSP_SRC}/external/ruy/ruy/have_built_path_for_avx512.cc"
    "${AOSP_SRC}/external/ruy/ruy/kernel_arm32.cc"
    "${AOSP_SRC}/external/ruy/ruy/kernel_arm64.cc"
    "${AOSP_SRC}/external/ruy/ruy/kernel_avx.cc"
    "${AOSP_SRC}/external/ruy/ruy/kernel_avx2_fma.cc"
    "${AOSP_SRC}/external/ruy/ruy/kernel_avx512.cc"
    "${AOSP_SRC}/external/ruy/ruy/pack_arm.cc"
    "${AOSP_SRC}/external/ruy/ruy/pack_avx.cc"
    "${AOSP_SRC}/external/ruy/ruy/pack_avx2_fma.cc"
    "${AOSP_SRC}/external/ruy/ruy/pack_avx512.cc"
    "${AOSP_SRC}/external/ruy/ruy/prepacked_cache.cc"
    "${AOSP_SRC}/external/ruy/ruy/prepare_packed_matrices.cc"
    "${AOSP_SRC}/external/ruy/ruy/system_aligned_alloc.cc"
    "${AOSP_SRC}/external/ruy/ruy/thread_pool.cc"
    "${AOSP_SRC}/external/ruy/ruy/trmul.cc"
    "${AOSP_SRC}/external/ruy/ruy/tune.cc"
    "${AOSP_SRC}/external/ruy/ruy/wait.cc"
)
target_include_directories(libruy_static PUBLIC
    "${AOSP_SRC}/external/ruy"
)
target_compile_options(libruy_static PRIVATE
    "-Wno-inline-asm"
)

add_library(libtextclassifier_hash_static STATIC
    "${AOSP_SRC}/external/libtextclassifier/native/utils/hash/farmhash.cc"
)
target_include_directories(libtextclassifier_hash_static PUBLIC
    "${AOSP_SRC}/external/libtextclassifier/native"
)
target_compile_options(libtextclassifier_hash_static PRIVATE
    "-DNAMESPACE_FOR_HASH_FUNCTIONS=farmhash"
)

add_library(libregex_re2 STATIC
    "${AOSP_SRC}/external/regex-re2/util/rune.cc"
    "${AOSP_SRC}/external/regex-re2/util/strutil.cc"
    "${AOSP_SRC}/external/regex-re2/re2/bitmap256.cc"
    "${AOSP_SRC}/external/regex-re2/re2/bitstate.cc"
    "${AOSP_SRC}/external/regex-re2/re2/compile.cc"
    "${AOSP_SRC}/external/regex-re2/re2/dfa.cc"
    "${AOSP_SRC}/external/regex-re2/re2/filtered_re2.cc"
    "${AOSP_SRC}/external/regex-re2/re2/mimics_pcre.cc"
    "${AOSP_SRC}/external/regex-re2/re2/nfa.cc"
    "${AOSP_SRC}/external/regex-re2/re2/onepass.cc"
    "${AOSP_SRC}/external/regex-re2/re2/parse.cc"
    "${AOSP_SRC}/external/regex-re2/re2/perl_groups.cc"
    "${AOSP_SRC}/external/regex-re2/re2/prefilter.cc"
    "${AOSP_SRC}/external/regex-re2/re2/prefilter_tree.cc"
    "${AOSP_SRC}/external/regex-re2/re2/prog.cc"
    "${AOSP_SRC}/external/regex-re2/re2/re2.cc"
    "${AOSP_SRC}/external/regex-re2/re2/regexp.cc"
    "${AOSP_SRC}/external/regex-re2/re2/set.cc"
    "${AOSP_SRC}/external/regex-re2/re2/simplify.cc"
    "${AOSP_SRC}/external/regex-re2/re2/tostring.cc"
    "${AOSP_SRC}/external/regex-re2/re2/unicode_casefold.cc"
    "${AOSP_SRC}/external/regex-re2/re2/unicode_groups.cc"
)
target_include_directories(libregex_re2 PUBLIC
    "${AOSP_SRC}/external/regex-re2"
)
target_link_libraries(libregex_re2 PUBLIC
    absl::strings
    absl::flat_hash_map
    absl::flat_hash_set
    absl::synchronization
    absl::optional
)

add_library(libtflite_static STATIC
    "${AOSP_SRC}/external/tensorflow/tensorflow/tsl/platform/default/logging.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/tsl/platform/default/env_time.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/allocation.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/arena_planner.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/c/common.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/c/c_api.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/c/c_api_experimental.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/c/c_api_opaque.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/api/error_reporter.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/api/flatbuffer_conversions.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/api/op_resolver.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/api/tensor_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/shims/jni/jni_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/core/subgraph.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/create_op_resolver_with_builtin_ops.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/delegates/interpreter_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/delegates/nnapi/nnapi_delegate.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/delegates/nnapi/quant_lstm_sup.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/delegates/serialization.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/delegates/utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/experimental/resource/initialization_status.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/experimental/resource/resource_variable.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/experimental/resource/static_hashtable.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/external_cpu_backend_context.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/graph_info.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/interpreter.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/interpreter_builder.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/interpreter_experimental.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/activations.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/add.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/add_n.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/arg_min_max.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/atan2.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/assign_variable.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/basic_rnn.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/batch_matmul.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/batch_to_space_nd.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/bidirectional_sequence_lstm.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/bidirectional_sequence_rnn.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/broadcast_args.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/broadcast_to.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/bucketize.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/call_once.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/cast.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/ceil.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/comparisons.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/complex_support.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/concatenation.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/conv.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/conv3d.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/conv3d_transpose.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/cpu_backend_context.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/cpu_backend_gemm_eigen.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/cumsum.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/densify.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/depth_to_space.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/depthwise_conv.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/dequantize.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/div.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/dynamic_update_slice.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/eigen_support.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/elementwise.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/embedding_lookup.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/embedding_lookup_sparse.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/exp.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/expand_dims.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/fake_quant.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/fill.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/floor.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/floor_div.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/floor_mod.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/fully_connected.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/gather.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/gather_nd.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/hashtable.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/hashtable_find.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/hashtable_import.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/hashtable_lookup.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/hashtable_size.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/if.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/kernel_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/optimized/cpu_check.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/optimized/neon_tensor_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/optimized/sse_tensor_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/quantization_util.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/reference/portable_tensor_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/tensor_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/transpose_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/internal/utils/sparsity_format_converter.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/kernel_util.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/l2norm.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/local_response_norm.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/logical.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/lsh_projection.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/lstm.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/lstm_eval.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/matrix_diag.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/matrix_set_diag.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/maximum_minimum.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/mirror_pad.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/mul.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/neg.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/non_max_suppression.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/one_hot.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/pack.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/pad.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/pooling.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/pow.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/quantize.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/random_ops.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/random_uniform_custom.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/range.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/rank.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/read_variable.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/reduce.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/register.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/register_ref.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/reshape.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/resize_bilinear.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/resize_nearest_neighbor.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/reverse.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/reverse_sequence.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/rfft2d.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/round.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/scatter_nd.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/segment_sum.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/select.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/shape.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/sign.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/skip_gram.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/slice.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/space_to_batch_nd.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/space_to_depth.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/sparse_to_dense.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/split.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/split_v.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/squared_difference.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/squeeze.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/strided_slice.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/sub.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/svdf.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/tile.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/topk_v2.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/transpose.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/transpose_conv.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/unidirectional_sequence_lstm.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/unidirectional_sequence_rnn.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/unique.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/unpack.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/unsorted_segment.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/var_handle.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/where.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/while.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/kernels/zeros_like.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/minimal_logging.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/minimal_logging_android.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/mmap_allocation.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/model_builder.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/mutable_op_resolver.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/nnapi/nnapi_implementation.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/nnapi/nnapi_util.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/nnapi/sl/SupportLibrary.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/npu_feature.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/optional_debug_tools.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/profiling/atrace_profiler.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/profiling/platform_profiler.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/profiling/root_profiler.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/schema/schema_conversion_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/schema/schema_utils.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/signature_runner.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/simple_memory_arena.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/simple_planner.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/stderr_reporter.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/string_util.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tflite_with_xnnpack_optional.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tools/delegates/delegate_provider.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tools/tool_params.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tools/verifier_internal.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tools/versioning/op_signature.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/tools/versioning/op_version.cc"
    "${AOSP_SRC}/external/tensorflow/tensorflow/lite/util.cc"
)
target_include_directories(libtflite_static PUBLIC
    "${AOSP_SRC}/external/tensorflow"
    "${GEN_DIR}/flatc/include"
)
target_include_directories(libtflite_static PRIVATE
    "${AOSP_SRC}/external/FP16/include"
    "${AOSP_SRC}/external/eigen"
    "${AOSP_SRC}/external/flatbuffers/include"
    "${AOSP_SRC}/external/gemmlowp"
    "${AOSP_SRC}/external/ruy"
    "${AOSP_SRC}/external/libtextclassifier/native"
    "${AOSP_SRC}/libnativehelper/include_jni"
    "${AOSP_SRC}/system/logging/liblog/include"
    "${AOSP_SRC}/system/libbase/include"
)
target_compile_options(libtflite_static PRIVATE
    "-DNAMESPACE_FOR_HASH_FUNCTIONS=farmhash"
    "-DTF_LITE_DISABLE_X86_NEON"
    "-Wno-user-defined-warnings"
)
target_link_libraries(libtflite_static PUBLIC
    libfft2d
    libregex_re2
    libruy_static
    libtextclassifier_hash_static
)
