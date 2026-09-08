#!/usr/bin/env bash
# ==============================================================================
# idle_sleep_poweroff.sh
#
# Bridges hypridle inactivity suspension with automated hardware poweroff:
# 1. Verifies idle inhibit state (caffeine mode, audio playback, power profile).
# 2. Computes target sleep duration until final inactivity poweroff.
# 3. Programs hardware RTC wakealarm (`rtcwake`) and triggers `systemctl suspend`.
# 4. Synchronously awaits system resume via D-Bus `PrepareForSleep(false)` signal.
# 5. On resume:
#    - User-initiated wake: If resumed before alarm expiry, cancels alarm & exits.
#    - Alarm-initiated wake: Gives grace window with desktop notification.
#      If user unlocks (hyprlock closed), plays audio, or toggles caffeine, aborts.
#      Otherwise, safely executes `systemctl poweroff`.
# ==============================================================================

set -euo pipefail

export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:/run/wrappers/bin:$PATH"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"


# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
# Battery: 5 min (300s) idle before suspend -> 1 hour (3600s) total inactivity
DEFAULT_BATTERY_TOTAL_SECS=3600
DEFAULT_BATTERY_IDLE_SECS=300

# AC: 20 min (1200s) idle before suspend -> 3 hours (10800s) total inactivity
DEFAULT_AC_TOTAL_SECS=10800
DEFAULT_AC_IDLE_SECS=1200

# Grace period in seconds upon alarm-triggered wake before poweroff
GRACE_PERIOD_SECS=10

# Script paths
IDLE_INHIBIT_BIN="$HOME/.local/bin/idle_inhibit.sh"
DPMS_HANDLER_BIN="$HOME/.local/bin/dpms_handler.sh"

# State & logging
STATE_DIR="$HOME/.local/state/haku_theme"
LOG_FILE="$STATE_DIR/idle_poweroff.log"
LOCK_FILE="$STATE_DIR/idle_poweroff.lock"
mkdir -p "$STATE_DIR"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" >> "$LOG_FILE"
    echo "$msg" >&2
}

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
is_on_ac() {
    if [[ -x "$IDLE_INHIBIT_BIN" ]]; then
        if "$IDLE_INHIBIT_BIN" --ac >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi

    for ps in /sys/class/power_supply/*; do
        if [[ -f "$ps/type" ]]; then
            local type
            type=$(cat "$ps/type" 2>/dev/null || true)
            if [[ "$type" == "Mains" || "$type" == "USB" ]]; then
                if [[ "$(cat "$ps/online" 2>/dev/null || true)" == "1" ]]; then
                    return 0
                fi
            fi
        fi
    done
    return 1
}

cancel_rtc_alarm() {
    log "Cancelling any active RTC wake alarm..."
    if rtcwake -m disable 2>/dev/null; then
        return 0
    elif command -v systemd-run >/dev/null 2>&1; then
        systemd-run --wait --quiet --collect rtcwake -m disable 2>/dev/null || true
    fi
}

set_rtc_alarm() {
    local secs="$1"
    log "Programming RTC wakealarm for $secs seconds in the future..."
    if rtcwake -m no -s "$secs" 2>/dev/null; then
        return 0
    elif command -v systemd-run >/dev/null 2>&1; then
        systemd-run --wait --quiet --collect rtcwake -m no -s "$secs"
    else
        rtcwake -m no -s "$secs"
    fi
}

notify_user() {
    local title="$1"
    local body="$2"
    local urgency="${3:-normal}"
    local timeout="${4:-10000}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -t "$timeout" -a "Hypridle Poweroff" "$title" "$body" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Fast CLI Handlers
# ------------------------------------------------------------------------------
if [[ "${1:-}" == "--cancel" ]]; then
    cancel_rtc_alarm
    exit 0
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
Usage: $0 [--battery | --ac] [OPTIONS]

Manages inactivity suspension and automatically powers off if undisturbed.

Options:
  --battery      Run in battery mode (suspend after 5m, poweroff after 1h total)
  --ac           Run in AC mode (suspend after 20m, poweroff after 3h total)
  --cancel       Cancel any scheduled RTC wakealarm and exit
  --dry-run      Simulate calculations and actions without suspending or powering off
  --test SECS    Override sleep duration to SECS for testing
  --grace SECS   Override grace period to SECS (default: 10)
  --help         Show this help message
EOF
    exit 0
fi

# ------------------------------------------------------------------------------
# Singleton Lock (Prevent multiple concurrent suspension handlers)
# ------------------------------------------------------------------------------
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "Another instance of idle_sleep_poweroff.sh is already running. Exiting."
    exit 0
fi

# ------------------------------------------------------------------------------
# Argument Parsing
# ------------------------------------------------------------------------------
MODE=""
DRY_RUN=0
CUSTOM_SECS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --battery)
            MODE="battery"
            shift
            ;;
        --ac)
            MODE="ac"
            shift
            ;;
        --cancel)
            cancel_rtc_alarm
            exit 0
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --test)
            if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
                CUSTOM_SECS="$2"
                shift 2
            else
                echo "Error: --test requires a duration in seconds" >&2
                exit 1
            fi
            ;;
        --grace)
            if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
                GRACE_PERIOD_SECS="$2"
                shift 2
            else
                echo "Error: --grace requires a duration in seconds" >&2
                exit 1
            fi
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Detect mode if not explicitly passed
if [[ -z "$MODE" ]]; then
    if is_on_ac; then
        MODE="ac"
    else
        MODE="battery"
    fi
fi

# ------------------------------------------------------------------------------
# Pre-sleep Inhibit Validation
# ------------------------------------------------------------------------------
if [[ -x "$IDLE_INHIBIT_BIN" ]]; then
    if ! "$IDLE_INHIBIT_BIN" "--$MODE"; then
        log "Inactivity action inhibited by idle_inhibit.sh for mode --$MODE (caffeine active, audio playing, or condition mismatch)."
        exit 0
    fi
fi

# Calculate sleep duration in seconds
if [[ -n "$CUSTOM_SECS" ]]; then
    SLEEP_SECS="$CUSTOM_SECS"
elif [[ "$MODE" == "battery" ]]; then
    SLEEP_SECS=$(( DEFAULT_BATTERY_TOTAL_SECS - DEFAULT_BATTERY_IDLE_SECS ))
else
    SLEEP_SECS=$(( DEFAULT_AC_TOTAL_SECS - DEFAULT_AC_IDLE_SECS ))
fi

if (( SLEEP_SECS <= 0 )); then
    log "Computed sleep duration is <= 0 ($SLEEP_SECS). Aborting."
    exit 1
fi

log "Initiating idle sleep routine. Mode: $MODE, Scheduled sleep duration: ${SLEEP_SECS}s."

if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY-RUN] Would program RTC alarm for ${SLEEP_SECS}s and run systemctl suspend."
    exit 0
fi

# ------------------------------------------------------------------------------
# Program RTC Alarm & Synchronous Suspend
# ------------------------------------------------------------------------------
# Cancel any prior alarm first
cancel_rtc_alarm

# Program hardware wakealarm
set_rtc_alarm "$SLEEP_SECS"

# Verify RTC wakealarm in sysfs
if [[ -r /sys/class/rtc/rtc0/wakealarm ]]; then
    ALARM_EPOCH=$(cat /sys/class/rtc/rtc0/wakealarm 2>/dev/null || true)
    log "Hardware RTC wakealarm confirmed in sysfs: ${ALARM_EPOCH:-empty}"
fi

# Verify / ensure session lock
WAS_LOCKED=0
if pidof hyprlock >/dev/null 2>&1; then
    WAS_LOCKED=1
else
    log "hyprlock is not currently running; triggering session lock..."
    loginctl lock-session 2>/dev/null || true
    sleep 0.5
    if pidof hyprlock >/dev/null 2>&1; then
        WAS_LOCKED=1
    fi
fi

START_EPOCH=$(date +%s)
log "Starting D-Bus monitor for resume event and initiating systemctl suspend..."

# Spawn D-Bus monitor for PrepareForSleep signal from systemd-logind
coproc DBUS_MON {
    exec gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1
}

# Wait for monitor coproc to initialize (first line confirms monitoring has started)
read -r _ <&"${DBUS_MON[0]}" || true

# Trigger systemctl suspend
if ! systemctl suspend; then
    log "systemctl suspend failed! Cancelling RTC alarm."
    kill "$DBUS_MON_PID" 2>/dev/null || true
    cancel_rtc_alarm
    exit 1
fi

log "System suspend initiated. Awaiting resume signal PrepareForSleep(false)..."

# Read signals until PrepareForSleep(false) is received
while read -r line <&"${DBUS_MON[0]}"; do
    if [[ "$line" =~ PrepareForSleep.*false ]]; then
        log "Detected resume signal from logind: $line"
        break
    fi
done

# Terminate D-Bus monitor coproc
kill "$DBUS_MON_PID" 2>/dev/null || true

# ------------------------------------------------------------------------------
# Resume Handling
# ------------------------------------------------------------------------------
RESUME_EPOCH=$(date +%s)
ELAPSED_SECS=$(( RESUME_EPOCH - START_EPOCH ))
log "System resumed from suspend. Elapsed time in sleep: ${ELAPSED_SECS}s (Target was: ${SLEEP_SECS}s)."

# Always cancel any lingering RTC alarm
cancel_rtc_alarm

# Wake up display if dpms_handler is available
if [[ -x "$DPMS_HANDLER_BIN" ]]; then
    "$DPMS_HANDLER_BIN" on >/dev/null 2>&1 || true
fi

# Dynamic margin for resume latency & clock skew:
# For long durations (>60s), 15s margin is safe.
# For short testing durations (<=60s), use 5s margin.
if (( SLEEP_SECS > 60 )); then
    MARGIN=15
elif (( SLEEP_SECS > 10 )); then
    MARGIN=5
else
    MARGIN=2
fi

THRESHOLD_SECS=$(( SLEEP_SECS - MARGIN ))

if (( ELAPSED_SECS < THRESHOLD_SECS )); then
    log "User-initiated resume detected (${ELAPSED_SECS}s < ${THRESHOLD_SECS}s). Poweroff aborted."
    exit 0
fi

# ------------------------------------------------------------------------------
# Alarm-Triggered Resume -> Grace Period & Verification
# ------------------------------------------------------------------------------
log "Target sleep duration reached (${ELAPSED_SECS}s >= ${THRESHOLD_SECS}s). Evaluating automated poweroff..."

# Check if plugged into AC while sleeping on battery
if [[ "$MODE" == "battery" ]] && is_on_ac; then
    log "System was plugged into AC during sleep. Aborting battery shutdown to allow longer AC idle."
    notify_user "Inactivity Shutdown Cancelled" "AC power connected during sleep. Shutdown aborted."
    exit 0
fi

notify_user "Inactivity Shutdown" "System inactive for timeout. Shutting down in ${GRACE_PERIOD_SECS}s unless user acts." "critical" $(( GRACE_PERIOD_SECS * 1000 ))

# Grace period loop (check every second if user unlocked, audio started, or caffeine enabled)
for (( i = GRACE_PERIOD_SECS; i > 0; i-- )); do
    sleep 1

    # Check 1: Did the user unlock the screen?
    if [[ "$WAS_LOCKED" -eq 1 ]] && ! pidof hyprlock >/dev/null 2>&1; then
        log "Grace period aborted: hyprlock is no longer running (user unlocked screen)."
        notify_user "Inactivity Shutdown Cancelled" "User presence detected (screen unlocked)."
        exit 0
    fi

    # Check 2: Did caffeine / idle inhibit get enabled?
    if [[ -x "$IDLE_INHIBIT_BIN" ]]; then
        if "$IDLE_INHIBIT_BIN" --check >/dev/null 2>&1; then
            log "Grace period aborted: Caffeine mode was enabled."
            notify_user "Inactivity Shutdown Cancelled" "Caffeine mode enabled."
            exit 0
        fi
    fi
done

log "Grace period expired without user intervention. Executing systemctl poweroff now."
systemctl poweroff || systemctl poweroff -i
