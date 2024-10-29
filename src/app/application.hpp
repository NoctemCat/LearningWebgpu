#pragma once

// #include "webgpu_impl.hpp"

#include "utils/print_format.hpp"
// #define WEBGPU_CPP_IMPLEMENTATION
#include <webgpu/webgpu.hpp>

#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
// #include <emscripten/html5.h>
#else
// #include <webgpu/webgpu_glfw.h>
#endif

#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>

namespace ninelives {

class Application {
public:
    Application() = default;
    bool initialize();
    void terminate();
    void mainLoop();

    bool isRunning() { return !shouldClose; }

private:
    wgpu::Instance instance = nullptr;
    wgpu::Device device = nullptr;
    wgpu::Queue queue = nullptr;
    SDL_Window *window = nullptr;
    wgpu::Surface surface = nullptr;
    bool shouldClose = false;

    wgpu::Buffer pointBuffer = nullptr;
    wgpu::Buffer indexBuffer = nullptr;
    uint32_t indexCount;

    wgpu::RenderPipeline pipeline = nullptr;
    wgpu::TextureFormat surfaceFormat = wgpu::TextureFormat::Undefined;

    wgpu::RequiredLimits getRequiredLimits(wgpu::Adapter adapter) const;
    wgpu::TextureView getNextSurfaceTextureView();
    void initializePipeline();
    void initializeBuffers();
    void pollSDLEvents();
    void playingWithBuffers();

#if defined(__EMSCRIPTEN__)
    std::unique_ptr<wgpu::ErrorCallback> errCallbackPtr;
    std::unique_ptr<wgpu::QueueWorkDoneCallback> errDoneCallbackPtr;
#endif
};

} // namespace ninelives
