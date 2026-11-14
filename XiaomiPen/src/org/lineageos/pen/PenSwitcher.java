/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.pen;

public final class PenSwitcher {
    public enum PenType {
        PRO,
        NORMAL,
        NONE
    }

    private PenSwitcher() {}

    /** Classify by advertised hardware identity, never by a particular owner's MAC. */
    public static PenType detectPenType(String address, String name, int vendorId, int productId) {
        if (vendorId == 0x0022 && productId == 0x5081) {
            return PenType.PRO;
        }
        if (name != null && name.toLowerCase(java.util.Locale.ROOT).contains("pen pro")
                || (name != null && name.toLowerCase(java.util.Locale.ROOT).contains("p81c"))) {
            return PenType.PRO;
        }
        if (vendorId == 0x0022 && productId == 0x4D80) {
            return PenType.NORMAL;
        }
        if (name != null
                && (name.toLowerCase().contains("focus pen")
                        || name.toLowerCase().contains("smart pen")
                        || name.toLowerCase().contains("stylus")
                        || (name.toLowerCase().contains("xiaomi")
                                && name.toLowerCase().contains("pen")))) {
            return PenType.NORMAL;
        }
        return PenType.NONE;
    }
}
