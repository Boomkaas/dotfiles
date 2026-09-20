#!/usr/bin/env bash
# ==============================================================================
# restore_boot_state.sh
#
# Closes all opened client windows and terminates all user applications/tasks,
# flushes memory buffers, and returns the machine to its post-boot RAM state (~1.0 GB)
# without requiring a full reboot and without crashing the Wayland desktop session.
# ==============================================================================

set -eo pipefail

SCRIPT_NAME="restore_boot_state"
TARGET_USER="${USER:-peng}"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || echo 1000)

# Colors
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    MAGENTA=$'\033[0;35m'
    CYAN=$'\033[0;36m'
    RESET=$'\033[0m'
else
    BOLD=''
    DIM=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    RESET=''
fi

# ------------------------------------------------------------------------------
# Default Flags
# ------------------------------------------------------------------------------
DRY_RUN=0
KEEP_TERM=0
FORCE=0
CLEAN_CACHE=0
DROP_CACHES=0
QUIET=0

# ------------------------------------------------------------------------------
# Parse CLI Options
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run|--test)
            DRY_RUN=1
            shift
            ;;
        -k|--keep-term|--keep-terminal)
            KEEP_TERM=1
            shift
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        --clean-cache)
            CLEAN_CACHE=1
            shift
            ;;
        --drop-caches)
            DROP_CACHES=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -h|--help)
            cat <<EOF
${BOLD}${SCRIPT_NAME}.sh${RESET} - Restore Post-Boot State & Free RAM

Closes all user applications and background processes to return the PC
to its fresh post-boot memory footprint (~1.0 GB RAM) without rebooting.

${BOLD}USAGE:${RESET}
    ${SCRIPT_NAME}.sh [OPTIONS]

${BOLD}OPTIONS:${RESET}
    -n, --dry-run          Simulate without terminating any processes or windows
    -k, --keep-term        Keep the calling terminal window open
    -f, --force            Execute immediately without prompts or countdowns
    --clean-cache          Also clear temporary files in ~/.cache
    --drop-caches          Drop kernel page cache (requires sudo if not passwordless)
    -q, --quiet            Suppress stdout output (desktop notification still sent)
    -h, --help             Show this help message

${BOLD}EXAMPLES:${RESET}
    ${SCRIPT_NAME}.sh --dry-run      # Preview which windows & processes will be closed
    ${SCRIPT_NAME}.sh -k             # Close everything but keep current terminal open
    ${SCRIPT_NAME}.sh -f             # Full reset to desktop-only state immediately

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1 (use --help for options)" >&2
            exit 1
            ;;
    esac
done

# Ensure Mango IPC socket is discovered if running under Wayland
if [ -z "${MANGO_INSTANCE_SIGNATURE:-}" ]; then
    MANGO_INSTANCE_SIGNATURE=$(ls /run/user/"$TARGET_UID"/mango-*.sock 2>/dev/null | head -n1 || true)
    export MANGO_INSTANCE_SIGNATURE
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

notify() {
    local urgency="${1:-normal}"
    local icon="${2:-system-reboot}"
    local title="$3"
    local msg="$4"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -i "$icon" "$title" "$msg" -t 4500
    fi
}

get_ram_used_mb() {
    free -m | awk '/^Mem:/ {print $3}'
}

get_ram_used_human() {
    local mb
    mb=$(get_ram_used_mb)
    if [ "$mb" -ge 1024 ]; then
        awk -v m="$mb" 'BEGIN {printf "%.2f GiB", m / 1024}'
    else
        echo "${mb} MiB"
    fi
}

format_mb() {
    local mb="$1"
    if [ "$mb" -ge 1024 ]; then
        awk -v m="$mb" 'BEGIN {printf "%.2f GiB", m / 1024}'
    else
        echo "${mb} MiB"
    fi
}

# ------------------------------------------------------------------------------
# Discover Execution Ancestry
# ------------------------------------------------------------------------------
# We record all ancestor PIDs of this script so we do not terminate ourselves
# or the terminal caller midway through execution.
declare -A ANCESTOR_PIDS
CALLER_TERM_PID=""
CALLER_TERM_WID=""

cur=$$
while [ -n "$cur" ] && [ "$cur" -gt 1 ]; do
    ANCESTOR_PIDS["$cur"]=1
    # Check if this ancestor is a terminal emulator
    cur_comm=$(ps -o comm= -p "$cur" 2>/dev/null || true)
    if [[ "$cur_comm" =~ (kitty|\.kitty|alacritty|foot|wezterm|ghostty) ]] && [ -z "$CALLER_TERM_PID" ]; then
        CALLER_TERM_PID="$cur"
    fi
    cur=$(ps -o ppid= -p "$cur" 2>/dev/null | tr -d ' ' || true)
done

# ------------------------------------------------------------------------------
# Discover Whitelisted Units and Daemons
# ------------------------------------------------------------------------------
# The whitelist ensures the Wayland compositor, status bar, notification center,
# sound server, polkit, wallpaper daemon, and systemd user services never die.

declare -A WHITELIST_COMMS=(
    ["systemd"]=1
    ["(sd-pam)"]=1
    ["dbus-daemon"]=1
    ["dbus-broker"]=1
    ["mango"]=1
    ["Xwayland"]=1
    ["gdm-wayland-session"]=1
    ["gdm-wayland-ses"]=1
    ["waybar"]=1
    [".waybar-wrapped"]=1
    ["swaync"]=1
    [".swaync-wrapped"]=1
    ["swaync-client"]=1
    [".swaync-client-"]=1
    ["nm-applet"]=1
    [".nm-applet-wrap"]=1
    ["blueman-applet"]=1
    [".blueman-applet"]=1
    ["blueman-tray"]=1
    [".blueman-tray-w"]=1
    ["polkit-mate-authentication-agent-1"]=1
    ["polkit-mate-aut"]=1
    ["awww-daemon"]=1
    [".awww-daemon-wr"]=1
    ["hypridle"]=1
    ["wl-paste"]=1
    ["cliphist"]=1
    ["pipewire"]=1
    ["pipewire-pulse"]=1
    ["wireplumber"]=1
    ["xdg-desktop-portal"]=1
    [".xdg-desktop-po"]=1
    ["xdg-desktop-portal-gtk"]=1
    ["xdg-desktop-portal-wlr"]=1
    ["xdg-document-portal"]=1
    [".xdg-document-p"]=1
    ["xdg-permission-store"]=1
    [".xdg-permission"]=1
    ["gvfsd"]=1
    [".gvfsd-wrapped"]=1
    ["gvfsd-fuse"]=1
    [".gvfsd-fuse-wra"]=1
    ["obexd"]=1
    ["fusermount3"]=1
    ["playerctld"]=1
)

# Active systemd user services to protect
declare -A WHITELIST_SYSTEMD_SERVICES
while read -r svc_unit; do
    [ -n "$svc_unit" ] && WHITELIST_SYSTEMD_SERVICES["$svc_unit"]=1
done < <(systemctl --user list-units --type=service --state=running --no-legend 2>/dev/null | awk '{print $1}')

# Always ensure critical boot services are explicitly preserved
WHITELIST_SYSTEMD_SERVICES["antigravity-cli-daemon.service"]=1
WHITELIST_SYSTEMD_SERVICES["telegram-pc-bot.service"]=1
WHITELIST_SYSTEMD_SERVICES["awww-daemon.service"]=1
WHITELIST_SYSTEMD_SERVICES["hypridle.service"]=1
WHITELIST_SYSTEMD_SERVICES["dbus.service"]=1
WHITELIST_SYSTEMD_SERVICES["pipewire.service"]=1
WHITELIST_SYSTEMD_SERVICES["wireplumber.service"]=1
WHITELIST_SYSTEMD_SERVICES["pipewire-pulse.service"]=1
WHITELIST_SYSTEMD_SERVICES["xdg-desktop-portal.service"]=1
WHITELIST_SYSTEMD_SERVICES["gvfs-daemon.service"]=1

# Helper function to test if a PID belongs to an allowed service/daemon
is_whitelisted_proc() {
    local p="$1"
    local pcomm="$2"

    # Match comm against known core daemons
    if [ -n "${WHITELIST_COMMS["$pcomm"]:-}" ]; then
        return 0
    fi

    # Check cgroup for systemd user service membership
    if [ -r "/proc/$p/cgroup" ]; then
        local pcg
        pcg=$(cat "/proc/$p/cgroup" 2>/dev/null || true)
        for svc in "${!WHITELIST_SYSTEMD_SERVICES[@]}"; do
            if [[ "$pcg" == *"$svc"* ]]; then
                return 0
            fi
        done
    fi

    # Check cmdline for background telegram bot or agy serve
    if [ -r "/proc/$p/cmdline" ]; then
        local pcmd
        pcmd=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null || true)
        if [[ "$pcmd" =~ (PcControlBot/venv/bin/python|remote-control\ serve|pinchtab\ server|pinchtab\ bridge) ]]; then
            return 0
        fi
    fi

    return 1
}

# ------------------------------------------------------------------------------
# Step 1: Discover All Graphical Client Windows (Mango Compositor)
# ------------------------------------------------------------------------------
declare -A CLIENT_WINDOW_WIDS
declare -A CLIENT_WINDOW_PIDS
declare -A CLIENT_WINDOW_APPS
declare -A CLIENT_WINDOW_TITLES

if command -v mmsg >/dev/null 2>&1 && [ -n "$MANGO_INSTANCE_SIGNATURE" ]; then
    while IFS=$'\t' read -r wid wpid wappid wtitle; do
        [ -z "$wid" ] || [ "$wid" = "null" ] && continue
        CLIENT_WINDOW_WIDS["$wid"]="$wpid"
        CLIENT_WINDOW_PIDS["$wpid"]="$wid"
        CLIENT_WINDOW_APPS["$wid"]="${wappid:-Unknown}"
        CLIENT_WINDOW_TITLES["$wid"]="${wtitle:-Untitled}"

        if [ -n "$CALLER_TERM_PID" ] && [ "$wpid" -eq "$CALLER_TERM_PID" ]; then
            CALLER_TERM_WID="$wid"
        fi
    done < <(mmsg get all-clients 2>/dev/null | jq -r '.clients[]? | [ .id, .pid, .appid, (.title | gsub("\t|\n"; " ")) ] | @tsv' 2>/dev/null || true)
fi

# ------------------------------------------------------------------------------
# Step 2: Discover Non-Window User Processes to Terminate
# ------------------------------------------------------------------------------
declare -A TARGET_PROCS
declare -A TARGET_PROCS_COMM
declare -A TARGET_PROCS_CMD

for pid_dir in /proc/[0-9]*; do
    p="${pid_dir#/proc/}"
    [ "$p" = "$$" ] && continue
    [ -n "${ANCESTOR_PIDS["$p"]:-}" ] && continue

    # Check UID
    if [ -r "/proc/$p/status" ]; then
        p_uid=$(awk '/^Uid:/ {print $2}' "/proc/$p/status" 2>/dev/null || echo -1)
        [ "$p_uid" -ne "$TARGET_UID" ] && continue
    else
        continue
    fi

    p_comm=$(cat "/proc/$p/comm" 2>/dev/null || true)
    [ -z "$p_comm" ] && continue

    # Skip if whitelisted
    if is_whitelisted_proc "$p" "$p_comm"; then
        continue
    fi

    # Skip standard short-lived utility calls
    [[ "$p_comm" =~ ^(ps|jq|awk|sed|grep|sleep|mmsg|free|tr|cat|find|cut|head|tail) ]] && continue

    p_cmd=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null || echo "$p_comm")
    TARGET_PROCS["$p"]=1
    TARGET_PROCS_COMM["$p"]="$p_comm"
    TARGET_PROCS_CMD["$p"]="$p_cmd"
done

# ------------------------------------------------------------------------------
# DRY-RUN REPORTING
# ------------------------------------------------------------------------------
RAM_BEFORE_MB=$(get_ram_used_mb)
RAM_BEFORE_HUMAN=$(get_ram_used_human)

if [ "$DRY_RUN" -eq 1 ]; then
    echo "${BOLD}${CYAN}=== DRY RUN: Restore Post-Boot State Simulation ===${RESET}"
    echo "Current RAM Used: ${YELLOW}${RAM_BEFORE_HUMAN}${RESET} (${RAM_BEFORE_MB} MiB)"
    echo

    echo "${BOLD}Graphical Client Windows to Close (${#CLIENT_WINDOW_WIDS[@]} total):${RESET}"
    if [ ${#CLIENT_WINDOW_WIDS[@]} -eq 0 ]; then
        echo "  ${DIM}(No open graphical windows)${RESET}"
    else
        for wid in "${!CLIENT_WINDOW_WIDS[@]}"; do
            wpid="${CLIENT_WINDOW_WIDS["$wid"]}"
            app="${CLIENT_WINDOW_APPS["$wid"]}"
            title="${CLIENT_WINDOW_TITLES["$wid"]}"
            is_caller=""
            if [ -n "$CALLER_TERM_WID" ] && [ "$wid" = "$CALLER_TERM_WID" ]; then
                is_caller=" ${CYAN}[Current Terminal]${RESET}"
            fi
            echo "  • [WID $wid | PID $wpid] ${BOLD}$app${RESET}: \"$title\"$is_caller"
        done
    fi
    echo

    echo "${BOLD}User Processes to Terminate (${#TARGET_PROCS[@]} total):${RESET}"
    if [ ${#TARGET_PROCS[@]} -eq 0 ]; then
        echo "  ${DIM}(No orphaned background processes)${RESET}"
    else
        for p in "${!TARGET_PROCS[@]}"; do
            comm="${TARGET_PROCS_COMM["$p"]}"
            cmd="${TARGET_PROCS_CMD["$p"]}"
            [ ${#cmd} -gt 60 ] && cmd="${cmd:0:57}..."
            echo "  • [PID $p] ${BOLD}$comm${RESET}: $cmd"
        done
    fi
    echo

    echo "${BOLD}Protected Daemons & Desktop Components (Preserved):${RESET}"
    echo "  • Session:    mango (compositor), Xwayland, gdm-wayland-session"
    echo "  • UI Panel:   waybar, swaync, nm-applet, blueman-applet, polkit-mate, awww-daemon, hypridle"
    echo "  • Audio/IPC:  pipewire, wireplumber, xdg-desktop-portal*, dbus-daemon, systemd user daemons"
    echo "  • Services:   telegram-pc-bot, antigravity-cli-daemon"
    echo
    echo "${GREEN}Simulation complete. No processes or windows were modified.${RESET}"
    exit 0
fi

# ------------------------------------------------------------------------------
# EXECUTION: Graceful Close -> Terminate -> Memory Reclaim
# ------------------------------------------------------------------------------

if [ "$QUIET" -eq 0 ]; then
    echo "${BOLD}${CYAN}Restoring system to fresh post-boot state...${RESET}"
    echo "Initial RAM Used: ${YELLOW}${RAM_BEFORE_HUMAN}${RESET}"
fi

CLOSED_WINS=0
KILLED_PROCS=0

# Step 2a: Close GUI Windows Gracefully via Mango IPC or SIGTERM
for wid in "${!CLIENT_WINDOW_WIDS[@]}"; do
    wpid="${CLIENT_WINDOW_WIDS["$wid"]}"
    # If this window is the current terminal and KEEP_TERM is requested, keep it!
    if [ -n "$CALLER_TERM_WID" ] && [ "$wid" = "$CALLER_TERM_WID" ] && [ "$KEEP_TERM" -eq 1 ]; then
        continue
    fi
    # If caller terminal without KEEP_TERM, we close it at the very end to finish output
    if [ -n "$CALLER_TERM_WID" ] && [ "$wid" = "$CALLER_TERM_WID" ]; then
        continue
    fi

    if command -v mmsg >/dev/null 2>&1 && [ -n "$MANGO_INSTANCE_SIGNATURE" ]; then
        mmsg dispatch killclient "client,$wid" >/dev/null 2>&1 || true
    fi
    if kill -0 "$wpid" 2>/dev/null; then
        kill -15 "$wpid" 2>/dev/null || true
    fi
    ((CLOSED_WINS++)) || true
done

# Step 2b: Send SIGTERM to other targeted processes
for p in "${!TARGET_PROCS[@]}"; do
    if [ -n "${ANCESTOR_PIDS["$p"]:-}" ]; then
        continue
    fi
    if kill -0 "$p" 2>/dev/null; then
        kill -15 "$p" 2>/dev/null || true
        ((KILLED_PROCS++)) || true
    fi
done

# Step 2c: Grace period for processes to exit cleanly
sleep 1.0

# Step 2d: Force kill (SIGKILL) any stubborn surviving processes
for wid in "${!CLIENT_WINDOW_WIDS[@]}"; do
    wpid="${CLIENT_WINDOW_WIDS["$wid"]}"
    if [ -n "$CALLER_TERM_WID" ] && [ "$wid" = "$CALLER_TERM_WID" ]; then
        continue
    fi
    if kill -0 "$wpid" 2>/dev/null; then
        kill -9 "$wpid" 2>/dev/null || true
    fi
done

for p in "${!TARGET_PROCS[@]}"; do
    if [ -n "${ANCESTOR_PIDS["$p"]:-}" ]; then
        continue
    fi
    if kill -0 "$p" 2>/dev/null; then
        kill -9 "$p" 2>/dev/null || true
    fi
done

# ------------------------------------------------------------------------------
# Step 3: Reclaim Memory & Flush Caches
# ------------------------------------------------------------------------------
sync

if [ "$CLEAN_CACHE" -eq 1 ]; then
    rm -rf "$HOME/.cache/"* 2>/dev/null || true
fi

# If passwordless sudo is available or DROP_CACHES is explicitly set
if [ "$DROP_CACHES" -eq 1 ] || sudo -n true 2>/dev/null; then
    sudo -n sync 2>/dev/null || true
    echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true

    # Reset swap if any swap space is currently used
    SWAP_USED=$(free -m | awk '/^Swap:/ {print $3}')
    if [ "${SWAP_USED:-0}" -gt 0 ]; then
        sudo -n swapoff -a 2>/dev/null && sudo -n swapon -a 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# Step 4: Calculate Results & Metrics
# ------------------------------------------------------------------------------
RAM_AFTER_MB=$(get_ram_used_mb)
RAM_AFTER_HUMAN=$(get_ram_used_human)

RAM_FREED_MB=$(( RAM_BEFORE_MB > RAM_AFTER_MB ? RAM_BEFORE_MB - RAM_AFTER_MB : 0 ))
RAM_FREED_HUMAN=$(format_mb "$RAM_FREED_MB")

SUMMARY_MSG="RAM: ${RAM_BEFORE_HUMAN} → ${RAM_AFTER_HUMAN} (Freed: ${RAM_FREED_HUMAN})
Closed ${CLOSED_WINS} windows, terminated ${KILLED_PROCS} processes."

# Send desktop notification
notify normal system-reboot "System Restored to Fresh Boot" "$SUMMARY_MSG"

if [ "$QUIET" -eq 0 ]; then
    echo
    echo "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${RESET}"
    echo "${BOLD}${GREEN}║                System Restored to Fresh Boot State                    ║${RESET}"
    echo "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${RESET}"
    echo "  RAM Before:     ${YELLOW}${RAM_BEFORE_HUMAN}${RESET} (${RAM_BEFORE_MB} MiB)"
    echo "  RAM After:      ${GREEN}${RAM_AFTER_HUMAN}${RESET} (${RAM_AFTER_MB} MiB)"
    echo "  Memory Freed:   ${CYAN}${RAM_FREED_HUMAN}${RESET} (${RAM_FREED_MB} MiB)"
    echo "  Windows Closed: ${BOLD}${CLOSED_WINS}${RESET}"
    echo "  Tasks Cleared:  ${BOLD}${KILLED_PROCS}${RESET}"
    echo
fi

# ------------------------------------------------------------------------------
# Step 5: Terminal Handling
# ------------------------------------------------------------------------------
# If running without a TTY or caller asked to keep terminal:
if [ "$KEEP_TERM" -eq 1 ] || [ ! -t 1 ]; then
    exit 0
fi

# If caller ran interactively from terminal without -k:
if [ "$FORCE" -eq 1 ]; then
    if [ -n "$CALLER_TERM_PID" ]; then
        kill -15 "$CALLER_TERM_PID" 2>/dev/null || true
    fi
    exit 0
fi

# Interactive countdown allowing user to keep terminal if desired
echo "${DIM}Closing terminal in 3 seconds to finish complete reboot state...${RESET}"
echo "${DIM}(Press Ctrl+C to keep this terminal open)${RESET}"

for i in 3 2 1; do
    echo -ne "\r${CYAN}Exiting in ${i}...${RESET} "
    sleep 1
done
echo

if [ -n "$CALLER_TERM_PID" ]; then
    kill -15 "$CALLER_TERM_PID" 2>/dev/null || true
fi

exit 0
