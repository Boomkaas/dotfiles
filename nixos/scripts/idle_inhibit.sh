#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# This script is designed to manage the idle state of the system based on:
# 1. State file override (Caffeine mode)
# 2. Audio playback status
# 3. Power profile (Battery vs AC/Charging)

STATE_DIR="$HOME/.local/state/haku_theme"
STATE_FILE="$STATE_DIR/idle_inhibit"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Audio checking logic (PipeWire / PulseAudio)
# Checks if any audio sink is actively playing sound (State: RUNNING and not muted)
is_audio_playing() {
    if command -v pactl >/dev/null 2>&1; then
        pactl list sinks 2>/dev/null | awk '
            /^Sink #[0-9]+/ {
                if (state == "RUNNING" && mute == "no") found=1
                state=""; mute=""
            }
            /^[[:space:]]*State:[[:space:]]*/ { state=$2 }
            /^[[:space:]]*Mute:[[:space:]]*/ { mute=$2 }
            END {
                if (state == "RUNNING" && mute == "no") found=1
                exit !found
            }
        '
        if [ $? -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# Check if plugged into AC (electricity) power or charging
is_on_ac() {
    # 1. Check power supply mains / AC / USB adapters
    for ps in /sys/class/power_supply/*; do
        if [[ -f "$ps/type" ]]; then
            local type
            type=$(cat "$ps/type" 2>/dev/null)
            if [[ "$type" == "Mains" || "$type" == "USB" ]]; then
                if [[ -f "$ps/online" ]]; then
                    local online
                    online=$(cat "$ps/online" 2>/dev/null)
                    if [[ "$online" == "1" ]]; then
                        return 0
                    fi
                fi
            fi
        fi
    done

    # 2. Check battery status via sysfs (Charging only)
    for ps in /sys/class/power_supply/*; do
        if [[ -f "$ps/type" ]]; then
            local type
            type=$(cat "$ps/type" 2>/dev/null)
            if [[ "$type" == "Battery" && -f "$ps/status" ]]; then
                local status
                status=$(cat "$ps/status" 2>/dev/null)
                if [[ "$status" == "Charging" ]]; then
                    return 0
                fi
            fi
        fi
    done

    # 3. Fallback to upower if available
    if command -v upower >/dev/null 2>&1; then
        local ac_path
        ac_path=$(upower -e 2>/dev/null | grep -iE 'line_power|ac' | head -n 1)
        if [[ -n "$ac_path" ]]; then
            if upower -i "$ac_path" 2>/dev/null | grep -E "online:" | grep -Eq "\byes\b"; then
                return 0
            fi
        fi

        local bat_path
        bat_path=$(upower -e 2>/dev/null | grep 'battery' | head -n 1)
        if [[ -n "$bat_path" ]]; then
            if upower -i "$bat_path" 2>/dev/null | grep -E "state:" | grep -Eq "\b(charging|fully-charged)\b"; then
                return 0
            fi
        fi
    fi

    return 1
}

# Handle help argument
if [[ "$1" == "--help" ]]; then
    echo "Idle Inhibit Script: Handles screen idle prevention based on state file, audio playback, and power source."
    echo "Usage: $0 [--check | --toggle | --battery | --ac | --sleep | --help]"
    echo "  --check    Check if the screen is forced to stay on"
    echo "  --toggle   Toggle manual caffeine state (prevents or allows it to turn off)"
    echo "  --battery  Condition: Allow only when running on battery (NOT charging)"
    echo "  --ac       Condition: Allow only when connected to AC power (IS charging)"
    echo "  --sleep    Inhibit sleep/suspend when plugged into AC power (legacy)"
    echo "  --help     Show this help message"
    exit 0
fi

# Handle the check logic for the state file
if [[ "$1" == "--check" ]]; then
    if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "1" ]]; then
        echo "Hypridle: Forced Prevented (Screen cannot turn off)"
        echo "State: $(cat "$STATE_FILE" 2>/dev/null)"
        exit 0
    fi

    echo "Hypridle: Allowed (Screen can turn off)"
    exit 1
fi

# Handle the toggle logic
if [[ "$1" == "--toggle" ]]; then
    if command -v awake >/dev/null 2>&1; then
        exec awake toggle
    elif [[ -x "$HOME/.local/bin/awake" ]]; then
        exec "$HOME/.local/bin/awake" toggle
    fi

    if [[ -f "$STATE_FILE" ]]; then
        CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null)
    else
        CURRENT_STATE="0"
    fi

    if [[ "$CURRENT_STATE" == "1" ]]; then
        echo "0" > "$STATE_FILE"
        echo "Hypridle: Allowed (Screen can turn off)"
        notify-send "Hypridle" "Allowed (Screen can turn off)"
    else
        echo "1" > "$STATE_FILE"
        echo "Hypridle: Forced Prevented (Screen cannot turn off)"
        notify-send "Hypridle" "Forced Prevented (Screen cannot turn off)"
    fi
    exit 0
fi

# Check manual override state (1 = manual caffeine override to prevent idle actions)
if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "1" ]]; then
    exit 2
fi

# Power source condition checks
if [[ "$1" == "--battery" || "$1" == "--on-battery" || "$1" == "--sleep" || "$1" == "--suspend" || "$1" == "--check-sleep" ]]; then
    # Must be on battery (NOT charging)
    if is_on_ac; then
        exit 3
    fi
elif [[ "$1" == "--ac" || "$1" == "--on-ac" || "$1" == "--charging" ]]; then
    # Must be on AC power (IS charging)
    if ! is_on_ac; then
        exit 3
    fi
fi

exit 0