
if(EMSCRIPTEN)
    set(WEBGPU_CPP_TAG "emscripten-v3.1.61")
    FetchContent_Declare(
        webgpu
        GIT_REPOSITORY https://github.com/eliemichel/WebGPU-distribution
        GIT_TAG ${WEBGPU_CPP_TAG}
        GIT_PROGRESS TRUE
    )
    FetchContent_MakeAvailable(webgpu)

# if(NOT EXISTS "${CMAKE_SOURCE_DIR}/third_party/webgpu-emscripten")
# message(NOTICE "WebGPU sources not found")
# message(NOTICE "Downloading git repository...")

# file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/third_party/webgpu-emscripten")
# execute_process(
# COMMAND git clone --depth 1 --branch ${WEBGPU_CPP_TAG} --progress https://github.com/eliemichel/WebGPU-distribution .
# WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/third_party/webgpu-emscripten"
# COMMAND_ERROR_IS_FATAL ANY
# )
# endif()
else(EMSCRIPTEN)
    # if(IS_DIRECTORY "D:/Projects/WebGPU/minimal/bundler/webgpu-bundle/install/Visual_Studio_17_2022_/include/dawn-src/docs")
    # message(NOTICE "Yep is dir")
    # endif()

    # message(FATAL_ERROR "ss")
    BundleContent_Declare(webgpu-bundle BUNDLE_TARGET webgpu
        SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/webgpu-dawn"

        CMAKE_ARGS
        -DCMAKE_POLICY_DEFAULT_CMP0091=NEW

        CMAKE_ARGS_DEBUG -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL
        CMAKE_ARGS_RELEASE -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL
    )
    BundleContent_MakeAvailable(webgpu-bundle)

    # print_target_properties(webgpu-bundle)

    # get_target_property(webgpuStaticFile webgpu LOCATION_DEBUG)
    # get_target_property(webgpuIsImported webgpu IMPORTED)
    # file(SIZE "${webgpuStaticFile}" webgpuStaticSize)
    # math(EXPR webgpuStaticSize "${webgpuStaticSize} / 1024 / 1024 / 8")
    # message(NOTICE "webgpu imported: ${webgpuIsImported}")
    # message(NOTICE "webgpu imported locations: ${IMPORTED_LOCATION}")
    # message(NOTICE "webgpu static bundle size: ${webgpuStaticSize}")

    # message(FATAL_ERROR "Arghh")

    # FetchContent_Declare(
    # webgpu
    # GIT_REPOSITORY https://github.com/eliemichel/WebGPU-distribution
    # GIT_TAG ${WEBGPU_CPP_TAG}
    # GIT_PROGRESS TRUE
    # )
    # FetchContent_MakeAvailable(webgpu)
    # target_include_directories(dawn_utils PUBLIC "${FETCHCONTENT_BASE_DIR}/dawn-src/src")

    # target_link_libraries(webgpu INTERFACE dawn_public_config)

    # bundle_static_library(webgpu_dawn webgpu_bundle)
    # target_include_directories(webgpu_bundle INTERFACE
    # "${FETCHCONTENT_BASE_DIR}/webgpu-src/include"
    # "${FETCHCONTENT_BASE_DIR}/dawn-src/include"
    # )

    # # This is used to advertise the flavor of WebGPU that this zip provides
    # target_compile_definitions(webgpu_bundle INTERFACE WEBGPU_BACKEND_DAWN)

    # -----------------------------------------
    # Commenting it out, now that it is modified. Still leaving it here, maybe it will be useeful
    # set(WebGPU_CPP_Dawn_Dir "${CMAKE_SOURCE_DIR}/third_party/webgpu-dawn")

    # if(NOT EXISTS "${WebGPU_CPP_Dawn_Dir}")
    # message(NOTICE "WebGPU-CPP sources not found")
    # message(NOTICE "Downloading git repository...")

    # file(MAKE_DIRECTORY "${WebGPU_CPP_Dawn_Dir}")
    # execute_process(
    # COMMAND git clone --depth 1 --branch ${WEBGPU_CPP_TAG} --progress https://github.com/eliemichel/WebGPU-distribution .
    # WORKING_DIRECTORY "${WebGPU_CPP_Dawn_Dir}"
    # COMMAND_ERROR_IS_FATAL ANY
    # )
    # endif()
    # -----------------------------------------
endif(EMSCRIPTEN)
