#!/vendor/bin/sh
#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Caps Lock LED + keyboard backlight for Xiaomi Pad 7 (uke).
# Caps follows Caps Lock key; backlight adjusted with Ctrl+Alt+3 / Ctrl+Alt+4.

DEV=/dev/nanodev0
TAG="xiaomi_kbd_leds"

# Caps Lock feature command
CAPS_CMD=2e
CAPS_ON=fd
CAPS_OFF=fc

# Backlight (cmd 0x23, level 0-100)
BL_CMD=23
BL_MAX=100
BL_STEP=20
BL_DEFAULT=60
BL_NEED_CTRL=1
BL_NEED_ALT=1
BL_KEY_UP=KEY_4
BL_KEY_DOWN=KEY_3

logline() { log -t "$TAG" "$*"; }
sum_hex() { s=0; for h in "$@"; do s=$((s + 0x$h)); done; printf '%02x' $((s & 255)); }

send_frame() {
    fmt=""
    fn=0
    for h in "$@"; do
        fmt="$fmt\\$(printf '%03o' $((0x$h)))"
        fn=$((fn + 1))
    done
    [ $fn -gt 66 ] && { logline "frame >66 bytes, skipped"; return 1; }
    while [ $fn -lt 66 ]; do
        fmt="$fmt\\000"
        fn=$((fn + 1))
    done
    printf "$fmt" > "$DEV" 2>/dev/null
}

send_feature() {
    body="4e 31 80 38 $1 01 $2"
    send_frame 32 00 $body $(sum_hex $body)
}

bl_send() {
    send_feature "$BL_CMD" "$(printf '%02x' $1)"
    logline "backlight=$1"
}

find_capsdev() {
    cur_dev=""
    getevent -pl 2>/dev/null | while read -r w1 w2 w3 w4 rest; do
        if [ "$w1" = "add" ] && [ "$w2" = "device" ]; then
            cur_dev="$w4"
        fi
        case "$w1 $w2 $w3 $w4 $rest" in
            *LED_CAPSL*)
                echo "$cur_dev"
                break
                ;;
        esac
    done
}

bl=0
bllast=$BL_DEFAULT

run_session() {
    node=$1
    cs=off
    ctrl=0
    alt=0

    getevent -lq "$node" 2>/dev/null | while read -r a b c rest; do
        case "$b" in
            KEY_LEFTCTRL|KEY_RIGHTCTRL)
                [ "$c" = "DOWN" ] && ctrl=1
                [ "$c" = "UP" ] && ctrl=0
                ;;
            KEY_LEFTALT|KEY_RIGHTALT)
                [ "$c" = "DOWN" ] && alt=1
                [ "$c" = "UP" ] && alt=0
                ;;
            KEY_CAPSLOCK)
                [ "$c" = "DOWN" ] && {
                    if [ "$cs" = "on" ]; then
                        cs=off
                        send_feature "$CAPS_CMD" "$CAPS_OFF"
                        logline "caps OFF"
                    else
                        cs=on
                        send_feature "$CAPS_CMD" "$CAPS_ON"
                        logline "caps ON"
                    fi
                }
                ;;
            LED_CAPSL)
                case "$c" in
                    00000000|0)
                        [ "$cs" != "off" ] && {
                            cs=off
                            send_feature "$CAPS_CMD" "$CAPS_OFF"
                            logline "caps OFF (sync)"
                        }
                        ;;
                    *)
                        [ "$cs" != "on" ] && {
                            cs=on
                            send_feature "$CAPS_CMD" "$CAPS_ON"
                            logline "caps ON (sync)"
                        }
                        ;;
                esac
                ;;
        esac

        # Backlight combo
        if [ "$c" = "DOWN" ] && { [ "$BL_NEED_CTRL" = 0 ] || [ "$ctrl" = 1 ]; } && { [ "$BL_NEED_ALT" = 0 ] || [ "$alt" = 1 ]; }; then
            case "$b" in
                "$BL_KEY_UP")
                    bl=$((bl + BL_STEP))
                    [ $bl -gt $BL_MAX ] && bl=$BL_MAX
                    bllast=$bl
                    bl_send $bl
                    ;;
                "$BL_KEY_DOWN")
                    bl=$((bl - BL_STEP))
                    [ $bl -lt 0 ] && bl=0
                    [ $bl -gt 0 ] && bllast=$bl
                    bl_send $bl
                    ;;
            esac
        fi
    done
}

logline "## kbd_leds start"
while true; do
    capsdev=$(find_capsdev)
    if [ -n "$capsdev" ] && [ -e "$capsdev" ]; then
        logline "found capsdev=$capsdev; running session"
        run_session "$capsdev"
        logline "session ended for $capsdev; waiting"
    fi
    sleep 2
done
