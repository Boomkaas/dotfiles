#!/usr/bin/env bash

# ==============================================================================
# Wi-Fi & Network Menu for Rofi
# Scans, displays, and connects to nearby Wi-Fi networks using nmcli & rofi.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 42%; height: 62%; } listview { lines: 12; }'
ROFI_PASS_THEME_STR='window { width: 35%; height: 22%; } listview { lines: 1; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-network-wireless}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 3000
    fi
}

get_active_ssid() {
    nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }'
}

get_wifi_status() {
    nmcli -t -f WIFI g 2>/dev/null || echo "disabled"
}

connect_to_ssid() {
    local ssid="$1"
    local security="$2"

    if [ -z "$ssid" ]; then
        return
    fi

    # Check if network profile is already saved
    local saved_connection
    saved_connection=$(nmcli -t -f NAME,TYPE con show 2>/dev/null | awk -F: -v s="$ssid" '$1 == s && $2 == "802-11-wireless" { print $1; exit }')

    if [ -n "$saved_connection" ]; then
        notify normal network-wireless "Wi-Fi" "Connecting to saved network: $ssid..."
        if nmcli con up id "$ssid" >/dev/null 2>&1; then
            notify normal network-wireless "Wi-Fi Connected" "Connected to $ssid"
        else
            notify critical network-error "Wi-Fi Failed" "Could not connect to saved profile $ssid. Try forgetting and reconnecting."
        fi
        return
    fi

    # If open network (no security)
    if [ -z "$security" ] || [ "$security" = "--" ]; then
        notify normal network-wireless "Wi-Fi" "Connecting to open network: $ssid..."
        if nmcli dev wifi connect "$ssid" >/dev/null 2>&1; then
            notify normal network-wireless "Wi-Fi Connected" "Connected to $ssid"
        else
            notify critical network-error "Wi-Fi Failed" "Failed to connect to open network $ssid"
        fi
        return
    fi

    # Secured network: prompt for password
    local pass
    pass=$(rofi -dmenu -password -p "Password for $ssid:" -theme-str "$ROFI_PASS_THEME_STR" -lines 0)
    
    if [ -z "$pass" ]; then
        # User cancelled password prompt
        return
    fi

    notify normal network-wireless "Wi-Fi" "Connecting to $ssid..."
    local err
    if err=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1); then
        notify normal network-wireless "Wi-Fi Connected" "Successfully connected to $ssid"
    else
        notify critical network-error "Wi-Fi Connection Failed" "$err"
    fi
}

manage_active_ssid() {
    local ssid="$1"
    local options="󰤮  Disconnect from \"$ssid\"
󰑐  Reconnect to \"$ssid\"
󰚃  Forget Network (Delete Saved Profile)
󰢻  Edit Connection Settings"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "$ssid" -theme-str 'window { width: 35%; height: 35%; } listview { lines: 4; }')

    case "$choice" in
        *"Disconnect"*)
            if nmcli con down id "$ssid" >/dev/null 2>&1; then
                notify normal network-wireless-disconnected "Wi-Fi" "Disconnected from $ssid"
            else
                nmcli dev disconnect iface "$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="wifi"{print $1; exit}')" >/dev/null 2>&1 || true
                notify normal network-wireless-disconnected "Wi-Fi" "Disconnected"
            fi
            ;;
        *"Reconnect"*)
            notify normal network-wireless "Wi-Fi" "Reconnecting to $ssid..."
            nmcli con up id "$ssid" >/dev/null 2>&1 || nmcli dev wifi connect "$ssid" >/dev/null 2>&1
            ;;
        *"Forget Network"*)
            if nmcli con delete id "$ssid" >/dev/null 2>&1; then
                notify normal user-trash "Wi-Fi" "Forgot network profile: $ssid"
            else
                notify critical network-error "Wi-Fi" "Could not delete profile $ssid"
            fi
            ;;
        *"Edit Connection Settings"*)
            nm-connection-editor &
            ;;
    esac
}

connect_hidden() {
    local hidden_ssid
    hidden_ssid=$(rofi -dmenu -p "Hidden SSID:" -theme-str "$ROFI_PASS_THEME_STR" -lines 0)
    [ -z "$hidden_ssid" ] && return

    local hidden_pass
    hidden_pass=$(rofi -dmenu -password -p "Password (leave empty if open):" -theme-str "$ROFI_PASS_THEME_STR" -lines 0)

    notify normal network-wireless "Wi-Fi" "Connecting to hidden network: $hidden_ssid..."
    local err
    if [ -n "$hidden_pass" ]; then
        err=$(nmcli dev wifi connect "$hidden_ssid" password "$hidden_pass" hidden yes 2>&1)
    else
        err=$(nmcli dev wifi connect "$hidden_ssid" hidden yes 2>&1)
    fi

    if [ $? -eq 0 ]; then
        notify normal network-wireless "Wi-Fi Connected" "Connected to $hidden_ssid"
    else
        notify critical network-error "Wi-Fi Connection Failed" "$err"
    fi
}

main_menu() {
    local wifi_status
    wifi_status=$(get_wifi_status)

    if [ "$wifi_status" = "disabled" ]; then
        local off_options="󰖩  Turn Wi-Fi ON
󰢻  Network Connections Editor (Advanced)
󰌢  NetworkManager TUI (nmtui)"

        local choice
        choice=$(echo -e "$off_options" | rofi -dmenu -i -p "󰖪 Wi-Fi Disabled" -theme-str 'window { width: 35%; height: 30%; } listview { lines: 3; }')
        case "$choice" in
            *"Turn Wi-Fi ON"*)
                nmcli radio wifi on
                notify normal network-wireless "Wi-Fi" "Wi-Fi enabled"
                sleep 0.5
                exec "$0" "$@"
                ;;
            *"Connections Editor"*)
                nm-connection-editor &
                ;;
            *"NetworkManager TUI"*)
                kitty --class nmtui -e nmtui &
                ;;
        esac
        exit 0
    fi

    local active_ssid
    active_ssid=$(get_active_ssid)

    # Fetch raw wifi list
    local raw_list
    raw_list=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ dev wifi list 2>/dev/null || true)

    # If no networks found, trigger rescan once
    if [ -z "$raw_list" ]; then
        nmcli dev wifi rescan >/dev/null 2>&1 || true
        sleep 1
        raw_list=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ dev wifi list 2>/dev/null || true)
    fi

    # Declare associative arrays for quick lookup
    declare -A SSID_MAP
    declare -A SEC_MAP
    declare -A ACTIVE_MAP
    declare -A SEEN_SSIDS
    declare -A BAND_MAP

    # First pass: find best signal and active status per unique SSID
    while IFS= read -r line; do
        [ -z "$line" ] && continue

        local in_use ssid signal security freq
        in_use=$(echo "$line" | cut -d: -f1)
        ssid=$(echo "$line" | cut -d: -f2)
        signal=$(echo "$line" | cut -d: -f3)
        security=$(echo "$line" | cut -d: -f4)
        freq=$(echo "$line" | cut -d: -f5)

        [ -z "$ssid" ] && continue
        [ "$ssid" = "--" ] && continue

        local sig_num
        sig_num=$(echo "$signal" | tr -dc '0-9')
        [ -z "$sig_num" ] && sig_num=0

        local band=""
        local f_num
        f_num=$(echo "$freq" | tr -dc '0-9')
        if [ -n "$f_num" ]; then
            if [ "$f_num" -gt 4000 ]; then band="5G"
            elif [ "$f_num" -gt 2000 ]; then band="2.4G"
            fi
        fi

        local is_act=0
        if [ "$in_use" = "*" ] || [ "$ssid" = "$active_ssid" ]; then
            is_act=1
        fi

        # Keep highest signal or active version of SSID
        if [ -z "${SEEN_SSIDS["$ssid"]+x}" ] || [ "$sig_num" -gt "${SEEN_SSIDS["$ssid"]}" ] || [ "$is_act" -eq 1 ]; then
            SEEN_SSIDS["$ssid"]="$sig_num"
            SEC_MAP["$ssid"]="$security"
            ACTIVE_MAP["$ssid"]="$is_act"
            BAND_MAP["$ssid"]="$band"
        fi
    done <<< "$raw_list"

    # Second pass: format display items for unique SSIDs
    local network_lines=()
    for s in "${!SEEN_SSIDS[@]}"; do
        local sig_val="${SEEN_SSIDS["$s"]}"
        local sec_val="${SEC_MAP["$s"]}"
        local is_act_val="${ACTIVE_MAP["$s"]}"
        local band_val="${BAND_MAP["$s"]}"

        local sig_icon="󰤯"
        if [ "$sig_val" -ge 80 ]; then sig_icon="󰤨"
        elif [ "$sig_val" -ge 60 ]; then sig_icon="󰤥"
        elif [ "$sig_val" -ge 40 ]; then sig_icon="󰤢"
        elif [ "$sig_val" -ge 20 ]; then sig_icon="󰤟"
        fi

        local sec_icon="  "
        if [ -n "$sec_val" ] && [ "$sec_val" != "--" ]; then
            sec_icon="󰌾"
        fi

        local act_mark="  "
        if [ "$is_act_val" -eq 1 ]; then
            act_mark="✓ "
        fi

        local sec_label="$sec_val"
        [ -z "$sec_label" ] || [ "$sec_label" = "--" ] && sec_label="Open"

        local formatted_line
        if [ -n "$band_val" ]; then
            formatted_line=$(printf "%s%s %s  %-24s (%d%%  %s  %s)" "$act_mark" "$sig_icon" "$sec_icon" "$s" "$sig_val" "$band_val" "$sec_label")
        else
            formatted_line=$(printf "%s%s %s  %-24s (%d%%  %s)" "$act_mark" "$sig_icon" "$sec_icon" "$s" "$sig_val" "$sec_label")
        fi

        SSID_MAP["$formatted_line"]="$s"
        network_lines+=("$formatted_line")
    done

    # Sort networks: active network first (starts with ✓), then by signal strength / line
    local sorted_networks=""
    if [ ${#network_lines[@]} -gt 0 ]; then
        sorted_networks=$(printf "%s\n" "${network_lines[@]}" | sort -k1,1r -k5,5nr)
    fi

    # Build full menu options
    local menu_content=""
    menu_content+="󰑐  Rescan Available Networks\n"
    if [ -n "$active_ssid" ]; then
        menu_content+="󰤮  Disconnect from \"$active_ssid\"\n"
    fi
    menu_content+="󰛐  Connect to Hidden Network...\n"
    menu_content+="󰖪  Turn Wi-Fi OFF\n"

    if [ -n "$sorted_networks" ]; then
        menu_content+="$sorted_networks\n"
    else
        menu_content+="--- No Wi-Fi Networks Found ---\n"
    fi

    menu_content+="󰢻  Network Connections Editor (Advanced)\n"
    menu_content+="󰌢  NetworkManager TUI (nmtui)"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local prompt_text="󰖩 Wi-Fi"
    [ -n "$active_ssid" ] && prompt_text="󰖩 Wi-Fi ($active_ssid)"

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "$prompt_text" -theme-str "$ROFI_THEME_STR")

    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Rescan Available Networks"*)
            notify normal network-wireless "Wi-Fi" "Scanning for nearby networks..."
            nmcli dev wifi rescan >/dev/null 2>&1 || true
            sleep 1.2
            exec "$0" "$@"
            ;;
        *"Disconnect from"*)
            if [ -n "$active_ssid" ]; then
                nmcli con down id "$active_ssid" >/dev/null 2>&1 || nmcli dev disconnect iface "$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="wifi"{print $1; exit}')" >/dev/null 2>&1 || true
                notify normal network-wireless-disconnected "Wi-Fi" "Disconnected from $active_ssid"
            fi
            ;;
        *"Connect to Hidden Network"*)
            connect_hidden
            ;;
        *"Turn Wi-Fi OFF"*)
            nmcli radio wifi off
            notify normal network-wireless-disconnected "Wi-Fi" "Wi-Fi disabled"
            ;;
        *"Network Connections Editor"*)
            nm-connection-editor &
            ;;
        *"NetworkManager TUI"*)
            kitty --class nmtui -e nmtui &
            ;;
        *"No Wi-Fi Networks Found"*)
            exit 0
            ;;
        *)
            local target_ssid="${SSID_MAP["$selected"]}"
            if [ -n "$target_ssid" ]; then
                if [ "${ACTIVE_MAP["$target_ssid"]}" = "1" ]; then
                    manage_active_ssid "$target_ssid"
                else
                    connect_to_ssid "$target_ssid" "${SEC_MAP["$target_ssid"]}"
                fi
            else
                local fallback_ssid
                fallback_ssid=$(echo "$selected" | awk '{print $3}')
                if [ -n "$fallback_ssid" ]; then
                    connect_to_ssid "$fallback_ssid" ""
                fi
            fi
            ;;
    esac
}

main_menu "$@"
