#!/usr/bin/env bash

# ==============================================================================
# Grim Screenshot Tool (Wayland)
# Supports region capture (slurp) and fullscreen capture. Copies to wl-clipboard.
# ==============================================================================

# Include SCREENSHOT_DIR if defined
[ -f "$HOME/hakuspace-control/main_setting.sh" ] && source "$HOME/hakuspace-control/main_setting.sh"

SCREENSHOT_DIR=${SCREENSHOT_DIR:-"$HOME/Pictures/Screenshots"}
mkdir -p "$SCREENSHOT_DIR"

timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
file="${SCREENSHOT_DIR}/Screenshot_${timestamp}.png"

usage() {
    cat <<'EOF'
Usage:
    screenshot.sh              # Select region with slurp
    screenshot.sh --fullscreen # Fullscreen capture
EOF
}

mode="region"
if [[ "${1:-}" == "--fullscreen" ]]; then
    mode="fullscreen"
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
elif [[ $# -gt 0 ]]; then
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 1
fi

for cmd in grim wl-copy; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd" >&2
        exit 1
    }
done

if [[ "$mode" == "region" ]]; then
    command -v slurp >/dev/null 2>&1 || {
        echo "Missing dependency: slurp (required for region mode)" >&2
        exit 1
    }
    geometry="$(slurp)" || exit 0
    grim -g "$geometry" "$file"
else
    grim "$file"
fi

if [[ -f "$file" ]]; then
    wl-copy < "$file"
    echo "Saved & copied: $file"
    notify-send -i "$file" "Screenshot Captured" "Saved to $file and copied to clipboard"
fi
