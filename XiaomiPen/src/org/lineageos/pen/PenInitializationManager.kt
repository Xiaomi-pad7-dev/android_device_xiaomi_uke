package org.lineageos.pen

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.util.Log
import java.util.UUID

@SuppressLint("MissingPermission")
class PenInitializationManager(
    private val context: Context,
    private val device: BluetoothDevice,
    private val tabletMacAddress: String,
    private val onSetTouchMode: (Int, Int) -> Unit
) {
    private var bluetoothGatt: BluetoothGatt? = null
    private var currentState = 0
    private var w0: Byte = 0x00

    fun start() {
        Log.i(TAG, "Starting GATT connection to ${device.address}")
        bluetoothGatt = device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
    }

    fun stop() {
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.i(TAG, "GATT connected, discovering services...")
                gatt.discoverServices()
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.i(TAG, "GATT disconnected")
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                val service = gatt.getService(SERVICE_UUID)
                if (service != null) {
                    val notifyChar = service.getCharacteristic(NOTIFY_CHAR_UUID)
                    if (notifyChar != null) {
                        gatt.setCharacteristicNotification(notifyChar, true)
                        val descriptor = notifyChar.getDescriptor(DESCRIPTOR_UUID)
                        if (descriptor != null) {
                            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                            gatt.writeDescriptor(descriptor)
                        } else {
                            Log.e(TAG, "Descriptor not found")
                        }
                    } else {
                        Log.e(TAG, "Notify characteristic not found")
                    }
                } else {
                    Log.e(TAG, "Service not found")
                }
            }
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.i(TAG, "Notifications enabled, starting state machine")
                currentState = 1
                sendNextPayload()
            }
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            val value = characteristic.value
            Log.d(TAG, "Received notification: ${value.joinToString("") { "%02x".format(it) }}")
            
            if (value.isNotEmpty()) {
                val prefix = value[0].toInt() and 0xFF
                if (prefix == 0x84 && value.size >= 3) {
                    w0 = value[2]
                    Log.i(TAG, "Assigned ID (w0): ${"%02x".format(w0)}")
                } else if (prefix == 0xD2 && value.size >= 3) {
                    val penActiveState = value[2].toInt() and 0xFF
                    Log.i(TAG, "Pen active state: $penActiveState — syncing to digitizer")
                    onSetTouchMode(29, penActiveState)
                } else if (prefix == 0x53 && value.size >= 3) {
                    val active = value[2].toInt() and 0xFF
                    Log.i(TAG, "Pen activate ACK: $active — enabling pen tracking")
                    onSetTouchMode(37, if (active == 1) 1 else 1) // Force 1 to match the user's fallback behavior
                }
            }

            // Acknowledge received, advance state
            currentState++
            sendNextPayload()
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                Log.e(TAG, "Failed to write characteristic, status: $status")
            }
        }
    }

    private fun sendNextPayload() {
        val payload = when (currentState) {
            1 -> byteArrayOf(0x52, 0x00) // 2023
            2 -> byteArrayOf(0x00, 0x00) // 2001
            3 -> byteArrayOf(0x01, 0x00) // 2002
            4 -> byteArrayOf(0x02, 0x00) // 2003
            5 -> byteArrayOf(0x03, 0x00) // 2004
            6 -> byteArrayOf(0x04, 0x00) // 2005 (Assign ID 1)
            7 -> buildV4(w0, tabletMacAddress) // 2006
            8 -> buildU4(w0) // 2007
            9 -> buildW4(w0) // 2008
            10 -> byteArrayOf(0x04, 0x00) // 2005 (Assign ID 2)
            11 -> buildV4(w0, tabletMacAddress) // 2006
            12 -> buildU4(w0) // 2007
            13 -> buildW4(w0) // 2008
            14 -> byteArrayOf(0x5E, 0x02, 0x00, 0x00) // 2020
            15 -> byteArrayOf(0xDD.toByte(), 0x00) // 2024
            16 -> byteArrayOf(0x51, 0x01, 0x01) // s4 (ACTIVATE)
            else -> null
        }

        if (payload != null) {
            val service = bluetoothGatt?.getService(SERVICE_UUID)
            val writeChar = service?.getCharacteristic(WRITE_CHAR_UUID)
            if (writeChar != null) {
                Log.d(TAG, "Sending state $currentState payload: ${payload.joinToString("") { "%02x".format(it) }}")
                writeChar.value = payload
                bluetoothGatt?.writeCharacteristic(writeChar)
            }
        } else {
            Log.i(TAG, "Initialization sequence complete.")
            // Just in case we missed 0x53, ensure tracking is on
            onSetTouchMode(37, 1)
        }
    }

    private fun buildV4(w0: Byte, mac: String): ByteArray {
        val macBytes = mac.replace(":", "").chunked(2).map { it.toInt(16).toByte() }.toByteArray()
        return byteArrayOf(
            0x30, 0x1E,
            macBytes[0], macBytes[1], macBytes[2], macBytes[3], macBytes[4], macBytes[5],
            0x03, w0,
            0xA0.toByte(), 0x1E, 0x3E, 0x17, 0x1A, 0x04, 0x1A,
            0x03,
            0x00, 0x00, 0x0D, 0x68, 0x00, 0x00, 0x05, 0x28, 0x00, 0x00, 0x0D, 0x68,
            0xF4.toByte(), 0x01
        )
    }

    private fun buildU4(w0: Byte): ByteArray {
        return byteArrayOf(
            0x31, 0x08, w0, 0x03,
            0x9B.toByte(), 0x6F, 0xEF.toByte(), 0x43,
            0x28, 0x00
        )
    }

    private fun buildW4(w0: Byte): ByteArray {
        return byteArrayOf(
            0x32, 0x03, w0, 0x28, 0x00
        )
    }

    companion object {
        private const val TAG = "PenInitManager"
        private val SERVICE_UUID = UUID.fromString("0000fe10-aa6c-462a-964a-7f2ed5b3e512")
        private val WRITE_CHAR_UUID = UUID.fromString("0000fe11-aa6c-462a-964a-7f2ed5b3e512")
        private val NOTIFY_CHAR_UUID = UUID.fromString("0000fe12-aa6c-462a-964a-7f2ed5b3e512")
        private val DESCRIPTOR_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
