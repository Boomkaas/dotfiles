#!/usr/bin/env bash

# Create screenshots directory if it doesn't exist
mkdir -p "$HOME/Pictures/Screenshots"

# Generate a timestamped filename
FILE="$HOME/Pictures/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

# Capture selected area
GEOM=$(slurp) || exit 0

if [ -n "$GEOM" ] && grim -g "$GEOM" "$FILE"; then
    # Copy to clipboard
    wl-copy < "$FILE"
    # Notify user
    notify-send "Screenshot Captured" "Saved to $FILE and copied to clipboard"
fi
