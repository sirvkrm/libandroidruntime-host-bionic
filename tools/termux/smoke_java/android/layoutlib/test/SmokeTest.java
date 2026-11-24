package android.layoutlib.test;

import android.os.SystemProperties;
import android.util.Log;
import java.io.File;

public class SmokeTest {
    public static void main(String[] args) {
        String libDir = args.length > 0 ? args[0] : "/data/data/com.termux/files/usr/lib/layoutlib";
        File jniSo = new File(libDir, "layoutlib_jni.so");
        if (!jniSo.isFile()) {
            throw new IllegalStateException("Missing " + jniSo.getAbsolutePath());
        }

        System.setProperty("core_native_classes", "android.os.SystemProperties,android.util.Log");
        System.setProperty("graphics_native_classes", "");
        System.setProperty("method_binding_format", "");
        System.setProperty("use_base_native_hostruntime", "false");

        System.out.println("Loading " + jniSo.getAbsolutePath() + " via System.load()...");
        System.load(jniSo.getAbsolutePath());
        System.out.println("[ok] JNI_OnLoad succeeded in both layoutlib_jni.so and libandroid_runtime.so");

        String sdk = SystemProperties.native_get("ro.build.version.sdk", "MISSING");
        if (!"36".equals(sdk)) {
            throw new AssertionError("Expected ro.build.version.sdk=36, got " + sdk);
        }
        System.out.println("[ok] Bridge.setSystemProperties -> ro.build.version.sdk=" + sdk);

        SystemProperties.native_set("ro.termux.layoutlib", "bionic_host_verified");
        String roundtrip = SystemProperties.native_get("ro.termux.layoutlib", "MISSING");
        if (!"bionic_host_verified".equals(roundtrip)) {
            throw new AssertionError("SystemProperties roundtrip failed: " + roundtrip);
        }
        System.out.println("[ok] In-process HostProperties ro.* set/get verified: " + roundtrip);

        int maxPayload = Log.logger_entry_max_payload_native();
        Log.println_native(0, Log.INFO, "LayoutlibSmokeTest", "Host Bionic JNI Log test ok (maxPayload=" + maxPayload + ")");
        System.out.println("[ok] android.util.Log JNI call succeeded (maxPayload=" + maxPayload + ")");
        System.out.println("[PASS] JVM <-> layoutlib_jni.so <-> libandroid_runtime.so live JNI test passed!");
    }
}
