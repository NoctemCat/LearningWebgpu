#pragma once
#include "utils/print_format.hpp"
#include <filesystem>
#include <webgpu/webgpu.hpp>

namespace ninelives {

void inspectDevice(wgpu::Device device);
bool loadGeometry(const std::filesystem::path &path, std::vector<float> &pointData, std::vector<uint16_t> &indexData);

void setProc();
} // namespace ninelives