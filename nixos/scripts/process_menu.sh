#!/usr/bin/env bash

# ==============================================================================
# Processes & Window Manager for Rofi & Wayland (Mango)
#
# Provides a comprehensive process and window manager inside Rofi:
# - Lists active graphical windows (from Mango compositor via mmsg)
# - Lists active background processes (from ps)
# - Action submenu on Enter:
#   * For Windows: Focus, Close, Toggle Fullscreen, Toggle Floating, Kill, Suspend, Details
#   * For Background: Kill, Terminate, Suspend, Resume, Inspect (htop), Details
# - Works seamlessly as Rofi Script Mode (Processes tab) and standalone CLI
# ==============================================================================

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-utilities-system-monitor}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 3000
    fi
}

resolve_app_details() {
    local raw_app="$1"
    local raw_title="$2"
    local pid="$3"

    local app_lower="${raw_app,,}"
    local title_lower="${raw_title,,}"
    local combined="$app_lower $title_lower"

    APP_NAME="$raw_app"
    APP_ICON="application-x-executable"
    NERD_ICON="󰍛"

    # Clean up NixOS wrapper prefixes/suffixes
    APP_NAME="${APP_NAME#.}"
    APP_NAME="${APP_NAME%-wrapped}"
    APP_NAME="${APP_NAME%-wrappe}"

    if [ -z "$APP_NAME" ] || [ "$APP_NAME" = "electron" ]; then
        if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
            local cmdline
            cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || echo "")
            local cmd_lower="${cmdline,,}"
            if [[ "$cmd_lower" =~ (obsidian) ]]; then APP_NAME="Obsidian"
            elif [[ "$cmd_lower" =~ (discord) ]]; then APP_NAME="Discord"
            elif [[ "$cmd_lower" =~ (telegram) ]]; then APP_NAME="Telegram"
            elif [[ "$cmd_lower" =~ (slack) ]]; then APP_NAME="Slack"
            elif [[ "$cmd_lower" =~ (teams) ]]; then APP_NAME="Teams"
            elif [[ "$cmd_lower" =~ (code) ]]; then APP_NAME="VS Code"
            elif [[ "$cmd_lower" =~ (antigravity) ]]; then APP_NAME="Antigravity"
            elif [ -n "$cmdline" ]; then
                APP_NAME=$(basename "$(echo "$cmdline" | awk '{print $1}')")
            fi
        fi
    fi

    if [[ "$combined" =~ (firefox|zen-browser) ]] || [[ "$APP_NAME" =~ (firefox|zen) ]]; then
        APP_NAME="Firefox"
        APP_ICON="firefox"
        NERD_ICON=""
    elif [[ "$combined" =~ (chromium|chrome|brave) ]] || [[ "$APP_NAME" =~ (chromium|chrome|brave) ]]; then
        APP_NAME="Chromium"
        APP_ICON="chromium"
        NERD_ICON=""
    elif [[ "$combined" =~ (telegram|org\.telegram\.desktop) ]] || [[ "$APP_NAME" =~ telegram ]]; then
        APP_NAME="Telegram"
        APP_ICON="telegram"
        NERD_ICON="󰭹"
    elif [[ "$combined" =~ (discord) ]] || [[ "$APP_NAME" =~ discord ]]; then
        APP_NAME="Discord"
        APP_ICON="discord"
        NERD_ICON="󰭹"
    elif [[ "$combined" =~ (antigravity) ]] || [[ "$APP_NAME" =~ antigravity ]]; then
        APP_NAME="Antigravity"
        APP_ICON="code"
        NERD_ICON=""
    elif [[ "$combined" =~ (code|codex|vscodium) ]] || [[ "$APP_NAME" =~ (code|codex|vscodium) ]]; then
        APP_NAME="VS Code"
        APP_ICON="code"
        NERD_ICON=""
    elif [[ "$combined" =~ (kitty) ]] || [[ "$APP_NAME" =~ kitty ]]; then
        APP_NAME="Kitty"
        APP_ICON="terminal"
        NERD_ICON=""
    elif [[ "$combined" =~ (alacritty|foot|wezterm|ghostty) ]] || [[ "$APP_NAME" =~ (alacritty|foot|wezterm|ghostty) ]]; then
        APP_NAME="Terminal"
        APP_ICON="terminal"
        NERD_ICON=""
    elif [[ "$combined" =~ (tmux) ]] || [[ "$APP_NAME" =~ tmux ]]; then
        APP_NAME="tmux"
        APP_ICON="terminal"
        NERD_ICON=""
    elif [[ "$combined" =~ (thunar|nautilus|dolphin|pcmanfm) ]] || [[ "$APP_NAME" =~ (thunar|nautilus|dolphin|pcmanfm) ]]; then
        APP_NAME="Files"
        APP_ICON="system-file-manager"
        NERD_ICON=""
    elif [[ "$combined" =~ (obsidian) ]] || [[ "$APP_NAME" =~ obsidian ]]; then
        APP_NAME="Obsidian"
        APP_ICON="obsidian"
        NERD_ICON="󰠮"
    elif [[ "$combined" =~ (viewnior) ]] || [[ "$APP_NAME" =~ viewnior ]]; then
        APP_NAME="Viewnior"
        APP_ICON="viewnior"
        NERD_ICON=""
    elif [[ "$combined" =~ (shutter) ]] || [[ "$APP_NAME" =~ shutter ]]; then
        APP_NAME="Shutter"
        APP_ICON="shutter"
        NERD_ICON="󰄀"
    elif [[ "$combined" =~ (spotify) ]] || [[ "$APP_NAME" =~ spotify ]]; then
        APP_NAME="Spotify"
        APP_ICON="multimedia-audio-player"
        NERD_ICON="󰎆"
    elif [[ "$combined" =~ (cava|mpv|vlc) ]] || [[ "$APP_NAME" =~ (cava|mpv|vlc) ]]; then
        APP_NAME="Media"
        APP_ICON="multimedia-audio-player"
        NERD_ICON="󰎆"
    elif [[ "$combined" =~ (pipewire|wireplumber) ]] || [[ "$APP_NAME" =~ (pipewire|wireplumber) ]]; then
        APP_ICON="audio-speakers"
        NERD_ICON="󰓃"
    elif [[ "$combined" =~ (waybar|swaync|mango|hypr) ]] || [[ "$APP_NAME" =~ (waybar|swaync|mango|hypr) ]]; then
        APP_ICON="preferences-system"
        NERD_ICON="󱂩"
    elif [[ "$combined" =~ (bash|zsh|fish|sh) ]] || [[ "$APP_NAME" =~ (bash|zsh|fish|sh) ]]; then
        APP_ICON="terminal"
        NERD_ICON=""
    elif [[ "$combined" =~ (python|node|ruby|perl|go|cargo|rust) ]] || [[ "$APP_NAME" =~ (python|node|ruby|perl|go|cargo|rust) ]]; then
        APP_ICON="utilities-system-monitor"
        NERD_ICON="󰘐"
    fi
}

render_main_list() {
    echo -en "\0prompt\x1f Processes\n"

    declare -A WIN_PIDS

    # 1. Graphical Windows from Mango Compositor
    if command -v mmsg >/dev/null 2>&1; then
        while IFS=$'\t' read -r wid wpid wappid wtag wfocused wfullscreen wfloating wtitle; do
            [ -z "$wid" ] && continue
            WIN_PIDS["$wpid"]=1

            resolve_app_details "$wappid" "$wtitle" "$wpid"

            # Clean and truncate window title
            local clean_title
            clean_title=$(echo "$wtitle" | tr -d '\r\n\t' | sed 's/^[ \t]*//')
            if [ -z "$clean_title" ] || [ "$clean_title" = "$APP_NAME" ]; then
                clean_title="$APP_NAME"
            fi
            if [ ${#clean_title} -gt 38 ]; then
                clean_title="${clean_title:0:35}..."
            fi

            local star=""
            if [ "$wfocused" = "true" ]; then
                star="★ "
            fi

            local tag_label="WS $wtag"
            [ "$wtag" = "0" ] || [ -z "$wtag" ] && tag_label="Scratch"

            local display_line
            display_line=$(printf "%s  [%-6s %s] %-10s — %-38s (PID: %s)" "$NERD_ICON" "$tag_label" "$star" "$APP_NAME" "$clean_title" "$wpid")
            echo -en "${display_line}\0icon\x1f${APP_ICON}\x1finfo\x1fwin:${wid}:${wpid}:${APP_NAME}\n"
        done < <(mmsg get all-clients 2>/dev/null | jq -r '.clients[] | [ .id, .pid, .appid, (.tags[0] // 1), .is_focused, .is_fullscreen, .is_floating, (.title | gsub("\t|\n"; " ")) ] | @tsv' 2>/dev/null)
    fi

    # 2. Background Processes from ps
    local count=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local bpid bppid bcpu bmem bcomm
        bpid=$(echo "$line" | awk '{print $1}')
        bppid=$(echo "$line" | awk '{print $2}')
        bcpu=$(echo "$line" | awk '{print $3}')
        bmem=$(echo "$line" | awk '{print $4}')
        bcomm=$(echo "$line" | awk '{$1=""; $2=""; $3=""; $4=""; print $0}' | sed 's/^[ \t]*//')

        [ -z "$bpid" ] || [ "$bpid" = "PID" ] && continue
        [ "$bppid" = "2" ] && continue
        [[ "$bcomm" =~ ^(\[|kworker|rcu|migration|ps|jq|awk|sed|grep|sleep|mmsg|rofi) ]] && continue
        [[ "$bcomm" =~ (Web Content|Isolated Web|RDD Process|Utility Process|WebExtensions|Privileged Cont) ]] && continue

        # Skip if already listed as a graphical window
        [ -n "${WIN_PIDS["$bpid"]}" ] && continue

        # Skip current script process
        [ "$bpid" = "$$" ] || [ "$bpid" = "$PPID" ] && continue

        resolve_app_details "$bcomm" "" "$bpid"

        local display_line
        display_line=$(printf "%s  [BG]         %-14s (CPU: %4s%% | MEM: %4s%%) (PID: %s)" "$NERD_ICON" "$APP_NAME" "$bcpu" "$bmem" "$bpid")
        echo -en "${display_line}\0icon\x1f${APP_ICON}\x1finfo\x1fproc:0:${bpid}:${APP_NAME}\n"

        count=$((count + 1))
        [ "$count" -ge 40 ] && break
    done < <(ps -u "$USER" -o pid,ppid,pcpu,pmem,comm --no-headers --sort=-%cpu 2>/dev/null)
}

render_action_menu() {
    local target_info="$1"
    local p_type p_wid p_pid p_name
    p_type=$(echo "$target_info" | cut -d: -f1)
    p_wid=$(echo "$target_info" | cut -d: -f2)
    p_pid=$(echo "$target_info" | cut -d: -f3)
    p_name=$(echo "$target_info" | cut -d: -f4)

    echo -en "\0prompt\x1fManage: ${p_name} (PID: ${p_pid})\n"
    echo -en "\0data\x1f${target_info}\n"

    if [ "$p_type" = "win" ]; then
        echo -en "󰖯  Focus / Bring to Front\0icon\x1fview-restore\x1finfo\x1ffocus\n"
        echo -en "󰅖  Close Window (Graceful)\0icon\x1fwindow-close\x1finfo\x1fclose\n"
        echo -en "󰊓  Toggle Fullscreen\0icon\x1fview-fullscreen\x1finfo\x1ffullscreen\n"
        echo -en "󰉦  Toggle Floating\0icon\x1fwindow-duplicate\x1finfo\x1ffloating\n"
        echo -en "󰚃  Kill Process (Force SIGKILL -9)\0icon\x1fprocess-stop\x1finfo\x1fkill9\n"
        echo -en "󰚌  Terminate Gracefully (SIGTERM -15)\0icon\x1fprocess-stop\x1finfo\x1fkill15\n"
        echo -en "󰏤  Suspend Process (SIGSTOP)\0icon\x1fmedia-playback-pause\x1finfo\x1fstop\n"
        echo -en "󰐊  Resume Process (SIGCONT)\0icon\x1fmedia-playback-start\x1finfo\x1fcont\n"
        echo -en "󰢻  Inspect in Terminal (htop)\0icon\x1futilities-system-monitor\x1finfo\x1fhtop\n"
        echo -en "󰋼  View Process Details\0icon\x1fdialog-information\x1finfo\x1fdetails\n"
        echo -en "󰌍  Back to Processes List\0icon\x1fgo-previous\x1finfo\x1fback\n"
    else
        echo -en "󰚃  Kill Process (Force SIGKILL -9)\0icon\x1fprocess-stop\x1finfo\x1fkill9\n"
        echo -en "󰚌  Terminate Gracefully (SIGTERM -15)\0icon\x1fprocess-stop\x1finfo\x1fkill15\n"
        echo -en "󰏤  Suspend Process (SIGSTOP)\0icon\x1fmedia-playback-pause\x1finfo\x1fstop\n"
        echo -en "󰐊  Resume Process (SIGCONT)\0icon\x1fmedia-playback-start\x1finfo\x1fcont\n"
        echo -en "󰢻  Inspect in Terminal (htop)\0icon\x1futilities-system-monitor\x1finfo\x1fhtop\n"
        echo -en "󰋼  View Process Details\0icon\x1fdialog-information\x1finfo\x1fdetails\n"
        echo -en "󰌍  Back to Processes List\0icon\x1fgo-previous\x1finfo\x1fback\n"
    fi
}

execute_action() {
    local target_info="$1"
    local action="$2"

    local p_type p_wid p_pid p_name
    p_type=$(echo "$target_info" | cut -d: -f1)
    p_wid=$(echo "$target_info" | cut -d: -f2)
    p_pid=$(echo "$target_info" | cut -d: -f3)
    p_name=$(echo "$target_info" | cut -d: -f4)

    case "$action" in
        "back")
            ROFI_DATA=""
            render_main_list
            return
            ;;
        "focus")
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch focusid,"$p_wid" >/dev/null 2>&1
            fi
            exit 0
            ;;
        "close")
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch killclient client,"$p_wid" >/dev/null 2>&1
            fi
            notify normal window-close "Window Closed" "Requested close for $p_name (Window $p_wid)"
            exit 0
            ;;
        "fullscreen")
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch togglefullscreen client,"$p_wid" >/dev/null 2>&1
            fi
            exit 0
            ;;
        "floating")
            if command -v mmsg >/dev/null 2>&1; then
                mmsg dispatch togglefloating client,"$p_wid" >/dev/null 2>&1
            fi
            exit 0
            ;;
        "kill9")
            if kill -0 "$p_pid" 2>/dev/null; then
                kill -9 "$p_pid" 2>/dev/null
                notify normal process-stop "Process Killed" "Sent SIGKILL (-9) to $p_name (PID: $p_pid)"
            else
                notify low dialog-warning "Process Not Found" "$p_name (PID: $p_pid) is no longer running"
            fi
            exit 0
            ;;
        "kill15")
            if kill -0 "$p_pid" 2>/dev/null; then
                kill -15 "$p_pid" 2>/dev/null
                notify normal process-stop "Process Terminated" "Sent SIGTERM (-15) to $p_name (PID: $p_pid)"
            else
                notify low dialog-warning "Process Not Found" "$p_name (PID: $p_pid) is no longer running"
            fi
            exit 0
            ;;
        "stop")
            if kill -STOP "$p_pid" 2>/dev/null; then
                notify normal media-playback-pause "Process Suspended" "Paused $p_name (PID: $p_pid)"
            else
                notify critical dialog-error "Failed" "Could not suspend $p_name (PID: $p_pid)"
            fi
            exit 0
            ;;
        "cont")
            if kill -CONT "$p_pid" 2>/dev/null; then
                notify normal media-playback-start "Process Resumed" "Resumed $p_name (PID: $p_pid)"
            else
                notify critical dialog-error "Failed" "Could not resume $p_name (PID: $p_pid)"
            fi
            exit 0
            ;;
        "htop")
            coproc ( kitty --class htop -e htop -p "$p_pid" >/dev/null 2>&1 )
            exit 0
            ;;
        "details")
            local full_cmd stats
            full_cmd=$(tr '\0' ' ' < "/proc/$p_pid/cmdline" 2>/dev/null || ps -p "$p_pid" -o args= 2>/dev/null || echo "$p_name")
            stats=$(ps -p "$p_pid" -o pid,%cpu,%mem,stat,etime --no-headers 2>/dev/null || echo "N/A")
            notify normal dialog-information "Process Details: $p_name" "PID: $p_pid\nCMD: $full_cmd\nStats: $stats"
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
}

# ==============================================================================
# MAIN ENTRY POINT
# ==============================================================================

# CLI Helper options
if [ "$1" = "--print-list" ] || [ "$1" = "-l" ]; then
    render_main_list
    exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $(basename "$0") [--print-list | -l | --help | -h]"
    echo "  When called without arguments in terminal, opens Rofi Processes menu."
    echo "  Integrated natively as a Rofi mode script for managing windows & background processes."
    exit 0
fi

# If invoked outside of Rofi script mode (i.e. ROFI_RETV is unset)
if [ -z "$ROFI_RETV" ]; then
    exec rofi -show Processes
fi

# ROFI SCRIPT MODE PROTOCOL:
# 1. If ROFI_DATA is already set, the user selected an action in the submenu
if [ -n "$ROFI_DATA" ]; then
    execute_action "$ROFI_DATA" "$ROFI_INFO"
    exit 0
fi

# 2. If user selected an item from the main list (ROFI_RETV == 1 and no ROFI_DATA)
if [ "$ROFI_RETV" -eq 1 ] && [ -n "$ROFI_INFO" ]; then
    render_action_menu "$ROFI_INFO"
    exit 0
fi

# 3. Initial display (ROFI_RETV == 0 or fallback)
render_main_list
exit 0
