#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Brightness OSD
# Changes the display backlight by 5% and shows the resulting level as a
# notification. Launched from niri binds (Fn+F4/F5), so it runs with a minimal
# environment and exports its own PATH above.
#
# Usage: brightness_osd.sh up | down
# ==============================================================================

case "${1:-}" in
    up)   brightnessctl set 5%+ >/dev/null ;;
    down) brightnessctl set 5%- >/dev/null ;;
    *)    echo "usage: ${0##*/} up|down" >&2; exit 2 ;;
esac

# brightnessctl -m: "device,class,current,percent%,max"
pct=$(brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%')
pct=${pct:-0}

if [ "$pct" -eq 0 ]; then
    icon="display-brightness-off"
elif [ "$pct" -lt 33 ]; then
    icon="display-brightness-low"
elif [ "$pct" -lt 66 ]; then
    icon="display-brightness-medium"
else
    icon="display-brightness-high"
fi

# Same synchronous hint on every call so a new notification replaces the last
# one instead of stacking; int:value draws a level bar in mako.
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Brightness" -i "$icon" -t 1500 \
        -h string:x-canonical-private-synchronous:brightness-osd \
        -h "int:value:${pct}" \
        "Brightness: ${pct}%" ""
fi
