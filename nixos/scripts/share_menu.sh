#!/usr/bin/env bash
# ==============================================================================
# share_menu.sh - Wrapper for 'share' interactive fzf TUI menu
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARE_BIN="$DIR/share"

if [ ! -t 0 ] || [ ! -t 1 ]; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        if command -v kitty >/dev/null 2>&1; then
            exec kitty --title "Network & Share Manager" "$SHARE_BIN" "$@"
        elif command -v foot >/dev/null 2>&1; then
            exec foot --title "Network & Share Manager" "$SHARE_BIN" "$@"
        fi
    fi
fi

exec "$SHARE_BIN" "$@"
