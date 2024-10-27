
if(COMPILER_MSVC)
    file(REMOVE "${CMAKE_SOURCE_DIR}/build/compile_commands.json")
else(COMPILER_MSVC)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")
    file(CREATE_LINK
        "${CMAKE_BINARY_DIR}/compile_commands.json"
        "${CMAKE_SOURCE_DIR}/build/compile_commands.json"
        SYMBOLIC
    )
endif(COMPILER_MSVC)