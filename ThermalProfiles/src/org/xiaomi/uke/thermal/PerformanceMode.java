/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.xiaomi.uke.thermal;

import android.content.Context;
import android.net.Uri;
import android.provider.Settings;

/** The "Performance" Quick Settings toggle: every app gets the nolimits scene. */
final class PerformanceMode {

    static final String KEY = "uke_thermal_performance_mode";
    static final Uri URI = Settings.Global.getUriFor(KEY);

    private PerformanceMode() {}

    static boolean isEnabled(Context context) {
        return Settings.Global.getInt(context.getContentResolver(), KEY, 0) == 1;
    }

    static void setEnabled(Context context, boolean enabled) {
        Settings.Global.putInt(context.getContentResolver(), KEY, enabled ? 1 : 0);
    }
}
