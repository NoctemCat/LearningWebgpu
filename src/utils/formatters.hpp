#pragma once

#include "template_formatters.hpp"
#include <webgpu/webgpu.h>

namespace std {
// WebGPU-Cpp wrappers
template <typename T>
    requires std::is_convertible_v<T, typename T::W> and NotImplementedFormatters<T>
struct formatter<T> : formatter<typename T::W> {
    template <class FormatContext>
    constexpr auto format(const T &value, FormatContext &ctx) const {
        return formatter<typename T::W>::format(static_cast<typename T::W>(value), ctx);
    }
};
} // namespace std

namespace ninelives {

template <>
struct TypeFormatter<WGPUFeatureName> {
    static std::string toString(const WGPUFeatureName &value) {
        switch (value) {
        case WGPUFeatureName_Undefined: return "Undefined";
        case WGPUFeatureName_DepthClipControl: return "DepthClipControl";
        case WGPUFeatureName_Depth32FloatStencil8: return "Depth32FloatStencil8";
        case WGPUFeatureName_TimestampQuery: return "TimestampQuery";
        case WGPUFeatureName_TextureCompressionBC: return "TextureCompressionBC";
        case WGPUFeatureName_TextureCompressionETC2: return "TextureCompressionETC2";
        case WGPUFeatureName_TextureCompressionASTC: return "TextureCompressionASTC";
        case WGPUFeatureName_IndirectFirstInstance: return "IndirectFirstInstance";
        case WGPUFeatureName_ShaderF16: return "ShaderF16";
        case WGPUFeatureName_RG11B10UfloatRenderable: return "RG11B10UfloatRenderable";
        case WGPUFeatureName_BGRA8UnormStorage: return "BGRA8UnormStorage";
        case WGPUFeatureName_Float32Filterable: return "Float32Filterable";
#if not defined(__EMSCRIPTEN__)
        case WGPUFeatureName_DawnInternalUsages: return "DawnInternalUsages";
        case WGPUFeatureName_DawnMultiPlanarFormats: return "DawnMultiPlanarFormats";
        case WGPUFeatureName_DawnNative: return "DawnNative";
        case WGPUFeatureName_ChromiumExperimentalTimestampQueryInsidePasses:
            return "ChromiumExperimentalTimestampQueryInsidePasses";
        case WGPUFeatureName_ImplicitDeviceSynchronization: return "ImplicitDeviceSynchronization";
        case WGPUFeatureName_SurfaceCapabilities: return "SurfaceCapabilities";
        case WGPUFeatureName_TransientAttachments: return "TransientAttachments";
        case WGPUFeatureName_MSAARenderToSingleSampled: return "MSAARenderToSingleSampled";
        case WGPUFeatureName_DualSourceBlending: return "DualSourceBlending";
        case WGPUFeatureName_D3D11MultithreadProtected: return "D3D11MultithreadProtected";
        case WGPUFeatureName_ANGLETextureSharing: return "ANGLETextureSharing";
        case WGPUFeatureName_ChromiumExperimentalSubgroups: return "ChromiumExperimentalSubgroups";
        case WGPUFeatureName_ChromiumExperimentalSubgroupUniformControlFlow:
            return "ChromiumExperimentalSubgroupUniformControlFlow";
        case WGPUFeatureName_PixelLocalStorageCoherent: return "PixelLocalStorageCoherent";
        case WGPUFeatureName_PixelLocalStorageNonCoherent: return "PixelLocalStorageNonCoherent";
        case WGPUFeatureName_Unorm16TextureFormats: return "Unorm16TextureFormats";
        case WGPUFeatureName_Snorm16TextureFormats: return "Snorm16TextureFormats";
        case WGPUFeatureName_MultiPlanarFormatExtendedUsages:
            return "MultiPlanarFormatExtendedUsages";
        case WGPUFeatureName_MultiPlanarFormatP010: return "MultiPlanarFormatP010";
        case WGPUFeatureName_HostMappedPointer: return "HostMappedPointer";
        case WGPUFeatureName_MultiPlanarRenderTargets: return "MultiPlanarRenderTargets";
        case WGPUFeatureName_MultiPlanarFormatNv12a: return "MultiPlanarFormatNv12a";
        case WGPUFeatureName_FramebufferFetch: return "FramebufferFetch";
        case WGPUFeatureName_BufferMapExtendedUsages: return "BufferMapExtendedUsages";
        case WGPUFeatureName_AdapterPropertiesMemoryHeaps: return "AdapterPropertiesMemoryHeaps";
        case WGPUFeatureName_AdapterPropertiesD3D: return "AdapterPropertiesD3D";
        case WGPUFeatureName_AdapterPropertiesVk: return "AdapterPropertiesVk";
        case WGPUFeatureName_R8UnormStorage: return "R8UnormStorage";
        case WGPUFeatureName_FormatCapabilities: return "FormatCapabilities";
        case WGPUFeatureName_DrmFormatCapabilities: return "DrmFormatCapabilities";
        case WGPUFeatureName_Norm16TextureFormats: return "Norm16TextureFormats";
        case WGPUFeatureName_MultiPlanarFormatNv16: return "MultiPlanarFormatNv16";
        case WGPUFeatureName_MultiPlanarFormatNv24: return "MultiPlanarFormatNv24";
        case WGPUFeatureName_MultiPlanarFormatP210: return "MultiPlanarFormatP210";
        case WGPUFeatureName_MultiPlanarFormatP410: return "MultiPlanarFormatP410";
        case WGPUFeatureName_SharedTextureMemoryVkDedicatedAllocation:
            return "SharedTextureMemoryVkDedicatedAllocation";
        case WGPUFeatureName_SharedTextureMemoryAHardwareBuffer:
            return "SharedTextureMemoryAHardwareBuffer";
        case WGPUFeatureName_SharedTextureMemoryDmaBuf: return "SharedTextureMemoryDmaBuf";
        case WGPUFeatureName_SharedTextureMemoryOpaqueFD: return "SharedTextureMemoryOpaqueFD";
        case WGPUFeatureName_SharedTextureMemoryZirconHandle:
            return "SharedTextureMemoryZirconHandle";
        case WGPUFeatureName_SharedTextureMemoryDXGISharedHandle:
            return "SharedTextureMemoryDXGISharedHandle";
        case WGPUFeatureName_SharedTextureMemoryD3D11Texture2D:
            return "SharedTextureMemoryD3D11Texture2D";
        case WGPUFeatureName_SharedTextureMemoryIOSurface: return "SharedTextureMemoryIOSurface";
        case WGPUFeatureName_SharedTextureMemoryEGLImage: return "SharedTextureMemoryEGLImage";
        case WGPUFeatureName_SharedFenceVkSemaphoreOpaqueFD:
            return "SharedFenceVkSemaphoreOpaqueFD";
        case WGPUFeatureName_SharedFenceVkSemaphoreSyncFD: return "SharedFenceVkSemaphoreSyncFD";
        case WGPUFeatureName_SharedFenceVkSemaphoreZirconHandle:
            return "SharedFenceVkSemaphoreZirconHandle";
        case WGPUFeatureName_SharedFenceDXGISharedHandle: return "SharedFenceDXGISharedHandle";
        case WGPUFeatureName_SharedFenceMTLSharedEvent: return "SharedFenceMTLSharedEvent";
        case WGPUFeatureName_SharedBufferMemoryD3D12Resource:
            return "SharedBufferMemoryD3D12Resource";
        case WGPUFeatureName_StaticSamplers: return "StaticSamplers";
        case WGPUFeatureName_YCbCrVulkanSamplers: return "YCbCrVulkanSamplers";
        case WGPUFeatureName_ShaderModuleCompilationOptions:
            return "ShaderModuleCompilationOptions";
        case WGPUFeatureName_DawnLoadResolveTexture: return "DawnLoadResolveTexture";
#endif

        case WGPUFeatureName_Force32: return "Force32";
        }
        return std::format(
            "WGPUFeatureName: {:#010X}", static_cast<std::underlying_type_t<WGPUFeatureName>>(value)
        );
    }
};

template <>
struct TypeFormatter<WGPUAdapterType> {
    static std::string toString(const WGPUAdapterType &value) {
        switch (value) {
        case WGPUAdapterType_DiscreteGPU: return "DiscreteGPU";
        case WGPUAdapterType_IntegratedGPU: return "IntegratedGPU";
        case WGPUAdapterType_CPU: return "CPU";
        case WGPUAdapterType_Unknown: return "Unknown";
        case WGPUAdapterType_Force32: return "Force32";
        }
        return std::format(
            "WGPUAdapterType: {:#010X}", static_cast<std::underlying_type_t<WGPUAdapterType>>(value)
        );
    }
};

template <>
struct TypeFormatter<WGPUBackendType> {
    static std::string toString(const WGPUBackendType &value) {
        switch (value) {
        case WGPUBackendType_Undefined: return "Undefined";
        case WGPUBackendType_Null: return "Null";
        case WGPUBackendType_WebGPU: return "WebGPU";
        case WGPUBackendType_D3D11: return "D3D11";
        case WGPUBackendType_D3D12: return "D3D12";
        case WGPUBackendType_Metal: return "Metal";
        case WGPUBackendType_Vulkan: return "Vulkan";
        case WGPUBackendType_OpenGL: return "OpenGL";
        case WGPUBackendType_OpenGLES: return "OpenGLES";
        case WGPUBackendType_Force32: return "Force32";
        }
        return std::format(
            "WGPUBackendType: {:#010X}", static_cast<std::underlying_type_t<WGPUBackendType>>(value)
        );
    }
};

template <>
struct TypeFormatter<WGPUQueueWorkDoneStatus> {
    static std::string toString(const WGPUQueueWorkDoneStatus &value) {
        switch (value) {
        case WGPUQueueWorkDoneStatus_Success: return "Success";
#if not defined(__EMSCRIPTEN__)
        case WGPUQueueWorkDoneStatus_InstanceDropped: return "InstanceDropped";
#endif
        case WGPUQueueWorkDoneStatus_Error: return "Error";
        case WGPUQueueWorkDoneStatus_Unknown: return "Unknown";
        case WGPUQueueWorkDoneStatus_DeviceLost: return "DeviceLost";
        case WGPUQueueWorkDoneStatus_Force32: return "Force32";
        }
        return std::format(
            "WGPUQueueWorkDoneStatus: {:#010X}",
            static_cast<std::underlying_type_t<WGPUQueueWorkDoneStatus>>(value)
        );
    }
};

template <>
struct TypeFormatter<WGPUTextureFormat> {
    static std::string toString(const WGPUTextureFormat &value) {
        switch (value) {
        case WGPUTextureFormat_Undefined: return "Undefined";
        case WGPUTextureFormat_R8Unorm: return "R8Unorm";
        case WGPUTextureFormat_R8Snorm: return "R8Snorm";
        case WGPUTextureFormat_R8Uint: return "R8Uint";
        case WGPUTextureFormat_R8Sint: return "R8Sint";
        case WGPUTextureFormat_R16Uint: return "R16Uint";
        case WGPUTextureFormat_R16Sint: return "R16Sint";
        case WGPUTextureFormat_R16Float: return "R16Float";
        case WGPUTextureFormat_RG8Unorm: return "RG8Unorm";
        case WGPUTextureFormat_RG8Snorm: return "RG8Snorm";
        case WGPUTextureFormat_RG8Uint: return "RG8Uint";
        case WGPUTextureFormat_RG8Sint: return "RG8Sint";
        case WGPUTextureFormat_R32Float: return "R32Float";
        case WGPUTextureFormat_R32Uint: return "R32Uint";
        case WGPUTextureFormat_R32Sint: return "R32Sint";
        case WGPUTextureFormat_RG16Uint: return "RG16Uint";
        case WGPUTextureFormat_RG16Sint: return "RG16Sint";
        case WGPUTextureFormat_RG16Float: return "RG16Float";
        case WGPUTextureFormat_RGBA8Unorm: return "RGBA8Unorm";
        case WGPUTextureFormat_RGBA8UnormSrgb: return "RGBA8UnormSrgb";
        case WGPUTextureFormat_RGBA8Snorm: return "RGBA8Snorm";
        case WGPUTextureFormat_RGBA8Uint: return "RGBA8Uint";
        case WGPUTextureFormat_RGBA8Sint: return "RGBA8Sint";
        case WGPUTextureFormat_BGRA8Unorm: return "BGRA8Unorm";
        case WGPUTextureFormat_BGRA8UnormSrgb: return "BGRA8UnormSrgb";
        case WGPUTextureFormat_RGB10A2Uint: return "RGB10A2Uint";
        case WGPUTextureFormat_RGB10A2Unorm: return "RGB10A2Unorm";
        case WGPUTextureFormat_RG11B10Ufloat: return "RG11B10Ufloat";
        case WGPUTextureFormat_RGB9E5Ufloat: return "RGB9E5Ufloat";
        case WGPUTextureFormat_RG32Float: return "RG32Float";
        case WGPUTextureFormat_RG32Uint: return "RG32Uint";
        case WGPUTextureFormat_RG32Sint: return "RG32Sint";
        case WGPUTextureFormat_RGBA16Uint: return "RGBA16Uint";
        case WGPUTextureFormat_RGBA16Sint: return "RGBA16Sint";
        case WGPUTextureFormat_RGBA16Float: return "RGBA16Float";
        case WGPUTextureFormat_RGBA32Float: return "RGBA32Float";
        case WGPUTextureFormat_RGBA32Uint: return "RGBA32Uint";
        case WGPUTextureFormat_RGBA32Sint: return "RGBA32Sint";
        case WGPUTextureFormat_Stencil8: return "Stencil8";
        case WGPUTextureFormat_Depth16Unorm: return "Depth16Unorm";
        case WGPUTextureFormat_Depth24Plus: return "Depth24Plus";
        case WGPUTextureFormat_Depth24PlusStencil8: return "Depth24PlusStencil8";
        case WGPUTextureFormat_Depth32Float: return "Depth32Float";
        case WGPUTextureFormat_Depth32FloatStencil8: return "Depth32FloatStencil8";
        case WGPUTextureFormat_BC1RGBAUnorm: return "BC1RGBAUnorm";
        case WGPUTextureFormat_BC1RGBAUnormSrgb: return "BC1RGBAUnormSrgb";
        case WGPUTextureFormat_BC2RGBAUnorm: return "BC2RGBAUnorm";
        case WGPUTextureFormat_BC2RGBAUnormSrgb: return "BC2RGBAUnormSrgb";
        case WGPUTextureFormat_BC3RGBAUnorm: return "BC3RGBAUnorm";
        case WGPUTextureFormat_BC3RGBAUnormSrgb: return "BC3RGBAUnormSrgb";
        case WGPUTextureFormat_BC4RUnorm: return "BC4RUnorm";
        case WGPUTextureFormat_BC4RSnorm: return "BC4RSnorm";
        case WGPUTextureFormat_BC5RGUnorm: return "BC5RGUnorm";
        case WGPUTextureFormat_BC5RGSnorm: return "BC5RGSnorm";
        case WGPUTextureFormat_BC6HRGBUfloat: return "BC6HRGBUfloat";
        case WGPUTextureFormat_BC6HRGBFloat: return "BC6HRGBFloat";
        case WGPUTextureFormat_BC7RGBAUnorm: return "BC7RGBAUnorm";
        case WGPUTextureFormat_BC7RGBAUnormSrgb: return "BC7RGBAUnormSrgb";
        case WGPUTextureFormat_ETC2RGB8Unorm: return "ETC2RGB8Unorm";
        case WGPUTextureFormat_ETC2RGB8UnormSrgb: return "ETC2RGB8UnormSrgb";
        case WGPUTextureFormat_ETC2RGB8A1Unorm: return "ETC2RGB8A1Unorm";
        case WGPUTextureFormat_ETC2RGB8A1UnormSrgb: return "ETC2RGB8A1UnormSrgb";
        case WGPUTextureFormat_ETC2RGBA8Unorm: return "ETC2RGBA8Unorm";
        case WGPUTextureFormat_ETC2RGBA8UnormSrgb: return "ETC2RGBA8UnormSrgb";
        case WGPUTextureFormat_EACR11Unorm: return "EACR11Unorm";
        case WGPUTextureFormat_EACR11Snorm: return "EACR11Snorm";
        case WGPUTextureFormat_EACRG11Unorm: return "EACRG11Unorm";
        case WGPUTextureFormat_EACRG11Snorm: return "EACRG11Snorm";
        case WGPUTextureFormat_ASTC4x4Unorm: return "ASTC4x4Unorm";
        case WGPUTextureFormat_ASTC4x4UnormSrgb: return "ASTC4x4UnormSrgb";
        case WGPUTextureFormat_ASTC5x4Unorm: return "ASTC5x4Unorm";
        case WGPUTextureFormat_ASTC5x4UnormSrgb: return "ASTC5x4UnormSrgb";
        case WGPUTextureFormat_ASTC5x5Unorm: return "ASTC5x5Unorm";
        case WGPUTextureFormat_ASTC5x5UnormSrgb: return "ASTC5x5UnormSrgb";
        case WGPUTextureFormat_ASTC6x5Unorm: return "ASTC6x5Unorm";
        case WGPUTextureFormat_ASTC6x5UnormSrgb: return "ASTC6x5UnormSrgb";
        case WGPUTextureFormat_ASTC6x6Unorm: return "ASTC6x6Unorm";
        case WGPUTextureFormat_ASTC6x6UnormSrgb: return "ASTC6x6UnormSrgb";
        case WGPUTextureFormat_ASTC8x5Unorm: return "ASTC8x5Unorm";
        case WGPUTextureFormat_ASTC8x5UnormSrgb: return "ASTC8x5UnormSrgb";
        case WGPUTextureFormat_ASTC8x6Unorm: return "ASTC8x6Unorm";
        case WGPUTextureFormat_ASTC8x6UnormSrgb: return "ASTC8x6UnormSrgb";
        case WGPUTextureFormat_ASTC8x8Unorm: return "ASTC8x8Unorm";
        case WGPUTextureFormat_ASTC8x8UnormSrgb: return "ASTC8x8UnormSrgb";
        case WGPUTextureFormat_ASTC10x5Unorm: return "ASTC10x5Unorm";
        case WGPUTextureFormat_ASTC10x5UnormSrgb: return "ASTC10x5UnormSrgb";
        case WGPUTextureFormat_ASTC10x6Unorm: return "ASTC10x6Unorm";
        case WGPUTextureFormat_ASTC10x6UnormSrgb: return "ASTC10x6UnormSrgb";
        case WGPUTextureFormat_ASTC10x8Unorm: return "ASTC10x8Unorm";
        case WGPUTextureFormat_ASTC10x8UnormSrgb: return "ASTC10x8UnormSrgb";
        case WGPUTextureFormat_ASTC10x10Unorm: return "ASTC10x10Unorm";
        case WGPUTextureFormat_ASTC10x10UnormSrgb: return "ASTC10x10UnormSrgb";
        case WGPUTextureFormat_ASTC12x10Unorm: return "ASTC12x10Unorm";
        case WGPUTextureFormat_ASTC12x10UnormSrgb: return "ASTC12x10UnormSrgb";
        case WGPUTextureFormat_ASTC12x12Unorm: return "ASTC12x12Unorm";
        case WGPUTextureFormat_ASTC12x12UnormSrgb: return "ASTC12x12UnormSrgb";
#if not defined(__EMSCRIPTEN__)
        case WGPUTextureFormat_R16Unorm: return "R16Unorm";
        case WGPUTextureFormat_RG16Unorm: return "RG16Unorm";
        case WGPUTextureFormat_RGBA16Unorm: return "RGBA16Unorm";
        case WGPUTextureFormat_R16Snorm: return "R16Snorm";
        case WGPUTextureFormat_RG16Snorm: return "RG16Snorm";
        case WGPUTextureFormat_RGBA16Snorm: return "RGBA16Snorm";
        case WGPUTextureFormat_R8BG8Biplanar420Unorm: return "R8BG8Biplanar420Unorm";
        case WGPUTextureFormat_R10X6BG10X6Biplanar420Unorm: return "R10X6BG10X6Biplanar420Unorm";
        case WGPUTextureFormat_R8BG8A8Triplanar420Unorm: return "R8BG8A8Triplanar420Unorm";
        case WGPUTextureFormat_R8BG8Biplanar422Unorm: return "R8BG8Biplanar422Unorm";
        case WGPUTextureFormat_R8BG8Biplanar444Unorm: return "R8BG8Biplanar444Unorm";
        case WGPUTextureFormat_R10X6BG10X6Biplanar422Unorm: return "R10X6BG10X6Biplanar422Unorm";
        case WGPUTextureFormat_R10X6BG10X6Biplanar444Unorm: return "R10X6BG10X6Biplanar444Unorm";
        case WGPUTextureFormat_External: return "External";
#endif
        case WGPUTextureFormat_Force32: return "Force32";
        }
        return std::format(
            "WGPUTextureFormat: {:#010X}",
            static_cast<std::underlying_type_t<WGPUTextureFormat>>(value)
        );
    }
};

template <>
struct TypeFormatter<WGPUBufferMapAsyncStatus> {
    static std::string toString(const WGPUBufferMapAsyncStatus &value) {
        switch (value) {
        case WGPUBufferMapAsyncStatus_Success: return "Success";
        case WGPUBufferMapAsyncStatus_InstanceDropped: return "InstanceDropped";
        case WGPUBufferMapAsyncStatus_ValidationError: return "ValidationError";
        case WGPUBufferMapAsyncStatus_Unknown: return "Unknown";
        case WGPUBufferMapAsyncStatus_DeviceLost: return "DeviceLost";
        case WGPUBufferMapAsyncStatus_DestroyedBeforeCallback: return "DestroyedBeforeCallback";
        case WGPUBufferMapAsyncStatus_UnmappedBeforeCallback: return "UnmappedBeforeCallback";
        case WGPUBufferMapAsyncStatus_MappingAlreadyPending: return "MappingAlreadyPending:";
        case WGPUBufferMapAsyncStatus_OffsetOutOfRange: return "OffsetOutOfRange";
        case WGPUBufferMapAsyncStatus_SizeOutOfRange: return "SizeOutOfRange:";
        case WGPUBufferMapAsyncStatus_Force32: return "Force32";
        }
        return std::format(
            "WGPUQueueWorkDoneStatus: {:#010X}",
            static_cast<std::underlying_type_t<WGPUQueueWorkDoneStatus>>(value)
        );
    }
};
} // namespace ninelives