package miui.os;

/**
 * Stub of Xiaomi's HyperOS feature-flag resolver for LineageOS.
 *
 * com.xiaomi.touchservice resolves this class reflectively and asks
 * getBoolean("support_pencil_engine", false); if that throws or returns false,
 * PencilEngineManagerService rejects every client with
 * "Binding request rejected, not support this device".
 */
public class HyperOSCustFeatureResolve {

    public static boolean getBoolean(String key, boolean defValue) {
        if (key == null) {
            return defValue;
        }
        // The pen engine is exactly what we are bringing up.
        if ("support_pencil_engine".equals(key)) {
            return true;
        }
        // Everything else keeps the caller's default so we do not silently
        // enable unrelated touch features (game turbo, sensorhub, MQS...).
        return defValue;
    }

    public static int getInt(String key, int defValue) {
        return defValue;
    }

    public static long getLong(String key, long defValue) {
        return defValue;
    }

    public static String getString(String key, String defValue) {
        return defValue;
    }
}
