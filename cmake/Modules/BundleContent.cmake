# MIT License
#
# Copyright (c) 2024 NoctemCat
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

include_guard()

cmake_minimum_required(VERSION 3.25...3.30)

if(EXISTS "${CMAKE_SOURCE_DIR}/BundleContentBaseDir.txt")
    set(BUNDLECONTENT_BASE_DIR "${CMAKE_SOURCE_DIR}" CACHE INTERNAL "")
    file(READ "${CMAKE_SOURCE_DIR}/BundleContentBaseDir.txt" ModuleDir)
    set(BUNDLECONTENT_MODULE_DIR "${ModuleDir}" CACHE INTERNAL "")

elseif(NOT DEFINED BUNDLECONTENT_BASE_DIR)
    set(BUNDLECONTENT_BASE_DIR "${CMAKE_SOURCE_DIR}/bundler" CACHE INTERNAL "")
endif()

if(NOT DEFINED BUNDLECONTENT_MODULE_DIR)
    set(BUNDLECONTENT_MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")
endif()

include(${BUNDLECONTENT_MODULE_DIR}/BundleContent/BundleContent_Utils.cmake)

_set_if_undefined_cache(BUNDLECONTENT_CMAKE_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}" "Copy of the toolchain file location")
_set_if_undefined_cache(BUNDLECONTENT_DEPS_DIR "${BUNDLECONTENT_BASE_DIR}/_bundler_deps" "")
_set_if_undefined_cache(BUNDLECONTENT_INSTALL_DIR "install" "")

_set_if_undefined_cache(BUNDLECONTENT_BUILD_DIR "${CMAKE_BINARY_DIR}" "")
_set_if_undefined_cache(BUNDLECONTENT_KEY_SEPARATOR "_" "")
_set_if_undefined_cache(BUNDLECONTENT_SPACE_REPLACEMENT "_" "")
_set_if_undefined_cache(BUNDLECONTENT_DEFAULT_MAPPING "MinSizeRel;RelWithDebInfo;Release;Debug" "")
include(${BUNDLECONTENT_MODULE_DIR}/BundleContent/BundleContent_Impl.cmake)

if(NOT EXISTS "${BUNDLECONTENT_BASE_DIR}/CMakeLists.txt")
endif()

file(COPY "${BUNDLECONTENT_MODULE_DIR}/BundleContent/CMakeLists.txt"
    DESTINATION "${BUNDLECONTENT_BASE_DIR}"
)

if(NOT EXISTS "${BUNDLECONTENT_BASE_DIR}/BundleContentBaseDir.txt")
    file(WRITE "${BUNDLECONTENT_BASE_DIR}/BundleContentBaseDir.txt" "${BUNDLECONTENT_MODULE_DIR}")
endif()