#!/usr/bin/env bash

# ==============================================================================
# Disk & Storage Manager for Rofi
# Inspects disk partitions, mounts, and storage utilization directly in Rofi.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 44%; height: 50%; } listview { lines: 8; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-drive-harddisk}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 2500
    fi
}

manage_mount() {
    local mountpoint="$1"
    local filesystem="$2"

    local options="󁁤  Open Mountpoint in File Manager (Thunar)
  Open Terminal at Mountpoint
󰌢  Analyze Space Usage with ncdu
󰢻  Open Full GParted GUI"

    local choice
    choice=$(echo -e "$options" | rofi -dmenu -i -p "Drive: $mountpoint ($filesystem)" -theme-str 'window { width: 38%; height: 35%; } listview { lines: 4; }')
    [ -z "$choice" ] && return

    case "$choice" in
        *"File Manager"*)
            thunar "$mountpoint" &
            ;;
        *"Open Terminal"*)
            kitty --directory "$mountpoint" &
            ;;
        *"Analyze Space Usage"*)
            kitty --class ncdu -e ncdu "$mountpoint" &
            ;;
        *"Open Full GParted"*)
            gparted &
            ;;
    esac
}

main_menu() {
    declare -A MOUNT_MAP
    declare -A FS_MAP

    local disk_lines=()

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local fs size used avail pcent target
        fs=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        avail=$(echo "$line" | awk '{print $4}')
        pcent=$(echo "$line" | awk '{print $5}')
        target=$(echo "$line" | awk '{print $6}')

        [ -z "$fs" ] || [ "$fs" = "Filesystem" ] && continue

        local icon="󰋊"
        [ "$target" = "/" ] && icon="󰋊"
        [ "$target" = "/boot" ] && icon="󰌢"
        [ "$target" = "/home" ] && icon="󰋜"

        local display_line
        display_line=$(printf "%s  %-12s %5s / %-5s (%4s used)  Free: %-5s" "$icon" "$target" "$used" "$size" "$pcent" "$avail")
        disk_lines+=("$display_line")
        MOUNT_MAP["$display_line"]="$target"
        FS_MAP["$target"]="$fs"
    done < <(df -h -x tmpfs -x devtmpfs -x efivarfs -x squashfs 2>/dev/null)

    local menu_content=""
    menu_content+="󰑐  Refresh Storage Status\n"
    menu_content+="󰢻  Open Full GParted GUI\n"
    menu_content+="󰌢  Run Disk Analyzer (ncdu ~)\n"

    for l in "${disk_lines[@]}"; do
        menu_content+="$l\n"
    done

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "Storage" -theme-str "$ROFI_THEME_STR")
    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Refresh Storage Status"*)
            exec "$0" "$@"
            ;;
        *"Open Full GParted"*)
            gparted &
            ;;
        *"Run Disk Analyzer"*)
            kitty --class ncdu -e ncdu "$HOME" &
            ;;
        *)
            local target_mount="${MOUNT_MAP["$selected"]}"
            if [ -n "$target_mount" ]; then
                manage_mount "$target_mount" "${FS_MAP["$target_mount"]}"
            fi
            ;;
    esac
}

main_menu "$@"
