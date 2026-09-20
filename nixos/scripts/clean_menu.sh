#!/usr/bin/env bash

# ==============================================================================
# Clean System Garbage & Cache for Rofi
# Triggers cache cleaning and NixOS garbage collection directly via Rofi.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 40%; height: 42%; } listview { lines: 5; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-user-trash}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 3000
    fi
}

clean_user_cache() {
    notify normal user-trash "System Clean" "Cleaning user cache (~/.cache)..."
    local before
    before=$(du -sh "$HOME/.cache" 2>/dev/null | awk '{print $1}' || echo "0")
    rm -rf "$HOME/.cache/"* 2>/dev/null || true
    local after
    after=$(du -sh "$HOME/.cache" 2>/dev/null | awk '{print $1}' || echo "0")
    notify normal user-trash "Cache Cleaned" "Cleaned user caches (Before: $before, Now: $after)"
}

clean_nix_garbage() {
    notify normal user-trash "Nix Garbage Collection" "Collecting old Nix generations..."
    if nix-collect-garbage -d >/tmp/nix-clean.log 2>&1; then
        local freed
        freed=$(grep -oP '\d+(\.\d+)?\s*(MiB|GiB|KiB)\s*freed' /tmp/nix-clean.log | tail -n1 || echo "Garbage cleaned")
        notify normal user-trash "Nix Garbage Cleaned" "Success: $freed"
    else
        notify critical dialog-error "Nix Clean" "Finished with warnings. Check /tmp/nix-clean.log"
    fi
}

clean_all() {
    notify normal user-trash "Full System Clean" "Cleaning user cache and collecting Nix garbage..."
    clean_user_cache
    clean_nix_garbage
    notify normal user-trash "Full Clean Complete" "All temporary caches and unreferenced generations cleaned."
}

main_menu() {
    local menu_content=""
    menu_content+="󰚰  Clean User Caches (~/.cache)\n"
    menu_content+="󰚰  Clean Nix Garbage (nix-collect-garbage -d)\n"
    menu_content+="󰚰  Full System Clean (Caches + Nix Generations)\n"
    menu_content+="󰜉  Restore Fresh Boot State (Kill All Apps & Free RAM)\n"
    menu_content+="󰌢  Run Full Clean in Terminal (Live Verbose Output)"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "Clean System" -theme-str "$ROFI_THEME_STR")
    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"Clean User Caches"*)
            clean_user_cache
            ;;
        *"Clean Nix Garbage"*)
            clean_nix_garbage
            ;;
        *"Full System Clean"*)
            clean_all
            ;;
        *"Restore Fresh Boot State"*)
            /home/peng/Code/Dotfiles/nixos/scripts/restore_boot_state.sh --force
            ;;
        *"Run Full Clean in Terminal"*)
            kitty --class clean -e bash -c 'echo "=== Cleaning System Garbage & Caches ==="; nix-collect-garbage -d; rm -rf ~/.cache/*; echo -e "\n=== Clean complete! ==="; sleep 2' &
            ;;
    esac
}

main_menu "$@"
