package android.os;

public class SystemProperties {
    public static native String native_get(String key, String def);
    public static native int native_get_int(String key, int def);
    public static native long native_get_long(String key, long def);
    public static native boolean native_get_boolean(String key, boolean def);
    public static native long native_find(String name);
    public static native String native_get(long handle);
    public static native int native_get_int(long handle, int def);
    public static native long native_get_long(long handle, long def);
    public static native boolean native_get_boolean(long handle, boolean def);
    public static native void native_set(String key, String val);
    public static native void native_add_change_callback();
    public static native void native_report_sysprop_change();

    public static void callChangeCallbacks() {
    }
}
