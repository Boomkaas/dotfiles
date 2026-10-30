#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# Locks the screen with swaylock (look set in config/swaylock/config), pausing
# visual background processes while locked.

if ! command -v swaylock &> /dev/null; then
    echo "swaylock is not installed. Please install it to use this script."
    notify-send "Lock screen" "swaylock is not installed. Please install it to use this script."
    exit 1
fi

# Visual processes to suspend on lock and resume on unlock
VISUAL_TARGETS=(
    "bongocat-all"
    "cava"
    "mpvpaper"
    "awww-daemon"
)

VISUAL_PATTERNS=(
    "cava-layer.py"
    "random_wallpaper.sh"
)

suspend_visual_processes() {
    echo "Suspending visual background processes (pet, cava, wallpaper randomizer, etc.)..."
    for proc in "${VISUAL_TARGETS[@]}"; do
        pkill -STOP -x "$proc" 2>/dev/null || true
    done
    for pat in "${VISUAL_PATTERNS[@]}"; do
        pkill -STOP -f "$pat" 2>/dev/null || true
    done
}

resume_visual_processes() {
    echo "Resuming visual background processes..."
    for proc in "${VISUAL_TARGETS[@]}"; do
        pkill -CONT -x "$proc" 2>/dev/null || true
    done
    for pat in "${VISUAL_PATTERNS[@]}"; do
        pkill -CONT -f "$pat" 2>/dev/null || true
    done
}

# Ensure processes are always resumed when lock.sh exits (normal unlock, error, or signal)
trap resume_visual_processes EXIT INT TERM HUP

# Avoid duplicate swaylock instances
if pidof swaylock >/dev/null 2>&1; then
    echo "swaylock is already running."
    exit 0
fi

# Suspend visual processes right before locking the screen
suspend_visual_processes

swaylock
