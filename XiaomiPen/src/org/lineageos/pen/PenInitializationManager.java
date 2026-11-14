/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-FileCopyrightText: 2026 Yet Another AOSP Project
 * SPDX-License-Identifier: Apache-2.0
 */
package org.lineageos.pen;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.ArrayDeque;
import java.util.Queue;
import java.util.UUID;

@SuppressLint("MissingPermission")
public class PenInitializationManager {
    private static final String TAG = "XiaomiPen";

    private static final UUID SERVICE_UUID = UUID.fromString("0000fe10-aa6c-462a-964a-7f2ed5b3e512");
    private static final UUID WRITE_CHAR_UUID = UUID.fromString("0000fe11-aa6c-462a-964a-7f2ed5b3e512");
    private static final UUID NOTIFY_CHAR_UUID = UUID.fromString("0000fe12-aa6c-462a-964a-7f2ed5b3e512");
    private static final UUID DESCRIPTOR_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    private final Context mContext;
    private final BluetoothDevice mDevice;
    private final String mTabletMacAddress;
    private final Handler mHandler = new Handler(Looper.getMainLooper());

    private BluetoothGatt mGatt;
    private int mCurrentState = 0;
    private byte mW0 = 0x00;
    private boolean mIsInitialized = false;

    private final Queue<byte[]> mWriteQueue = new ArrayDeque<>();
    private boolean mIsWriting = false;

    public interface Callback {
        void onSetTouchMode(int mode, int value);
        void onInitialized();
    }

    private final Callback mCallback;

    public PenInitializationManager(Context context, BluetoothDevice device, String tabletMacAddress, Callback callback) {
        mContext = context;
        mDevice = device;
        mTabletMacAddress = tabletMacAddress != null ? tabletMacAddress : "00:00:00:00:00:00";
        mCallback = callback;
    }

    public void start() {
        Log.i(TAG, "Starting Normal Focus Pen GATT connection to " + mDevice.getAddress());
        mCurrentState = 0;
        mGatt = mDevice.connectGatt(mContext, false, mGattCallback, BluetoothDevice.TRANSPORT_LE);
    }

    public void stop() {
        Log.i(TAG, "Stopping Normal Focus Pen GATT connection to " + mDevice.getAddress());
        synchronized (this) {
            mWriteQueue.clear();
            mIsWriting = false;
        }
        if (mGatt != null) {
            mGatt.disconnect();
            mGatt.close();
            mGatt = null;
        }
        mIsInitialized = false;
        mCurrentState = 0;
    }

    public boolean isReady() {
        return mIsInitialized && mGatt != null;
    }

    private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.i(TAG, "GATT connected, discovering services...");
                gatt.discoverServices();
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.i(TAG, "GATT disconnected");
                stop();
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                BluetoothGattCharacteristic notifyChar = null;
                var service = gatt.getService(SERVICE_UUID);
                if (service != null) {
                    notifyChar = service.getCharacteristic(NOTIFY_CHAR_UUID);
                }
                if (notifyChar != null) {
                    gatt.setCharacteristicNotification(notifyChar, true);
                    var descriptor = notifyChar.getDescriptor(DESCRIPTOR_UUID);
                    if (descriptor != null) {
                        try {
                            gatt.writeDescriptor(descriptor, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                        } catch (Throwable t) {
                            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                            gatt.writeDescriptor(descriptor);
                        }
                    } else {
                        Log.e(TAG, "Descriptor not found");
                    }
                } else {
                    Log.e(TAG, "Notify characteristic not found");
                }
            } else {
                Log.e(TAG, "Service discovery failed with status: " + status);
            }
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "Notifications enabled on fe12, requesting MTU 512");
                if (!gatt.requestMtu(512)) {
                    Log.w(TAG, "requestMtu(512) returned false, starting state machine directly");
                    mCurrentState = 1;
                    sendNextPayload();
                }
            }
        }

        @Override
        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
            Log.i(TAG, "onMtuChanged: mtu=" + mtu + " status=" + status + ", starting state machine");
            if (mCurrentState == 0) {
                mCurrentState = 1;
                sendNextPayload();
            }
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            handleNotification(characteristic.getValue());
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, byte[] value) {
            handleNotification(value);
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            synchronized (PenInitializationManager.this) {
                mIsWriting = false;
                processQueue();
            }
        }
    };

    private void handleNotification(byte[] value) {
        if (value != null && value.length > 0) {
            int prefix = value[0] & 0xFF;
            if (prefix == 0x84 && value.length >= 3) {
                mW0 = value[2];
                Log.i(TAG, String.format("Assigned ID (w0): %02x", mW0));
            } else if (prefix == 0xD2 && value.length >= 3) {
                int penActiveState = value[2] & 0xFF;
                Log.i(TAG, "Pen active state: " + penActiveState + " — syncing to digitizer");
                if (mCallback != null) mCallback.onSetTouchMode(29, penActiveState);
            } else if (prefix == 0x53 && value.length >= 3) {
                int active = value[2] & 0xFF;
                Log.i(TAG, "Pen activate ACK: " + active + " — enabling pen tracking");
                if (mCallback != null) mCallback.onSetTouchMode(37, 1);
            }
        }

        mCurrentState++;
        sendNextPayload();
    }

    private void sendNextPayload() {
        byte[] payload = null;
        switch (mCurrentState) {
            case 1: payload = new byte[] { 0x52, 0x00 }; break;
            case 2: payload = new byte[] { 0x00, 0x00 }; break;
            case 3: payload = new byte[] { 0x01, 0x00 }; break;
            case 4: payload = new byte[] { 0x02, 0x00 }; break;
            case 5: payload = new byte[] { 0x03, 0x00 }; break;
            case 6: payload = new byte[] { 0x04, 0x00 }; break;
            case 7: payload = buildV4(mW0, mTabletMacAddress); break;
            case 8: payload = buildU4(mW0); break;
            case 9: payload = buildW4(mW0); break;
            case 10: payload = new byte[] { 0x04, 0x00 }; break;
            case 11: payload = buildV4(mW0, mTabletMacAddress); break;
            case 12: payload = buildU4(mW0); break;
            case 13: payload = buildW4(mW0); break;
            case 14: payload = new byte[] { 0x5E, 0x02, 0x00, 0x00 }; break;
            case 15: payload = new byte[] { (byte) 0xDD, 0x00 }; break;
            case 16: payload = new byte[] { 0x51, 0x01, 0x01 }; break;
            default: payload = null; break;
        }

        if (payload != null) {
            writePayload(payload);
        } else if (mCurrentState > 16) {
            Log.i(TAG, "Initialization sequence complete.");
            mIsInitialized = true;
            if (mCallback != null) {
                mCallback.onSetTouchMode(37, 1);
                mCallback.onInitialized();
            }
            setVirtualLaser(false);
        }
    }

    public void setVirtualLaser(boolean enable) {
        Log.i(TAG, "setVirtualLaser: " + enable);
        writePayload(enable ? new byte[] { 0x50, 0x01, 0x01 } : new byte[] { 0x50, 0x01, 0x00 });
    }

    private synchronized boolean writePayload(byte[] payload) {
        if (mGatt == null) return false;
        mWriteQueue.offer(payload);
        processQueue();
        return true;
    }

    private synchronized void processQueue() {
        if (mIsWriting || mWriteQueue.isEmpty() || mGatt == null) return;
        var service = mGatt.getService(SERVICE_UUID);
        if (service == null) return;
        var writeChar = service.getCharacteristic(WRITE_CHAR_UUID);
        if (writeChar == null) return;

        byte[] payload = mWriteQueue.poll();
        if (payload == null) return;

        mIsWriting = true;
        writeChar.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        try {
            mGatt.writeCharacteristic(writeChar, payload, BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        } catch (Throwable t) {
            writeChar.setValue(payload);
            mGatt.writeCharacteristic(writeChar);
        }

        mHandler.postDelayed(() -> {
            synchronized (PenInitializationManager.this) {
                mIsWriting = false;
                processQueue();
            }
        }, 20);
    }

    private byte[] buildV4(byte w0, String mac) {
        byte[] macBytes = new byte[6];
        String cleanMac = mac != null ? mac.replace(":", "") : "";
        if (cleanMac.length() >= 12) {
            for (int i = 0; i < 6; i++) {
                try {
                    macBytes[i] = (byte) Integer.parseInt(cleanMac.substring(i * 2, i * 2 + 2), 16);
                } catch (NumberFormatException ignored) {}
            }
        }
        return new byte[] {
            0x30, 0x1E,
            macBytes[0], macBytes[1], macBytes[2], macBytes[3], macBytes[4], macBytes[5],
            0x03, w0,
            (byte) 0xA0, 0x1E, 0x3E, 0x17, 0x1A, 0x04, 0x1A,
            0x03,
            0x00, 0x00, 0x0D, 0x68, 0x00, 0x00, 0x05, 0x28, 0x00, 0x00, 0x0D, 0x68,
            (byte) 0xF4, 0x01
        };
    }

    private byte[] buildU4(byte w0) {
        return new byte[] {
            0x31, 0x08, w0, 0x03,
            (byte) 0x9B, 0x6F, (byte) 0xEF, 0x43,
            0x28, 0x00
        };
    }

    private byte[] buildW4(byte w0) {
        return new byte[] {
            0x32, 0x03, w0, 0x28, 0x00
        };
    }
}
