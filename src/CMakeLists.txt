
add_subdirectory(webgpu)
target_include_directories(webgpu-aware PUBLIC .)

add_subdirectory(app)
target_include_directories(app-static PUBLIC .)