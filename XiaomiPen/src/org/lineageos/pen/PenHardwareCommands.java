/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.pen;

/** Validated MIPP payloads shared by reconnect and live configuration. */
final class PenHardwareCommands {
    static byte[] pinchThresholds(int grams) {
        int down = Math.max(90, Math.min(450, Math.round(grams / 90f) * 90));
        int up = down / 2;
        return new byte[] {
            0x5c, 0x04, (byte) (down >> 8), (byte) down, (byte) (up >> 8), (byte) up
        };
    }

    static byte[] pinchResistance(int level) {
        return new byte[] {0x5a, 0x02, (byte) Math.max(1, Math.min(5, level)), 0x00};
    }
}
