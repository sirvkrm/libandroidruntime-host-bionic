package com.android.layoutlib.bridge;

import android.os.SystemProperties;
import android.view.InputDevice;
import com.android.ide.common.rendering.api.ILayoutLog;

public class Bridge {
    private static final ILayoutLog sLog = new ILayoutLog() {};

    public static ILayoutLog getLog() {
        return sLog;
    }

    public static void setSystemProperties() {
        SystemProperties.native_set("ro.icu.data.path", System.getProperty("icu.data.path", ""));
        SystemProperties.native_set("ro.hyphen.data.dir", "");
        SystemProperties.native_set("ro.keyboard.paths", "");
        SystemProperties.native_set("ro.build.version.sdk", "36");
    }

    public static void setInputManager(InputDevice[] devices) {
    }
}
