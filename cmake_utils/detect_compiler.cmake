
if("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
    set(COMPILER_CLANG TRUE)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(COMPILER_GCC TRUE)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(COMPILER_INTEL TRUE)
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(COMPILER_MSVC TRUE)
endif()