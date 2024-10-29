#pragma once

// clang-format off
#include "template_formatters.hpp"
#include "formatters.hpp"
#include <iostream>
#include <format>
#include <print>
// clang-format on

namespace ninelives {

/// @brief Checks if the first arg can be converted to bool and formats it on true
/// @return Formatted string if the first arg is true, otherwise empty string
template <class... Args>
    requires std::is_convertible_v<std::tuple_element_t<0, std::tuple<Args...>>, bool>
[[nodiscard]] std::string format_if(const std::format_string<Args...> fmt, Args &&...args) {

    auto &first = [](auto &first, auto &...) -> auto & {
        return first;
    }(args...);

    if (static_cast<bool>(first)) {
        return std::vformat(fmt.get(), std::make_format_args(args...));
    } else {
        return "";
    }
}

template <class... Args>
    requires std::is_convertible_v<std::tuple_element_t<0, std::tuple<Args...>>, bool> ||
             std::is_convertible_v<std::tuple_element_t<0, std::tuple<Args...>>, std::nullptr_t>
[[nodiscard]] std::string format_if_else(
    const std::format_string<Args...> fmt, std::string_view onFalse, Args &&...args
) {

    auto &first = [](auto &first, auto &...) -> auto & {
        return first;
    }(args...);

    if (static_cast<bool>(first)) {
        return std::vformat(fmt.get(), std::make_format_args(args...));
    } else {
        return {onFalse.data(), onFalse.size()};
    }
}
} // namespace ninelives
