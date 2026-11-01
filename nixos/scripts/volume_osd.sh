#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Volume OSD
# Changes the default sink volume (or toggles mute) and shows the resulting
# level as a notification. Launched from niri binds (F1/F2/F3), so it runs with
# a minimal environment and exports its own PATH above.
#
# Usage: volume_osd.sh up | down | mute
# ==============================================================================

SINK="@DEFAULT_AUDIO_SINK@"

case "${1:-}" in
    up)   wpctl set-volume -l 1.5 "$SINK" 5%+ ;;
    down) wpctl set-volume "$SINK" 5%- ;;
    mute) wpctl set-mute "$SINK" toggle ;;
    *)    echo "usage: ${0##*/} up|down|mute" >&2; exit 2 ;;
esac

# Read back the state after the change (wpctl prints e.g. "Volume: 0.40 [MUTED]").
raw=$(wpctl get-volume "$SINK" 2>/dev/null)
val=$(echo "$raw" | grep -oP '\d+\.\d+' | head -n1)
pct=$(awk -v v="${val:-0}" 'BEGIN { printf "%d", (v * 100) + 0.5 }')
muted=0
echo "$raw" | grep -qi "MUTED" && muted=1

if [ "$muted" -eq 1 ]; then
    icon="audio-volume-muted"
    title="Muted"
elif [ "$pct" -eq 0 ]; then
    icon="audio-volume-muted"
    title="Volume: 0%"
elif [ "$pct" -lt 33 ]; then
    icon="audio-volume-low"
    title="Volume: ${pct}%"
elif [ "$pct" -lt 66 ]; then
    icon="audio-volume-medium"
    title="Volume: ${pct}%"
else
    icon="audio-volume-high"
    title="Volume: ${pct}%"
fi

# Same synchronous hint on every call so a new notification replaces the last
# one instead of stacking; int:value draws a level bar in mako.
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Volume" -i "$icon" -t 1500 \
        -h string:x-canonical-private-synchronous:volume-osd \
        -h "int:value:${pct}" \
        "$title" ""
fi
