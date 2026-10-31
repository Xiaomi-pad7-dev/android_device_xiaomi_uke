package miui.hardware.input;

/**
 * Stub of MIUI's input manager.
 *
 * TouchService reflectively obtains getInstance() and calls
 * enableStylusTouchFilmForApp / enableStylusPostureForApp to tell the MIUI input
 * stack which app is currently drawing. LineageOS has no touch-film pipeline, so
 * these are no-ops that only record state.
 */
public class MiuiInputManager {

    private static final MiuiInputManager INSTANCE = new MiuiInputManager();

    private String touchFilmPackage;
    private boolean touchFilmEnabled;
    private String posturePackage;
    private boolean postureEnabled;

    private MiuiInputManager() {
    }

    public static MiuiInputManager getInstance() {
        return INSTANCE;
    }

    public void enableStylusTouchFilmForApp(String packageName, boolean enable) {
        this.touchFilmPackage = packageName;
        this.touchFilmEnabled = enable;
    }

    public void enableStylusPostureForApp(String packageName, boolean enable) {
        this.posturePackage = packageName;
        this.postureEnabled = enable;
    }

    public String getTouchFilmPackage() {
        return touchFilmPackage;
    }

    public boolean isTouchFilmEnabled() {
        return touchFilmEnabled;
    }

    public String getPosturePackage() {
        return posturePackage;
    }

    public boolean isPostureEnabled() {
        return postureEnabled;
    }
}
