#!/usr/bin/env bash

# ==============================================================================
# Configuration Files & Folders Picker for Rofi
# Allows selecting and editing specific config targets without opening everything at once.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 44%; height: 55%; } listview { lines: 10; }'

open_target() {
    local target="$1"
    if command -v zeditor >/dev/null 2>&1; then
        zeditor "$target" &
    elif command -v codex >/dev/null 2>&1; then
        codex "$target" &
    elif command -v code >/dev/null 2>&1; then
        code "$target" &
    else
        xdg-open "$target" &
    fi
}

main_menu() {
    declare -A TARGET_MAP

    local items=()

    add_item() {
        local label="$1"
        local path="$2"
        if [ -e "$path" ]; then
            items+=("$label")
            TARGET_MAP["$label"]="$path"
        fi
    }

    add_item "󰒓  Waybar Bar Configuration" "$HOME/.config/waybar"
    add_item "󰒓  Mango Compositor Configuration" "$HOME/.config/mango"
    add_item "󰒓  Hyprland / Idle Configuration" "$HOME/.config/hypr"
    add_item "󰒓  SwayNC Notifications Configuration" "$HOME/.config/swaync"
    add_item "󰒓  Kitty Terminal Configuration" "$HOME/.config/kitty"
    add_item "󰒓  Rofi Launcher Configuration" "$HOME/.config/rofi"
    add_item "󰒓  Fish Shell Configuration" "$HOME/.config/fish"
    add_item "󰒓  Haku Menu Custom Scripts" "$HOME/hakuspace-control"
    add_item "󰒓  NixOS Flake & System Config" "$HOME/Code/Dotfiles/nixos"

    local menu_content=""
    for item in "${items[@]}"; do
        menu_content+="$item\n"
    done
    menu_content+="󱁤  Open Hakuspace Folder in File Manager (Thunar)\n"
    menu_content+="  Open All Config Paths in Editor"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "Configs" -theme-str "$ROFI_THEME_STR")
    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Open Hakuspace Folder"*)
            thunar "$HOME/hakuspace-control" &
            ;;
        *"Open All Config Paths"*)
            local existing=()
            for p in "$HOME/.config/waybar" "$HOME/.config/mango" "$HOME/.config/swaync" "$HOME/.config/kitty" "$HOME/.config/rofi" "$HOME/.config/fish" "$HOME/hakuspace-control" "$HOME/Code/Dotfiles/nixos"; do
                [ -e "$p" ] && existing+=("$p")
            done
            code -n "${existing[@]}" &
            ;;
        *)
            local target_path="${TARGET_MAP["$selected"]}"
            if [ -n "$target_path" ]; then
                open_target "$target_path"
            fi
            ;;
    esac
}

main_menu "$@"
