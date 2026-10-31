# uke build patches

Small patches against upstream/other projects that our device tree needs.
They live here because a `repo sync` silently reverts the files they touch.

## 0001-sepolicy-vndr-hidraw-label.patch

Applies to `device/qcom/sepolicy_vndr/sm8650/generic/vendor/common/file_contexts`
(selected for uke via `UM_6_1_FAMILY` in `device/qcom/sepolicy_vndr/SEPolicy.mk`).

Without it, the build dies during sepolicy generation:

```
Multiple different specifications for /dev/hidraw[0-9]*
  (u:object_r:hidraw_device:s0 and u:object_r:vendor_hidraw_device:s0)
```

Reason: this device tree labels `/dev/hidraw[0-9]*` as `hidraw_device`
(`sepolicy/vendor/file_contexts`) so the system_ext stylus app can read the
Focus Pen reports. Qualcomm's policy labels the same path as
`vendor_hidraw_device`, and sepolicy refuses to merge two specs for one path.

Qualcomm's label is unused on uke — the only hidraw node present at runtime is
`/dev/hidraw0` (the pen, `HID_ID=0005:00000022:00005081`), so removing it costs
nothing and keeps `hal_sensors_default`'s (also unused) access rule harmless.

Apply after any `repo sync` that touches `device/qcom/sepolicy_vndr`:

```bash
cd <tree>
git apply device/xiaomi/uke/patches/0001-sepolicy-vndr-hidraw-label.patch
```

(Alternatively: `sed -i '/hidraw\[0-9\]\*.*vendor_hidraw_device/d' <file>`)

## Other build gotchas (not patches)

- `vendor/xiaomi/uke/radio/modem.img` is git-lfs. A sync without LFS objects
  leaves a 134-byte pointer and kati reports a SHA1 mismatch. Fix:
  `cd vendor/xiaomi/uke && git lfs install --local && git lfs pull`
- `external/chromium-webview/prebuilt/*/webview.apk` are also git-lfs; a stub
  makes signapk fail late with `zip END header not found`.
