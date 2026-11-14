#!/vendor/bin/sh
#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Connection-aware Xiaomi keyboard handling for Xiaomi Pad 7 (uke).
#
# Binds the virtual HID when keyboard reports Connected=[1] and unbinds when detached,
# so the on-screen keyboard functions properly when detached.
# Controls vendor.devauth.keyboard_connected to start/stop the auth daemon and LEDs.

HID="0006:15D9:00A3.0001"
DRV="/sys/bus/hid/drivers/hid-generic"
STATE="/sys/class/nanodev/nanodev0/_version176x"
TAG="xiaomi_kbd"
POLL=2

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done
sleep 2

last=""
while true; do
    if grep -q 'Connected=\[1\]' "$STATE" 2>/dev/null; then cur=1; else cur=0; fi
    if [ "$cur" != "$last" ]; then
        if [ "$cur" = "1" ]; then
            [ -e "$DRV/$HID" ] && echo "$HID" > "$DRV/unbind" && sleep 1
            echo "$HID" > "$DRV/bind" && log -t "$TAG" "keyboard attached: HID bound"
            setprop vendor.devauth.keyboard_connected true
        else
            [ -e "$DRV/$HID" ] && echo "$HID" > "$DRV/unbind" && log -t "$TAG" "keyboard detached: HID unbound"
            setprop vendor.devauth.keyboard_connected false
        fi
        last="$cur"
    fi
    sleep "$POLL"
done
