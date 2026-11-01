#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Touchpad Toggle
# Enables/disables the built-in touchpad. niri has no action for this, so
# "disable" holds an exclusive evdev grab (EVIOCGRAB) on the touchpad's event
# node: the compositor receives no events from it while the grab is held.
# "Enable" stops the holder, and the kernel releases the grab on exit.
#
# The device is looked up in /proc/bus/input/devices each time (event numbers
# change between boots). Reading /dev/input/event* needs the `input` group.
# ==============================================================================

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/touchpad-grab.pid"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Touchpad" -i "$1" -t 2000 \
            -h string:x-canonical-private-synchronous:touchpad-osd \
            "$2" "$3"
    fi
}

# Is the grab holder recorded in PIDFILE still running?
holder_running() {
    local pid
    [ -r "$PIDFILE" ] || return 1
    pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ] &&
        grep -q "touchpad-grab" "/proc/$pid/cmdline"
}

if holder_running; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
    notify input-touchpad "Touchpad enabled" ""
    exit 0
fi
rm -f "$PIDFILE"

# First touchpad node in /proc/bus/input/devices, e.g. "event11".
dev=$(awk '
    BEGIN { RS = ""; FS = "\n" }
    /[Tt]ouchpad/ {
        for (i = 1; i <= NF; i++)
            if ($i ~ /^H: Handlers=/) {
                if (match($i, /event[0-9]+/)) { print substr($i, RSTART, RLENGTH); exit }
            }
    }' /proc/bus/input/devices)

if [ -z "$dev" ]; then
    notify dialog-error "Touchpad" "No touchpad found"
    exit 1
fi

# Holder process: grab the device, record our PID, then wait for SIGTERM.
# Named "touchpad-grab" in argv so holder_running() can recognise it.
python3 -c '
import fcntl, os, signal, sys
EVIOCGRAB = 0x40044590  # _IOW("E", 0x90, int)
dev, pidfile = sys.argv[2], sys.argv[3]  # argv[1] is the name tag
fd = os.open(dev, os.O_RDONLY)
fcntl.ioctl(fd, EVIOCGRAB, 1)
with open(pidfile, "w") as f:
    f.write(str(os.getpid()))
signal.signal(signal.SIGTERM, lambda *a: sys.exit(0))
signal.pause()
' touchpad-grab "/dev/input/$dev" "$PIDFILE" >/dev/null 2>&1 </dev/null &
disown

# Give the holder a moment to take the grab (or fail).
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if holder_running; then
        notify input-touchpad "Touchpad disabled" ""
        exit 0
    fi
    sleep 0.05
done

notify dialog-error "Touchpad" "Could not grab /dev/input/$dev (is the user in the input group?)"
exit 1
