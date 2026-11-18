#!/vendor/bin/sh
#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Binds the keyboard's virtual HID while it is connected, and starts/stops
# the auth daemon and LEDs through vendor.devauth.keyboard_connected.

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
