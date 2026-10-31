/*
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.pixelos.stylus;

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
 * Report 2 carries the pen keyboard usages, i.e. the four gestures the kernel
 * also exposes as scan codes 189 (pinch), 96 (double press), 73 (swipe up) and
 * 81 (swipe down).  Watch it here to run the gesture feedback and actions that
 * HyperOS used to run in system_server.
 */
final class PenReports {

    private static final String TAG = "XiaomiStylus";

    private static final String HIDRAW_CLASS = "/sys/class/hidraw";
    // hidraw nodes link to their HID device, named bus:vendor:product.instance
    private static final String PEN_HID_ID = "0005:0022:5081.";

    private static final int REPORT_GESTURES = 2;
    private static final int REPORT_PRESSURE = 5;
    private static final int REPORT_PRESSURE_LEN = 15;
    private static final int MODE_PEN_PRESSURE = 1088;

    /*
     * HID keyboard usages, one byte each in report 2. Stock HyperOS buzzes the
     * pen on a double press and never on a pinch, so the two are told apart
     * here rather than in the keylayout.
     */
    private static final int USAGE_PINCH = 0xbd;
    private static final int USAGE_DOUBLE_PRESS = 0x58;

    private Runnable mOnPinch;
    private Runnable mOnDoublePress;

    private boolean mPinchDown;
    private boolean mDoublePressDown;

    private Thread mThread;

    void setOnPinch(Runnable callback) {
        mOnPinch = callback;
    }

    void setOnDoublePress(Runnable callback) {
        mOnDoublePress = callback;
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
                if (Files.readSymbolicLink(node.toPath()).toString().contains(PEN_HID_ID)) {
                    return "/dev/" + node.getName();
                }
            } catch (IOException e) {
                Log.w(TAG, "Failed to read " + node, e);
            }
        }
        return null;
    }

    /**
     * Report 2 holds the gesture usages. Report 2 is sent on press and again
     * with the usage cleared on release, so track the edge and only act once
     * per gesture rather than on every report the pen sends while held.
     */
    private void handleGestureReport(byte[] buf, int len) {
        boolean pinch = containsUsage(buf, len, USAGE_PINCH);
        boolean doublePress = containsUsage(buf, len, USAGE_DOUBLE_PRESS);

        if (pinch && !mPinchDown) {
            Log.i(TAG, "Pinch gesture detected");
            fire(mOnPinch);
        }
        mPinchDown = pinch;

        if (doublePress && !mDoublePressDown) {
            Log.i(TAG, "Double press detected, requesting pen haptic");
            fire(mOnDoublePress);
        }
        mDoublePressDown = doublePress;
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

                if (buf[0] == REPORT_GESTURES) {
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
