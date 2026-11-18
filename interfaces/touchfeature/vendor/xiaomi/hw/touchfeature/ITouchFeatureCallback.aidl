//
// SPDX-FileCopyrightText: 2025 The LineageOS Project
// SPDX-License-Identifier: Apache-2.0
//

package vendor.xiaomi.hw.touchfeature;

@VintfStability
interface ITouchFeatureCallback {
    int callback(int type, int mode, int status, in int[] intValues, in String[] strValues);
}
