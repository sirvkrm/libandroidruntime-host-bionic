cmake_minimum_required(VERSION 3.19)
project(host_codegen_tools C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(SRC "${ROOT}/src")
set(PROTOBUF_INST "${ROOT}/build/host-protobuf-inst")
set(ABSL_INST "${ROOT}/build/host-absl-inst")
set(PROTOC_BIN "${ROOT}/build/host-tools/bin/protoc")

list(PREPEND CMAKE_PREFIX_PATH "${ABSL_INST}" "${PROTOBUF_INST}")
find_package(absl REQUIRED)
find_package(Protobuf CONFIG REQUIRED)
find_package(BISON REQUIRED)
find_package(FLEX REQUIRED)
find_package(Threads REQUIRED)

# Common host fmtlib
add_library(host_fmt STATIC
    ${SRC}/external/fmtlib/src/format.cc
    ${SRC}/external/fmtlib/src/os.cc
)
target_include_directories(host_fmt PUBLIC ${SRC}/external/fmtlib/include)

# Common host liblog
add_library(host_liblog STATIC
    ${SRC}/system/logging/liblog/log_event_list.cpp
    ${SRC}/system/logging/liblog/log_event_write.cpp
    ${SRC}/system/logging/liblog/logger_name.cpp
    ${SRC}/system/logging/liblog/logger_read.cpp
    ${SRC}/system/logging/liblog/logger_write.cpp
    ${SRC}/system/logging/liblog/logprint.cpp
    ${SRC}/system/logging/liblog/properties.cpp
    ${SRC}/system/logging/liblog/event_tag_map.cpp
)
target_compile_definitions(host_liblog PRIVATE
    -DLIBLOG_LOG_TAG=1006
    -DSNET_EVENT_LOG_TAG=1397638484
    -DANDROID_DEBUGGABLE=0
    -DFAKE_LOG_DEVICE=1
)
target_include_directories(host_liblog PUBLIC
    ${SRC}/system/logging/liblog/include
    ${SRC}/system/core/libcutils/include
    ${SRC}/system/core/libutils/include
    ${SRC}/system/core/include
    ${SRC}/system/libbase/include
)

# Common host libbase
add_library(host_libbase STATIC
    ${SRC}/system/libbase/chrono_utils.cpp
    ${SRC}/system/libbase/cmsg.cpp
    ${SRC}/system/libbase/errors_unix.cpp
    ${SRC}/system/libbase/file.cpp
    ${SRC}/system/libbase/hex.cpp
    ${SRC}/system/libbase/logging.cpp
    ${SRC}/system/libbase/mapped_file.cpp
    ${SRC}/system/libbase/parsebool.cpp
    ${SRC}/system/libbase/parsenetaddress.cpp
    ${SRC}/system/libbase/posix_strerror_r.cpp
    ${SRC}/system/libbase/process.cpp
    ${SRC}/system/libbase/properties.cpp
    ${SRC}/system/libbase/result.cpp
    ${SRC}/system/libbase/stringprintf.cpp
    ${SRC}/system/libbase/strings.cpp
    ${SRC}/system/libbase/test_utils.cpp
    ${SRC}/system/libbase/threads.cpp
)
target_include_directories(host_libbase PUBLIC
    ${SRC}/system/libbase/include
    ${SRC}/external/fmtlib/include
)
target_link_libraries(host_libbase PUBLIC host_fmt host_liblog Threads::Threads)

# 1. Perfetto base + 3 protoc plugins (exact perfetto_src_base_base + perfetto_base_default_platform)
set(PERFETTO_BASE_SRCS
    ${SRC}/external/perfetto/src/base/default_platform.cc
    ${SRC}/external/perfetto/src/base/android_utils.cc
    ${SRC}/external/perfetto/src/base/base64.cc
    ${SRC}/external/perfetto/src/base/crash_keys.cc
    ${SRC}/external/perfetto/src/base/ctrl_c_handler.cc
    ${SRC}/external/perfetto/src/base/event_fd.cc
    ${SRC}/external/perfetto/src/base/file_utils.cc
    ${SRC}/external/perfetto/src/base/fixed_string_writer.cc
    ${SRC}/external/perfetto/src/base/getopt_compat.cc
    ${SRC}/external/perfetto/src/base/intrusive_list.cc
    ${SRC}/external/perfetto/src/base/intrusive_tree.cc
    ${SRC}/external/perfetto/src/base/lock_free_task_runner.cc
    ${SRC}/external/perfetto/src/base/logging.cc
    ${SRC}/external/perfetto/src/base/metatrace.cc
    ${SRC}/external/perfetto/src/base/paged_memory.cc
    ${SRC}/external/perfetto/src/base/periodic_task.cc
    ${SRC}/external/perfetto/src/base/pipe.cc
    ${SRC}/external/perfetto/src/base/rt_mutex.cc
    ${SRC}/external/perfetto/src/base/scoped_mmap.cc
    ${SRC}/external/perfetto/src/base/scoped_sched_boost.cc
    ${SRC}/external/perfetto/src/base/status.cc
    ${SRC}/external/perfetto/src/base/string_splitter.cc
    ${SRC}/external/perfetto/src/base/string_utils.cc
    ${SRC}/external/perfetto/src/base/string_view.cc
    ${SRC}/external/perfetto/src/base/string_view_splitter.cc
    ${SRC}/external/perfetto/src/base/subprocess.cc
    ${SRC}/external/perfetto/src/base/subprocess_posix.cc
    ${SRC}/external/perfetto/src/base/temp_file.cc
    ${SRC}/external/perfetto/src/base/thread_checker.cc
    ${SRC}/external/perfetto/src/base/thread_task_runner.cc
    ${SRC}/external/perfetto/src/base/thread_utils.cc
    ${SRC}/external/perfetto/src/base/time.cc
    ${SRC}/external/perfetto/src/base/unix_task_runner.cc
    ${SRC}/external/perfetto/src/base/utils.cc
    ${SRC}/external/perfetto/src/base/uuid.cc
    ${SRC}/external/perfetto/src/base/virtual_destructors.cc
    ${SRC}/external/perfetto/src/base/waitable_event.cc
    ${SRC}/external/perfetto/src/base/watchdog_posix.cc
    ${SRC}/external/perfetto/src/base/weak_runner.cc
)

add_library(host_perfetto_base STATIC ${PERFETTO_BASE_SRCS})
target_include_directories(host_perfetto_base PUBLIC
    ${SRC}/external/perfetto
    ${SRC}/external/perfetto/include
    ${SRC}/external/perfetto/include/perfetto/base/build_configs/android_tree
    ${SRC}/external/perfetto/src/profiling/memory/include
)
target_compile_definitions(host_perfetto_base PUBLIC
    -DGOOGLE_PROTOBUF_NO_RTTI
    -DGOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
)

foreach(pname cppgen_plugin protozero_plugin)
    add_executable(${pname}
        ${SRC}/external/perfetto/src/protozero/protoc_plugin/${pname}.cc
    )
    target_link_libraries(${pname} PRIVATE host_perfetto_base protobuf::libprotoc protobuf::libprotobuf Threads::Threads)
endforeach()

add_executable(ipc_plugin
    ${SRC}/external/perfetto/src/ipc/protoc_plugin/ipc_plugin.cc
)
target_link_libraries(ipc_plugin PRIVATE host_perfetto_base protobuf::libprotoc protobuf::libprotobuf Threads::Threads)

# 2. AIDL host compiler
set(AIDL_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/aidl_gen")
file(MAKE_DIRECTORY "${AIDL_GEN_DIR}")
add_custom_command(
    OUTPUT ${AIDL_GEN_DIR}/aidl_language_y.cpp ${AIDL_GEN_DIR}/aidl_language_y.h ${AIDL_GEN_DIR}/location.hh ${AIDL_GEN_DIR}/position.hh
    COMMAND ${BISON_EXECUTABLE} -d --defines=${AIDL_GEN_DIR}/aidl_language_y.h -o ${AIDL_GEN_DIR}/aidl_language_y.cpp ${SRC}/system/tools/aidl/aidl_language_y.yy
    DEPENDS ${SRC}/system/tools/aidl/aidl_language_y.yy
)
add_custom_command(
    OUTPUT ${AIDL_GEN_DIR}/aidl_language_l.cpp
    COMMAND ${FLEX_EXECUTABLE} -o ${AIDL_GEN_DIR}/aidl_language_l.cpp ${SRC}/system/tools/aidl/aidl_language_l.ll
    DEPENDS ${SRC}/system/tools/aidl/aidl_language_l.ll ${AIDL_GEN_DIR}/aidl_language_y.h
)

add_executable(aidl
    ${SRC}/system/tools/aidl/aidl_checkapi.cpp
    ${SRC}/system/tools/aidl/aidl_const_expressions.cpp
    ${SRC}/system/tools/aidl/aidl_dumpapi.cpp
    ${SRC}/system/tools/aidl/aidl_language.cpp
    ${SRC}/system/tools/aidl/aidl_to_common.cpp
    ${SRC}/system/tools/aidl/aidl_to_cpp_common.cpp
    ${SRC}/system/tools/aidl/aidl_to_cpp.cpp
    ${SRC}/system/tools/aidl/aidl_to_java.cpp
    ${SRC}/system/tools/aidl/aidl_to_ndk.cpp
    ${SRC}/system/tools/aidl/aidl_to_rust.cpp
    ${SRC}/system/tools/aidl/aidl_typenames.cpp
    ${SRC}/system/tools/aidl/aidl.cpp
    ${SRC}/system/tools/aidl/ast_java.cpp
    ${SRC}/system/tools/aidl/check_valid.cpp
    ${SRC}/system/tools/aidl/code_writer.cpp
    ${SRC}/system/tools/aidl/comments.cpp
    ${SRC}/system/tools/aidl/diagnostics.cpp
    ${SRC}/system/tools/aidl/generate_aidl_mappings.cpp
    ${SRC}/system/tools/aidl/generate_cpp.cpp
    ${SRC}/system/tools/aidl/generate_cpp_analyzer.cpp
    ${SRC}/system/tools/aidl/generate_java_binder.cpp
    ${SRC}/system/tools/aidl/generate_java.cpp
    ${SRC}/system/tools/aidl/generate_ndk.cpp
    ${SRC}/system/tools/aidl/generate_rust.cpp
    ${SRC}/system/tools/aidl/import_resolver.cpp
    ${SRC}/system/tools/aidl/io_delegate.cpp
    ${SRC}/system/tools/aidl/location.cpp
    ${SRC}/system/tools/aidl/logging.cpp
    ${SRC}/system/tools/aidl/options.cpp
    ${SRC}/system/tools/aidl/parser.cpp
    ${SRC}/system/tools/aidl/permission.cpp
    ${SRC}/system/tools/aidl/preprocess.cpp
    ${SRC}/system/tools/aidl/main.cpp
    ${AIDL_GEN_DIR}/aidl_language_y.cpp
    ${AIDL_GEN_DIR}/aidl_language_l.cpp
)
add_library(host_gtest STATIC
    ${SRC}/external/googletest/googletest/src/gtest-all.cc
)
target_include_directories(host_gtest PUBLIC
    ${SRC}/external/googletest/googletest/include
)
target_include_directories(host_gtest PRIVATE
    ${SRC}/external/googletest/googletest
)

target_include_directories(aidl PRIVATE
    ${SRC}/system/tools/aidl
    ${SRC}/system/tools/aidl/include
    ${AIDL_GEN_DIR}
)
target_compile_definitions(aidl PRIVATE -DPLATFORM_SDK_VERSION=36)
target_link_libraries(aidl PRIVATE host_libbase host_gtest)

# 3. sysprop_cpp
set(SYSPROP_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/sysprop_gen")
file(MAKE_DIRECTORY "${SYSPROP_GEN_DIR}")
add_custom_command(
    OUTPUT ${SYSPROP_GEN_DIR}/sysprop.pb.cc ${SYSPROP_GEN_DIR}/sysprop.pb.h
    COMMAND ${PROTOC_BIN} --cpp_out=${SYSPROP_GEN_DIR} -I ${SRC}/system/tools/sysprop ${SRC}/system/tools/sysprop/sysprop.proto
    DEPENDS ${SRC}/system/tools/sysprop/sysprop.proto
)
add_executable(sysprop_cpp
    ${SRC}/system/core/property_service/libpropertyinfoparser/property_info_parser.cpp
    ${SRC}/system/core/property_service/libpropertyinfoserializer/property_info_file.cpp
    ${SRC}/system/core/property_service/libpropertyinfoserializer/property_info_serializer.cpp
    ${SRC}/system/core/property_service/libpropertyinfoserializer/trie_builder.cpp
    ${SRC}/system/core/property_service/libpropertyinfoserializer/trie_serializer.cpp
    ${SRC}/system/tools/sysprop/Common.cpp
    ${SRC}/system/tools/sysprop/CodeWriter.cpp
    ${SRC}/system/tools/sysprop/CppGen.cpp
    ${SRC}/system/tools/sysprop/CppMain.cpp
    ${SYSPROP_GEN_DIR}/sysprop.pb.cc
)
target_include_directories(sysprop_cpp PRIVATE
    ${SRC}/system/tools/sysprop/include
    ${SRC}/system/tools/sysprop
    ${SRC}/system/core/property_service/libpropertyinfoparser/include
    ${SRC}/system/core/property_service/libpropertyinfoserializer/include
    ${SYSPROP_GEN_DIR}
)
target_compile_options(sysprop_cpp PRIVATE "SHELL:-include cstdint" "SHELL:-include algorithm" "SHELL:-include cstring")
target_link_libraries(sysprop_cpp PRIVATE host_libbase protobuf::libprotobuf)

# 4. hidl-gen
set(HIDL_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/hidl_gen")
file(MAKE_DIRECTORY "${HIDL_GEN_DIR}")
add_custom_command(
    OUTPUT ${HIDL_GEN_DIR}/hidl-gen_y.cpp ${HIDL_GEN_DIR}/hidl-gen_y.h ${HIDL_GEN_DIR}/location.hh ${HIDL_GEN_DIR}/position.hh
    COMMAND ${BISON_EXECUTABLE} -d --defines=${HIDL_GEN_DIR}/hidl-gen_y.h -o ${HIDL_GEN_DIR}/hidl-gen_y.cpp ${SRC}/system/tools/hidl/hidl-gen_y.yy
    DEPENDS ${SRC}/system/tools/hidl/hidl-gen_y.yy
)
add_custom_command(
    OUTPUT ${HIDL_GEN_DIR}/hidl-gen_l.cpp
    COMMAND ${FLEX_EXECUTABLE} -o ${HIDL_GEN_DIR}/hidl-gen_l.cpp ${SRC}/system/tools/hidl/hidl-gen_l.ll
    DEPENDS ${SRC}/system/tools/hidl/hidl-gen_l.ll ${HIDL_GEN_DIR}/hidl-gen_y.h
)

add_library(host_jsoncpp STATIC
    ${SRC}/external/jsoncpp/src/lib_json/json_reader.cpp
    ${SRC}/external/jsoncpp/src/lib_json/json_value.cpp
    ${SRC}/external/jsoncpp/src/lib_json/json_writer.cpp
)
target_include_directories(host_jsoncpp PUBLIC ${SRC}/external/jsoncpp/include)

add_executable(hidl-gen
    ${SRC}/system/tools/hidl/Annotation.cpp
    ${SRC}/system/tools/hidl/ArrayType.cpp
    ${SRC}/system/tools/hidl/CompoundType.cpp
    ${SRC}/system/tools/hidl/ConstantExpression.cpp
    ${SRC}/system/tools/hidl/DeathRecipientType.cpp
    ${SRC}/system/tools/hidl/DocComment.cpp
    ${SRC}/system/tools/hidl/EnumType.cpp
    ${SRC}/system/tools/hidl/FmqType.cpp
    ${SRC}/system/tools/hidl/HandleType.cpp
    ${SRC}/system/tools/hidl/HidlTypeAssertion.cpp
    ${SRC}/system/tools/hidl/Interface.cpp
    ${SRC}/system/tools/hidl/Location.cpp
    ${SRC}/system/tools/hidl/MemoryType.cpp
    ${SRC}/system/tools/hidl/Method.cpp
    ${SRC}/system/tools/hidl/NamedType.cpp
    ${SRC}/system/tools/hidl/PointerType.cpp
    ${SRC}/system/tools/hidl/ScalarType.cpp
    ${SRC}/system/tools/hidl/Scope.cpp
    ${SRC}/system/tools/hidl/StringType.cpp
    ${SRC}/system/tools/hidl/Type.cpp
    ${SRC}/system/tools/hidl/TypeDef.cpp
    ${SRC}/system/tools/hidl/VectorType.cpp
    ${SRC}/system/tools/hidl/AST.cpp
    ${SRC}/system/tools/hidl/Coordinator.cpp
    ${SRC}/system/tools/hidl/generateCpp.cpp
    ${SRC}/system/tools/hidl/generateCppImpl.cpp
    ${SRC}/system/tools/hidl/generateDependencies.cpp
    ${SRC}/system/tools/hidl/generateFormattedHidl.cpp
    ${SRC}/system/tools/hidl/generateInheritanceHierarchy.cpp
    ${SRC}/system/tools/hidl/generateJava.cpp
    ${SRC}/system/tools/hidl/generateJavaImpl.cpp
    ${SRC}/system/tools/hidl/generateVts.cpp
    ${SRC}/system/tools/hidl/hashing/Hash.cpp
    ${SRC}/system/tools/hidl/host_utils/Formatter.cpp
    ${SRC}/system/tools/hidl/host_utils/StringHelper.cpp
    ${SRC}/system/tools/hidl/utils/FQName.cpp
    ${SRC}/system/tools/hidl/utils/FqInstance.cpp
    ${SRC}/system/tools/hidl/main.cpp
    ${HIDL_GEN_DIR}/hidl-gen_y.cpp
    ${HIDL_GEN_DIR}/hidl-gen_l.cpp
)
target_include_directories(hidl-gen PRIVATE
    ${SRC}/system/tools/hidl
    ${SRC}/system/tools/hidl/hashing/include
    ${SRC}/system/tools/hidl/host_utils/include
    ${SRC}/system/tools/hidl/host_utils/include/hidl-util
    ${SRC}/system/tools/hidl/utils/include
    ${SRC}/system/tools/hidl/utils/include/hidl-util
    ${SRC}/system/libhwbinder/include
    ${SRC}/system/core/libutils/include
    ${HIDL_GEN_DIR}
)
target_compile_options(hidl-gen PRIVATE "SHELL:-include cstdint" "SHELL:-include algorithm" "SHELL:-include cstring")
target_link_libraries(hidl-gen PRIVATE host_libbase host_jsoncpp crypto)

# 5. flatc
file(GLOB FLATC_SRCS "${SRC}/external/flatbuffers/src/*.cpp")
list(REMOVE_ITEM FLATC_SRCS "${SRC}/external/flatbuffers/src/flathash.cpp")
file(GLOB FLATC_GRPC_SRCS "${SRC}/external/flatbuffers/grpc/src/compiler/*.cc")
add_executable(flatc
    ${SRC}/external/flatbuffers/include/codegen/python.cc
    ${FLATC_SRCS}
    ${FLATC_GRPC_SRCS}
)
target_include_directories(flatc PRIVATE
    ${SRC}/external/flatbuffers/grpc
    ${SRC}/external/flatbuffers/include
)
target_compile_options(flatc PRIVATE -fsigned-char -Wno-implicit-fallthrough)

# 6. stats-log-api-gen
set(STATS_PROTO_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/stats_proto_gen")
file(MAKE_DIRECTORY "${STATS_PROTO_GEN_DIR}")
file(GLOB_RECURSE STATS_MESSAGE_PROTOS "${SRC}/frameworks/proto_logging/stats/message/*.proto")
file(GLOB_RECURSE STATS_ENUM_PROTOS "${SRC}/frameworks/proto_logging/stats/enums/*.proto")
file(GLOB_RECURSE STATS_ATOM_PROTOS "${SRC}/frameworks/proto_logging/stats/atoms/*.proto")
set(STATS_PROTOS
    "${SRC}/frameworks/proto_logging/stats/atom_field_options.proto"
    "${SRC}/frameworks/proto_logging/stats/atoms.proto"
    "${SRC}/frameworks/proto_logging/stats/attribution_node.proto"
    ${STATS_MESSAGE_PROTOS}
    ${STATS_ENUM_PROTOS}
    ${STATS_ATOM_PROTOS}
)
list(REMOVE_DUPLICATES STATS_PROTOS)
set(STATS_PB_SRCS "")
set(STATS_PB_HDRS "")
foreach(PF ${STATS_PROTOS})
    file(RELATIVE_PATH REL_PF "${SRC}" "${PF}")
    string(REGEX REPLACE "\\.proto$" ".pb.cc" PB_CC "${STATS_PROTO_GEN_DIR}/${REL_PF}")
    string(REGEX REPLACE "\\.proto$" ".pb.h" PB_H "${STATS_PROTO_GEN_DIR}/${REL_PF}")
    list(APPEND STATS_PB_SRCS "${PB_CC}")
    list(APPEND STATS_PB_HDRS "${PB_H}")
endforeach()
add_custom_command(
    OUTPUT ${STATS_PB_SRCS} ${STATS_PB_HDRS}
    COMMAND ${PROTOC_BIN} --cpp_out=${STATS_PROTO_GEN_DIR} -I ${SRC} -I ${SRC}/external/protobuf/src ${STATS_PROTOS}
    DEPENDS ${STATS_PROTOS}
    COMMENT "Generating stats proto C++ files (${CMAKE_CURRENT_BINARY_DIR}/stats_proto_gen)"
)
add_library(host_stats_proto STATIC ${STATS_PB_SRCS})
target_include_directories(host_stats_proto PUBLIC ${STATS_PROTO_GEN_DIR})
target_link_libraries(host_stats_proto PUBLIC protobuf::libprotobuf)
target_compile_options(host_stats_proto PRIVATE -Wno-deprecated-declarations)

add_executable(stats-log-api-gen
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/Collation.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/settings_provider.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/utils.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/java_writer.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/java_writer_q.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/java_writer_vendor.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/main.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/native_writer.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/native_writer_vendor.cpp
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen/rust_writer.cpp
)
target_include_directories(stats-log-api-gen PRIVATE
    ${SRC}/frameworks/proto_logging/stats/stats_log_api_gen
    ${STATS_PROTO_GEN_DIR}
)
target_compile_definitions(stats-log-api-gen PRIVATE -DWITH_VENDOR)
target_compile_options(stats-log-api-gen PRIVATE -Wno-deprecated-declarations)
target_link_libraries(stats-log-api-gen PRIVATE host_stats_proto host_libbase protobuf::libprotobuf absl::strings)

install(TARGETS cppgen_plugin protozero_plugin ipc_plugin aidl sysprop_cpp hidl-gen flatc stats-log-api-gen
    RUNTIME DESTINATION ${ROOT}/build/host-tools/bin
)
