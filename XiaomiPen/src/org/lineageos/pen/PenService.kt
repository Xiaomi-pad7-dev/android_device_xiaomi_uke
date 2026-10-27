/*
 * SPDX-FileCopyrightText: 2025-2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.pen

import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Resources
import android.database.ContentObserver
import android.hardware.input.InputManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.ParcelUuid
import android.os.SystemProperties
import android.os.UEventObserver
import android.provider.Settings
import android.provider.Settings.System.PEAK_REFRESH_RATE
import android.provider.Settings.System.MIN_REFRESH_RATE
import android.util.Log
import java.util.Locale

class PenService : Service() {
    private val bluetoothManager by lazy { getSystemService(BluetoothManager::class.java) }
    private val inputManager by lazy { getSystemService(InputManager::class.java) }

    private val handler by lazy { Handler(mainLooper) }

    private val prefs by lazy { getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE) }

    private var penRefreshRateObserverRegistered = false
    private var isUpdatingSettings = false

    private var activeInitManager: PenInitializationManager? = null
    private var pendingAddress: String? = null
    private var bluetoothPendingDocked = false
    private var isScanning = false

    private val scanTimeoutRunnable = Runnable {
        Log.i(TAG, "Pen scan timed out")
        stopPenScan()
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device ?: return
            if (!isFocusPen(device) && (pendingAddress == null || !device.address.equals(pendingAddress, ignoreCase = true))) {
                return
            }
            Log.i(TAG, "Pen scan found device: ${device.name} (${device.address})")
            stopPenScan()

            val adapter = bluetoothManager.adapter ?: return
            pendingAddress = device.address

            if (isBonded(adapter, device)) {
                Log.i(TAG, "Scanned device already bonded, triggering GATT init")
                triggerPenInit(device, adapter)
            } else {
                Log.i(TAG, "Initiating LE bond with scanned device ${device.address}")
                try {
                    val bonded = device.createBond(BluetoothDevice.TRANSPORT_LE)
                    Log.i(TAG, "createBond(TRANSPORT_LE) returned: $bonded")
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to createBond on scanned device", e)
                }
            }
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>) {
            for (res in results) {
                val dev = res.device ?: continue
                if (isFocusPen(dev) || (pendingAddress != null && dev.address.equals(pendingAddress, ignoreCase = true))) {
                    onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, res)
                    break
                }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Pen scan failed with error code: $errorCode")
            isScanning = false
        }
    }

    private val pairingReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (BluetoothDevice.ACTION_PAIRING_REQUEST != intent.action) return
            val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
            } ?: return

            if (!isFocusPen(device)) {
                return
            }

            val variant = intent.getIntExtra(BluetoothDevice.EXTRA_PAIRING_VARIANT, -1)
            Log.i(TAG, "Received pairing request for ${device.address}, variant=$variant")

            if (variant == BluetoothDevice.PAIRING_VARIANT_CONSENT ||
                variant == BluetoothDevice.PAIRING_VARIANT_PASSKEY_CONFIRMATION) {
                Log.i(TAG, "Auto-confirming pairing request for pen ${device.address}")
                try {
                    device.setPairingConfirmation(true)
                    if (isOrderedBroadcast) {
                        abortBroadcast()
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to auto-confirm pairing", e)
                }
            }
        }
    }

    private val bondStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (BluetoothDevice.ACTION_BOND_STATE_CHANGED != intent.action) return
            val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
            } ?: return

            if (!isFocusPen(device)) {
                return
            }

            val bondState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE)
            val prevBondState = intent.getIntExtra(BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, BluetoothDevice.BOND_NONE)
            Log.i(TAG, "Bond state changed for ${device.address}: $prevBondState -> $bondState")

            if (bondState == BluetoothDevice.BOND_BONDED) {
                Log.i(TAG, "Pen ${device.address} successfully bonded! Initializing...")
                pendingAddress = null
                stopPenScan()
                val adapter = bluetoothManager.adapter
                if (adapter != null) {
                    triggerPenInit(device, adapter)
                }
            } else if (bondState == BluetoothDevice.BOND_NONE && prevBondState == BluetoothDevice.BOND_BONDING) {
                Log.w(TAG, "Bonding failed for pen ${device.address}, scanning to retry")
                startPenScan(device.address)
            }
        }
    }

    private val btStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (BluetoothAdapter.ACTION_STATE_CHANGED != intent.action) return
            val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
            if (state == BluetoothAdapter.STATE_ON) {
                Log.i(TAG, "Bluetooth turned ON")
                if (bluetoothPendingDocked) {
                    bluetoothPendingDocked = false
                    val addr = pendingAddress
                    handler.post { handlePenDocked(addr) }
                } else {
                    handler.post { refreshPenState() }
                }
            }
        }
    }

    private val observer = object : UEventObserver() {
        private val lock = Any()

        override fun onUEvent(event: UEvent) {
            val pencilStatus = event.get("POWER_SUPPLY_PEN_HALL3") ?: return
            val rawMac = event.get("POWER_SUPPLY_PEN_MAC")
            val pencilAddr = parseAddress(rawMac)

            synchronized(lock) {
                when (pencilStatus) {
                    "0" -> {
                        Log.i(TAG, "Pen attached (docked), MAC: $pencilAddr")
                        handlePenDocked(pencilAddr)
                        handlePenHallState(PenHallState.ATTACHED)
                    }
                    "1" -> {
                        Log.i(TAG, "Pen detached (in use)")
                        stopPenScan()
                        handlePenHallState(PenHallState.DETACHED)
                    }
                }
            }
        }
    }

    private val inputObserver = object : InputManager.InputDeviceListener {
        override fun onInputDeviceAdded(deviceId: Int) {
            if (isXiaomiPenInputDevice(deviceId)) {
                Log.i(TAG, "Xiaomi Pen input device added (id=$deviceId)")
                notifyPenType(deviceId)
                applyPenDetachedOverride()
            }
        }

        override fun onInputDeviceRemoved(deviceId: Int) {
            if (!hasActiveXiaomiPenInput()) {
                SystemProperties.set("sys.pen.active", "0")
            }
        }

        override fun onInputDeviceChanged(deviceId: Int) {
            // Do nothing
        }
    }

    private val penRefreshRateObserver by lazy {
        object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                if (isUpdatingSettings) return

                val currentPeak = readRefreshRate(PEAK_REFRESH_RATE) ?: defaultPeakRefreshRate()
                val currentMin = readRefreshRate(MIN_REFRESH_RATE) ?: defaultMinRefreshRate()

                if (currentPeak > 120f) {
                    prefs.edit().putFloat(KEY_USER_PEAK, currentPeak).apply()
                    setPenDetachedRefreshRate()
                } else if (currentMin > 120f) {
                    setPenDetachedRefreshRate()
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra(EXTRA_PENCIL_ADDR)?.let { addr ->
            handler.post { handlePenDocked(parseAddress(addr) ?: addr) }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()

        inputManager?.registerInputDeviceListener(inputObserver, handler)

        val pairingFilter = IntentFilter(BluetoothDevice.ACTION_PAIRING_REQUEST).apply {
            priority = 1000
        }
        registerReceiver(pairingReceiver, pairingFilter, RECEIVER_EXPORTED)
        registerReceiver(bondStateReceiver, IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED), RECEIVER_EXPORTED)
        registerReceiver(btStateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED), RECEIVER_EXPORTED)

        // Observe hall sensor uevents from battery charger
        observer.startObserving("DEVPATH=/devices/platform/soc/soc:qcom,pmic_glink/soc:qcom,pmic_glink:qcom,battery_charger")

        // Sync current state on startup
        handler.post { refreshPenState() }
    }

    override fun onDestroy() {
        super.onDestroy()

        inputManager?.unregisterInputDeviceListener(inputObserver)
        unregisterReceiver(pairingReceiver)
        unregisterReceiver(bondStateReceiver)
        unregisterReceiver(btStateReceiver)
        stopPenScan()
        activeInitManager?.stop()
        activeInitManager = null
        unregisterPenRefreshRateObserver()
        restoreUserRefreshRate()
        setPenEvents("false")
        observer.stopObserving()
    }

    private fun handlePenDocked(pencilAddr: String?) {
        val adapter = bluetoothManager.adapter
        if (adapter == null) {
            Log.w(TAG, "BluetoothAdapter is null")
            return
        }

        if (!adapter.isEnabled) {
            Log.i(TAG, "Bluetooth disabled, enabling for pen pairing...")
            pendingAddress = pencilAddr
            bluetoothPendingDocked = true
            @Suppress("DEPRECATION")
            adapter.enable()
            return
        }

        // If pen address is known, check if already bonded
        if (pencilAddr != null) {
            val device = try { adapter.getRemoteDevice(pencilAddr) } catch (e: Exception) { null }
            if (device != null && isBonded(adapter, device)) {
                Log.i(TAG, "Pen $pencilAddr already bonded, triggering GATT init directly on dock")
                triggerPenInit(device, adapter)
                return
            }
        } else {
            val bondedPen = findBondedFocusPen(adapter)
            if (bondedPen != null) {
                Log.i(TAG, "Found bonded pen ${bondedPen.address}, triggering GATT init directly on dock")
                triggerPenInit(bondedPen, adapter)
                return
            }
        }

        // Pen attached and not bonded: initiate automatic pairing
        startAutoPairing(pencilAddr, adapter)
    }

    private fun startAutoPairing(pencilAddr: String?, adapter: BluetoothAdapter) {
        pendingAddress = pencilAddr
        Log.i(TAG, "Starting automatic pairing for pen (MAC: $pencilAddr)")

        if (pencilAddr != null) {
            val device = try { adapter.getRemoteDevice(pencilAddr) } catch (e: Exception) { null }
            if (device != null) {
                Log.i(TAG, "Attempting direct LE bond with $pencilAddr")
                try {
                    val initiated = device.createBond(BluetoothDevice.TRANSPORT_LE)
                    Log.i(TAG, "device.createBond(TRANSPORT_LE) = $initiated")
                    if (!initiated) {
                        Log.i(TAG, "Direct bond failed to initiate, starting LE scan for $pencilAddr")
                        startPenScan(pencilAddr)
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Direct createBond threw exception, falling back to LE scan", e)
                    startPenScan(pencilAddr)
                }
                return
            }
        }

        Log.i(TAG, "Starting LE scan for unbonded Focus Pen")
        startPenScan(pencilAddr)
    }

    private fun startPenScan(filterAddr: String?) {
        val adapter = bluetoothManager.adapter ?: return
        if (!adapter.isEnabled) return
        val scanner = adapter.bluetoothLeScanner ?: return

        stopPenScan()

        val filters = if (filterAddr != null) {
            listOf(ScanFilter.Builder().setDeviceAddress(filterAddr).build())
        } else {
            listOf(
                ScanFilter.Builder().setDeviceName("Xiaomi Focus Pen").build(),
                ScanFilter.Builder().setDeviceName("Xiaomi Focus Pen Pro").build(),
                ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString("0000fe10-aa6c-462a-964a-7f2ed5b3e512")).build()
            )
        }

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setReportDelay(0L)
            .build()

        isScanning = true
        try {
            scanner.startScan(filters, settings, scanCallback)
            handler.postDelayed(scanTimeoutRunnable, SCAN_TIMEOUT_MS)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to start BLE scan", e)
            isScanning = false
        }
    }

    private fun stopPenScan() {
        if (!isScanning) return
        isScanning = false
        handler.removeCallbacks(scanTimeoutRunnable)
        try {
            bluetoothManager.adapter?.bluetoothLeScanner?.stopScan(scanCallback)
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping pen scan", e)
        }
    }

    private enum class PenHallState { ATTACHED, DETACHED, UNKNOWN }

    private fun handlePenHallState(state: PenHallState) {
        when (state) {
            PenHallState.ATTACHED -> {
                // The charger's pen hall reports "attached" even while the pen
                // is in use on this board. Only restore the refresh rate when
                // no pen input device is active and the pen is not tracking.
                if (hasActiveXiaomiPenInput() ||
                        SystemProperties.get("sys.pen.active") == "1") {
                    Log.i(TAG, "Hall says attached but pen is active, keeping 120Hz")
                    return
                }
                Log.i(TAG, "Pen attached (docked): restoring user refresh rate")
                restoreUserRefreshRate()
            }
            PenHallState.DETACHED -> {
                Log.i(TAG, "Pen detached (in use): capping peak refresh rate to 120Hz (VRR preserved)")
                applyPenDetachedOverride()
            }
            PenHallState.UNKNOWN -> Unit
        }
    }

    private fun applyPenDetachedOverride() {
        val adapter = bluetoothManager.adapter
        if (findBondedFocusPen(adapter) == null && !hasActiveXiaomiPenInput()) {
            Log.i(TAG, "No Focus Pen bonded/active; skipping refresh rate override")
            unregisterPenRefreshRateObserver()
            return
        }

        val peak = readRefreshRate(PEAK_REFRESH_RATE) ?: defaultPeakRefreshRate()
        val min = readRefreshRate(MIN_REFRESH_RATE) ?: defaultMinRefreshRate()

        if (!prefs.contains(KEY_USER_PEAK)) {
            if (peak > 120f) {
                val editor = prefs.edit()
                    .putFloat(KEY_USER_PEAK, peak)
                    .putBoolean(KEY_USER_PEAK_SET, settingExists(PEAK_REFRESH_RATE))

                if (min > 120f) {
                    editor.putFloat(KEY_USER_MIN, min)
                        .putBoolean(KEY_USER_MIN_SET, settingExists(MIN_REFRESH_RATE))
                }
                editor.apply()
                Log.i(TAG, "Pen active: snapshotted user settings (peak=" + peak + ", min=" + min + " preserved for VRR)")
            }
        }

        setPenDetachedRefreshRate()
    }

    private fun setPenDetachedRefreshRate() {
        val adapter = bluetoothManager.adapter
        if (findBondedFocusPen(adapter) == null && !hasActiveXiaomiPenInput()) {
            Log.i(TAG, "No Focus Pen bonded/active; skipping setPenDetachedRefreshRate")
            unregisterPenRefreshRateObserver()
            return
        }

        val currentPeak = readRefreshRate(PEAK_REFRESH_RATE) ?: defaultPeakRefreshRate()
        val currentMin = readRefreshRate(MIN_REFRESH_RATE) ?: defaultMinRefreshRate()

        isUpdatingSettings = true
        try {
            if (currentPeak > 120f) {
                writeRefreshRate(PEAK_REFRESH_RATE, 120f)
            }
            if (currentMin > 120f) {
                writeRefreshRate(MIN_REFRESH_RATE, 120f)
            }
        } finally {
            isUpdatingSettings = false
        }
        registerPenRefreshRateObserver()
        setPenEvents("true")
        Log.i(TAG, "Pen active: peak capped at 120Hz (min=" + currentMin + " preserved for VRR)")
    }

    private fun restoreUserRefreshRate() {
        unregisterPenRefreshRateObserver()

        val userPeak = prefs.getFloat(KEY_USER_PEAK, -1f)
        if (userPeak >= 0f) {
            isUpdatingSettings = true
            try {
                if (prefs.getBoolean(KEY_USER_PEAK_SET, true)) {
                    writeRefreshRate(PEAK_REFRESH_RATE, userPeak)
                } else {
                    deleteRefreshRate(PEAK_REFRESH_RATE)
                }

                if (prefs.contains(KEY_USER_MIN)) {
                    val userMin = prefs.getFloat(KEY_USER_MIN, -1f)
                    if (prefs.getBoolean(KEY_USER_MIN_SET, true)) {
                        writeRefreshRate(MIN_REFRESH_RATE, userMin)
                    } else {
                        deleteRefreshRate(MIN_REFRESH_RATE)
                    }
                }
            } finally {
                isUpdatingSettings = false
            }
            prefs.edit().clear().apply()
            Log.i(TAG, "Pen docked: restored user refresh rate (peak=" + userPeak + ")")
        }

        setPenEvents("false")
    }

    private fun isFocusPen(device: BluetoothDevice?): Boolean {
        val name = device?.name ?: ""
        val address = device?.address ?: ""
        return address.equals("28:CE:15:14:68:AE", ignoreCase = true) ||
               (pendingAddress != null && address.equals(pendingAddress, ignoreCase = true)) ||
               name.contains("Focus Pen", ignoreCase = true) ||
               name.contains("Smart Pen", ignoreCase = true) ||
               name.contains("Xiaomi Stylus", ignoreCase = true) ||
               name.contains("Stylus", ignoreCase = true) ||
               (name.contains("Xiaomi", ignoreCase = true) && name.contains("Pen", ignoreCase = true))
    }

    private fun isXiaomiPenInputDevice(id: Int): Boolean {
        val inputDevice = inputManager?.getInputDevice(id) ?: return false
        val name = inputDevice.name ?: ""
        val vendorId = inputDevice.vendorId
        val productId = inputDevice.productId
        val isXiaomiVendor = (vendorId == 34 || vendorId == 0x0022 || vendorId == 0x2717)
        val isXiaomiProduct = (productId == 19840 || productId == 20609 || productId == 5081 || productId == 0x4D80 || productId == 0x5081)
        val isPenName = name.contains("Focus Pen", ignoreCase = true) ||
                        name.contains("Smart Pen", ignoreCase = true) ||
                        (name.contains("Xiaomi", ignoreCase = true) && name.contains("Pen", ignoreCase = true))
        return (isXiaomiVendor && isXiaomiProduct) || isPenName
    }

    private fun hasActiveXiaomiPenInput(): Boolean {
        val im = inputManager ?: return false
        return im.inputDeviceIds.any { isXiaomiPenInputDevice(it) }
    }

    private fun readRefreshRate(key: String): Float? = try {
        Settings.System.getFloat(contentResolver, key)
    } catch (e: Exception) {
        null
    }

    private fun settingExists(key: String): Boolean =
        Settings.System.getString(contentResolver, key) != null

    private fun writeRefreshRate(key: String, value: Float) {
        val current = readRefreshRate(key)
        if (current == null || current != value) {
            Settings.System.putFloat(contentResolver, key, value)
        }
    }

    private fun deleteRefreshRate(key: String) {
        Settings.System.putString(contentResolver, key, null)
    }

    private fun defaultPeakRefreshRate(): Float = try {
        Resources.getSystem()
            .getInteger(com.android.internal.R.integer.config_defaultPeakRefreshRate)
            .toFloat()
    } catch (e: Exception) {
        DEFAULT_PEAK_REFRESH_RATE
    }

    private fun defaultMinRefreshRate(): Float = DEFAULT_MIN_REFRESH_RATE

    private fun registerPenRefreshRateObserver() {
        if (penRefreshRateObserverRegistered) return
        penRefreshRateObserverRegistered = true
        contentResolver.registerContentObserver(
            Settings.System.getUriFor(PEAK_REFRESH_RATE), false, penRefreshRateObserver)
        contentResolver.registerContentObserver(
            Settings.System.getUriFor(MIN_REFRESH_RATE), false, penRefreshRateObserver)
    }

    private fun unregisterPenRefreshRateObserver() {
        if (!penRefreshRateObserverRegistered) return
        penRefreshRateObserverRegistered = false
        try {
            contentResolver.unregisterContentObserver(penRefreshRateObserver)
        } catch (ignored: Exception) {}
    }

    private fun parseAddress(value: String?): String? {
        if (value.isNullOrEmpty()) return null
        if (value.matches(Regex("^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$"))) {
            return value.uppercase(Locale.ROOT)
        }
        val mac = value.toLongOrNull(16) ?: return null
        if (mac == 0L) return null
        val hex = String.format(Locale.ROOT, "%012X", mac)
        return hex.chunked(2).joinToString(":")
    }

    private fun isBonded(adapter: BluetoothAdapter, device: BluetoothDevice): Boolean = try {
        adapter.bondedDevices.contains(device)
    } catch (e: Exception) {
        Log.w(TAG, "Failed to query bonded devices", e)
        false
    }

    private fun findBondedFocusPen(adapter: BluetoothAdapter?): BluetoothDevice? {
        if (adapter == null) return null
        return try {
            adapter.bondedDevices.firstOrNull { device ->
                isFocusPen(device)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to query bonded devices", e)
            null
        }
    }

    private fun triggerPenInit(device: BluetoothDevice, adapter: BluetoothAdapter) {
        Log.i(TAG, "Running GATT init for pen ${device.address}")
        activeInitManager?.stop()
        val initManager = PenInitializationManager(this, device, adapter.address) { mode, value ->
            setTouchMode(mode, value)
        }
        activeInitManager = initManager
        initManager.start()
    }

    private fun setPenEvents(isDisabled: String) {
        SystemProperties.set("persist.pen.events.disabled", isDisabled)
    }

    private fun setTouchMode(mode: Int, value: Int) {
        Log.i(TAG, "setTouchMode: mode=$mode, value=$value")

        try {
            val service = android.os.ServiceManager.getService("vendor.xiaomi.hw.touchfeature.ITouchFeature/default")
            if (service != null) {
                val data = android.os.Parcel.obtain()
                val reply = android.os.Parcel.obtain()
                data.writeInterfaceToken("vendor.xiaomi.hw.touchfeature.ITouchFeature")
                data.writeInt(0)
                data.writeInt(mode)
                data.writeInt(value)
                service.transact(6, data, reply, 0)
                Log.i(TAG, "AIDL setTouchMode($mode, $value) OK")
                data.recycle()
                reply.recycle()
            }
        } catch (e: Exception) {
            Log.w(TAG, "AIDL setTouchMode($mode, $value) failed: ${e.message}")
        }

        try {
            SystemProperties.set("persist.vendor.parts.pen.val", value.toString())
            SystemProperties.set("persist.vendor.parts.pen", mode.toString())
            if (mode == 37 || mode == 29) {
                SystemProperties.set("sys.pen.active", if (value > 0) "1" else "0")
                if (value > 0) {
                    handler.post { applyPenDetachedOverride() }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set pen system properties: ${e.message}")
        }
    }

    private fun notifyPenType(deviceId: Int) {
        val dev = inputManager?.getInputDevice(deviceId) ?: return
        if (dev.vendorId != 0x0022 && dev.vendorId != 34 && dev.vendorId != 0x2717) return
        val penId = when (dev.productId) {
            0x5081 -> 8                              // Focus Pen Pro (P81C)
            0x4d80, 0x4d81, 0x3280, 0x3281 -> 3      // Focus Pen (M80P)
            else -> return
        }
        Log.i(TAG, "Pen type for ${dev.name} -> NVT pen id $penId")
        setTouchMode(20, penId or 0x10)
        SystemProperties.set("sys.pen.active", "1")
    }

    private fun refreshPenState() {
        val im = inputManager ?: return
        val adapter = bluetoothManager.adapter
        var penPresent = false
        for (id in im.inputDeviceIds) {
            if (isXiaomiPenInputDevice(id)) {
                penPresent = true
                notifyPenType(id)
            }
        }
        if (!penPresent) {
            return
        }
        SystemProperties.set("sys.pen.active", "1")
        val btAdapter = adapter ?: return
        val bonded = findBondedFocusPen(btAdapter)
        if (bonded != null) {
            Log.i(TAG, "Cold boot pen attached, running MIPP init for ${bonded.address}")
            triggerPenInit(bonded, btAdapter)
        } else {
            Log.i(TAG, "Cold boot pen input present but not bonded, starting auto-pairing...")
            startAutoPairing(null, btAdapter)
        }
    }

    companion object {
        private const val TAG = "XiaomiPenService"

        private const val EXTRA_PENCIL_ADDR = "pencil_addr"
        private const val SCAN_TIMEOUT_MS = 30000L

        private const val DEFAULT_PEAK_REFRESH_RATE = 144f
        private const val DEFAULT_MIN_REFRESH_RATE = 0f

        private const val PREFS_NAME = "pen_refresh_rate"
        private const val KEY_USER_PEAK = "user_peak_refresh_rate"
        private const val KEY_USER_MIN = "user_min_refresh_rate"
        private const val KEY_USER_PEAK_SET = "user_peak_refresh_rate_set"
        private const val KEY_USER_MIN_SET = "user_min_refresh_rate_set"
    }
}
