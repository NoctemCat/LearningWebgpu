#pragma once
#include <concepts>
#include <format>
#include <string>
#include <string_view>

namespace ninelives {

template <typename T>
struct TypeFormatter {};

// clang-format off
// Disable custom formatters for already existing types in std::format
template <> struct TypeFormatter<int> {};
template <> struct TypeFormatter<unsigned int> {};
template <> struct TypeFormatter<long long> {};
template <> struct TypeFormatter<unsigned long long> {};
template <> struct TypeFormatter<bool> {};
template <> struct TypeFormatter<float> {};
template <> struct TypeFormatter<double> {};
template <> struct TypeFormatter<long double> {};
template <> struct TypeFormatter<nullptr_t> {};
template <> struct TypeFormatter<void *> {};
template <> struct TypeFormatter<const void *> {};
template <> struct TypeFormatter<unsigned short> {};
template <> struct TypeFormatter<long> {};
template <> struct TypeFormatter<unsigned long> {};
template <> struct TypeFormatter<signed char> {};
template <> struct TypeFormatter<unsigned char> {};
template <> struct TypeFormatter<const char*> {};
template <> struct TypeFormatter<const wchar_t*> {};
template <> struct TypeFormatter<std::string_view> {};
template <> struct TypeFormatter<std::wstring_view> {};
template <> struct TypeFormatter<std::string> {};
template <> struct TypeFormatter<std::wstring> {};
// clang-format on
} // namespace ninelives

template <typename T>
concept ImplementedTypeFormatter = requires(const T &value) {
    { ninelives::TypeFormatter<T>::toString(value) } -> std::same_as<std::string>;
};
template <typename T>
concept ImplementedTypeFormatterComplex = requires(const T &value, std::format_context &ctx_) {
    { ninelives::TypeFormatter<T>::format(value, ctx_, std::string_view{}) } -> std::same_as<decltype(ctx_.out())>;
};

template <typename T>
concept NotImplementedTypeFormatter = not ImplementedTypeFormatter<T>;
template <typename T>
concept NotImplementedTypeFormatterCustom = not ImplementedTypeFormatterComplex<T>;

template <typename T>
concept IsSimpleTypeFormatter = ImplementedTypeFormatter<T> and NotImplementedTypeFormatterCustom<T>;
template <typename T>
concept IsComplexTypeFormatter = not IsSimpleTypeFormatter<T>;

template <typename T>
concept NotImplementedFormatters = NotImplementedTypeFormatter<T> and NotImplementedTypeFormatterCustom<T>;
template <typename T>
concept ImplementedFormatters = ImplementedTypeFormatter<T> or ImplementedTypeFormatterComplex<T>;

template <typename T>
concept IsNotVoidPtr = not std::is_void_v<std::remove_pointer_t<T>>;
template <typename T>
concept IsNotConstCharPtr = not std::is_same_v<std::remove_cvref_t<std::remove_pointer_t<T>>, char>;
template <typename T>
concept IsNotWCharPtr = not std::is_same_v<std::remove_cvref_t<std::remove_pointer_t<T>>, wchar_t>;
template <typename T>
concept IsFormattablePtr = IsNotVoidPtr<T> and IsNotConstCharPtr<T> and IsNotWCharPtr<T>;

namespace std {
namespace nl = ninelives;

template <typename T>
    requires IsSimpleTypeFormatter<T>
struct formatter<T> : formatter<string> {
    template <class FormatContext>
    constexpr auto format(const T &value, FormatContext &ctx) const {
        using namespace ninelives;
        return formatter<string>::format(TypeFormatter<T>::toString(value), ctx);
    }
};

template <typename T>
    requires ImplementedTypeFormatterComplex<T>

struct formatter<T> {
    string_view formatString{""};

    template <class ParseFormatContext>
    constexpr auto parse(ParseFormatContext &ctx) {
        auto beg = ctx.begin();
        auto pos = ctx.begin();
        while (pos != ctx.end() && *pos != '}') {
            ++pos;
        }
        formatString = {beg, pos};
        return pos;
    }

    template <class FormatContext>
    constexpr auto format(const T &value, FormatContext &ctx) const {
        using namespace ninelives;
        return TypeFormatter<T>::format(value, ctx, formatString);
    }
};

template <typename T>
    requires is_enum_v<T> and NotImplementedFormatters<T>
struct formatter<T> : formatter<underlying_type_t<T>> {

    template <class FormatContext>
    constexpr auto format(const T &value, FormatContext &ctx) const {
        return formatter<underlying_type_t<T>>::format(static_cast<underlying_type_t<T>>(value), ctx);
    }
};

template <typename T>
    requires is_pointer_v<T> and IsFormattablePtr<T> and NotImplementedFormatters<T>
struct formatter<T> : formatter<void *> {
    // #if not defined(_MSC_VER)
    //     template <class FormatContext>
    //     auto format(const T &value, FormatContext &ctx) const {
    // #else
    //     auto format(const T &value, format_context &ctx) const {
    // #endif
    // TODO: check future versions for template
    template <class FormatContext>
    constexpr auto format(const T &value, FormatContext &ctx) const {
        return formatter<void *>::format(static_cast<void *>(value), ctx);
    }
}; // namespace std
} // namespace std
