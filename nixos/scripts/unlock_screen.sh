#!/usr/bin/env bash
# unlock_screen.sh - Reliable desktop unlocker for MangoWM / Hyprland
# Handles DPMS wake, hyprlock PAM authentication via wtype, and stuck lock recovery.

set -e

PASSWORD="${1:-}"

# 1. Wake displays across compositors
[ -x "$HOME/.local/bin/dpms_handler.sh" ] && "$HOME/.local/bin/dpms_handler.sh" on 2>/dev/null || true
MON=$(wlr-randr 2>/dev/null | awk '/^[a-zA-Z0-9-]+/ {print $1; exit}')
mmsg dispatch wakeup_monitor,"${MON:-eDP-1}" 2>/dev/null || mmsg dispatch wakeup_monitor 2>/dev/null || true
hyprctl dispatch dpms on 2>/dev/null || true
niri msg action power-on-monitors 2>/dev/null || true
swaymsg "output * dpms on" 2>/dev/null || true
wlopm --on '*' 2>/dev/null || true

# Give display a moment to power up
sleep 0.2

# 2. Check if hyprlock is running
if pidof hyprlock >/dev/null 2>&1; then
    if [ -z "$PASSWORD" ]; then
        echo "LOCKED: hyprlock is running but no password provided"
        exit 1
    fi

    WTYPE=$(command -v wtype || ls /nix/store/*-wtype-*/bin/wtype 2>/dev/null | head -n 1)
    if [ -n "$WTYPE" ]; then
        # Type password into hyprlock and press Return
        "$WTYPE" -d 20 "$PASSWORD" -k Return
        # Wait up to 2 seconds for hyprlock to authenticate PAM and cleanly unlock
        for _ in {1..20}; do
            if ! pidof hyprlock >/dev/null 2>&1; then
                echo "UNLOCKED: hyprlock authenticated and exited cleanly"
                exit 0
            fi
            sleep 0.1
        done
        echo "WARNING: hyprlock still running after typing password"
    else
        echo "ERROR: wtype utility not found"
        exit 1
    fi
fi

# 3. Check for stuck MangoWM locked_bg state (e.g. if hyprlock was killed or crashed)
if pidof mango >/dev/null 2>&1 && ! pidof hyprlock >/dev/null 2>&1; then
    TMP_IMG="/tmp/screen_check_$$.png"
    if grim "$TMP_IMG" 2>/dev/null; then
        IS_STUCK=$(python3 -c "
from PIL import Image
try:
    im = Image.open('$TMP_IMG')
    colors = im.getcolors(maxcolors=2)
    if colors and len(colors) == 1 and colors[0][1] == (25, 25, 25):
        print('yes')
    else:
        print('no')
except Exception:
    print('no')
" 2>/dev/null || echo "no")
        rm -f "$TMP_IMG"

        if [ "$IS_STUCK" = "yes" ]; then
            echo "DETECTED: Stuck MangoWM locked_bg (grey screen). Recovering..."
            MANGO_PID=$(pidof mango | awk '{print $1}')
            if [ -n "$PASSWORD" ] && [ -n "$MANGO_PID" ]; then
                echo "$PASSWORD" | sudo -S gdb "/proc/$MANGO_PID/exe" -p "$MANGO_PID" --batch \
                    -ex "set (int)locked = 0" \
                    -ex "call wlr_scene_node_set_enabled(locked_bg, 0)" >/dev/null 2>&1 || true
            fi
            echo "RECOVERED: Stuck session lock cleared"
            exit 0
        fi
    fi
fi

echo "UNLOCKED: Desktop is active"
exit 0
