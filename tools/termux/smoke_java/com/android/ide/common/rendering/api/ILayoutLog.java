package com.android.ide.common.rendering.api;

public interface ILayoutLog {
    default void logAndroidFramework(int priority, String tag, String message) {
        System.out.println("[FrameworkLog p=" + priority + " " + tag + "] " + message);
    }
}
