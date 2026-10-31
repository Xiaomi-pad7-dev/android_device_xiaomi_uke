/*
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.pixelos.stylus;

import android.hardware.input.InputManager;
import android.os.SystemClock;
import android.os.SystemProperties;
import android.util.Log;
import android.view.KeyEvent;

/*
 * Runs the action bound to a pen gesture.
 *
 * HyperOS did this in system_server: MiuiStylusTouchFilmManager read the keys
 * the pen keyboard produced and, depending on the user's stylus setting, either
 * let the key through or performed an action itself.  This app already runs as
 * android.uid.system, so it can do the same job without a second daemon.
 *
 * The keylayout keeps one distinct key per gesture (pinch BUTTON_7, double
 * press BUTTON_8, swipes BUTTON_9/BUTTON_10), so an app that implements
 * BUTTON_7 still receives it untouched.  Apps that only implement the
 * double-press key get the action injected instead - StarNote is such an app:
 * on this ROM it acts on BUTTON_8 and ignores BUTTON_7, which is why a pinch
 * did nothing while a double press toggled the tool.
 *
 * persist.pen.pinch_action selects the behaviour:
 *   toggle       (default) inject BUTTON_8, i.e. the brush/eraser switch
 *   none         swallow the gesture, do nothing
 *   passthrough  rely on the BUTTON_7 key only and let the app decide
 */
final class PenGestureAction {

    private static final String TAG = "XiaomiStylus";

    private static final String PROP_PINCH_ACTION = "persist.pen.pinch_action";

    private static final String MODE_TOGGLE = "toggle";
    private static final String MODE_NONE = "none";
    private static final String MODE_PASSTHROUGH = "passthrough";

    /* What the brush/eraser switch is bound to on this pen */
    private static final int KEYCODE_TOGGLE_TOOL = KeyEvent.KEYCODE_BUTTON_8;

    void onPinch() {
        String mode = SystemProperties.get(PROP_PINCH_ACTION, MODE_TOGGLE);
        if (MODE_NONE.equals(mode) || MODE_PASSTHROUGH.equals(mode)) {
            Log.i(TAG, "Pinch seen, action is " + mode + ", leaving it to the app");
            return;
        }

        Log.i(TAG, "Pinch seen, injecting the brush/eraser toggle");
        injectKey(KEYCODE_TOGGLE_TOOL);
    }

    private static void injectKey(int keyCode) {
        long now = SystemClock.uptimeMillis();
        InputManager inputManager = InputManager.getInstance();

        // deviceId -1 and source 0 mirror the `input keyevent` path, which is
        // the only injection route the apps we tested accept.
        KeyEvent down = new KeyEvent(now, now, KeyEvent.ACTION_DOWN, keyCode,
                0, 0, -1, 0, 0);
        KeyEvent up = new KeyEvent(now, now, KeyEvent.ACTION_UP, keyCode,
                0, 0, -1, 0, 0);

        inputManager.injectInputEvent(down, InputManager.INJECT_INPUT_EVENT_MODE_ASYNC);
        inputManager.injectInputEvent(up, InputManager.INJECT_INPUT_EVENT_MODE_ASYNC);
    }
}
