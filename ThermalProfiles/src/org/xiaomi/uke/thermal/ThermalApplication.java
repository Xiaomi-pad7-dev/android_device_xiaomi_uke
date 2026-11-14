/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.xiaomi.uke.thermal;

import android.app.Application;

public class ThermalApplication extends Application {

    private ThermalSceneController mController;

    @Override
    public void onCreate() {
        super.onCreate();
        mController = new ThermalSceneController(this);
        mController.start();
    }
}
