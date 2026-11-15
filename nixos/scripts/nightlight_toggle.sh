#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$PATH"

# Toggles a gammastep night light. --check exits 0 when it is on.
# Match with -f: the gammastep binary is a wrapper, so the process is .gammastep-wrapped.

NIGHT_LIGHT_TEMPERATURE=${NIGHT_LIGHT_TEMPERATURE:-4000}

if [[ "${1:-}" == "--check" ]]; then
    pgrep -f gammastep > /dev/null
    exit
fi

if pgrep -f gammastep > /dev/null; then
    pkill -f gammastep
    echo "Night light mode disabled"
else
    setsid gammastep -O "$NIGHT_LIGHT_TEMPERATURE" > /dev/null 2>&1 &
    echo "Night light mode enabled at ${NIGHT_LIGHT_TEMPERATURE} K"
fi
