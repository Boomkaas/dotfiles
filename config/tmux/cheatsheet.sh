#!/usr/bin/env bash
clear

G=$'\e[1;32m'    # Green
Y=$'\e[1;33m'    # Yellow/Gold
B=$'\e[1;34m'    # Blue
C=$'\e[1;36m'    # Cyan
M=$'\e[1;35m'    # Magenta
D=$'\e[2m'       # Dim
R=$'\e[0m'       # Reset
BOLD=$'\e[1m'

cat << EOF | less -R --mouse -Ps"  [Scroll: ↑/↓/jk/Mouse/PgUp/PgDn | Quit: q] "
${Y}╔═════════════════════════════════════════════════════════════════════════════╗${R}
${Y}║                     󰈺 TMUX & YAZI CHEAT SHEET (F1)                         ║${R}
${Y}╚═════════════════════════════════════════════════════════════════════════════╝${R}
  ${BOLD}Prefix Key:${R} ${C}Ctrl-a${R} ${D}(primary)${R} or ${C}Ctrl-b${R} ${D}(fallback)${R}

  ${B}─── 󰍹 PANES (Splits & Focus) ────────────────────────────────────────────────${R}
    ${G}Alt + Arrows${R}        Switch active pane directly ${D}(NO PREFIX!)${R}
    ${G}Alt + h / j / k / l${R} Switch active pane using Vim navigation ${D}(NO PREFIX!)${R}
    ${G}Prefix + | or \\${R}     Split pane vertically (left / right in current dir)
    ${G}Prefix + - or _${R}     Split pane horizontally (top / bottom in current dir)
    ${G}Prefix + H/J/K/L${R}    Resize active pane by 5 cells
    ${G}Prefix + m or z${R}     Toggle maximize active pane (zoom in/out)
    ${G}Prefix + x${R}          Kill active pane (with confirmation prompt)

  ${B}─── 󰖯 WINDOWS (Tabs) ────────────────────────────────────────────────────────${R}
    ${G}Prefix + c${R}          Create new window (in current directory)
    ${G}Alt + 0 .. 9${R}        Switch to or create window 0–9 ${D}(NO PREFIX!)${R}
    ${G}Shift+Alt + 0 .. 9${R}  Move current window to slot 0–9 ${D}(NO PREFIX!)${R}
    ${G}Shift + Left/Right${R}  Cycle to previous / next window ${D}(NO PREFIX!)${R}
    ${G}Prefix + Tab${R}        Jump to last active window
    ${G}Prefix + ,${R}          Rename current window
    ${G}Prefix + &${R}          Kill current window

  ${B}─── 󰄬 POPUPS & CLIPBOARD ────────────────────────────────────────────────────${R}
    ${G}Prefix + y${R}          ${BOLD}Floating Yazi File Manager popup${R}
    ${G}Prefix + [${R}          Enter Vi copy mode (${C}v${R}: select, ${C}y${R}: copy to Wayland)
    ${G}Prefix + ]${R}          Paste from Wayland clipboard into tmux
    ${G}Prefix + r${R}          Reload tmux configuration
    ${G}F1${R} or ${G}Prefix + /${R}    Show this cheat sheet popup

  ${M}─── 󰇥 YAZI QUICK REFERENCE (Inside Yazi or Shell) ───────────────────────────${R}
    ${G}Ctrl + o${R}            Open Yazi from Fish shell with cwd tracking
    ${G}Enter / l${R}           Open file or enter folder
    ${G}h${R}                   Go up to parent folder
    ${G}.${R}                   Toggle hidden files
    ${G}e / o${R}               Edit in Zed / Open with system app
    ${G}Space / v${R}           Select item / Visual multi-select
    ${G}a / r / d / D${R}       Create / Rename / Trash / Delete permanent
    ${G}yy / x / p${R}          Copy / Cut / Paste files
    ${G}yp / yf / yd${R}        Copy path / filename / directory to clipboard
    ${G}z / f / s${R}           Zoxide jump / FZF search / Ripgrep content search
    ${G}q / Q${R}               Quit & cd to dir / Quit without changing dir
${Y}═══════════════════════════════════════════════════════════════════════════════${R}
EOF
