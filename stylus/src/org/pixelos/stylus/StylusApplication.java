/*
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.pixelos.stylus;

import android.app.Application;
import android.content.ContentResolver;
import android.provider.Settings;

public class StylusApplication extends Application {

    /**
     * Xiaomi pen apps (StarNote, Mi Canvas, ...) only register a listener with
     * com.xiaomi.touchservice when this marker is present, and the version has
     * to be "0.3.2". Without it they bind the service, call triggerFunction
     * before registering, get -1 back and unbind - so no gesture is delivered.
     */
    private static final String KEY_PENCIL_ENGINE_VERSION = "stylus_pencil_engine_version";
    private static final String PENCIL_ENGINE_VERSION = "0.3.2";

    private PenPairing mPenPairing;
    private StylusDeviceListener mStylusDeviceListener;

    @Override
    public void onCreate() {
        super.onCreate();

        ensurePencilEngineVersion();

        mStylusDeviceListener = new StylusDeviceListener(this);
        mStylusDeviceListener.start();

        mPenPairing = new PenPairing(this);
        mPenPairing.start();
    }

    private void ensurePencilEngineVersion() {
        ContentResolver cr = getContentResolver();
        String current = Settings.System.getString(cr, KEY_PENCIL_ENGINE_VERSION);
        if (!PENCIL_ENGINE_VERSION.equals(current)) {
            Settings.System.putString(cr, KEY_PENCIL_ENGINE_VERSION, PENCIL_ENGINE_VERSION);
        }
    }
}
