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
    private PenRefreshRate mRefreshRate;

    @Override
    public void onCreate() {
        super.onCreate();

        mRefreshRate = new PenRefreshRate(this);
        mRefreshRate.start();

        mDeviceListener = new PenDeviceListener(this);
        mDeviceListener.setConnectionListener(mRefreshRate::onConnectionChanged);
        mDeviceListener.start();

        mPairing = new PenPairing(this, docked -> {
            mDeviceListener.onDockChanged(docked);
            mRefreshRate.onDockChanged(docked);
        });
        mPairing.start();
    }
}
