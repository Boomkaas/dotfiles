#!/usr/bin/env bash
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:/run/wrappers/bin:$PATH"

# This script handles DPMS commands for different window managers.

# Auto-detect MANGO_INSTANCE_SIGNATURE if unset
if [ -z "$MANGO_INSTANCE_SIGNATURE" ]; then
    MANGO_SOCK=$(ls -t /run/user/$(id -u)/mango-*.sock 2>/dev/null | head -n 1)
    if [ -n "$MANGO_SOCK" ]; then
        export MANGO_INSTANCE_SIGNATURE="$MANGO_SOCK"
    fi
fi

WM=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

if [[ "$WM" =~ hyprland ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.dpms({ action = \"$1\" }))"
elif [[ "$WM" =~ niri ]]; then
    if [ "$1" = "on" ]; then
        niri msg action power-on-monitors
    else
        niri msg action power-off-monitors
    fi
elif [[ "$WM" =~ mango ]]; then
    MONITOR=$(wlr-randr 2>/dev/null | awk '/^[a-zA-Z0-9-]+/ {print $1; exit}')
    MONITOR=${MONITOR:-eDP-1}
    if [ "$1" = "on" ]; then
        mmsg dispatch wakeup_monitor,"$MONITOR" 2>/dev/null || mmsg dispatch wakeup_monitor 2>/dev/null || wlr-randr --output "$MONITOR" --on
    else
        mmsg dispatch sleep_monitor,"$MONITOR" 2>/dev/null || mmsg dispatch sleep_monitor 2>/dev/null || wlr-randr --output "$MONITOR" --off
    fi
elif [[ "$WM" =~ labwc ]]; then
    # Dynamically extract the first active display name (e.g., eDP-1)
    MONITOR=$(wlr-randr | awk '/^[a-zA-Z0-9-]+/ {print $1; exit}')
    
    if [ -n "$MONITOR" ]; then
        if [ "$1" = "on" ]; then
            wlr-randr --output "$MONITOR" --on
        else
            wlr-randr --output "$MONITOR" --off
        fi
    fi
fi

if [ "$1" = "on" ]; then
    ( sleep 0.5 && "$HOME/.local/bin/wallpaper_set.sh" --restore ) >/dev/null 2>&1 &
fi