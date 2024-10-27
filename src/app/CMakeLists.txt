project(app-static)

# file(
# GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
# "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
# "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
# )

# list(REMOVE_ITEM SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/webgpu_impl.cpp")
# print_target_properties(dawn_public_config)
add_library(${PROJECT_NAME} STATIC
    application.hpp
    application.cpp
)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(${PROJECT_NAME} PROPERTIES ${SHARED_PROPERTIES})
target_link_libraries(${PROJECT_NAME} PUBLIC webgpu-aware sdl2webgpu)

# target_precompile_headers(${PROJECT_NAME} REUSE_FROM webgpu-aware)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    RESOURCE_DIR="${CMAKE_SOURCE_DIR}/resources"
)
