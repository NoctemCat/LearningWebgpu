cmake_minimum_required(VERSION 3.25)

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# if(EMSCRIPTEN)
# set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
# set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-sSIDE_MODULE=1")
# set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS "-sSIDE_MODULE=1")

# set(CMAKE_STRIP FALSE)
# endif(EMSCRIPTEN)

# -----------------
# include(InstallRequiredSystemLibraries)
# -------------------
project(
    LearnWebGPU
    VERSION 0.1.0
    LANGUAGES CXX C
)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

include(FetchContent)
Set(FETCHCONTENT_QUIET FALSE)
include(BundleContent)

include(cmake_utils/execute_sequential.cmake)

# include(cmake_utils/bundle_static_library.cmake)
include(cmake_utils/print_target_properties.cmake)
include(cmake_utils/detect_compiler.cmake)
include(cmake_utils/symlink_compile_commands.cmake)
include(cmake_utils/fetch_webgpu.cmake)
include(cmake_utils/fetch_sdl2.cmake)

set(SHARED_PROPERTIES "")
set(EXE_LINK_LIBRARIES "")
set(COMPILE_OPTIONS "")

if(COMPILER_MSVC)
    list(APPEND COMPILE_OPTIONS /W4 /MP)
else(COMPILER_MSVC)
    list(APPEND COMPILE_OPTIONS -Wall -Wextra -pedantic)
endif(COMPILER_MSVC)

if(COMPILER_GCC)
    # std::print support
    list(APPEND EXE_LINK_LIBRARIES stdc++exp)
endif(COMPILER_GCC)

list(APPEND SHARED_PROPERTIES
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
    COMPILE_WARNING_AS_ERROR ON
)

if(XCODE)
    list(APPEND SHARED_PROPERTIES
        XCODE_GENERATE_SCHEME ON
        XCODE_SCHEME_ENABLE_GPU_FRAME_CAPTURE_MODE "Metal"
    )
endif(XCODE)

add_subdirectory(third_party/sdl2webgpu)
add_subdirectory(src)
list(APPEND EXE_LINK_LIBRARIES app-static)

add_executable(App src/main.cpp)

if(EMSCRIPTEN)
    set_target_properties(App PROPERTIES
        OUTPUT_NAME "index"
        SUFFIX ".html"
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/out
    )
    target_link_options(App PRIVATE
        --preload-file "${CMAKE_SOURCE_DIR}/resources"
        -sALLOW_MEMORY_GROWTH
        -g
        -gseparate-dwarf=out/temp.debug.wasm
    )
elseif(WIN32)
    add_custom_command(TARGET App POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_RUNTIME_DLLS:App> $<TARGET_FILE_DIR:App>
        COMMAND_EXPAND_LISTS
    )
endif()

set_target_properties(App PROPERTIES ${SHARED_PROPERTIES})
target_link_libraries(App PRIVATE ${EXE_LINK_LIBRARIES})
target_compile_options(App PRIVATE ${COMPILE_OPTIONS})