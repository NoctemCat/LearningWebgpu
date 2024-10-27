project(webgpu-static)

add_library(webgpu-impl STATIC webgpu_impl.cpp)
set_target_properties(webgpu-impl PROPERTIES ${SHARED_PROPERTIES})
target_link_libraries(webgpu-impl PUBLIC sdl2webgpu)

add_library(webgpu-aware STATIC
    webgpu_impl.hpp
    webgpu_utils.hpp
    webgpu_utils.cpp
    webgpu_utils_sep.cpp
)

set_target_properties(webgpu-aware PROPERTIES ${SHARED_PROPERTIES})
target_include_directories(webgpu-aware PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(webgpu-aware PUBLIC webgpu-impl)

# target_precompile_headers(webgpu-aware PUBLIC
# <webgpu/webgpu.h>
# <webgpu/webgpu.hpp>

# <iostream>
# <format>
# <print>
# <utils/template_formatters.hpp>
# <utils/formatters.hpp>
# <utils/print_format.hpp>
# )
if(EMSCRIPTEN)
    target_link_options(webgpu-aware
        PUBLIC -sASYNCIFY # Required by WebGPU-C++
    )
endif()