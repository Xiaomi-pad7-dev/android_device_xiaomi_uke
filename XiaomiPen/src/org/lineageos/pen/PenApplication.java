/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.pen;

import android.app.Application;

public class PenApplication extends Application {

    private PenDeviceListener mDeviceListener;
    private PenPairing mPairing;

    @Override
    public void onCreate() {
        super.onCreate();

        mDeviceListener = new PenDeviceListener(this);
        mDeviceListener.start();

        mPairing = new PenPairing(this, mDeviceListener::onDockChanged);
        mPairing.start();
    }
}
