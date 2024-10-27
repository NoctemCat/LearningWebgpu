#include <memory>
namespace ninelives {

/// @brief The pointer is only valid for a full expression, i.e. don't store it
/// @param v rvalue
/// @return The pointer to rvalue
template <typename T>
T *addressof_rvalue(T &&v) {
    return std::addressof(v);
}
template <typename T>
T *addressof_rvalue(T &v) = delete;

} // namespace ninelives
