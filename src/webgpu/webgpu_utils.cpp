#include "webgpu_utils.hpp"
#include <cassert>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

namespace ninelives {

void inspectDevice(wgpu::Device device) {
    using namespace std;

    vector<WGPUFeatureName> features{};

    size_t featureCount = device.enumerateFeatures(nullptr);
    features.resize(featureCount);
    device.enumerateFeatures(reinterpret_cast<wgpu::FeatureName *>(features.data()));

    println("Device features:");
    for (auto f : features) {
        println(" - {}", f);
    }

    wgpu::SupportedLimits limits{};

#if defined(WEBGPU_BACKEND_DAWN)
    bool success = device.getLimits(&limits) == wgpu::Status::Success;
#else
    bool success = device.getLimits(&limits);
#endif

    if (success) {
        println("Device limits: ");
        println(" - maxTextureDimension1D: {}", limits.limits.maxTextureDimension1D);
        println(" - maxTextureDimension2D: {}", limits.limits.maxTextureDimension2D);
        println(" - maxTextureDimension3D: {}", limits.limits.maxTextureDimension3D);
        println(" - maxTextureArrayLayers: {}", limits.limits.maxTextureArrayLayers);
        println(" - maxVertexAttributes: {}", limits.limits.maxVertexAttributes);
    }
}

bool loadGeometry(
    const std::filesystem::path &path, std::vector<float> &pointData,
    std::vector<uint16_t> &indexData
) {
    std::ifstream file(path);
    if (!file.is_open()) {
        return false;
    }

    pointData.clear();
    indexData.clear();

    enum class Section {
        None,
        Points,
        Indices,
    };
    Section currentSection = Section::None;

    float value;
    uint16_t index;
    std::string line;
    while (!file.eof()) {
        getline(file, line);

        // overcome the `CRLF` problem
        if (!line.empty() && line.back() == '\r') {
            line.pop_back();
        }

        if (line == "[points]") {
            currentSection = Section::Points;
        } else if (line == "[indices]") {
            currentSection = Section::Indices;
        } else if (line[0] == '#' || line.empty()) {
            // Do nothing, this is a comment
        } else if (currentSection == Section::Points) {
            std::istringstream iss(line);
            // Get x, y, r, g, b
            for (int i = 0; i < 5; ++i) {
                iss >> value;
                pointData.push_back(value);
            }
        } else if (currentSection == Section::Indices) {
            std::istringstream iss(line);
            // Get corners #0 #1 and #2
            for (int i = 0; i < 3; ++i) {
                iss >> index;
                indexData.push_back(index);
            }
        }
    }
    return true;
}
} // namespace ninelives