#!/usr/bin/env bash

# ==============================================================================
# Audio & Volume Menu for Rofi
# Controls volume, mutes, and selects output sinks / input microphones via wpctl.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 42%; height: 55%; } listview { lines: 11; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-audio-volume-high}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 2500
    fi
}

get_sink_volume() {
    local vol_raw
    vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.50")
    local vol_val
    vol_val=$(echo "$vol_raw" | grep -oP '\d+\.\d+' || echo "0.50")
    local vol_pct
    vol_pct=$(awk -v v="$vol_val" 'BEGIN { printf "%d", (v * 100) + 0.5 }')
    local is_muted=0
    echo "$vol_raw" | grep -qi "MUTED" && is_muted=1
    echo "$vol_pct:$is_muted"
}

get_source_volume() {
    local vol_raw
    vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo "Volume: 1.00")
    local vol_val
    vol_val=$(echo "$vol_raw" | grep -oP '\d+\.\d+' || echo "1.00")
    local vol_pct
    vol_pct=$(awk -v v="$vol_val" 'BEGIN { printf "%d", (v * 100) + 0.5 }')
    local is_muted=0
    echo "$vol_raw" | grep -qi "MUTED" && is_muted=1
    echo "$vol_pct:$is_muted"
}

select_sink() {
    local status_output
    status_output=$(wpctl status 2>/dev/null)
    local sinks_section
    sinks_section=$(echo "$status_output" | sed -n '/├─ Sinks:/,/├─ Sources:/p' | grep -E '^\s*│?\s*(\*|\s)\s*[0-9]+\.')

    local sink_lines=()
    declare -A SINK_ID_MAP

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local is_default=0
        echo "$line" | grep -q '\*' && is_default=1
        local id
        id=$(echo "$line" | grep -oP '\d+(?=\.)' | head -n1)
        [ -z "$id" ] && continue
        local name
        name=$(echo "$line" | sed -E 's/.*[0-9]+\.\s*//; s/\[.*//; s/\s+$//')

        local mark="  "
        [ "$is_default" -eq 1 ] && mark="✓ "

        local display_line
        display_line=$(printf "%s󰓃  %-30s (ID: %s)" "$mark" "$name" "$id")
        sink_lines+=("$display_line")
        SINK_ID_MAP["$display_line"]="$id"
    done <<< "$sinks_section"

    local sink_content=""
    for l in "${sink_lines[@]}"; do
        sink_content+="$l\n"
    done

    local choice
    choice=$(echo -e "$sink_content" | sed '/^$/d' | rofi -dmenu -i -p "Select Audio Output" -theme-str 'window { width: 45%; height: 40%; } listview { lines: 6; }')
    [ -z "$choice" ] && return

    local target_id="${SINK_ID_MAP["$choice"]}"
    if [ -n "$target_id" ]; then
        wpctl set-default "$target_id"
        notify normal audio-speakers "Audio Output Changed" "Active output set to ID $target_id"
    fi
}

select_source() {
    local status_output
    status_output=$(wpctl status 2>/dev/null)
    local sources_section
    sources_section=$(echo "$status_output" | sed -n '/├─ Sources:/,/├─ Filters:/p' | grep -E '^\s*│?\s*(\*|\s)\s*[0-9]+\.')

    local source_lines=()
    declare -A SOURCE_ID_MAP

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local is_default=0
        echo "$line" | grep -q '\*' && is_default=1
        local id
        id=$(echo "$line" | grep -oP '\d+(?=\.)' | head -n1)
        [ -z "$id" ] && continue
        local name
        name=$(echo "$line" | sed -E 's/.*[0-9]+\.\s*//; s/\[.*//; s/\s+$//')

        local mark="  "
        [ "$is_default" -eq 1 ] && mark="✓ "

        local display_line
        display_line=$(printf "%s󰍬  %-30s (ID: %s)" "$mark" "$name" "$id")
        source_lines+=("$display_line")
        SOURCE_ID_MAP["$display_line"]="$id"
    done <<< "$sources_section"

    local source_content=""
    for l in "${source_lines[@]}"; do
        source_content+="$l\n"
    done

    local choice
    choice=$(echo -e "$source_content" | sed '/^$/d' | rofi -dmenu -i -p "Select Microphone" -theme-str 'window { width: 45%; height: 40%; } listview { lines: 6; }')
    [ -z "$choice" ] && return

    local target_id="${SOURCE_ID_MAP["$choice"]}"
    if [ -n "$target_id" ]; then
        wpctl set-default "$target_id"
        notify normal audio-input-microphone "Microphone Changed" "Active microphone set to ID $target_id"
    fi
}

set_custom_volume() {
    local input
    input=$(rofi -dmenu -p "Set Volume (0-150%):" -theme-str 'window { width: 35%; height: 20%; } listview { lines: 1; }')
    [ -z "$input" ] && return
    local pct
    pct=$(echo "$input" | tr -dc '0-9')
    if [ -n "$pct" ]; then
        local frac
        frac=$(awk -v p="$pct" 'BEGIN { printf "%.2f", p / 100 }')
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "$frac"
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        notify normal audio-volume-high "Volume Set" "Output volume set to ${pct}%"
    fi
}

main_menu() {
    local sink_info
    sink_info=$(get_sink_volume)
    local sink_pct="${sink_info%%:*}"
    local sink_muted="${sink_info##*:}"

    local source_info
    source_info=$(get_source_volume)
    local source_pct="${source_info%%:*}"
    local source_muted="${source_info##*:}"

    local mute_label="󰝟  Mute Audio Output"
    local vol_icon=""
    if [ "$sink_muted" -eq 1 ]; then
        mute_label="󰕾  Unmute Audio Output"
        vol_icon="󰝟"
    elif [ "$sink_pct" -lt 30 ]; then
        vol_icon=""
    elif [ "$sink_pct" -lt 70 ]; then
        vol_icon=""
    fi

    local mic_label="󰍭  Mute Microphone"
    [ "$source_muted" -eq 1 ] && mic_label="󰍬  Unmute Microphone"

    local mute_tag=""
    [ "$sink_muted" -eq 1 ] && mute_tag=" [MUTED]"
    local mic_tag=""
    [ "$source_muted" -eq 1 ] && mic_tag=" [MUTED]"

    local menu_content=""
    menu_content+="$mute_label\n"
    menu_content+="$mic_label\n"
    menu_content+="  Set Volume: 100%\n"
    menu_content+="  Set Volume: 80%\n"
    menu_content+="  Set Volume: 60%\n"
    menu_content+="  Set Volume: 40%\n"
    menu_content+="  Set Volume: 20%\n"
    menu_content+="󰕾  Custom Volume (Enter Number)\n"
    menu_content+="󰓃  Select Output Device (Speakers / Headphones)\n"
    menu_content+="󰍬  Select Input Microphone (Source)\n"
    menu_content+="󰢻  Open Pavucontrol (Full GUI)"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local prompt_text="Audio ($vol_icon ${sink_pct}%$mute_tag | 󰍬 ${source_pct}%$mic_tag)"

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "$prompt_text" -theme-str "$ROFI_THEME_STR")
    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Mute Audio Output"*|*"Unmute Audio Output"*)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            local n_info
            n_info=$(get_sink_volume)
            if [ "${n_info##*:}" -eq 1 ]; then
                notify normal audio-volume-muted "Audio Output" "Muted"
            else
                notify normal audio-volume-high "Audio Output" "Unmuted (${n_info%%:*}%)"
            fi
            ;;
        *"Mute Microphone"*|*"Unmute Microphone"*)
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            local m_info
            m_info=$(get_source_volume)
            if [ "${m_info##*:}" -eq 1 ]; then
                notify normal audio-input-microphone-muted "Microphone" "Muted"
            else
                notify normal audio-input-microphone "Microphone" "Unmuted"
            fi
            ;;
        *"Set Volume: 100%"*)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.00
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            notify normal audio-volume-high "Volume" "Set to 100%"
            ;;
        *"Set Volume: 80%"*)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.80
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            notify normal audio-volume-high "Volume" "Set to 80%"
            ;;
        *"Set Volume: 60%"*)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.60
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            notify normal audio-volume-medium "Volume" "Set to 60%"
            ;;
        *"Set Volume: 40%"*)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.40
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            notify normal audio-volume-low "Volume" "Set to 40%"
            ;;
        *"Set Volume: 20%"*)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.20
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            notify normal audio-volume-low "Volume" "Set to 20%"
            ;;
        *"Custom Volume"*)
            set_custom_volume
            ;;
        *"Select Output Device"*)
            select_sink
            ;;
        *"Select Input Microphone"*)
            select_source
            ;;
        *"Open Pavucontrol"*)
            pavucontrol &
            ;;
        *)
            local num
            num=$(echo "$selected" | tr -dc '0-9')
            if [ -n "$num" ] && [ "$num" -le 150 ]; then
                local frac
                frac=$(awk -v p="$num" 'BEGIN { printf "%.2f", p / 100 }')
                wpctl set-volume @DEFAULT_AUDIO_SINK@ "$frac"
                notify normal audio-volume-high "Volume" "Set to ${num}%"
            fi
            ;;
    esac
}

main_menu "$@"
