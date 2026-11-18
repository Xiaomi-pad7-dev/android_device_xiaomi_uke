/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.pen;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.provider.Settings;
import android.util.Log;

/**
 * The Focus Pen only tracks the panel at 60 Hz and 120 Hz, so pin the refresh rate
 * to one of those while a connected pen is off the tablet.
 */
class PenRefreshRate {

    private static final String TAG = "PenRefreshRate";

    private static final String PREFS = "refresh_rate";
    private static final String KEY_MIN = "saved_min";
    private static final String KEY_PEAK = "saved_peak";
    private static final String KEY_PINNED = "pinned";

    private static final float HIGH_RATE = 120f;
    private static final float LOW_RATE = 60f;

    private final ContentResolver mResolver;
    private final SharedPreferences mPrefs;

    // null until the first hall sensor event, treated as docked
    private Boolean mDocked;
    private boolean mConnected;

    PenRefreshRate(Context context) {
        mResolver = context.getContentResolver();
        mPrefs = context.createDeviceProtectedStorageContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    void start() {
        // A pin left behind by a reboot with the pen off goes away until the
        // next undock pins it again.
        restore();
    }

    void onDockChanged(boolean docked) {
        mDocked = docked;
        update();
    }

    void onConnectionChanged(boolean connected) {
        mConnected = connected;
        update();
    }

    private void update() {
        if (mConnected && Boolean.FALSE.equals(mDocked)) {
            pin();
        } else {
            restore();
        }
    }

    private void pin() {
        if (mPrefs.contains(KEY_PINNED)) return;

        float min = Settings.System.getFloat(mResolver, Settings.System.MIN_REFRESH_RATE, 0f);
        float peak = Settings.System.getFloat(mResolver, Settings.System.PEAK_REFRESH_RATE, 0f);
        float rate = (peak == 0f || peak >= HIGH_RATE) ? HIGH_RATE : LOW_RATE;

        mPrefs.edit()
                .putFloat(KEY_MIN, min)
                .putFloat(KEY_PEAK, peak)
                .putFloat(KEY_PINNED, rate)
                .commit();

        Settings.System.putFloat(mResolver, Settings.System.MIN_REFRESH_RATE, rate);
        Settings.System.putFloat(mResolver, Settings.System.PEAK_REFRESH_RATE, rate);
        Log.i(TAG, "Pen in use, pinning the display to " + rate + " Hz");
    }

    private void restore() {
        if (!mPrefs.contains(KEY_PINNED)) return;

        float pinned = mPrefs.getFloat(KEY_PINNED, 0f);
        float min = Settings.System.getFloat(mResolver, Settings.System.MIN_REFRESH_RATE, 0f);
        float peak = Settings.System.getFloat(mResolver, Settings.System.PEAK_REFRESH_RATE, 0f);

        // Leave the settings alone if the user changed them meanwhile.
        if (min == pinned && peak == pinned) {
            Settings.System.putFloat(mResolver, Settings.System.MIN_REFRESH_RATE,
                    mPrefs.getFloat(KEY_MIN, 0f));
            Settings.System.putFloat(mResolver, Settings.System.PEAK_REFRESH_RATE,
                    mPrefs.getFloat(KEY_PEAK, 0f));
            Log.i(TAG, "Restored the refresh rate settings");
        }

        mPrefs.edit().clear().commit();
    }
}
