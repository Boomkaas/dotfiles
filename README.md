# NixOS & Hyprland Dotfiles

Personal declarative NixOS configuration flake and user environment.

## 🖥️ Overview

- **OS:** [NixOS](https://nixos.org/) (Flake-based, 25.05)
- **Window Manager:** [Hyprland](https://hyprland.org/) (Wayland compositor)
- **Shell / UI:** [Noctalia Shell](https://github.com/noctalia/noctalia) (Quickshell-based desktop shell)
- **Terminal:** Kitty
- **Shell:** Zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) + Oh My Zsh
- **User Environment:** [Home Manager](https://github.com/nix-community/home-manager)

---

## 📁 Repository Structure

```text
nixos/
├── flake.nix             # Nix Flake entrypoint
├── flake.lock            # Locked input revisions
├── modules/
│   ├── default.nix       # Module aggregator
│   ├── pkgs.nix          # System and user package declarations
│   ├── core/
│   │   ├── system.nix    # Base system config, locale, bootloader, nix-ld
│   │   ├── services.nix  # Virtualisation (Docker/Libvirt/Waydroid), PostgreSQL, etc.
│   │   ├── audio.nix     # PipeWire & ALSA sound configurations
│   │   ├── connections.nix # NetworkManager & Bluetooth
│   │   └── user.nix      # User accounts & default shell
│   └── utils/
│       ├── zsh.nix       # Zsh shell configuration & plugins
│       └── xserver.nix   # Display & X11/Wayland helpers
├── scripts/
│   ├── epic              # Opens native Firefox to claim weekly Epic Games freebies (alias: epic)
│   ├── epic-games-claimer.user.js # Native in-browser Epic claimer userscript
│   ├── twitch            # Opens native Firefox to auto-claim Twitch Drops (aliases: twitch, tdrops)
│   ├── twitch-drops-claimer.user.js # Native in-browser Twitch Drops claimer (DST & DBD priority)
│   ├── nixreb.sh         # Sync dotfiles to /etc/nixos and rebuild system (alias: nixreb)
│   ├── screenshot.sh     # Area screenshot with grim/slurp and clipboard copy
│   ├── controlbot.sh     # PC Control Telegram bot runner
│   ├── gfn.sh            # GeForce NOW launcher
│   ├── roblox.sh         # Roblox launcher
│   └── channels.sh       # Channel setup utility
└── system/
    ├── configuration.nix # Main system & Home Manager configuration
    └── hardware-configuration.nix # Hardware scan / disk mounts
```

---

## 🚀 Rebuilding the System

A helper script `nixreb` is provided in `nixos/scripts/nixreb.sh` (and aliased in Zsh):

```bash
nixreb
```

This script:
1. Syncs the repo configuration to `/etc/nixos/` via `rsync`.
2. Runs `nixos-rebuild switch --flake /etc/nixos#nixos` with optimal build cores.

---

## 🛠️ Key Components & Utilities

### 🎁 `epic` (Epic Games Free Games Claimer)
An in-browser auto-claimer for weekly Epic Games freebies:
- **No Captchas / No Login Prompts:** Runs directly inside your native logged-in Firefox session.
- **Calm Execution:** Politely navigates and taps "Get", bypasses mature content gates, and completes checkout ("Place Order") without aggressive bot behavior.
- **Usage:** Run `epic` in any terminal to focus/open Firefox at the Free Games page.

### 🟣 `twitch` (Twitch Drops Auto-Claimer)
An in-browser auto-claimer for Twitch Drops:
- **Game Priorities:** Prioritizes **Don't Starve Together** (1st) and **Dead by Daylight** (2nd).
- **Language Filter:** Automatically ignores Russian-tagged / Russian-language streams and joins the top active non-Russian channel.
- **Auto-Claim & Auto-Close:** Mutes stream, claims in-chat bonuses and completed drops from inventory, and automatically closes the browser window once all target rewards are claimed.
- **Usage:** Run `twitch` or `tdrops` in any terminal to start.

### ⚡ `nix-ld`
Configured in `nixos/modules/core/system.nix` to allow running unpatched foreign dynamically-linked binaries (e.g. prebuilt language servers, CLI tools) on NixOS.

### 🎮 Virtualization & Gaming
- **Virtualization:** Docker, Libvirt / KVM (`virt-manager`), Waydroid.
- **Gaming:** Steam, GeForce NOW (Flatpak), TLauncher, Sober / Roblox.

---

## 📝 License

Personal dotfiles. Feel free to use and adapt to your own configuration.
