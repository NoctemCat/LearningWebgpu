
#include "application.hpp"

namespace ninelives {} // namespace ninelives

int main(int, char **) {
    using namespace ninelives;

    Application app{};
    if (!app.initialize()) {
        return 1;
    }

#if defined(__EMSCRIPTEN__)
    // [...] Emscripten main loop
    auto callback = [](void *arg) {
        Application *pApp = reinterpret_cast<Application *>(arg);
        pApp->mainLoop();
    };
    emscripten_set_main_loop_arg(callback, &app, 0, true);
    emscripten_set_main_loop_timing(EM_TIMING_RAF, 1);
#else  // __EMSCRIPTEN__
    while (app.isRunning()) {
        app.mainLoop();
    }
#endif // __EMSCRIPTEN__

    app.terminate();

    return 0;
}