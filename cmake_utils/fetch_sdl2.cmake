add_library(SDL2-aware INTERFACE)

if(NOT EMSCRIPTEN)
    # set(BUILD_SHARED_LIBS_SAVE ${BUILD_SHARED_LIBS})
    # set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

    # FetchContent_Declare(
    # SDL2
    # GIT_REPOSITORY https://github.com/libsdl-org/SDL
    # GIT_TAG release-2.30.8
    # GIT_PROGRESS TRUE
    # )

    # FetchContent_Declare(
    # SDL2_IMAGE
    # GIT_REPOSITORY https://github.com/libsdl-org/SDL_image
    # GIT_TAG release-2.8.2
    # GIT_PROGRESS TRUE
    # )

    # FetchContent_MakeAvailable(SDL2 SDL2_IMAGE)
    # target_link_libraries(SDL2-aware
    # INTERFACE SDL2::SDL2
    # INTERFACE SDL2_image::SDL2_image
    # )

    # # target_link_libraries(SDL2-aware INTERFACE SDL2::SDL2-static SDL2_image::SDL2_image-static)
    # set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_SAVE} CACHE BOOL "" FORCE)
    # unset(BUILD_SHARED_LIBS_SAVE)
    BundleContent_Declare(SDL2 BUNDLE_TARGET SDL2::SDL2
        GIT_REPOSITORY https://github.com/libsdl-org/SDL
        GIT_TAG release-2.30.8
        GIT_PROGRESS TRUE

        CMAKE_ARGS -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DBUILD_SHARED_LIBS=ON
        CMAKE_ARGS_DEBUG -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL
        CMAKE_ARGS_RELEASE -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL
    )

    BundleContent_Declare(SDL2_IMAGE BUNDLE_TARGET SDL2_image::SDL2_image
        GIT_REPOSITORY https://github.com/libsdl-org/SDL_image
        GIT_TAG release-2.8.2
        GIT_PROGRESS TRUE

        CMAKE_ARGS -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DBUILD_SHARED_LIBS=ON
        CMAKE_ARGS_DEBUG -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDebugDLL
        CMAKE_ARGS_RELEASE -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL
    )

    BundleContent_MakeAvailable(SDL2 SDL2_IMAGE)

    target_link_libraries(SDL2-aware INTERFACE
        SDL2::SDL2
        SDL2_image::SDL2_image
    )

# BundleContent_MakeAvailable(SDL2_IMAGE)
# print_target_properties(DEPS_SDL2_image)
# message(FATAL_ERROR "errr")
else(NOT EMSCRIPTEN)
    target_link_options(SDL2-aware INTERFACE
        --use-port=sdl2
        --use-port=sdl2_image
    )
endif(NOT EMSCRIPTEN)
