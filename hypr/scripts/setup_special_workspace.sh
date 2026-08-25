#!/usr/bin/env bash

# Setup special workspace with Telegram on left (50%) and Fastfetch terminal on right (50%)

SPECIAL_WS="special:magic"

# Check if Telegram window is open in Hyprland
if ! hyprctl clients | grep -E -q "class: (org\.telegram\.desktop|telegram-desktop|TelegramDesktop)"; then
    # Launch Telegram
    telegram-desktop &
    # Wait up to 3 seconds for Telegram window to be created
    for i in {1..30}; do
        if hyprctl clients | grep -E -q "class: (org\.telegram\.desktop|telegram-desktop|TelegramDesktop)"; then
            break
        fi
        sleep 0.1
    done
else
    # Move existing window to special workspace
    hyprctl dispatch movetoworkspacesilent "${SPECIAL_WS},class:^(org\.telegram\.desktop|telegram-desktop|TelegramDesktop)$"
fi

# Check if fastfetch terminal window is open in Hyprland
if ! hyprctl clients | grep -q "class: fastfetch-term"; then
    # Launch Kitty with fastfetch
    kitty --class fastfetch-term -e sh -c "fastfetch; exec $SHELL" &
    # Wait up to 2 seconds for Fastfetch terminal to appear
    for i in {1..20}; do
        if hyprctl clients | grep -q "class: fastfetch-term"; then
            break
        fi
        sleep 0.1
    done
else
    # Move existing terminal to special workspace
    hyprctl dispatch movetoworkspacesilent "${SPECIAL_WS},class:^(fastfetch-term)$"
fi

# Open special workspace if not already open
if ! hyprctl monitors -j | grep -q '"name": "special:magic"'; then
    hyprctl dispatch togglespecialworkspace magic
fi

# Ensure layout: Telegram on the left (50%), Fastfetch on the right (50%)
python3 - <<'PYEOF'
import json
import re
import subprocess
import time

for _ in range(15):
    try:
        clients = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"]))
        tg = None
        ff = None
        for c in clients:
            ws_name = c.get("workspace", {}).get("name", "")
            if ws_name == "special:magic":
                cls = c.get("class", "")
                if re.search(r"org\.telegram\.desktop|telegram-desktop|TelegramDesktop", cls, re.I):
                    tg = c
                elif "fastfetch-term" in cls:
                    ff = c

        if tg and ff:
            tg_x, tg_y = tg["at"]
            ff_x, ff_y = ff["at"]

            # If stacked vertically (top/bottom) instead of side-by-side, toggle split
            if abs(tg_x - ff_x) < 20 and abs(tg_y - ff_y) > 20:
                subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{tg['address']}"], stdout=subprocess.DEVNULL)
                subprocess.run(["hyprctl", "dispatch", "layoutmsg", "togglesplit"], stdout=subprocess.DEVNULL)
                time.sleep(0.1)
                continue

            # If Telegram is on the right of Fastfetch (tg_x > ff_x), swap to left
            if tg_x > ff_x:
                subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{tg['address']}"], stdout=subprocess.DEVNULL)
                subprocess.run(["hyprctl", "dispatch", "swapwindow", "l"], stdout=subprocess.DEVNULL)
                time.sleep(0.05)
            break
    except Exception:
        pass
    time.sleep(0.1)
PYEOF
