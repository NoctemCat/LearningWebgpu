# From https://izzys.casa/2023/09/finding-msvc-with-cmake/
# with some modifications
cmake_minimum_required(VERSION 3.25)

include_guard(GLOBAL)

set(MSVC 1 CACHE INTERNAL "Using MSVC")

if(NOT(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows"))
    set(CMAKE_SYSTEM_NAME "Windows" CACHE INTERNAL "")
endif()

# set(CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
# IZ_MSVC_LINE_VERSION
# IZ_MSVC_EDITION)
if(NOT CMAKE_GENERATOR MATCHES "^Visual Studio")
    if(NOT DEFINED CMAKE_SYSTEM_PROCESSOR)
        set(CMAKE_SYSTEM_PROCESSOR "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    endif()

    if(NOT DEFINED CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE)
        set(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE "x86")

        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64")
            set(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE "x64")
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ARM64")
            set(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE "arm64")
        endif()
    endif()

    if(NOT DEFINED CMAKE_VS_PLATFORM_NAME)
        set(CMAKE_VS_PLATFORM_NAME "x86")

        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
            set(CMAKE_VS_PLATFORM_NAME "x64")
        elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
            set(CMAKE_VS_PLATFORM_NAME "arm64")
        endif()
    endif()
endif()

block(SCOPE_FOR VARIABLES)

# cmake_path(
# CONVERT "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
# TO_CMAKE_PATH_LIST vswhere.dir1
# NORMALIZE)
# cmake_path(
# CONVERT "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio Installer"
# TO_CMAKE_PATH_LIST vswhere.dir2
# NORMALIZE)

# set(vswherePaths "${vswhere.dir1}" "${vswhere.dir2}")
# list(APPEND CMAKE_PROGRAM_PATH ${vswherePaths})
# find_program(VSWHERE_EXECUTABLE NAMES vswhere DOC "Visual Studio Locator" REQUIRED)
# endblock()

# if(DEFINED IZ_MSVC_EDITION)
# set(product "Microsoft.VisualStudio.Product.${IZ_MSVC_EDITION}")
# else()
# set(product "*")
# endif()

# message(CHECK_START "Searching for Visual Studio ${IZ_MSVC_EDITION}")
# execute_process(COMMAND "${VSWHERE_EXECUTABLE}" -nologo -nocolor
# -format json
# -products "${product}"
# -utf8
# -sort
# ENCODING UTF-8
# OUTPUT_VARIABLE candidates
# OUTPUT_STRIP_TRAILING_WHITESPACE)
# string(JSON candidates.length LENGTH "${candidates}")
# string(JOIN " " error "Could not find Visual Studio"
# "${IZ_MSVC_LINE_VERSION}"
# "${IZ_MSVC_EDITION}")

# if(candidates.length EQUAL 0)
# message(CHECK_FAIL "no products")

# # You can choose to either hard fail here, or continue
# message(FATAL_ERROR "${error}")
# endif()

# block(SCOPE_FOR VARIABLES)

# if(NOT DEFINED MSVC_INSTALL_PATH)
# if(NOT IZ_MSVC_LINE_VERSION)
# string(JSON candidate.install.path GET "${candidates}" 0 "installationPath")
# else()
# # Unfortunately, range operations are inclusive in CMake for god knows why
# math(EXPR stop "${candidates.length} - 1")

# foreach(idx RANGE 0 ${stop})
# string(JSON LineVersion GET "${candidates}" ${idx} "catalog" "productLineVersion")

# if(LineVersion VERSION_EQUAL IZ_MSVC_LINE_VERSION)
# string(JSON candidate.install.path
# GET "${candidates}" ${idx} "installationPath")
# break()
# endif()
# endforeach()
# endif()

# if(NOT candidate.install.path)
# message(CHECK_FAIL "no install path found")
# message(FATAL_ERROR "${error}")
# endif()

# cmake_path(
# CONVERT "${candidate.install.path}"
# TO_CMAKE_PATH_LIST candidate.install.path
# NORMALIZE)
# message(CHECK_PASS "found: ${candidate.install.path}")
# set(MSVC_INSTALL_PATH "${candidate.install.path}" CACHE INTERNAL "Visual Studio Installation Path")
# endif()

# endblock()

# if(NOT DEFINED CMAKE_VS_PLATFORM_TOOLSET_VERSION)
# message(CHECK_START "MSVS_TOOLSET is not set, reading default version from Microsoft.VCToolsVersion.default.txt")
# file(READ "${MSVC_INSTALL_PATH}/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt" DefaultVersion)
# string(STRIP "${DefaultVersion}" DefaultVersion)

# if("${DefaultVersion}" STREQUAL "")
# message(CHECK_FAIL "file ${MSVC_INSTALL_PATH}/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt not found or empty")
# else()
# set(CMAKE_VS_PLATFORM_TOOLSET_VERSION "${DefaultVersion}" CACHE INTERNAL "VC++ Compiler Toolset")
# message(CHECK_PASS "Version: ${CMAKE_VS_PLATFORM_TOOLSET_VERSION}")
# endif()
# endif()

# if(NOT DEFINED CMAKE_WINDOWS_KITS_10_DIR)
# message(CHECK_START "Searching for Windows SDK Root Directory")
# cmake_host_system_information(RESULT CMAKE_WINDOWS_KITS_10_DIR QUERY
# WINDOWS_REGISTRY "HKLM/SOFTWARE/Microsoft/Windows Kits/Installed Roots"
# VALUE "KitsRoot10"
# VIEW BOTH
# ERROR_VARIABLE error
# )

# if(error)
# message(CHECK_FAIL "not found: ${error}")
# else()
# cmake_path(CONVERT "${CMAKE_WINDOWS_KITS_10_DIR}"
# TO_CMAKE_PATH_LIST CMAKE_WINDOWS_KITS_10_DIR
# NORMALIZE)
# message(CHECK_PASS "found: ${CMAKE_WINDOWS_KITS_10_DIR}")
# set(CMAKE_WINDOWS_KITS_10_DIR ${CMAKE_WINDOWS_KITS_10_DIR} CACHE INTERNAL "Windows SDK Root Directory")
# endif()
# endif()

# if(NOT DEFINED CMAKE_SYSTEM_VERSION)
# message(CHECK_START "CMAKE_SYSTEM_VERSION not set, selecting the latest SDK")
# file(GLOB IncludedSDKsFullPath "${CMAKE_WINDOWS_KITS_10_DIR}/Include/*")
# set(IncludedSDKs "")

# foreach(SDKPath IN LISTS IncludedSDKsFullPath)
# cmake_path(GET SDKPath FILENAME SDKPathFilename)
# list(APPEND IncludedSDKs "${SDKPathFilename}")
# endforeach()

# list(SORT IncludedSDKs COMPARE NATURAL ORDER DESCENDING)
# list(GET IncludedSDKs 0 LatestSDK)

# if("${LatestSDK}" STREQUAL "")
# message(CHECK_FAIL "directory ${CMAKE_WINDOWS_KITS_10_DIR}/Include/ is empty")
# else()
# set(CMAKE_SYSTEM_VERSION "${LatestSDK}" CACHE INTERNAL "Windows SDK version")
# message(CHECK_PASS "Windows SDK version: ${LatestSDK}")
# endif()
# endif()

# set(windows.sdk.host "Host${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}")
# set(windows.sdk.target "${CMAKE_VS_PLATFORM_NAME}")
# set(msvc.tools.dir "${MSVC_INSTALL_PATH}/VC/Tools/MSVC/${CMAKE_VS_PLATFORM_TOOLSET_VERSION}")

# block(SCOPE_FOR VARIABLES)
# list(APPEND CMAKE_PROGRAM_PATH
# "${msvc.tools.dir}/bin/${windows.sdk.host}/${windows.sdk.target}"
# "${CMAKE_WINDOWS_KITS_10_DIR}/bin/${CMAKE_SYSTEM_VERSION}/${windows.sdk.target}"
# "${CMAKE_WINDOWS_KITS_10_DIR}/bin"
# )
include(VSWhere.cmake)
findVisualStudio()
include(Windows.Kits.cmake)

set(msvc.tools.dir "${MSVC_INSTALL_PATH}/VC/Tools/MSVC/${CMAKE_VS_PLATFORM_TOOLSET_VERSION}")
message(NOTICE "nn ${MSVC_INSTALL_PATH}")

list(APPEND CMAKE_PROGRAM_PATH
    "${msvc.tools.dir}/bin/${windows.sdk.host}/${windows.sdk.target}"
    "${CMAKE_WINDOWS_KITS_10_DIR}/bin/${CMAKE_SYSTEM_VERSION}/${windows.sdk.target}"
    "${CMAKE_WINDOWS_KITS_10_DIR}/bin"
)

find_program(CMAKE_MASM_ASM_COMPILER NAMES ml64 ml DOC "MSVC ASM Compiler")
find_program(CMAKE_CXX_COMPILER NAMES cl REQUIRED DOC "MSVC C++ Compiler")
find_program(CMAKE_RC_COMPILER NAMES rc REQUIRED DOC "MSVC Resource Compiler")
find_program(CMAKE_C_COMPILER NAMES cl REQUIRED DOC "MSVC C Compiler")
find_program(CMAKE_LINKER NAMES link REQUIRED DOC "MSVC Linker")
find_program(CMAKE_AR NAMES lib REQUIRED DOC "MSVC Archiver")
find_program(CMAKE_MT NAMES mt REQUIRED DOC "MSVC Manifest Tool")

if(NOT DEFINED MSVC_VERSION)
    # Keep an eye, if for some reason you can't get cl version
    # should match "Microsoft (R) C/C++ Optimizing Compiler Version *.*.* for"
    # I can't imagine why it ouput it in error
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}"
        ENCODING UTF-8

        # OUTPUT_VARIABLE ClHelp
        # RESULT_VARIABLE ClRes
        ERROR_VARIABLE ClErr
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(REGEX MATCH "Compiler Version (.+) for" _ "${ClErr}")
    string(REPLACE "." "" Version "${CMAKE_MATCH_1}")
    string(SUBSTRING "${Version}" 0 4 Version)
    set(MSVC_VERSION ${Version} CACHE INTERNAL "MSVC C/C++ Compiler Version")
endif()

endblock()

# set(includes ucrt shared um winrt cppwinrt)
# set(libs ucrt um)

# list(TRANSFORM includes PREPEND "${CMAKE_WINDOWS_KITS_10_DIR}/Include/${CMAKE_SYSTEM_VERSION}/")
# list(TRANSFORM lib PREPEND "${CMAKE_WINDOWS_KITS_10_DIR}/Lib/${CMAKE_SYSTEM_VERSION}/")
# list(TRANSFORM lib APPEND "/${windows.sdk.target}")

# # We could technically set `CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES` and others,
# # but not for the library paths.
# include_directories(BEFORE SYSTEM "${msvc.tools.dir}/include" ${includes})
# link_directories(BEFORE "${msvc.tools.dir}/lib/${windows.sdk.target}" ${lib})

# kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib