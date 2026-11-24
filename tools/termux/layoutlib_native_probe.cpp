#include <dlfcn.h>
#include <libgen.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static std::string dirname_of(const std::string& path) {
    std::string copy = path;
    char* d = dirname(copy.data());
    return d ? std::string(d) : ".";
}

static bool file_exists(const std::string& p) {
    return access(p.c_str(), R_OK) == 0;
}

static std::string pick_lib_dir(int argc, char** argv) {
    if (argc > 1 && argv[1] && argv[1][0] != '\0') {
        return argv[1];
    }
    std::vector<std::string> candidates;
    if (const char* env_dir = getenv("LAYOUTLIB_NATIVE_DIR")) {
        candidates.emplace_back(env_dir);
    }
    if (const char* prefix = getenv("PREFIX")) {
        candidates.push_back(std::string(prefix) + "/lib/layoutlib");
        candidates.push_back(std::string(prefix) + "/lib");
    }
    candidates.emplace_back("/data/data/com.termux/files/usr/lib/layoutlib");
    candidates.emplace_back("/data/data/com.termux/files/usr/lib");
    char exe[4096] = {};
    ssize_t n = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
    if (n > 0) {
        exe[n] = '\0';
        candidates.push_back(dirname_of(exe));
    }
    candidates.emplace_back(".");

    for (const auto& dir : candidates) {
        if (file_exists(dir + "/layoutlib_jni.so") &&
            file_exists(dir + "/libandroid_runtime.so")) {
            return dir;
        }
    }
    return candidates.front();
}

static bool check_sym(void* handle, const char* lib_label, const char* sym) {
    dlerror();
    void* addr = dlsym(handle, sym);
    const char* err = dlerror();
    if (!addr || err) {
        std::fprintf(stderr, "[FAIL] dlsym(%s, %s): %s\n", lib_label, sym, err ? err : "null");
        return false;
    }
    std::printf("  [ok] %-22s -> %-48s @ %p\n", lib_label, sym, addr);
    return true;
}

int main(int argc, char** argv) {
    std::string dir = pick_lib_dir(argc, argv);
    std::string jni_path = dir + "/layoutlib_jni.so";
    std::string rt_path = dir + "/libandroid_runtime.so";

    std::printf("=== Termux Bionic Layoutlib Native Probe ===\n");
    std::printf("Target lib dir : %s\n", dir.c_str());

    if (!file_exists(rt_path) || !file_exists(jni_path)) {
        std::fprintf(stderr, "[FAIL] Missing shared libraries in %s\n", dir.c_str());
        return 1;
    }

    // Load layoutlib_jni.so directly first to exercise DT_RUNPATH=$ORIGIN -> libandroid_runtime.so
    dlerror();
    void* h_jni = dlopen(jni_path.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (!h_jni) {
        std::fprintf(stderr, "[FAIL] dlopen(%s, RTLD_NOW): %s\n", jni_path.c_str(), dlerror());
        return 2;
    }
    std::printf("[ok] dlopen(layoutlib_jni.so, RTLD_NOW) succeeded (resolved libandroid_runtime.so via $ORIGIN)\n");

    void* h_rt = dlopen(rt_path.c_str(), RTLD_NOW | RTLD_NOLOAD);
    if (!h_rt) {
        h_rt = dlopen(rt_path.c_str(), RTLD_NOW | RTLD_GLOBAL);
        if (!h_rt) {
            std::fprintf(stderr, "[FAIL] dlopen(%s): %s\n", rt_path.c_str(), dlerror());
            dlclose(h_jni);
            return 3;
        }
    } else {
        std::printf("[ok] libandroid_runtime.so already resident via DT_NEEDED + $ORIGIN\n");
    }

    bool ok = true;
    ok &= check_sym(h_jni, "layoutlib_jni.so", "JNI_OnLoad");
    ok &= check_sym(h_jni, "layoutlib_jni.so", "JNI_OnUnload");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "JNI_OnLoad");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "ANativeWindow_acquire");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "ANativeWindow_release");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "ANativeWindow_getWidth");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "ANativeWindow_getHeight");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "ANativeWindow_getFormat");
    ok &= check_sym(h_rt, "libandroid_runtime.so",
                    "_ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEEb");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "_ZN7android14AndroidRuntime9getJNIEnvEv");
    ok &= check_sym(h_rt, "libandroid_runtime.so", "_ZTIN7android14AndroidRuntimeE");

    dlclose(h_jni);
    dlclose(h_rt);

    if (!ok) {
        return 4;
    }
    std::printf("[PASS] Native Bionic dynamic link + RTTI + ANativeWindow + BufferQueue symbol verification passed.\n");
    return 0;
}
