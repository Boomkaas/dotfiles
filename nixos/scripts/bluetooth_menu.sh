#!/usr/bin/env bash

# ==============================================================================
# Bluetooth Menu for Rofi
# Scans, displays, connects, pairs, and manages Bluetooth devices via bluetoothctl & rofi.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 42%; height: 62%; } listview { lines: 12; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-bluetooth}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 3000
    fi
}

get_power_status() {
    if bluetoothctl show 2>/dev/null | grep -qi "Powered: yes"; then
        echo "on"
    else
        echo "off"
    fi
}

get_device_icon() {
    local mac="$1"
    local name="$2"

    local lower_name
    lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    if [[ "$lower_name" =~ (headphone|headset|earbud|airpod|wh-|wf-|tune|sound|buds) ]]; then
        echo "󰋋"
    elif [[ "$lower_name" =~ (speaker|audio|soundbar) ]]; then
        echo "󰓃"
    elif [[ "$lower_name" =~ (keyboard|keychron) ]]; then
        echo "󰌌"
    elif [[ "$lower_name" =~ (mouse|trackpad|mx\ master) ]]; then
        echo "󰍽"
    elif [[ "$lower_name" =~ (controller|gamepad|xbox|ps4|ps5|switch) ]]; then
        echo "󰊴"
    elif [[ "$lower_name" =~ (phone|iphone|galaxy|pixel|android) ]]; then
        echo "󰏲"
    elif [[ "$lower_name" =~ (laptop|pc|desktop) ]]; then
        echo "󰌢"
    else
        echo "󰂯"
    fi
}

scan_devices() {
    notify normal bluetooth "Bluetooth" "Scanning for nearby devices (5 seconds)..."
    bluetoothctl --timeout 5 scan on >/dev/null 2>&1 || true
    notify normal bluetooth "Bluetooth" "Scan complete. Refreshing devices..."
    sleep 0.5
    exec "$0" "$@"
}

manage_connected_device() {
    local mac="$1"
    local name="$2"

    local options="󰂭  Disconnect from \"$name\"
󰚃  Forget / Remove Device ($name)
󰌢  Show Device Details"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "$name" -theme-str 'window { width: 35%; height: 32%; } listview { lines: 3; }')

    case "$choice" in
        *"Disconnect"*)
            notify normal bluetooth "Bluetooth" "Disconnecting from $name..."
            if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
                notify normal bluetooth "Bluetooth" "Disconnected from $name"
            else
                notify critical network-error "Bluetooth Failed" "Could not disconnect from $name"
            fi
            ;;
        *"Forget / Remove"*)
            if bluetoothctl remove "$mac" >/dev/null 2>&1; then
                notify normal user-trash "Bluetooth" "Removed device: $name"
            else
                notify critical network-error "Bluetooth Failed" "Could not remove device $name"
            fi
            ;;
        *"Show Device Details"*)
            local info
            info=$(bluetoothctl info "$mac" 2>/dev/null | grep -E "Name|Alias|Paired|Connected|Battery|Trusted" || echo "No details available")
            notify normal bluetooth "Bluetooth Device Info" "$info"
            ;;
    esac
}

manage_paired_device() {
    local mac="$1"
    local name="$2"

    local options="󰂱  Connect to \"$name\"
󰚃  Forget / Remove Device ($name)
󰌢  Show Device Details"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "$name" -theme-str 'window { width: 35%; height: 32%; } listview { lines: 3; }')

    case "$choice" in
        *"Connect"*)
            notify normal bluetooth "Bluetooth" "Connecting to $name..."
            if bluetoothctl connect "$mac" >/dev/null 2>&1; then
                notify normal bluetooth "Bluetooth Connected" "Connected to $name"
            else
                notify critical network-error "Bluetooth Failed" "Could not connect to $name. Make sure it is powered on and in range."
            fi
            ;;
        *"Forget / Remove"*)
            if bluetoothctl remove "$mac" >/dev/null 2>&1; then
                notify normal user-trash "Bluetooth" "Removed device: $name"
            else
                notify critical network-error "Bluetooth Failed" "Could not remove device $name"
            fi
            ;;
        *"Show Device Details"*)
            local info
            info=$(bluetoothctl info "$mac" 2>/dev/null | grep -E "Name|Alias|Paired|Connected|Battery|Trusted" || echo "No details available")
            notify normal bluetooth "Bluetooth Device Info" "$info"
            ;;
    esac
}

manage_unpaired_device() {
    local mac="$1"
    local name="$2"

    local options="󰂱  Pair & Connect to \"$name\"
󰚃  Ignore / Remove Device"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "New Device: $name" -theme-str 'window { width: 35%; height: 28%; } listview { lines: 2; }')

    case "$choice" in
        *"Pair & Connect"*)
            notify normal bluetooth "Bluetooth" "Pairing with $name ($mac)..."
            bluetoothctl trust "$mac" >/dev/null 2>&1 || true
            if bluetoothctl pair "$mac" >/dev/null 2>&1; then
                notify normal bluetooth "Bluetooth" "Paired successfully. Connecting..."
                sleep 0.5
                if bluetoothctl connect "$mac" >/dev/null 2>&1; then
                    notify normal bluetooth "Bluetooth Connected" "Successfully connected to $name"
                else
                    notify normal bluetooth "Bluetooth Paired" "Device paired. Reconnect when ready."
                fi
            else
                notify critical network-error "Bluetooth Pairing Failed" "Could not pair with $name. Ensure pairing mode is active."
            fi
            ;;
        *"Ignore / Remove"*)
            bluetoothctl remove "$mac" >/dev/null 2>&1 || true
            ;;
    esac
}

main_menu() {
    local power_status
    power_status=$(get_power_status)

    if [ "$power_status" = "off" ]; then
        local off_options="󰂯  Turn Bluetooth ON
󰢻  Open Blueman Device Manager
󰌢  Open Bluetoothctl Console"

        local choice
        choice=$(echo -e "$off_options" | rofi -dmenu -i -p "󰂲 Bluetooth Disabled" -theme-str 'window { width: 35%; height: 30%; } listview { lines: 3; }')
        case "$choice" in
            *"Turn Bluetooth ON"*)
                bluetoothctl power on
                notify normal bluetooth "Bluetooth" "Bluetooth powered on"
                sleep 0.5
                exec "$0" "$@"
                ;;
            *"Blueman"*)
                blueman-manager &
                ;;
            *"Bluetoothctl"*)
                kitty --class bluetooth -e bluetoothctl &
                ;;
        esac
        exit 0
    fi

    # Maps for classification
    declare -A CONNECTED_MAP
    declare -A PAIRED_MAP
    declare -A DEVICE_NAME_MAP
    declare -A DEVICE_TYPE_MAP
    declare -A DEVICE_MAC_MAP

    while read -r _ mac _; do
        [ -n "$mac" ] && CONNECTED_MAP["$mac"]=1
    done < <(bluetoothctl devices Connected 2>/dev/null || true)

    while read -r _ mac _; do
        [ -n "$mac" ] && PAIRED_MAP["$mac"]=1
    done < <(bluetoothctl devices Paired 2>/dev/null || true)

    local connected_lines=()
    local paired_lines=()
    local available_lines=()
    local beacon_lines=()

    while read -r _ mac name; do
        [ -z "$mac" ] && continue
        [ -z "$name" ] && name="$mac"

        DEVICE_NAME_MAP["$mac"]="$name"

        local icon
        icon=$(get_device_icon "$mac" "$name")

        local clean_mac clean_name
        clean_mac=$(echo "$mac" | tr -d ":-")
        clean_name=$(echo "$name" | tr -d ":-")

        if [ "${CONNECTED_MAP["$mac"]}" = "1" ]; then
            local line
            line=$(printf "✓ %s  %-26s [Connected]" "$icon" "$name")
            connected_lines+=("$line")
            DEVICE_MAC_MAP["$line"]="$mac"
            DEVICE_TYPE_MAP["$line"]="connected"
        elif [ "${PAIRED_MAP["$mac"]}" = "1" ]; then
            local line
            line=$(printf "  %s  %-26s [Paired]" "$icon" "$name")
            paired_lines+=("$line")
            DEVICE_MAC_MAP["$line"]="$mac"
            DEVICE_TYPE_MAP["$line"]="paired"
        elif [ "$clean_mac" != "$clean_name" ]; then
            # Named discovered device
            local line
            line=$(printf "  %s  %-26s [Discovered / Available]" "$icon" "$name")
            available_lines+=("$line")
            DEVICE_MAC_MAP["$line"]="$mac"
            DEVICE_TYPE_MAP["$line"]="unpaired"
        else
            # Unnamed beacon / raw MAC
            local line
            line=$(printf "  󰛐  %-26s [Beacon]" "$name")
            beacon_lines+=("$line")
            DEVICE_MAC_MAP["$line"]="$mac"
            DEVICE_TYPE_MAP["$line"]="unpaired"
        fi
    done < <(bluetoothctl devices 2>/dev/null || true)

    local menu_content=""

    # Header actions
    menu_content+="󰑐  Scan for Nearby Devices (5s)\n"
    menu_content+="󰂲  Turn Bluetooth OFF\n"

    # Connected devices first
    if [ ${#connected_lines[@]} -gt 0 ]; then
        for line in "${connected_lines[@]}"; do
            menu_content+="$line\n"
        done
    fi

    # Paired devices second
    if [ ${#paired_lines[@]} -gt 0 ]; then
        for line in "${paired_lines[@]}"; do
            menu_content+="$line\n"
        done
    fi

    # Discovered / new nearby devices third
    if [ ${#available_lines[@]} -gt 0 ]; then
        for line in "${available_lines[@]}"; do
            menu_content+="$line\n"
        done
    fi

    # Raw beacons at the bottom if any
    if [ ${#beacon_lines[@]} -gt 0 ]; then
        for line in "${beacon_lines[@]}"; do
            menu_content+="$line\n"
        done
    fi

    if [ ${#connected_lines[@]} -eq 0 ] && [ ${#paired_lines[@]} -eq 0 ] && [ ${#available_lines[@]} -eq 0 ] && [ ${#beacon_lines[@]} -eq 0 ]; then
        menu_content+="--- No Bluetooth Devices Found (Click Scan above) ---\n"
    fi

    # Footer actions
    menu_content+="󰢻  Open Blueman Device Manager\n"
    menu_content+="󰌢  Open Bluetoothctl Console"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local prompt_text="󰂯 Bluetooth"
    if [ ${#connected_lines[@]} -gt 0 ]; then
        prompt_text="󰂯 Bluetooth (${#connected_lines[@]} connected)"
    fi

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "$prompt_text" -theme-str "$ROFI_THEME_STR")

    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Scan for Nearby Devices"*)
            scan_devices "$@"
            ;;
        *"Turn Bluetooth OFF"*)
            bluetoothctl power off
            notify normal bluetooth "Bluetooth" "Bluetooth powered off"
            ;;
        *"Open Blueman"*)
            blueman-manager &
            ;;
        *"Open Bluetoothctl"*)
            kitty --class bluetooth -e bluetoothctl &
            ;;
        *"No Bluetooth Devices Found"*)
            exit 0
            ;;
        *)
            local target_mac="${DEVICE_MAC_MAP["$selected"]}"
            local target_type="${DEVICE_TYPE_MAP["$selected"]}"
            local target_name="${DEVICE_NAME_MAP["$target_mac"]}"

            if [ -n "$target_mac" ]; then
                case "$target_type" in
                    "connected")
                        manage_connected_device "$target_mac" "$target_name"
                        ;;
                    "paired")
                        manage_paired_device "$target_mac" "$target_name"
                        ;;
                    "unpaired")
                        manage_unpaired_device "$target_mac" "$target_name"
                        ;;
                esac
            fi
            ;;
    esac
}

main_menu "$@"
