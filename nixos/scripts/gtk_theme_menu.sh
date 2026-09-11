#!/usr/bin/env bash

# ==============================================================================
# GTK Look & Appearance Menu for Rofi
# Changes GTK themes, icons, cursor themes, and font size directly in Rofi.
# ==============================================================================

set -eo pipefail

ROFI_THEME_STR='window { width: 40%; height: 50%; } listview { lines: 6; }'

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-preferences-desktop-theme}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 2500
    fi
}

get_current() {
    local key="$1"
    gsettings get org.gnome.desktop.interface "$key" 2>/dev/null | tr -d "'" || echo "Default"
}

set_gtk_theme() {
    local themes=()
    for d in /run/current-system/sw/share/themes/* "$HOME/.themes/"* "$HOME/.local/share/themes/"*; do
        [ -d "$d" ] || continue
        local name
        name=$(basename "$d")
        themes+=("$name")
    done
    local sorted_themes
    sorted_themes=$(printf "%s\n" "${themes[@]}" | sort -u | grep -v '^\.')

    local choice
    choice=$(echo -e "$sorted_themes" | rofi -dmenu -i -p "Select GTK Theme" -theme-str 'window { width: 35%; height: 40%; } listview { lines: 6; }')
    [ -z "$choice" ] && return

    gsettings set org.gnome.desktop.interface gtk-theme "$choice"
    mkdir -p "$HOME/.config/gtk-3.0"
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        sed -i -E "s/gtk-theme-name=.*/gtk-theme-name=$choice/" "$HOME/.config/gtk-3.0/settings.ini" || true
    else
        echo -e "[Settings]\ngtk-theme-name=$choice" > "$HOME/.config/gtk-3.0/settings.ini"
    fi
    notify normal preferences-desktop-theme "GTK Theme Applied" "Switched to: $choice"
}

set_icon_theme() {
    local icons=()
    for d in /run/current-system/sw/share/icons/* "$HOME/.icons/"* "$HOME/.local/share/icons/"*; do
        [ -d "$d" ] || continue
        local name
        name=$(basename "$d")
        icons+=("$name")
    done
    local sorted_icons
    sorted_icons=$(printf "%s\n" "${icons[@]}" | sort -u | grep -v '^\.' | grep -v 'default')

    local choice
    choice=$(echo -e "$sorted_icons" | rofi -dmenu -i -p "Select Icon Theme" -theme-str 'window { width: 35%; height: 40%; } listview { lines: 6; }')
    [ -z "$choice" ] && return

    gsettings set org.gnome.desktop.interface icon-theme "$choice"
    mkdir -p "$HOME/.config/gtk-3.0"
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        sed -i -E "s/gtk-icon-theme-name=.*/gtk-icon-theme-name=$choice/" "$HOME/.config/gtk-3.0/settings.ini" || true
    fi
    notify normal preferences-desktop-theme "Icon Theme Applied" "Switched to: $choice"
}

set_cursor_theme() {
    local cursors=()
    for d in /run/current-system/sw/share/icons/* "$HOME/.icons/"* "$HOME/.local/share/icons/"*; do
        [ -d "$d/cursors" ] || continue
        local name
        name=$(basename "$d")
        cursors+=("$name")
    done
    local sorted_cursors
    sorted_cursors=$(printf "%s\n" "${cursors[@]}" | sort -u | grep -v '^\.')

    local choice
    choice=$(echo -e "$sorted_cursors" | rofi -dmenu -i -p "Select Cursor Theme" -theme-str 'window { width: 35%; height: 35%; } listview { lines: 5; }')
    [ -z "$choice" ] && return

    gsettings set org.gnome.desktop.interface cursor-theme "$choice"
    notify normal input-mouse "Cursor Theme Applied" "Switched to: $choice"
}

set_font_size() {
    local sizes="9 pt
10 pt
11 pt
12 pt
13 pt
14 pt"
    local choice
    choice=$(echo -e "$sizes" | rofi -dmenu -i -p "Select Font Size" -theme-str 'window { width: 30%; height: 35%; } listview { lines: 6; }')
    [ -z "$choice" ] && return

    local pt
    pt=$(echo "$choice" | tr -dc '0-9')
    if [ -n "$pt" ]; then
        local current_font
        current_font=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
        local font_family
        font_family=$(echo "$current_font" | sed -E 's/\s+[0-9]+$//')
        [ -z "$font_family" ] && font_family="JetBrains Mono"
        gsettings set org.gnome.desktop.interface font-name "$font_family $pt"
        notify normal preferences-desktop-font "Font Size" "Updated to: $font_family $pt"
    fi
}

main_menu() {
    local cur_theme
    cur_theme=$(get_current "gtk-theme")
    local cur_icon
    cur_icon=$(get_current "icon-theme")
    local cur_cursor
    cur_cursor=$(get_current "cursor-theme")
    local cur_font
    cur_font=$(get_current "font-name")

    local menu_content=""
    menu_content+="󰏘  Change GTK Theme ($cur_theme)\n"
    menu_content+="󰀻  Change Icon Theme ($cur_icon)\n"
    menu_content+="󰍽  Change Cursor Theme ($cur_cursor)\n"
    menu_content+="  Change Font / Size ($cur_font)\n"
    menu_content+="󰢻  Open nwg-look (Full GUI)"

    if [ "$1" = "--print-list" ]; then
        echo -e "$menu_content" | sed '/^$/d'
        exit 0
    fi

    local selected
    selected=$(echo -e "$menu_content" | sed '/^$/d' | rofi -dmenu -i -p "Appearance" -theme-str "$ROFI_THEME_STR")
    [ -z "$selected" ] && exit 0

    case "$selected" in
        *"GTK Theme"*)
            set_gtk_theme
            ;;
        *"Icon Theme"*)
            set_icon_theme
            ;;
        *"Cursor Theme"*)
            set_cursor_theme
            ;;
        *"Change Font"*)
            set_font_size
            ;;
        *"Open nwg-look"*)
            nwg-look &
            ;;
    esac
}

main_menu "$@"
