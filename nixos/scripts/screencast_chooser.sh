#!/usr/bin/env bash
export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-peng}/bin:$HOME/.local/bin:$PATH"

# ==============================================================================
# Screencast Source Chooser
# dmenu-style chooser for xdg-desktop-portal-wlr (chooser_type=dmenu, set in
# nixos/modules/utils/xserver.nix). xdpw pipes the shareable sources on stdin,
# one per line ("Monitor: <output> ..." / "Window: <title> (<app_id>)"), and
# expects the chosen line back on stdout. Empty output cancels the share.
# The picker is an fzf list in a floating kitty window (tui-overlay rule).
# ==============================================================================

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/in"
[[ -s "$tmp/in" ]] || exit 0

# Prefix each line with its display form; the raw line stays in field 1 and is
# what gets returned, so xdpw can match it exactly.
awk '{
    line = $0
    if (sub(/^Monitor: /, "", line))     printf "%s\t󰍹  Screen  %s\n", $0, line
    else if (sub(/^Window: /, "", line)) printf "%s\t  Window  %s\n", $0, line
    else                                 printf "%s\t%s\n", $0, $0
}' "$tmp/in" > "$tmp/menu"

kitty \
    --class tui-overlay \
    --title "Share screen" \
    -o initial_window_width=100c \
    -o initial_window_height=18c \
    -o remember_window_size=no \
    -o confirm_os_window_close=0 \
    -o placement_strategy=center \
    -o hide_window_decorations=yes \
    bash -c 'fzf --delimiter="\t" --with-nth=2 --no-multi --layout=reverse \
        --prompt="Share > " --header="Pick a screen or window (Esc cancels)" \
        --color=border:bright-black,prompt:green,pointer:red,header:blue,info:yellow,hl:cyan,hl+:bright-red \
        < "$1" | cut -f1 > "$2"' _ "$tmp/menu" "$tmp/out" >/dev/null 2>&1

[[ -s "$tmp/out" ]] && head -n1 "$tmp/out"
exit 0
