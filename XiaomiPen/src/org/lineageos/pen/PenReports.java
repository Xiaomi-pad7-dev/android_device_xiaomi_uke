/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */
package org.lineageos.pen;

import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;

/*
 * The Focus Pen Pro measures tip pressure itself and sends it over
 * Bluetooth as HID report 5, next to the transmit frequencies it uses.
 * The touch firmware needs that report to tell contact from hover, so
 * pass every report on to the touch HAL the way stock does.
 *
 * Report 2 (and 1) carries the pen keyboard usages, i.e. gestures and button events:
 * - Focus Pen Pro: 0xbd (pinch), 0x58 (double press), 0x57 (swipe up), 0x51 (swipe down)
 * - Normal Focus Pen: 0x4b (page up), 0x4e (page down)
 */
final class PenReports {

    private static final String TAG = "XiaomiPen";

    private static final String HIDRAW_CLASS = "/sys/class/hidraw";
    // hidraw nodes link to their HID device, named bus:vendor:product.instance
    // 0005:0022: matches both Focus Pen Pro (5081) and Normal Focus Pen (4d80)
    private static final String PEN_HID_PREFIX = "0005:0022:";

    private static final int REPORT_KEYBOARD = 1;
    private static final int REPORT_GESTURES = 2;
    private static final int REPORT_PRESSURE = 5;
    private static final int REPORT_PRESSURE_LEN = 15;
    private static final int MODE_PEN_PRESSURE = 1088;

    /*
     * HID keyboard usages.
     */
    private static final int USAGE_PINCH = 0xbd;
    private static final int USAGE_DOUBLE_PRESS = 0x58;
    private static final int USAGE_SWIPE_UP = 0x57;
    private static final int USAGE_SWIPE_DOWN = 0x51;
    private static final int USAGE_PAGE_UP = 0x4b;
    private static final int USAGE_PAGE_DOWN = 0x4e;

    private Runnable mOnPinch;
    private Runnable mOnPinchRelease;
    private Runnable mOnDoublePress;
    private Runnable mOnSwipeUp;
    private Runnable mOnSwipeDown;
    private Runnable mOnPageUp;
    private Runnable mOnPageDown;

    private boolean mPinchDown;
    private boolean mDoublePressDown;
    private boolean mSwipeUpDown;
    private boolean mSwipeDownDown;
    private boolean mPageUpDown;
    private boolean mPageDownDown;

    private Thread mThread;

    void setOnPinch(Runnable callback) {
        mOnPinch = callback;
    }

    void setOnPinchRelease(Runnable callback) {
        mOnPinchRelease = callback;
    }

    void setOnDoublePress(Runnable callback) {
        mOnDoublePress = callback;
    }

    void setOnSwipeUp(Runnable callback) {
        mOnSwipeUp = callback;
    }

    void setOnSwipeDown(Runnable callback) {
        mOnSwipeDown = callback;
    }

    void setOnPageUp(Runnable callback) {
        mOnPageUp = callback;
    }

    void setOnPageDown(Runnable callback) {
        mOnPageDown = callback;
    }

    synchronized void start() {
        if (mThread != null && mThread.isAlive()) {
            return;
        }

        String node = findPenNode();
        if (node == null) {
            Log.w(TAG, "No hidraw node for the pen");
            return;
        }

        mThread = new Thread(() -> forward(node), "PenReports");
        mThread.start();
    }

    synchronized void stop() {
        if (mThread != null) {
            mThread.interrupt();
            mThread = null;
        }
    }

    private static String findPenNode() {
        File[] nodes = new File(HIDRAW_CLASS).listFiles();
        if (nodes == null) {
            return null;
        }

        for (File node : nodes) {
            try {
                String target = Files.readSymbolicLink(node.toPath()).toString().toLowerCase();
                if (target.contains("0005:0022:")) {
                    return "/dev/" + node.getName();
                }
            } catch (IOException e) {
                Log.w(TAG, "Failed to read " + node, e);
            }
        }
        return null;
    }

    /**
     * Reports hold the gesture and button usages. Only act once per gesture rather than on every
     * report the pen sends while held.
     */
    private void handleGestureReport(byte[] buf, int len) {
        boolean pinch = containsUsage(buf, len, USAGE_PINCH);
        boolean doublePress = containsUsage(buf, len, USAGE_DOUBLE_PRESS);
        boolean swipeUp = containsUsage(buf, len, USAGE_SWIPE_UP);
        boolean swipeDown = containsUsage(buf, len, USAGE_SWIPE_DOWN);
        boolean pageUp = containsUsage(buf, len, USAGE_PAGE_UP);
        boolean pageDown = containsUsage(buf, len, USAGE_PAGE_DOWN);

        if (pinch && !mPinchDown) {
            Log.i(TAG, "Pinch gesture detected");
            fire(mOnPinch);
        }
        if (!pinch && mPinchDown) fire(mOnPinchRelease);
        mPinchDown = pinch;

        if (doublePress && !mDoublePressDown) {
            Log.i(TAG, "Double press detected");
            fire(mOnDoublePress);
        }
        mDoublePressDown = doublePress;

        if (swipeUp && !mSwipeUpDown) {
            Log.i(TAG, "Swipe up detected");
            fire(mOnSwipeUp);
        }
        mSwipeUpDown = swipeUp;

        if (swipeDown && !mSwipeDownDown) {
            Log.i(TAG, "Swipe down detected");
            fire(mOnSwipeDown);
        }
        mSwipeDownDown = swipeDown;

        if (pageUp && !mPageUpDown) {
            Log.i(TAG, "Page up detected");
            fire(mOnPageUp);
        }
        mPageUpDown = pageUp;

        if (pageDown && !mPageDownDown) {
            Log.i(TAG, "Page down detected");
            fire(mOnPageDown);
        }
        mPageDownDown = pageDown;
    }

    private static boolean containsUsage(byte[] buf, int len, int usage) {
        for (int i = 1; i < len; i++) {
            if ((buf[i] & 0xff) == usage) {
                return true;
            }
        }
        return false;
    }

    private static void fire(Runnable callback) {
        if (callback != null) {
            callback.run();
        }
    }

    private void forward(String node) {
        Log.i(TAG, "Forwarding pen reports from " + node);
        byte[] buf = new byte[64];
        try (FileInputStream in = new FileInputStream(node)) {
            while (!Thread.currentThread().isInterrupted()) {
                int len = in.read(buf);
                if (len < 0) {
                    break;
                }

                if (buf[0] == REPORT_KEYBOARD || buf[0] == REPORT_GESTURES) {
                    handleGestureReport(buf, len);
                    continue;
                }

                if (len != REPORT_PRESSURE_LEN || buf[0] != REPORT_PRESSURE) {
                    continue;
                }

                int[] report = new int[len];
                for (int i = 0; i < len; i++) {
                    report[i] = buf[i] & 0xff;
                }
                TouchFeature.setModeLongValue(MODE_PEN_PRESSURE, report);
            }
        } catch (IOException e) {
            Log.i(TAG, "Pen reports stopped: " + e.getMessage());
        }
    }
}
