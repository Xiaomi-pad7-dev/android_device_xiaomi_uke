/*
 * SPDX-FileCopyrightText: 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.xiaomi.uke.thermal;

import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

public class PerformanceTileService extends TileService {

    @Override
    public void onStartListening() {
        super.onStartListening();
        updateTile();
    }

    @Override
    public void onClick() {
        super.onClick();
        PerformanceMode.setEnabled(this, !PerformanceMode.isEnabled(this));
        updateTile();
    }

    private void updateTile() {
        Tile tile = getQsTile();
        if (tile == null) {
            return;
        }
        boolean enabled = PerformanceMode.isEnabled(this);
        tile.setState(enabled ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        tile.setSubtitle(getString(enabled
                ? R.string.performance_tile_on : R.string.performance_tile_off));
        tile.updateTile();
    }
}
