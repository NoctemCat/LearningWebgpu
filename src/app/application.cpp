
#include "application.hpp"
// #include "webgpu_impl.hpp"

#include "utils/address.hpp"
#include "webgpu_utils.hpp"

#include <array>
#include <sdl2webgpu.h>
#include <vector>

namespace ninelives {

// We embbed the source of the shader module here
const char *shaderSource = R"(

struct VertexInput {
    @location(0) position: vec2f,
    @location(1) color: vec3f,
};

struct VertexOutput {
    @builtin(position) position: vec4f,
    @location(0) color: vec3f,
};

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    let ratio = 640.0 / 480.0; 
	var out: VertexOutput;
    out.position = vec4f(in.position.x, in.position.y * ratio, 0.0, 1.0);
    out.color = in.color;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4f {
	return vec4f(in.color, 1.0);
}
)";

bool Application::initialize() {
    using namespace std;
    using namespace wgpu;

    InstanceDescriptor desc{};

#if defined(WEBGPU_BACKEND_DAWN)

    // Make sure the uncaptured error callback is called as soon as an error
    // occurs rather than at the next call to "wgpu::DeviceTick".
    DawnTogglesDescriptor toggles;
    toggles.chain.next = nullptr;
    toggles.chain.sType = SType::DawnTogglesDescriptor;
    toggles.disabledToggleCount = 0;
    toggles.enabledToggleCount = 1;
    const char *toggleName = "enable_immediate_error_handling";
    toggles.enabledToggles = &toggleName;

    desc.nextInChain = &toggles.chain;
#endif // WEBGPU_BACKEND_DAWN

#if not defined(__EMSCRIPTEN__)
    instance = createInstance(desc);
#else
    instance = wgpuCreateInstance(nullptr);
#endif

    if (!instance) {
        println(cerr, "Could not initialize WebGPU!");
        return false;
    }

    println("Initializing SDL...");
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        println(cerr, "Could not initialize SDL! Error: {}", SDL_GetError());
        return false;
    }

    int windowFlags{0};
    window = SDL_CreateWindow("Learn WebGPU", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, windowFlags);
    surface = SDL_GetWGPUSurface(instance, window);

    println("Requesting adapter...");
    RequestAdapterOptions adapterOptions{WGPURequestAdapterOptions{
        .compatibleSurface = surface,
    }};

    Adapter adapter = instance.requestAdapter(adapterOptions);
    println("Got adapter: {}", adapter);

    SupportedLimits supportedLimits{};
#if not defined(__EMSCRIPTEN__)

#if defined(WEBGPU_BACKEND_DAWN)
    bool success = adapter.getLimits(&supportedLimits) == Status::Success;
#else
    bool success = adapter.getLimits(&supportedLimits);
#endif

    if (success) {
        println("Adapter limits: ");
        println(" - maxTextureDimension1D: {}", supportedLimits.limits.maxTextureDimension1D);
        println(" - maxTextureDimension2D: {}", supportedLimits.limits.maxTextureDimension2D);
        println(" - maxTextureDimension3D: {}", supportedLimits.limits.maxTextureDimension3D);
        println(" - maxTextureArrayLayers: {}", supportedLimits.limits.maxTextureArrayLayers);
        println(" - maxVertexAttributes: {}", supportedLimits.limits.maxVertexAttributes);
        println(" - minStorageBufferOffsetAlignment: {}", supportedLimits.limits.minStorageBufferOffsetAlignment);
        println(" - minUniformBufferOffsetAlignment: {}", supportedLimits.limits.minUniformBufferOffsetAlignment);
    }
#else
    // Error in Chrome: Aborted(TODO: wgpuAdapterGetLimits unimplemented)
    // (as of September 4, 2023), so we hardcode values:
    // These work for 99.95% of clients (source: https://web3dsurvey.com/webgpu)
    supportedLimits.limits.minStorageBufferOffsetAlignment = 256;
    supportedLimits.limits.minUniformBufferOffsetAlignment = 256;
#endif
    vector<WGPUFeatureName> features{};

    size_t featuresCount = adapter.enumerateFeatures(nullptr);
    features.resize(featuresCount);
    adapter.enumerateFeatures(reinterpret_cast<FeatureName *>(features.data()));

    println("Adapter features: ");
    for (auto f : features) {
        println(" - {}", f);
    }

    WGPUAdapterInfo adapterInfo{};
    wgpuAdapterGetInfo(adapter, &adapterInfo);
    println("Adapter properties: ");
    println(" - vendorID: {}", adapterInfo.vendorID);
    println(" - vendor: {}", format_if_else("{}", "<nullptr>", adapterInfo.vendor));
    println(" - architecture: {}", format_if_else("{}", "<nullptr>", adapterInfo.architecture));
    println(" - deviceID: {}", adapterInfo.deviceID);
    println(" - device: {}", format_if_else("{}", "<nullptr>", adapterInfo.device));
    println(" - description: {}", format_if_else("{}", "<nullptr>", adapterInfo.description));
    println(" - adapterType: {}", adapterInfo.adapterType);
    println(" - backendType: {}", adapterInfo.backendType);

    println("Requesting device...");

    RequiredLimits requiredLimits = getRequiredLimits(adapter);
    DeviceDescriptor deviceDesc{WGPUDeviceDescriptor{
        .label = "The WebGPU device",
        .requiredFeatureCount = 0,
        .requiredLimits = &requiredLimits,
        .defaultQueue =
            WGPUQueueDescriptor{
                .nextInChain = nullptr,
                .label = "The default queue",
            },
    }};

// A function that is invoked whenever the device stops being available.
#if not defined(__EMSCRIPTEN__)
    DeviceLostCallbackInfo deviceLostInfo{};
    deviceLostInfo.callback = [](WGPUDevice const *device, WGPUDeviceLostReason reason, char const *message, void *) {
        println("Device lost: reason {}{}", reason, format_if(" ({})", message));
    };
    deviceDesc.deviceLostCallbackInfo = deviceLostInfo;

    UncapturedErrorCallbackInfo errorCallbackInfo{};
    errorCallbackInfo.nextInChain = nullptr;
    errorCallbackInfo.callback = [](WGPUErrorType type, char const *message, void *) {
        println(cerr, "Uncaptured device error: type {}{}", type, format_if(" ({})", message));
    };
    deviceDesc.uncapturedErrorCallbackInfo = errorCallbackInfo;
#else
    deviceDesc.deviceLostCallback = [](WGPUDeviceLostReason reason, char const *message, void *) {
        print("Device lost: reason {}", reason);
        if (message)
            print(" ({})", message);
        println("");
    };
#endif

    device = adapter.requestDevice(deviceDesc);

#if defined(__EMSCRIPTEN__)
    errCallbackPtr = device.setUncapturedErrorCallback([](WGPUErrorType type, char const *message) {
        print(cerr, "Uncaptured device error: type {}", type);
        if (message)
            print(cerr, " ({})", message);
        println("");
    });
#endif

    println("Got device: {}", device);
    inspectDevice(device);
    queue = device.getQueue();

    // return false;
#if not defined(__EMSCRIPTEN__)
    queue.onSubmittedWorkDone2(WGPUQueueWorkDoneCallbackInfo2{
        .mode = CallbackMode::AllowProcessEvents,
        .callback = [](WGPUQueueWorkDoneStatus status, void *userdata1, void *userdata2) {
            println("Queued work finished with status: {} ", status);
        }});
#else
    errDoneCallbackPtr = queue.onSubmittedWorkDone(
        [](WGPUQueueWorkDoneStatus status) { println("Queued work finished with status: {} ", status); });
#endif

// TODO: Workaround for getting wgpu::SurfaceGetCapabilities to work
// check newer versions if it works without it
// The only thing needed is setting device
// all other values are for removing error
#if defined(WEBGPU_BACKEND_DAWN)
    setProc();

    surface.configure(WGPUSurfaceConfiguration{
        .device = device,
        .format = TextureFormat::BGRA8UnormSrgb,
        .usage = TextureUsage::TextureBinding,
        .alphaMode = CompositeAlphaMode::Auto,
        .width = 640,
        .height = 580,
        .presentMode = PresentMode::Fifo,
    });
#endif

    SurfaceCapabilities surfaceCaps{};
    surface.getCapabilities(adapter, &surfaceCaps);

    println("Surface supported texture formats: ");
    for (size_t i = 0; i < surfaceCaps.formatCount; i++) {
        println(" - {}", surfaceCaps.formats[i]);
    }

    surfaceFormat = surfaceCaps.formats[0];
    // surfaceFormat = TextureFormat::RGBA8UnormSrgb;

    surface.configure(WGPUSurfaceConfiguration{
        .device = device,
        .format = surfaceFormat,
        .usage = TextureUsage::RenderAttachment,
        .viewFormatCount = 0,
        .viewFormats = nullptr,
        .alphaMode = CompositeAlphaMode::Auto,
        .width = 640,
        .height = 580,
        .presentMode = PresentMode::Fifo,
    });

    adapter.release();

    initializePipeline();
    initializeBuffers();

    // playingWithBuffers();

    return true;
}

void Application::terminate() {
    pointBuffer.release();
    indexBuffer.release();
    pipeline.release();
    surface.unconfigure();
    queue.release();
    surface.release();
    device.release();

    SDL_DestroyWindow(window);
    SDL_Quit();

    instance.release();
}

void wgpuPollEvents([[maybe_unused]] wgpu::Device device, [[maybe_unused]] bool yieldToWebBrowser,
                    [[maybe_unused]] wgpu::Instance instance = nullptr) {
#if defined(WEBGPU_BACKEND_DAWN)
    instance.processEvents();
#elif defined(WEBGPU_BACKEND_WGPU)
    device.poll(false);
#elif defined(WEBGPU_BACKEND_EMSCRIPTEN)
    if (yieldToWebBrowser) {
        emscripten_sleep(100);
    }
#endif
}

void Application::mainLoop() {
    using namespace std;
    using namespace wgpu;

    pollSDLEvents();

    TextureView targetView = getNextSurfaceTextureView();
    if (!targetView)
        return;

    CommandEncoder encoder = device.createCommandEncoder(WGPUCommandEncoderDescriptor{
        .label = "My command encoder",
    });

    RenderPassColorAttachment renderPassColorAttachment{WGPURenderPassColorAttachment{
        .view = targetView,
#if not defined(WEBGPU_BACKEND_WGPU)
        .depthSlice = WGPU_DEPTH_SLICE_UNDEFINED,
#endif
        .resolveTarget = nullptr,
        .loadOp = LoadOp::Clear,
        .storeOp = StoreOp::Store,
        .clearValue = {0.05, 0.05, 0.05, 1.0},
    }};

    RenderPassDescriptor renderPassDesc{WGPURenderPassDescriptor{
        .colorAttachmentCount = 1,
        .colorAttachments = &renderPassColorAttachment,
        .depthStencilAttachment = nullptr,
        .timestampWrites = nullptr,
    }};
    RenderPassEncoder renderPass = encoder.beginRenderPass(renderPassDesc);

    renderPass.setPipeline(pipeline);

    renderPass.setVertexBuffer(0, pointBuffer, 0, pointBuffer.getSize());
    renderPass.setIndexBuffer(indexBuffer, IndexFormat::Uint16, 0, indexBuffer.getSize());
    // Draw 1 instance of a 3-vertices shape
    renderPass.drawIndexed(indexCount, 1, 0, 0, 0);

    renderPass.end();
    renderPass.release();

    CommandBufferDescriptor cmdBufferDescriptor{WGPUCommandBufferDescriptor{
        .label = "Command buffer",
    }};

    CommandBuffer command = encoder.finish(cmdBufferDescriptor);
    encoder.release();

    queue.submit(1, &command);
    command.release();
    targetView.release();

#if not defined(__EMSCRIPTEN__)
    surface.present();
#endif

    // #if defined(WEBGPU_BACKEND_DAWN)
    //     // instance.processEvents();
    //     device.tick();
    // #elif defined(WEBGPU_BACKEND_WGPU)
    //     device.poll(false);
    // #endif
    wgpuPollEvents(device, false, instance);
}

wgpu::RequiredLimits Application::getRequiredLimits(wgpu::Adapter adapter) const {
    using namespace wgpu;
    using namespace std;

    SupportedLimits supportedLimits{};
    adapter.getLimits(&supportedLimits);

    RequiredLimits requiredLimits{Default};
    // We use 2 vertex attribute for now
    requiredLimits.limits.maxVertexAttributes = 2;
    // We should also tell that we use 1 vertex buffers
    requiredLimits.limits.maxVertexBuffers = 1;
    // Maximum size of a buffer is 6 vertices of 5 float each
    requiredLimits.limits.maxBufferSize = 15 * 5 * sizeof(float);
    // Maximum stride between 5 consecutive vertices in the vertex buffer
    requiredLimits.limits.maxVertexBufferArrayStride = 5 * sizeof(float);

    // These two limits are different because they are "minimum" limits,
    // they are the only ones we are may forward from the adapter's supported
    // limits.
    requiredLimits.limits.minUniformBufferOffsetAlignment = supportedLimits.limits.minUniformBufferOffsetAlignment;
    requiredLimits.limits.minStorageBufferOffsetAlignment = supportedLimits.limits.minStorageBufferOffsetAlignment;

    // There is a maximum of 3 float forwarded from vertex to fragment shader
    requiredLimits.limits.maxInterStageShaderComponents = 3;

    return requiredLimits;
}

wgpu::TextureView Application::getNextSurfaceTextureView() {
    using namespace std;
    using namespace wgpu;

    SurfaceTexture surfaceTexture{};
    surface.getCurrentTexture(&surfaceTexture);

    if (surfaceTexture.status != SurfaceGetCurrentTextureStatus::Success) {
        return nullptr;
    }

    Texture texture = surfaceTexture.texture;
    TextureViewDescriptor viewDescriptor{WGPUTextureViewDescriptor{
        .label = "Surface texture view",
        .format = texture.getFormat(),
        .dimension = TextureViewDimension::_2D,
        .baseMipLevel = 0,
        .mipLevelCount = 1,
        .baseArrayLayer = 0,
        .arrayLayerCount = 1,
        .aspect = TextureAspect::All,
    }};
    TextureView targetView = texture.createView(viewDescriptor);

    return targetView;
}

void Application::initializePipeline() {
    using namespace wgpu;

    ShaderModuleDescriptor shaderDesc{};
#if defined(WEBGPU_BACKEND_WGPU)
    shaderDesc.hintCount = 0;
    shaderDesc.hints = nullptr;
#endif
    ShaderModuleWGSLDescriptor shaderCodeDesc{WGPUShaderModuleWGSLDescriptor{
        .chain = ChainedStruct{{
            .next = nullptr,
            .sType = SType::ShaderModuleWGSLDescriptor,
        }},
        .code = shaderSource,
    }};
    shaderDesc.nextInChain = &shaderCodeDesc.chain;

    ShaderModule shaderModule = device.createShaderModule(shaderDesc);

    pipeline =
        device.createRenderPipeline(
            WGPURenderPipelineDescriptor{
                .label = "Vertex Pipeline",
                .layout = nullptr,
                .vertex =
                    WGPUVertexState{
                        .nextInChain = nullptr,
                        .module = shaderModule,
                        .entryPoint = "vs_main",
                        .constantCount = 0,
                        .constants = nullptr,

                        .bufferCount = 1,
                        .buffers = //
                        (std::array{WGPUVertexBufferLayout{
                             .arrayStride = 5 * sizeof(float),
                             .stepMode = VertexStepMode::Vertex,

                             .attributeCount = 2,
                             .attributes = //
                             (std::array{
                                  WGPUVertexAttribute{
                                      .format = VertexFormat::Float32x2,
                                      .offset = 0,
                                      .shaderLocation = 0,
                                  },
                                  WGPUVertexAttribute{
                                      .format = VertexFormat::Float32x3,
                                      .offset = 2 * sizeof(float),
                                      .shaderLocation = 1,
                                  },
                              })
                                 .data(),
                         }}).data(),
                    },
                .primitive =
                    WGPUPrimitiveState{
                        .nextInChain = nullptr,
                        .topology = PrimitiveTopology::TriangleList,
                        .stripIndexFormat = IndexFormat::Undefined,
                        .frontFace = FrontFace::CCW,
                        .cullMode = CullMode::None,
                    },
                .depthStencil = nullptr,
                .multisample =
                    WGPUMultisampleState{
                        .nextInChain = nullptr,
                        .count = 1,
                        .mask = ~0u,
                        .alphaToCoverageEnabled = false,
                    },
                // Temporary object lives for a full expression
                .fragment = addressof_rvalue(WGPUFragmentState{
                    .nextInChain = nullptr,
                    .module = shaderModule,
                    .entryPoint = "fs_main",
                    .constantCount = 0,
                    .constants = nullptr,

                    // We have only one target because our render pass has only one
                    // output color attachment.
                    .targetCount = 1,
                    .targets = //
                    (std::array{
                         WGPUColorTargetState{
                             .nextInChain = nullptr,
                             .format = surfaceFormat,
                             .blend = addressof_rvalue(WGPUBlendState{
                                 .color = {.operation = BlendOperation::Add,
                                           .srcFactor = BlendFactor::SrcAlpha,
                                           .dstFactor = BlendFactor::OneMinusSrcAlpha},
                                 .alpha = {.operation = BlendOperation::Add,
                                           .srcFactor = BlendFactor::Zero,
                                           .dstFactor = BlendFactor::One},
                             }),
                             .writeMask = ColorWriteMask::All,
                         },
                     })
                        .data(),
                }),
            });
    shaderModule.release();
}

void Application::initializeBuffers() {
    using namespace std;
    using namespace wgpu;

    vector<float> pointData{};
    std::vector<uint16_t> indexData{};

    // ;

    bool success = loadGeometry(RESOURCE_DIR "/webgpu.txt", pointData, indexData);
    if (!success) {
        println(cerr, "Could not load geometry! RESOURCE_DIR: " RESOURCE_DIR);
        exit(1);
    }

    indexCount = static_cast<uint32_t>(indexData.size());

    uint64_t bufferSize = pointData.size() * sizeof(float);
    pointBuffer = device.createBuffer(WGPUBufferDescriptor{
        .label = "Vertex Buffer",
        .usage = BufferUsage::CopyDst | BufferUsage::Vertex,
        .size = bufferSize,
        .mappedAtCreation = false,
    });

    queue.writeBuffer(pointBuffer, 0, pointData.data(), bufferSize);

    uint64_t indexSize = indexData.size() * sizeof(uint16_t);
    indexSize = (indexSize + 3) & ~0x03; // round up to the next multiple of 4
    indexBuffer = device.createBuffer(WGPUBufferDescriptor{
        .label = "Index Buffer",
        .usage = BufferUsage::CopyDst | BufferUsage::Index,
        .size = indexSize,
        .mappedAtCreation = false,
    });
    queue.writeBuffer(indexBuffer, 0, indexData.data(), indexSize);
}

void Application::pollSDLEvents() {
    SDL_Event event{};
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_QUIT: shouldClose = true; break;

        default: break;
        }
    }
}

void Application::playingWithBuffers() {
    using namespace std;
    using namespace wgpu;

    Buffer buffer1 = device.createBuffer(WGPUBufferDescriptor{
        .label = "Source buffer",
        .usage = BufferUsage::CopyDst | BufferUsage::CopySrc,
        .size = 16,
        .mappedAtCreation = false,
    });
    Buffer buffer2 = device.createBuffer(WGPUBufferDescriptor{
        .label = "Output buffer",
        .usage = BufferUsage::CopyDst | BufferUsage::MapRead,
        .size = 16,
        .mappedAtCreation = false,
    });

    vector<uint8_t> numbers{};
    numbers.resize(16);
    for (uint8_t i = 0; i < 16; i++) {
        numbers[i] = i;
    }
    queue.writeBuffer(buffer1, 0, numbers.data(), numbers.size());

    CommandEncoder encoder = device.createCommandEncoder(Default);
    encoder.copyBufferToBuffer(buffer1, 0, buffer2, 0, 16);

    CommandBuffer command = encoder.finish(Default);
    encoder.release();
    queue.submit(1, &command);
    command.release();

    struct Context {
        bool ready{false};
        Buffer buffer{nullptr};
    };
    Context context = {false, buffer2};

#if defined(WEBGPU_BACKEND_DAWN)
    BufferMapCallbackInfo2 info{WGPUBufferMapCallbackInfo2{
        .mode = CallbackMode::WaitAnyOnly,
        .callback =
            [](WGPUMapAsyncStatus status, const char *message, void *pUserData1, void *pUserData2) {
                println("Buffer 2 mapped with status {}{}", status, format_if(" ({})", message));
                if (status != MapAsyncStatus::Success)
                    return;

                Buffer buffer = reinterpret_cast<WGPUBuffer>(pUserData1);
                const uint8_t *bufferData = static_cast<const uint8_t *>(buffer.getConstMappedRange(0, 16));
                print("bufferData = [");
                for (size_t i = 0; i < 16; ++i) {
                    if (i > 0)
                        print(", ");
                    print("{}", bufferData[i]);
                }
                println("]");
            },
        .userdata1 = buffer2,
    }};

    FutureWaitInfo waitInfo{WGPUFutureWaitInfo{
        .future = buffer2.mapAsync2(MapMode::Read, 0, 16, info),
        .completed = false,
    }};
    while (!waitInfo.completed) {
        instance.waitAny(1, &waitInfo, 0);
    }
#elif not defined(__EMSCRIPTEN__)
    BufferMapCallbackInfo2 info{WGPUBufferMapCallbackInfo2{
        .mode = CallbackMode::AllowProcessEvents,
        .callback =
            [](WGPUMapAsyncStatus status, const char *message, void *pUserData1, void *pUserData2) {
                Context *ctx = reinterpret_cast<Context *>(pUserData1);
                ctx->ready = true;
                println("Buffer 2 mapped with status {}", status);
                if (status != MapAsyncStatus::Success)
                    return;

                const uint8_t *bufferData = static_cast<const uint8_t *>(ctx->buffer.getConstMappedRange(0, 16));
                print("bufferData = [");
                for (size_t i = 0; i < 16; ++i) {
                    if (i > 0)
                        print(", ");
                    print("{}", bufferData[i]);
                }
                println("]");
            },
        .userdata1 = &context,
    }};
    buffer2.mapAsync2(MapMode::Read, 0, 16, info);
    while (!context.ready) {
        wgpuPollEvents(device, true, instance);
    }
#else
    auto onBuffer2Mapped = [](WGPUBufferMapAsyncStatus status, void *pUserData) {
        Context *ctx = reinterpret_cast<Context *>(pUserData);
        ctx->ready = true;
        println("Buffer 2 mapped with status {}", status);
        if (status != BufferMapAsyncStatus::Success)
            return;

        const uint8_t *bufferData = static_cast<const uint8_t *>(ctx->buffer.getConstMappedRange(0, 16));
        print("bufferData = [");
        for (size_t i = 0; i < 16; ++i) {
            if (i > 0)
                print(", ");
            print("{}", bufferData[i]);
        }
        println("]");
    };
    wgpuBufferMapAsync(buffer2, MapMode::Read, 0, 16, onBuffer2Mapped, &context);
    while (!context.ready) {
        wgpuPollEvents(device, true, instance);
    }
#endif

    buffer1.release();
    buffer2.release();
}

} // namespace ninelives