/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.xiaomi.uke.thermal;

import android.app.ActivityTaskManager;
import android.app.ActivityTaskManager.RootTaskInfo;
import android.app.TaskStackListener;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.database.ContentObserver;
import android.os.Handler;
import android.os.Looper;
import android.os.RemoteException;
import android.util.Log;

import java.io.FileWriter;
import java.io.IOException;
import java.util.Set;

/**
 * Picks the mi_thermald scene for the app in front. The "Performance" Quick
 * Settings tile puts every app on the nolimits scene.
 */
final class ThermalSceneController extends TaskStackListener {

    private static final String TAG = "UkeThermal";

    private static final String SCONFIG = "/sys/class/thermal/thermal_message/sconfig";

    private static final int SCENE_NORMAL = 0;
    // GPU at full clock until 51 degC, then one level down.
    private static final int SCENE_NOLIMITS = 6;
    // GPU capped to level 3 (736 MHz) only past 46 degC.
    private static final int SCENE_MGAME = 19;
    // Same shape as mgame, tuned by Xiaomi for Genshin Impact.
    private static final int SCENE_YUANSHEN = 20;

    private static final String[] BENCHMARK_PREFIXES = {
        "com.futuremark.",   // 3DMark, PCMark
        "com.primatelabs.",  // Geekbench
        "com.antutu.",       // AnTuTu
        "com.glbenchmark.",  // GFXBench
        "net.kishonti.",     // GFXBench
        "com.passmark.",     // PassMark
    };

    private static final Set<String> YUANSHEN_PACKAGES = Set.of(
            "com.miHoYo.GenshinImpact",
            "com.miHoYo.Yuanshen",
            "com.miHoYo.ys.mi",
            "com.miHoYo.ys.bilibili");

    private final Context mContext;
    private final PackageManager mPackageManager;
    private final Handler mHandler = new Handler(Looper.getMainLooper());
    private final Runnable mUpdate = this::update;

    private boolean mScreenOn = true;
    private boolean mPerformanceMode;
    private int mScene = Integer.MIN_VALUE;

    ThermalSceneController(Context context) {
        mContext = context;
        mPackageManager = context.getPackageManager();
    }

    void start() {
        try {
            ActivityTaskManager.getService().registerTaskStackListener(this);
        } catch (RemoteException e) {
            Log.e(TAG, "Failed to register task stack listener", e);
        }

        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        mContext.registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                mScreenOn = Intent.ACTION_SCREEN_ON.equals(intent.getAction());
                update();
            }
        }, filter);

        mPerformanceMode = PerformanceMode.isEnabled(mContext);
        mContext.getContentResolver().registerContentObserver(PerformanceMode.URI, false,
                new ContentObserver(mHandler) {
                    @Override
                    public void onChange(boolean selfChange) {
                        mPerformanceMode = PerformanceMode.isEnabled(mContext);
                        update();
                    }
                });

        update();
    }

    @Override
    public void onTaskStackChanged() {
        mHandler.removeCallbacks(mUpdate);
        mHandler.post(mUpdate);
    }

    private void update() {
        String pkg = mScreenOn ? focusedPackage() : null;
        int scene = sceneFor(pkg);
        if (scene == mScene) {
            return;
        }
        if (writeScene(scene)) {
            Log.i(TAG, "scene " + mScene + " -> " + scene + " (" + pkg + ")");
            mScene = scene;
        }
    }

    private static String focusedPackage() {
        try {
            RootTaskInfo info = ActivityTaskManager.getService().getFocusedRootTaskInfo();
            if (info != null && info.topActivity != null) {
                return info.topActivity.getPackageName();
            }
        } catch (RemoteException e) {
            Log.w(TAG, "Failed to get focused task", e);
        }
        return null;
    }

    private int sceneFor(String pkg) {
        if (pkg == null) {
            return SCENE_NORMAL;
        }
        if (mPerformanceMode) {
            return SCENE_NOLIMITS;
        }
        for (String prefix : BENCHMARK_PREFIXES) {
            if (pkg.startsWith(prefix)) {
                return SCENE_NOLIMITS;
            }
        }
        if (YUANSHEN_PACKAGES.contains(pkg)) {
            return SCENE_YUANSHEN;
        }
        if (isGame(pkg)) {
            return SCENE_MGAME;
        }
        return SCENE_NORMAL;
    }

    @SuppressWarnings("deprecation")
    private boolean isGame(String pkg) {
        try {
            ApplicationInfo ai = mPackageManager.getApplicationInfo(pkg, 0);
            return ai.category == ApplicationInfo.CATEGORY_GAME
                    || (ai.flags & ApplicationInfo.FLAG_IS_GAME) != 0;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private static boolean writeScene(int scene) {
        try (FileWriter writer = new FileWriter(SCONFIG)) {
            writer.write(Integer.toString(scene));
            return true;
        } catch (IOException e) {
            Log.e(TAG, "Failed to write " + SCONFIG, e);
            return false;
        }
    }
}
