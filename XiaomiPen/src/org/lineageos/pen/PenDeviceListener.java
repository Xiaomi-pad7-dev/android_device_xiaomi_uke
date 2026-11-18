/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */
package org.lineageos.pen;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.hardware.input.InputManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.SparseArray;
import android.util.SparseIntArray;
import android.view.InputDevice;

import java.util.function.Consumer;

/*
 * Sets up a Focus Pen Pro (PenMipp, PenReports) or Focus Pen
 * (PenInitializationManager) when its input device shows up.
 */
final class PenDeviceListener implements InputManager.InputDeviceListener {

    private static final String TAG = "XiaomiPen";

    private static final int PEN_CONNECTED = 0x10;

    private final Context mContext;
    private final InputManager mInputManager;
    private final BluetoothAdapter mAdapter;
    private final PenMipp mMipp;
    private final PenReports mReports = new PenReports();
    private final Handler mHandler = new Handler(Looper.getMainLooper());

    // input device id -> pen version
    private final SparseIntArray mPens = new SparseIntArray();
    // input device id -> pen type (PRO or NORMAL)
    private final SparseArray<PenSwitcher.PenType> mPenTypes = new SparseArray<>();

    private PenInitializationManager mNormalPenInit;

    private Consumer<Boolean> mConnectionListener = connected -> {};

    PenDeviceListener(Context context) {
        mContext = context;
        mInputManager = context.getSystemService(InputManager.class);
        mAdapter = context.getSystemService(BluetoothManager.class).getAdapter();
        mMipp = new PenMipp(context);

        // A double press buzzes the pen, as on stock.
        mReports.setOnDoublePress(mMipp::sendGestureHaptic);
    }

    /** Called with true when the first pen connects and false when the last one goes. */
    void setConnectionListener(Consumer<Boolean> listener) {
        mConnectionListener = listener;
    }

    void onDockChanged(boolean docked) {
        mMipp.setDocked(docked);
    }

    void start() {
        mMipp.start();
        mInputManager.registerInputDeviceListener(this, mHandler);

        for (int id : mInputManager.getInputDeviceIds()) {
            onInputDeviceAdded(id);
        }
    }

    @Override
    public void onInputDeviceAdded(int deviceId) {
        InputDevice device = mInputManager.getInputDevice(deviceId);
        if (device == null || mPens.indexOfKey(deviceId) >= 0) {
            return;
        }

        if (device.getName() != null && device.getName().contains("remapped")) return;
        int version = getPenVersion(device.getVendorId(), device.getProductId());
        if (version == 0) {
            return;
        }

        boolean alreadyConnected = mPens.size() > 0;
        mPens.put(deviceId, version);
        String address = device.getBluetoothAddress();
        String name = device.getName();

        PenSwitcher.PenType type =
                PenSwitcher.detectPenType(
                        address, name, device.getVendorId(), device.getProductId());
        mPenTypes.put(deviceId, type);

        if (alreadyConnected) return;
        mConnectionListener.accept(true);
        Log.i(
                TAG,
                "Pen "
                        + name
                        + " connected (addr="
                        + address
                        + "), version "
                        + version
                        + ", type="
                        + type);
        TouchFeature.setModeValue(TouchFeature.MODE_PEN_CONNECTION, version | PEN_CONNECTED);

        if (type == PenSwitcher.PenType.PRO) {
            Log.i(TAG, "Setting up Focus Pen Pro");
            BluetoothDevice btDev = null;
            if (address != null && mAdapter != null) {
                btDev = mAdapter.getRemoteDevice(address);
            } else if (mAdapter != null) {
                btDev = findBondedProPen(mAdapter);
            }
            if (btDev != null) {
                boolean activeStateFirst =
                        device.getVendorId() == 0x0022 && device.getProductId() == 0x5081;
                mMipp.connect(btDev, activeStateFirst);
            }
            mReports.start();
        } else {
            Log.i(TAG, "Setting up Focus Pen");
            BluetoothDevice btDev = null;
            if (address != null && mAdapter != null) {
                btDev = mAdapter.getRemoteDevice(address);
            } else if (mAdapter != null) {
                btDev = findBondedNormalPen(mAdapter);
            }

            if (btDev != null) {
                String tabletMac = null;
                if (mAdapter != null) {
                    try {
                        tabletMac = mAdapter.getAddress();
                    } catch (Exception ignored) {
                    }
                }
                if (tabletMac == null
                        || tabletMac.isEmpty()
                        || "02:00:00:00:00:00".equals(tabletMac)) {
                    try {
                        tabletMac =
                                android.provider.Settings.Secure.getString(
                                        mContext.getContentResolver(), "bluetooth_address");
                    } catch (Exception ignored) {
                    }
                }
                if (mNormalPenInit != null) {
                    mNormalPenInit.stop();
                }
                mNormalPenInit =
                        new PenInitializationManager(
                                mContext,
                                btDev,
                                tabletMac,
                                new PenInitializationManager.Callback() {
                                    @Override
                                    public void onSetTouchMode(int mode, int value) {
                                        TouchFeature.setModeValue(mode, value);
                                    }

                                    @Override
                                    public void onInitialized() {
                                        Log.i(
                                                TAG,
                                                "Focus Pen GATT init complete");
                                    }
                                });
                mNormalPenInit.start();
            }
            mReports.start();
        }
    }

    @Override
    public void onInputDeviceRemoved(int deviceId) {
        int index = mPens.indexOfKey(deviceId);
        if (index < 0) {
            return;
        }

        int version = mPens.valueAt(index);
        PenSwitcher.PenType type = mPenTypes.get(deviceId, PenSwitcher.PenType.NORMAL);
        mPens.removeAt(index);
        mPenTypes.remove(deviceId);
        if (mPens.size() > 0) return;
        mConnectionListener.accept(false);
        Log.i(TAG, "Pen disconnected, version " + version + ", type=" + type);
        TouchFeature.setModeValue(TouchFeature.MODE_PEN_CONNECTION, version);

        if (type == PenSwitcher.PenType.PRO) {
            if (mPens.size() == 0) {
                mMipp.disconnect();
                mReports.stop();
            }
        } else {
            if (mNormalPenInit != null) {
                mNormalPenInit.stop();
                mNormalPenInit = null;
            }
            if (mPens.size() == 0) {
                mReports.stop();
            }
            TouchFeature.setModeValue(TouchFeature.MODE_PEN_READY, 0);
        }

    }

    @Override
    public void onInputDeviceChanged(int deviceId) {}

    private BluetoothDevice findBondedProPen(BluetoothAdapter adapter) {
        if (adapter == null) return null;
        for (BluetoothDevice dev : adapter.getBondedDevices()) {
            String name = dev.getName();
            if (name != null && name.contains("Focus Pen Pro")) {
                return dev;
            }
        }
        return null;
    }

    private BluetoothDevice findBondedNormalPen(BluetoothAdapter adapter) {
        if (adapter == null) return null;
        for (BluetoothDevice dev : adapter.getBondedDevices()) {
            String name = dev.getName();
            String addr = dev.getAddress();
            if (PenSwitcher.detectPenType(addr, name, 0, 0) == PenSwitcher.PenType.NORMAL) {
                return dev;
            }
        }
        return null;
    }

    private static int getPenVersion(int vendorId, int productId) {
        if (vendorId == 0x1915) {
            switch (productId) {
                case 0xeaea:
                    return 1;
                case 0x4d81:
                    return 2;
            }
        } else if (vendorId == 0x0022) {
            switch (productId) {
                case 0x3280:
                case 0x3281:
                case 0x4d80:
                    return 3;
                case 0x4e83:
                    return 4;
                case 0x3183:
                    return 5;
                case 0x3283:
                    return 6;
                case 0x4f84:
                    return 7;
                case 0x5081:
                    return 8;
            }
        }
        return 0;
    }
}
