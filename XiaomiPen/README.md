# Xiaomi Focus Pen / Focus Pen Pro — Protocol & AOSP Implementation

## Overview

The Xiaomi Focus Pen and Focus Pen Pro communicate with the tablet
(Xiaomi Pad 7, codename `uke`) via **two independent channels**:

| Channel | Interface | Purpose |
|---|---|---|
| **BLE GATT** | `70:61:EE:C1:B9:C4` → service `0000fe10` (MIPP) | Pairing, initialization, button events, battery |
| **Capacitive** | NVT touch panel → `/dev/input/event12` (M80p), `/dev/input/event13` (P81c) | Real-time position, pressure, tilt |

Both channels must be active for the pen to work. BLE initializes the pen
hardware; the NVT digitizer must be told to track the pen signal via
`ITouchFeature` HAL calls.

---

## 1. BLE GATT Architecture

### 1.1 Services

The Focus Pen exposes these GATT services:

| UUID | Service | Notes |
|---|---|---|
| `00001800-...` | Generic Access | Standard |
| `00001801-...` | Generic Attribute | Standard |
| `0000180a-...` | Device Information | Read: firmware version, PNP ID |
| `0000180f-...` | Battery Service | `0x2A19` — battery level (read+notify) |
| `00001812-...` | HID Service | Report Map + HID reports at handle `0x002E` |
| `0000fe10-aa6c-462a-964a-7f2ed5b3e512` | **MIPP** (Xiaomi pen control) | Main pen init & control |
| `0000fe20-aa6c-462a-964a-7f2ed5b3e512` | Xiaomi secondary | `fe21` (write), `fe22`/`fe24` (notify) |
| `0000fef5-0000-1000-8000-00805f9b34fb` | Dialog SPOTA (OTA firmware update) | Pen firmware DFU |
| `0000fed0-aa6c-462a-964a-7f2ed5b3e512` | Xiaomi OTA v2 | Alternate OTA service |

### 1.2 MIPP Service (`0000fe10`) — The Pen Control Channel

| Characteristic | UUID | Properties | Purpose |
|---|---|---|---|
| `fe11` | `0000fe11-aa6c-462a-964a-7f2ed5b3e512` | **Write Without Response** | Command write — host sends init payloads here |
| `fe12` | `0000fe12-aa6c-462a-964a-7f2ed5b3e512` | **Notify** | Pen responses — ACKs, button events, status |

---

## 2. Pen Initialization Sequence

### 2.1 High-Level Flow

```
Pen physical attach → Hall sensor → UEvent (POWER_SUPPLY_PEN_HALL3=0)
  → BLE bond (if not bonded) or direct connect (if bonded)
  → GATT connect → discover services → find fe10/fe11/fe12
  → Enable CCCD on fe12 (write 0x0100 to descriptor 0x2902)
  → Request MTU 512
  → onMtuChanged → start 15-step init state machine on fe11
  → Pen responds on fe12 at each step
  → After init complete: ITouchFeature.setTouchMode(0, 37, 1)
  → Pen starts streaming HID reports on handle 0x002E
  → NVT digitizer reads pen capacitive signal → input events
```

### 2.2 The 15-Step Init Payload Sequence

All sent to `fe11` with `WRITE_TYPE_NO_RESPONSE` at 20ms intervals.
Captured from a working HyperOS HCI snoop log on Xiaomi Pad 7 (`uke`).

| Step | Payload (hex) | Meaning | Pen Response Prefix |
|---|---|---|---|
| 1 | `5200` | Read active state (INIT handshake) | `D2` |
| 2 | `0000` | Read touch ID | `80` |
| 3 | `0100` | Read pen feature | `81` |
| 4 | `0200` | Read work status | `82` |
| 5 | `0300` | Read painting version | `83` |
| 6 | `0400` | Assign ID number (1st pass) | `84` |
| 7 | `301e3c` | Set TX parameter (cmd 0x30, data 0x1E3C) | `B0` |
| 8 | `310800` | Set TX frequency (cmd 0x31, data 0x0800) | `B1` |
| 9 | `320300` | Set TX voltage (cmd 0x32, data 0x0300) | `B2` |
| 10 | `0400` | Assign ID number (2nd pass) | `84` |
| 11 | `301e3c` | Set TX parameter (repeat) | `B0` |
| 12 | `310801` | Set TX frequency (variant, data 0x0801) | `B1` |
| 13 | `320301` | Set TX voltage (variant, data 0x0301) | `B2` |
| 14 | `330469` | Set config (cmd 0x33, data 0x0469) | `B3` |
| 15 | `510101` | **ACTIVATE** (cmd 0x51, enable 0x01, param 0x01) | `53` |

After step 15, the pen ACKs with `53:01:01` and begins streaming
HID position/pressure/tilt reports on handle `0x002E`.

### 2.3 Why 20ms Between Payloads?

Steps 7-9 (`30xx`, `31xx`, `32xx`) physically reconfigure the pen's
Nordic BLE MCU — adjusting RF TX frequency and voltage regulators.
Spamming without delay can overflow the pen's GATT buffer and cause
the ACTIVATE command (`510101`) to be dropped.

The stock implementation is request-response: each step waits for
the pen's `fe12` notification ACK before sending the next. Our
AOSP implementation uses a 20ms delay as a simpler equivalent.

### 2.4 Pen Notification Prefixes (fe12 responses)

| Prefix Byte | Meaning |
|---|---|
| `80` | Touch ID response |
| `81` | Pen feature response |
| `82` | Work status response |
| `83` | Painting version response |
| `84` | ID assignment ACK |
| `D2` | Active state response (after `5200`) |
| `53` | Activate ACK (after `510101`) |
| `B0` | TX parameter ACK |
| `B1` | TX frequency ACK |
| `B2` | TX voltage ACK |
| `B3` | Config ACK |
| `D4` | Pen status update |
| `D6` | Force sleep OK |
| `58` | Disconnect request |

---

## 3. NVT Touch Panel Configuration

### 3.1 The Dotted Lines Problem

Without the NVT digitizer configured for pen tracking, the touch panel
stays in standard finger-scanning mode (60–120 Hz sample rate). The pen
emits coordinates at 240+ Hz. More than half the pen's coordinate samples
are dropped, producing **dotted lines, broken strokes, and high latency**.

### 3.2 ITouchFeature HAL

The stock `MiuiBleOobHelperService` calls `ITouchFeature.setTouchMode()`
at three key moments:

| Mode | Value | When | Purpose |
|---|---|---|---|
| **29** | pen active state | After pen responds to `5200` (D2 notification) | Syncs pen active/inactive state to digitizer |
| **37** | 1 (enable) | After 15-step init completes | **Enables High-Report-Rate NVT Pen Tracking Mode** — the critical fix for dotted lines |
| **22** | package name | After init | Configures touch latency profile |

### 3.3 AIDL Interface

```
Service: vendor.xiaomi.hw.touchfeature.ITouchFeature/default
Method:  setTouchMode(int touchId, int mode, int value)
Transaction code: 6
```

---

## 4. Stock Implementation Trace

### 4.1 Key Classes (BluetoothExtension.apk)

| Class | File | Purpose |
|---|---|---|
| `MiuiBleOobHelperService` | `oobhelper/MiuiBleOobHelperService.java` (3109 lines) | Main pen service — GATT lifecycle, state machine triggers |
| `i` | `oobhelper/i.java` | Handler — processes state machine codes 2000–2033 |
| `a` | `oobhelper/a.java` | BluetoothGattCallback — connection, services, writes, notifications |
| `f` | `oobhelper/f.java` | UEventObserver — detects pen attach via POWER_SUPPLY_PEN_MAC/HALL3 |
| `h` (y0) | `y0/h.java` | OTA firmware update manager (fef5 service) |
| `l` (y0) | `y0/l.java` | OTA v2 manager (fed0 service) |
| `C0937h` | `ble/C0937h.java` | Device feature detection — timestamp/resource-based capability checks |

### 4.2 Key Classes (TouchService.apk)

| Class | Purpose |
|---|---|
| `ITouchFeature` | Java wrapper for `vendor.xiaomi.hardware.touchfeature@1.0::ITouchFeature` HIDL + AIDL |
| `PencilEngineManagerService` | Coordinates pen posture, touch modes, app callbacks |
| `PencilPostureController` | Handles pen tilt/orientation/button events |
| `MiuiInputManager` | Input device management for pen |

### 4.3 State Machine Codes

The init state machine in `i.java` Handler uses these message codes:

| Code | Field | Payload | Meaning |
|---|---|---|---|
| 2000 | CCCD descriptor | `0100` | Write CCCD on fe12 |
| 2023 | `m1` = `{0x52, 0x00}` | `5200` | Read active state |
| 2001 | `h1` = `{0x00, 0x00}` | `0000` | Read touch ID |
| 2002 | `i1` = `{0x01, 0x00}` | `0100` | Read pen feature |
| 2003 | `j1` = `{0x02, 0x00}` | `0200` | Read work status |
| 2004 | `k1` = `{0x03, 0x00}` | `0300` | Read painting version |
| 2005 | `n1` = `{0x04, 0x00}` | `0400` | Assign ID number |
| 2006 | `v4()` builder | dynamic | Set TX parameter |
| 2007 | `u4()` builder | dynamic | Set TX frequency |
| 2008 | `w4()` builder | dynamic | Set TX voltage |
| 2009 | `X1` = `{0xE0, 0x01}` | `E001` | Set timestamp |
| 2010 | `Z1` = `{0xE2, 0x00}` | `E200` | Set hover state |
| 2013 | `Y1` = `{0xE1, 0x00}` | `E100` | Set hall state → INIT COMPLETE |
| 2015 | `l1` = `{0x54, 0x00}` | `5400` | Read charger status |
| 2016 | `N1` = `{0x56, 0x01, 0x01}` | `560101` | Force sleep enter |
| 2017 | `O1` = `{0x56, 0x01, 0x00}` | `560100` | Force sleep exit |
| 2018 | `w1` = `{0xD8, 0x00}` | `D800` | Disconnect request reply |

### 4.4 Dynamic Payload Builders

Steps 2006–2008 use dynamic builders (`v4()`, `u4()`, `w4()`) that
assemble payloads based on device capabilities. These call `C0937h.j()`
and `C0937h.l()` to check device timestamps/resources and determine
whether to use 0x20 or 0x22 byte payloads, and what TX parameters
to apply.

Our AOSP implementation hardcodes the builder output captured from
a working HCI snoop log — these are correct for `uke` specifically.

---

## 5. AOSP Implementation

### 5.1 File

`Pen/src/org/lineageos/pen/PenService.kt`

Single Kotlin file. System-ext priv-app with `platform_apis: true`.
No external dependencies beyond standard Android framework.

### 5.2 Flow

```
onCreate → UEventObserver (POWER_SUPPLY_PEN_HALL3 + PEN_MAC)
  → onUEvent:
      hall=0 (attach): postNotification(addr)
        → if bonded + isFocusPen: connectGattAndInit(device)
        → if not bonded: notification → user taps → BLE scan → createBond(TRANSPORT_LE)
      hall=1 (detach): cancel notification
      every uevent → re-evaluate refresh rate policy from the uevent value
        (POWER_SUPPLY_PEN_HALL3, 0 = attached, 1 = detached)

bondStateReceiver (ACTION_BOND_STATE_CHANGED):
  → if BOND_BONDED + isFocusPen: connectGattAndInit(device)

connectGattAndInit:
  → connectGatt(device, false, callback)  [autoConnect=false]
  → onConnectionStateChange(CONNECTED) → discoverServices()
  → onServicesDiscovered:
      → find fe10 service → fe11 (write), fe12 (notify)
      → gatt.setCharacteristicNotification(fe12, true)
      → write CCCD descriptor (0x0100 → 0x2902)
      → gatt.requestMtu(512)
  → onMtuChanged → start 15-step payload send on fe11
      → 20ms delay between each step
      → WRITE_TYPE_NO_RESPONSE

onCharacteristicChanged (fe12):
  → D2 xx → call setTouchMode(29, state)
  → 53 xx → call setTouchMode(37, 1)
  → fallback: setTouchMode(37, 1) after init complete

setTouchMode → ServiceManager.getService("vendor.xiaomi.hw.touchfeature.ITouchFeature/default")
  → Parcel.obtain → writeInt(touchId=0) → writeInt(mode) → writeInt(value)
  → transact(6, data, reply, 0)  [transaction 6 = setTouchMode(III)]

Refresh rate policy (Bluetooth connection + hall sensor based):
  The Focus Pen only works at 60/120 Hz, but the panel supports up to 144 Hz
  (with VVR-capable min rates). The pen hall state comes from the
  POWER_SUPPLY_PEN_HALL3 uevent emitted by the qti_battery_charger driver,
  and Bluetooth connection status is tracked in real time via ACL broadcasts.
  - No pen connected via Bluetooth OR pen attached/docked: leave refresh rate
    settings completely untouched. If an override from previous pen usage was
    active, restore the user's saved peak/min (e.g. 144 Hz) exactly and
    unregister the content observer so the user can freely use 144 Hz.
  - Pen actively connected via Bluetooth AND detached (in active use): if the
    user's peak was > 60 Hz (144/120/90), snapshot peak+min, then cap the peak
    at 120 Hz and clamp the min to <= 120 Hz (AOSP gets stuck at min when
    min > max). If the user's peak was 60 Hz, nothing is touched. While the pen
    is active and in use, a content observer re-asserts the cap.
  - As soon as the pen disconnects or docks, the user's original 144 Hz is
    immediately restored and the observer is unregistered.
  Saved user settings are persisted in SharedPreferences so they survive a
  service restart.
```

### 5.3 Pen Identification

BLE device name matching (used for GATT init trigger):
- `"Xiaomi Focus Pen"` (equals, case-insensitive)
- `"Xiaomi Focus Pen Pro"` (equals, case-insensitive)

---

## 6. Testing & Verification

### 6.1 Verify GATT Init

```bash
adb logcat -s XiaomiPenService:* | grep -E "Sending|step|Done|ACK|setTouch"
```

Expected output:
```
Sending init step 0: 5200
...
Pen activate ACK: 1 — enabling pen tracking
setTouchMode(37, 1) OK
✅ Pen init sequence complete!
```

### 6.2 Verify NVT Pen Mode

Check input devices exist:
```bash
adb shell cat /proc/bus/input/devices | grep -A6 NVTCapacitivePen
```

Should show both `NVTCapacitivePenM80p` and `NVTCapacitivePenP81c`.

### 6.3 Verify Touch Modes

```bash
adb shell dumpsys vendor.xiaomi.hw.touchfeature.ITouchFeature/default
```

### 6.4 HCI Snoop Capture (HyperOS)

```bash
adb shell setprop persist.bluetooth.btsnoopenable true
adb shell setprop persist.bluetooth.btsnoopsize 0
# Reboot or restart bluetooth
# After pen init, pull:
adb pull /data/misc/bluetooth/logs/btsnoop_hci_*.log
# Combine and analyze with wireshark/tshark:
tshark -r combined.log -Y "btatt.opcode == 0x52" -T fields -e btatt.value
```

---

## 7. Known Issues & Limitations

1. **Request-response vs fire-and-forget**: Stock waits for fe12 ACK
   before each step. We use 20ms delays. Works but could be fragile
   with different firmware versions.

2. **Hardcoded payloads**: The `30xx`/`31xx`/`32xx`/`33xx`/`51xx`
   payloads are the output of dynamic builders for `uke` specifically.
   Other devices (dagu, liuqin, pipa) may need different values.

3. **No OTA/DFU support**: Firmware updates are not implemented.
   The `fef5` (Dialog SPOTA) and `fed0` (v2 OTA) services are
   handled by the stock `BluetoothExtension.apk` but not ported.

4. **MTU timing**: Init starts in `onMtuChanged`. If MTU negotiation
   fails or returns a different value, init won't start.

5. **ITouchFeature HAL dependency**: If the HAL service is not
   running or the AIDL interface changes, `setTouchMode` calls fail
   silently. The pen will init via BLE but produce dotted lines.

---

## 8. Source References

### Stock APKs (from Xiaomi Pad 7, `uke`, HyperOS BP2A.250605.031.A3)

| APK | Path on device | Size | Purpose |
|---|---|---|---|
| `BluetoothExtension.apk` | `/system_ext/app/BluetoothExtension/` | 34 MB | BLE GATT pen service |
| `TouchService.apk` | `/system_ext/priv-app/TouchService/` | 123 KB | Touch panel HAL coordination |

### Decompiled Sources

- `BluetoothExtension.apk` → jadx → `/tmp/BtExt_java/sources/`
  - 8,542 classes decompiled, 7 errors (resources only)
- `TouchService.apk` → apktool → `/tmp/TouchService_decompiled/smali/`
  - Smali bytecode only (no Java decompile attempted)

### Key Source Files

```
/tmp/BtExt_java/sources/com/android/bluetooth/ble/app/oobhelper/
  MiuiBleOobHelperService.java    # Main service (3109 lines)
  i.java                           # State machine Handler (794 lines)
  a.java                           # GATT callback (543 lines)
  f.java                           # UEvent observer
  h.java                           # Messenger handler
/tmp/BtExt_java/sources/y0/
  h.java                           # OTA manager (fef5 service)
  l.java                           # OTA v2 manager (fed0 service)
/tmp/BtExt_java/sources/com/android/bluetooth/ble/
  C0937h.java                      # Device feature detection
/tmp/TouchService_decompiled/smali/com/xiaomi/touchservice/
  ITouchFeature.smali              # Touch HAL wrapper
  pencilengine/PencilEngineManagerService.smali
```

### HCI Snoop Log

The init payload sequence was extracted from an 84 KB BTSnoop log
captured on a working HyperOS tablet during pen initialization:

```
/tmp/btsnooz_hci.log (pulled from /data/misc/bluetooth/logs/)
```

Verified payloads with:
```bash
tshark -r /tmp/btsnooz_hci.log -Y "btatt.opcode == 0x52" -T fields -e btatt.value
```

---

## 9. Pen Model Support Matrix

| Pen Name | BLE Name | Support |
|---|---|---|
| Xiaomi Focus Pen | `Xiaomi Focus Pen` | ✅ Full |
| Xiaomi Focus Pen Pro | `Xiaomi Focus Pen Pro` | ✅ Full (same protocol) |
| Xiaomi Smart Pen | `Xiaomi Smart Pen` | ⚠️ Same protocol, untested |
| N83C pen | `N83C pen` | ⚠️ Same protocol, untested |
| Redmi Smart Pen | `Redmi Smart Pen` | ⚠️ Same protocol, untested |
| POCO Smart Pen | `POCO Smart Pen` | ⚠️ Same protocol, untested |

All listed pens appear in the stock whitelist at `MiuiBleOobHelperService.java`
and use the same `fe10` GATT service with identical init flow.

---

## 10. Credits

- **Reverse engineering**: MiuiBleOobHelperService, ITouchFeature, C0937h
  decompiled from Xiaomi Pad 7 (uke) HyperOS firmware
- **HCI snoop analysis**: Payload sequence extracted from live BTSnoop capture
- **NVT touch panel analysis**: `setTouchMode(37, 1)` requirement traced to
  stock code line 991 of MiuiBleOobHelperService.java
- **AOSP implementation**: PenService.kt for LineageOS 24.0, `device/xiaomi/sm8635-common`
