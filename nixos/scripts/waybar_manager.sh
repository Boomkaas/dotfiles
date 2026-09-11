#!/usr/bin/env bash

# Manage Waybar modes via symlinks, Rofi selection, mode cycling, and random mode on startup.

# Include WAYBAR_MODE_USER
[ -f "$HOME/hakuspace-control/main_setting.sh" ] && source "$HOME/hakuspace-control/main_setting.sh"

WAYBAR_DIR="$HOME/.config/waybar"
USER_WAYBAR_DIR="$HOME/hakuspace-control/waybar"
STATE_FILE="$HOME/.local/state/haku_theme/waybar_current_mode"
CURRENT_STATE="jakoolit-sleek"

# Use installed user waybar modes
WAYBAR_MODES=("${WAYBAR_MODE_USER[@]}")

# If empty, dynamically list available themes
if [[ ${#WAYBAR_MODES[@]} -eq 0 ]]; then
    if [[ -d "$USER_WAYBAR_DIR" ]]; then
        for d in "$USER_WAYBAR_DIR"/*; do
            [[ -d "$d" ]] && WAYBAR_MODES+=("$(basename "$d")")
        done
    fi
fi

# Init state file if missing or invalid
if [[ -f "$STATE_FILE" ]]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
    valid=false
    for m in "${WAYBAR_MODES[@]}"; do
        if [[ "$m" == "$CURRENT_STATE" ]]; then
            valid=true
            break
        fi
    done
    if [[ "$valid" == "false" && ${#WAYBAR_MODES[@]} -gt 0 ]]; then
        CURRENT_STATE="${WAYBAR_MODES[0]}"
        echo "$CURRENT_STATE" > "$STATE_FILE"
    fi
else
    mkdir -p "$(dirname "$STATE_FILE")"
    if [[ ${#WAYBAR_MODES[@]} -gt 0 ]]; then
        CURRENT_STATE="${WAYBAR_MODES[0]}"
    fi
    echo "$CURRENT_STATE" > "$STATE_FILE"
fi

# Link selected mode files to main config directory
link_mode() {
    local mode="$1"
    local target_dir=""

    if [[ -d "$USER_WAYBAR_DIR/$mode" ]]; then
        target_dir="$USER_WAYBAR_DIR/$mode"
    elif [[ -d "$WAYBAR_DIR/$mode" ]]; then
        target_dir="$WAYBAR_DIR/$mode"
    else
        notify-send "Waybar Error" "Mode directory not found: $mode"
        exit 1
    fi

    ln -sfn "$target_dir/config" "$WAYBAR_DIR/config"
    ln -sfn "$target_dir/style.css" "$WAYBAR_DIR/style.css"
    echo "$mode" > "$STATE_FILE"
    CURRENT_STATE="$mode"
}

# Get running Waybar PIDs (excluding dockbar and waybar_manager)
get_waybar_pids() {
    local pids=()
    local raw_pids
    raw_pids=$( (pgrep -x waybar 2>/dev/null; pgrep -x .waybar-wrapped 2>/dev/null; pgrep -fx waybar 2>/dev/null) | sort -u )
    for pid in $raw_pids; do
        local cmd
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        [[ -z "$cmd" ]] && cmd=$(ps -p "$pid" -o args= 2>/dev/null)
        if [[ "$cmd" != *"dockbar"* && "$cmd" != *"waybar_manager"* ]]; then
            pids+=("$pid")
        fi
    done
    echo "${pids[@]}"
}

# Start or restart Waybar
restart_waybar() {
    if [[ "$XDG_CURRENT_DESKTOP" == "niri" ]]; then
        if grep -q "1" /tmp/cava_underbar_status 2>/dev/null; then
            $HOME/.local/bin/cava_manager.sh --toggle
        fi
    fi

    local pids
    pids=($(get_waybar_pids))
    if [[ ${#pids[@]} -gt 0 ]]; then
        kill "${pids[@]}" 2>/dev/null
        sleep 0.2
    fi

    setsid -f waybar >/tmp/waybar.log 2>&1
}

# Handle --toggle argument to toggle Waybar on/off
if [[ "$1" == "--toggle" ]]; then
    pids=($(get_waybar_pids))
    if [[ ${#pids[@]} -gt 0 ]]; then
        kill "${pids[@]}" 2>/dev/null
    else
        restart_waybar
    fi
    exit 0
fi

# Handle --startup argument to restore current mode without randomizing
if [[ "$1" == "--startup" ]]; then
    if [[ ! -L "$WAYBAR_DIR/config" ]] || [[ ! -L "$WAYBAR_DIR/style.css" ]] || [[ ! -e "$WAYBAR_DIR/config" ]] || [[ ! -e "$WAYBAR_DIR/style.css" ]]; then
        link_mode "$CURRENT_STATE"
    fi
    pids=($(get_waybar_pids))
    if [[ ${#pids[@]} -eq 0 ]]; then
        setsid -f waybar >/tmp/waybar.log 2>&1
    fi
    exit 0
fi

# Handle --random argument to pick a random Waybar layout
if [[ "$1" == "--random" ]]; then
    if [[ ${#WAYBAR_MODES[@]} -gt 0 ]]; then
        random_idx=$(( RANDOM % ${#WAYBAR_MODES[@]} ))
        random_mode="${WAYBAR_MODES[$random_idx]}"
        link_mode "$random_mode"
        restart_waybar
    fi
    exit 0
fi

# Handle --cycle argument to toggle through the MODES array
if [[ "$1" == "--cycle" ]]; then
    current_idx=-1
    for i in "${!WAYBAR_MODES[@]}"; do
        if [[ "${WAYBAR_MODES[$i]}" == "$CURRENT_STATE" ]]; then
            current_idx=$i
            break
        fi
    done

    next_idx=$(( (current_idx + 1) % ${#WAYBAR_MODES[@]} ))
    next_mode="${WAYBAR_MODES[$next_idx]}"

    if [[ "$next_mode" != "$CURRENT_STATE" ]]; then
        link_mode "$next_mode"
        restart_waybar
    fi
    exit 0
fi

# Handle --select argument via Rofi
if [[ "$1" == "--select" ]]; then
    choice=$(printf "%s\n" "${WAYBAR_MODES[@]}" | rofi -dmenu -p "Waybar" -i -theme-str 'window {width: 25%; height: 40%;} entry { placeholder: " Select Mode"; }')
    [[ -z "$choice" ]] && exit 0

    if [[ "$choice" != "$CURRENT_STATE" ]]; then
        link_mode "$choice"
        restart_waybar
    fi
    exit 0
fi

# Ensure symlinks exist and are valid
if [[ ! -L "$WAYBAR_DIR/config" ]] || [[ ! -L "$WAYBAR_DIR/style.css" ]] || [[ ! -e "$WAYBAR_DIR/config" ]] || [[ ! -e "$WAYBAR_DIR/style.css" ]]; then
    link_mode "$CURRENT_STATE"
fi

# Auto-start Waybar if not running
pids=($(get_waybar_pids))
if [[ ${#pids[@]} -eq 0 ]]; then
    setsid -f waybar >/tmp/waybar.log 2>&1
fi