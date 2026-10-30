#!/usr/bin/env bash
# ==============================================================================
# night_presence_check.sh
#
# Prompts the user with "Are you still here?" between 01:00 and 08:00.
# If "I am here" is not clicked within the grace period (default: 60s),
# shuts down the system.
#
# Supports execution as:
# 1. System-level systemd service (runs as root, delegates UI to active user)
# 2. Unprivileged user session directly (e.g. for testing / CLI)
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-peng}"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || echo 1000)
TARGET_HOME=$(eval echo "~$TARGET_USER")

STATE_DIR="$TARGET_HOME/.local/state/haku_theme"
LOG_FILE="$STATE_DIR/night_presence.log"
DPMS_HANDLER="$TARGET_HOME/.local/bin/dpms_handler.sh"

mkdir -p "$STATE_DIR"
if [[ $EUID -eq 0 ]]; then
    chown -R "$TARGET_UID:$TARGET_UID" "$STATE_DIR" 2>/dev/null || true
fi

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" >> "$LOG_FILE"
    echo "$msg" >&2
}

DRY_RUN=0
FORCE=0
TIMEOUT_SEC=60

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --test|--dry-run)
            DRY_RUN=1
            FORCE=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --timeout)
            TIMEOUT_SEC="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--test] [--force] [--timeout SECONDS]"
            echo "  --test, --dry-run  Test notification without shutting down"
            echo "  --force            Run even if outside 01:00-08:00 window"
            echo "  --timeout SECONDS  Grace period in seconds (default: 60)"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Time Window Verification (01:00 to 08:00)
if [[ $FORCE -eq 0 ]]; then
    CURRENT_HOUR=$(date +%-H)
    CURRENT_MIN=$(date +%-M)

    # Allowed from 01:00 up to 08:05
    if (( CURRENT_HOUR < 1 || CURRENT_HOUR > 8 || (CURRENT_HOUR == 8 && CURRENT_MIN > 5) )); then
        log "Outside 01:00-08:00 schedule (current time: ${CURRENT_HOUR}:${CURRENT_MIN}). Exiting."
        exit 0
    fi
fi

# Bypass check if awake mode is active (inactivity inhibited)
if [[ -f "$STATE_DIR/idle_inhibit" ]] && [[ "$(cat "$STATE_DIR/idle_inhibit" 2>/dev/null || true)" == "1" ]]; then
    log "Awake mode active (inactivity inhibited). Night presence check skipped."
    exit 0
fi

log "Night presence check triggered (running as EUID: $EUID). Prompting user with ${TIMEOUT_SEC}s timeout..."

# Prompt user via desktop notification
USER_CONFIRMED=0

if [[ $EUID -eq 0 ]]; then
    # System service mode (root)
    USER_BUS="/run/user/$TARGET_UID/bus"
    if [[ ! -S "$USER_BUS" ]]; then
        log "No active user session detected at $USER_BUS during night schedule. Proceeding directly to poweroff."
    else
        # Find active Wayland socket
        WAYLAND_SOCK=$(ls -1 /run/user/"$TARGET_UID"/wayland-* 2>/dev/null | head -n 1 || true)
        WAYLAND_DISP=$(basename "${WAYLAND_SOCK:-wayland-0}")

        # Run UI prompt in user context
        set +e
        runuser -u "$TARGET_USER" -- env \
            PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$TARGET_USER/bin:$TARGET_HOME/.local/bin:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
            WAYLAND_DISPLAY="$WAYLAND_DISP" \
            DISPLAY=":0" \
            bash -c '
                TIMEOUT_SEC="'"$TIMEOUT_SEC"'"
                TIMEOUT_MS=$(( TIMEOUT_SEC * 1000 ))
                DPMS_HANDLER="'"$DPMS_HANDLER"'"

                if [[ -x "$DPMS_HANDLER" ]]; then
                    "$DPMS_HANDLER" on >/dev/null 2>&1 || true
                fi

                ACTION=$(notify-send \
                    -u critical \
                    -t "$TIMEOUT_MS" \
                    -a "Power Management" \
                    -i system-shutdown \
                    -A "default=I am here" \
                    "Are you still here?" \
                    "System will shut down in ${TIMEOUT_SEC}s unless you confirm you are still here." 2>/dev/null || true)

                if [[ "$ACTION" == "default" ]]; then
                    notify-send -t 3000 -a "Power Management" "System" "Presence confirmed. Shutdown cancelled." 2>/dev/null || true
                    exit 0
                fi
                exit 2
            '
        PROMPT_STATUS=$?
        set -e

        if [[ $PROMPT_STATUS -eq 0 ]]; then
            USER_CONFIRMED=1
        fi
    fi
else
    # User context mode (running directly as user)
    export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$HOME/.local/bin:$PATH"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

    if [[ -x "$DPMS_HANDLER" ]]; then
        "$DPMS_HANDLER" on >/dev/null 2>&1 || true
    fi

    TIMEOUT_MS=$(( TIMEOUT_SEC * 1000 ))
    ACTION=$(notify-send \
        -u critical \
        -t "$TIMEOUT_MS" \
        -a "Power Management" \
        -i system-shutdown \
        -A "default=I am here" \
        "Are you still here?" \
        "System will shut down in ${TIMEOUT_SEC}s unless you confirm you are still here." 2>/dev/null || true)

    if [[ "$ACTION" == "default" ]]; then
        USER_CONFIRMED=1
        notify-send -t 3000 -a "Power Management" "System" "Presence confirmed. Shutdown cancelled." 2>/dev/null || true
    fi
fi

if [[ $USER_CONFIRMED -eq 1 ]]; then
    log "User presence confirmed ('I am here' clicked). Shutdown aborted."
    exit 0
fi

log "No response received within ${TIMEOUT_SEC}s."

if [[ $DRY_RUN -eq 1 ]]; then
    log "[DRY-RUN] No response received within ${TIMEOUT_SEC}s. In production, systemctl poweroff would run."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u normal -t 5000 -a "Power Management" "Night Presence Test" "[TEST] No response received. In production, system would shut down now." 2>/dev/null || true
    fi
    exit 0
fi

# Execute poweroff
log "Executing systemctl poweroff now."
systemctl poweroff || systemctl poweroff -i
