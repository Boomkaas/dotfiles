# ❄️ NixOS & MangoWM / Hyprland Dotfiles

A fully declarative, high-performance, and aesthetically refined **NixOS (25.05)** flake configuration featuring **MangoWM** (Scroller tiling compositor), **Hyprland** ecosystem utilities, **80+ Waybar themes**, **Fish shell with Starship**, custom browser skins, automation scripts, and an integrated **Graphify** knowledge graph.

---

## 🖥️ System Architecture & Stack

| Component | Technology / Tool | Details |
| :--- | :--- | :--- |
| **Operating System** | [NixOS](https://nixos.org/) (25.05 / unstable) | Pure Flake-based declarative system configuration |
| **Compositor** | [MangoWM](https://github.com/Mangowm/mangowm) (v0.3.4) | Wayland tiling compositor with dynamic Scroller layout & 2-pass blur |
| **Idle & Lockscreen** | [Hypridle](https://github.com/hyprwm/hypridle) + [Hyprlock](https://github.com/hyprwm/hyprlock) | Intelligent AC/Battery dual power saving & blurred PAM lockscreen |
| **Display Manager** | [GDM](https://wiki.gnome.org/Projects/GDM) | Native Wayland session display manager |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Modular status bar featuring 80+ switchable Hancore & Jakoolit themes |
| **Notification Center**| [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) | GTK-based control center with quick toggles, sliders, and media widget |
| **App Launcher** | [Rofi](https://github.com/davatorium/rofi) (Wayland) | Multi-mode launcher (Apps, Commands, Window Switcher, Emoji Picker) |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal with Gruvbox Dark aesthetic & cursor trails |
| **Shell** | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) | Interactive shell with Zoxide, Direnv, Eza, and smart `agy` token wrapper |
| **Audio Stack** | [PipeWire](https://pipewire.org/) | PipeWire + ALSA + Pulse + JACK + Realtek ALC256 ASUS mic pin routing |
| **Virtualization** | Docker, KVM / Libvirt, Waydroid | Full container, virtual machine, and Android Wayland virtualization |
| **Browser Theme** | Custom Firefox `userChrome.css` | Glassmorphic dark translucent panels & AMOLED gold startpage |
| **Desktop Pet** | [Wayland-VPet](https://github.com/Boomkaas/dotfiles) (Bongo Cat) | Hardware input & CPU-reactive overlay pet with Digimon/Pokemon sprites |
| **Knowledge Graph** | [Graphify](https://github.com/safishamsi/graphify) | AST + semantic codebase knowledge graph, interactive HTML, & Obsidian vault |

---

## 📁 Repository Directory Structure

```text
.
├── browser/
│   ├── newtab.html                     # Minimalist AMOLED gold digital clock startpage
│   └── userChrome.css                  # Dark glassmorphic Firefox UI styling (rounded panels, translucent menus)
│
├── config/
│   ├── bongocat/                       # Virtual desktop pet (wayland-vpet / Bongo Cat) configuration
│   │   ├── bongocat.conf               # Overlay geometry, CPU load thresholds, typing KPM reaction, device paths
│   │   ├── digimon.txt                 # Digimon sprite roster definitions
│   │   ├── pet_list.txt                # Active pet selection list (Dodomon, Agumon, etc.)
│   │   └── pokemon.txt                 # Pokemon sprite roster definitions
│   ├── fish/                           # Fish interactive shell configuration
│   │   ├── config.fish                 # Environment variables, Git/Nix abbreviations, smart 'agy' wrapper function
│   │   └── functions/
│   │       └── fish_greeting.fish      # Startup greeting with randomized coder quotes
│   ├── hypr/                           # Hyprland ecosystem idle and lockscreen configurations
│   │   ├── hypridle.conf               # Dual AC vs. Battery multi-tier power saving (dim, lock, DPMS off, suspend, poweroff)
│   │   └── hyprlock.conf               # High-aesthetic lockscreen with blurred background, dual-color clock, & PAM auth
│   ├── kitty/
│   │   └── kitty.conf                  # Kitty terminal: Gruvbox Dark, cursor trail decay, remote control socket, 20px padding
│   ├── mango/                          # MangoWM Wayland Compositor configuration suite
│   │   ├── config.conf                 # Master entrypoint sourcing sub-configs and user overrides
│   │   ├── autostart.conf              # Startup daemons (awww, swaync, hypridle, cliphist, waybar, dockbar, polkit)
│   │   ├── bind.conf                   # Keybindings (WASD/arrows navigation, window state toggles, launchers, scratchpad)
│   │   ├── layout.conf                 # Scroller layout engine rules, master-stack, and dwindle settings
│   │   ├── effect.conf                 # Visual effects: 2-pass blur, noise, brightness/saturation, 24px drop-shadows
│   │   ├── animation.conf              # Cubic-bezier zoom, slide, and fade window transitions
│   │   ├── rule.conf                   # Tag/workspace layout bindings and layer animation exceptions
│   │   ├── settings.conf               # Hot corners, cursor theme (Bibata-Modern-Ice), and XWayland persistence
│   │   └── pkg-mango.txt               # Package dependencies list (mangowm-git, gammastep, xdg-desktop-portal-wlr)
│   ├── rofi/                           # Rofi application launcher and menu themes
│   │   ├── config.rasi                 # Master configuration (drun, run, window modes, Kitty terminal target)
│   │   ├── horizontal.rasi             # Horizontal card layout theme variant
│   │   ├── less-rounded.rasi           # Crisp square corner theme variant
│   │   └── vertical.rasi               # Default sleek vertical list theme
│   ├── starship.toml                   # Starship two-line connected prompt with Git status, duration, & Nix shell status
│   ├── swaync/                         # Sway Notification Center styling & configuration
│   │   ├── config.json                 # Panel dimensions (420px), notification width (500px), widget layout
│   │   └── style.css                   # GTK stylesheet with JetBrainsMono Nerd Font and translucent cards
│   ├── Thunar/
│   │   └── uca.xml                     # Thunar custom actions ("Open Terminal Here", "Compress to .zip")
│   └── waybar/                         # Extensive Waybar library (80+ switchable themes)
│       ├── config                      # Active Waybar module configuration
│       ├── config.jsonc                # Alternative / extended JSONC module definition
│       ├── style.css                   # Active Waybar stylesheet
│       ├── hancore-*/                  # Hancore theme collection (v1 through v7 iterations, cyber, glass, neon, pill, rounded)
│       └── jakoolit-*/                 # Jakoolit theme collection (camellia, everforest, minimal, sleek, summitsplit, top-*)
│
├── nixos/
│   ├── flake.nix                       # Nix Flake entrypoint (nixpkgs 25.05, nixpkgs-unstable, mangowm, home-manager)
│   ├── flake.lock                      # Locked input dependency revisions
│   ├── modules/
│   │   ├── default.nix                 # Module aggregator importing core, utils, and package configurations
│   │   ├── pkgs.nix                    # System and user package declarations, custom binary wrappers
│   │   ├── core/
│   │   │   ├── audio.nix               # PipeWire sound server + Realtek ALC256 ASUS mic pin routing fix
│   │   │   ├── connections.nix         # NetworkManager, Bluetooth (dual mode, fast connect), rfkill unblock, firewall
│   │   │   ├── services.nix            # Virtualization (Docker, Libvirt/KVM, Waydroid), PostgreSQL 16, UPower, printing
│   │   │   ├── system.nix              # systemd-boot, locale (Europe/Kyiv, US/UA keymap), nix-ld, Wayland session variables
│   │   │   └── user.nix                # User account 'peng' (groups: wheel, video, docker, libvirtd, input, uinput)
│   │   └── utils/
│   │       └── xserver.nix             # GDM Wayland display manager, Hyprlock PAM auth, XDG desktop portals
│   ├── scripts/
│   │   ├── agy-tokens.py               # Antigravity Global Token & Quota Reporter CLI (colored gauges, live reset timers)
│   │   ├── channels.sh                 # Channel setup script for nixos-unstable, nixpkgs-unstable, home-manager
│   │   ├── controlbot.sh               # Telegram PC Remote Control bot runner
│   │   ├── epic                        # CLI launcher for native in-browser Epic Games Store freebies claimer
│   │   ├── epic-games-claimer.user.js  # Userscript for calm, in-browser Epic free game checkout with floating HUD
│   │   ├── gfn.sh                      # GeForce NOW Flatpak launcher
│   │   ├── nixreb.sh                   # Dotfiles sync to /etc/nixos and system rebuild helper ('nixreb')
│   │   ├── roblox.sh                   # Roblox launcher via Sober Flatpak
│   │   ├── screenshot.sh               # Area screenshot via Grim + Slurp, copied to clipboard with notification
│   │   ├── twitch                      # CLI launcher for native in-browser Twitch Drops claimer ('twitch' / 'tdrops')
│   │   └── twitch-drops-claimer.user.js# Userscript for Don't Starve Together Twitch Drops (160p eco, non-RU filter, auto-claim)
│   └── system/
│       ├── configuration.nix           # Main system configuration (MangoWM enable, Steam firewall, power key rules)
│       └── hardware-configuration.nix  # Hardware-specific scan (Intel CPU, NVMe, EXT4 root, VFAT boot, swap partition)
│
├── graphify-out/                       # Codebase knowledge graph generated by Graphify
│   ├── graph.html                      # Interactive 2D/3D visual network graph for browser exploration
│   ├── GRAPH_REPORT.md                 # Analysis report detailing god nodes, community cohesion, and architecture
│   ├── graph.json                      # Raw graph dataset (nodes, AST symbols, dependencies, communities)
│   └── obsidian/                       # Obsidian knowledge vault (one linked markdown note per node/component)
│
├── GEMINI.md                           # AI Agent workspace guidelines & Graphify-first indexing rules
└── README.md                           # Complete documentation for all files and directories
```

---

## ⚙️ NixOS System Architecture & Modules

The NixOS configuration is built on flakes with a modular separation of concerns located in `nixos/modules/`:

### 1. Core Modules (`nixos/modules/core/`)
- **`system.nix`**:
  - **Bootloader**: `systemd-boot` with EFI variables and a 5-generation configuration limit.
  - **Localization**: Timezone set to `Europe/Kyiv`, default locale `en_US.UTF-8`, console keymap `ua-utf`.
  - **Keyboard Layout**: `us,ua` switching via `Win + Space` (`grp:win_space_toggle`).
  - **Binary Compatibility (`nix-ld`)**: Enables running unpatched foreign dynamically-linked binaries (prebuilt language servers, CLI binaries, IDE tooling).
  - **Session Flags**: `NIXOS_OZONE_WL = "1"` and `QT_QPA_PLATFORM = "wayland"` for native Wayland execution across Electron and Qt apps.
- **`audio.nix`**:
  - **Sound Server**: PipeWire with ALSA (including 32-bit support), PulseAudio replacement, and JACK.
  - **ASUS ALC256 Audio Fix**: Injects kernel module option `snd-hda-intel model=alc256-asus-mic` to resolve internal and headset microphone pin routing on ASUS VivoBook laptops (e.g. X409FA).
- **`connections.nix`**:
  - **Networking**: NetworkManager enabled with open TCP firewall ports `8080` (web dev) and `5432` (PostgreSQL).
  - **Bluetooth**: Auto-powered on boot, Dual Controller Mode, FastConnectable, experimental features, `blueman` integration, and a systemd service running `rfkill unblock bluetooth`.
- **`services.nix`**:
  - **Virtualization**: Docker daemon, Libvirt / KVM with SPICE USB redirection and `virt-manager`, and Waydroid for containerized Android on Wayland.
  - **Database**: PostgreSQL 16 server pre-configured with `mydatabase` and local trust authentication.
  - **Power & System**: UPower, `power-profiles-daemon`, UDisks2, GVFS, CUPS printing, and Android udev permissions.
- **`user.nix`**:
  - User `peng` configured with default shell `pkgs.fish` and membership in `networkmanager`, `wheel`, `video`, `docker`, `libvirtd`, `input`, and `uinput`.

### 2. Utilities & Display (`nixos/modules/utils/`)
- **`xserver.nix`**:
  - **Display Manager**: GDM with native Wayland session support (`gdm.wayland = true`), ensuring MangoWM and Hyprland launch in pure Wayland without missing `$DISPLAY` errors.
  - **Authentication**: Hyprlock PAM integration (`programs.hyprlock.enable = true`).
  - **Portals**: `xdg-desktop-portal-gtk` and `xdg-desktop-portal-wlr` for screensharing and file pickers.

### 3. Package Management & Wrappers (`nixos/modules/pkgs.nix`)
- Declares development toolchains, desktop applications, Wayland utilities, and custom binary wrappers:
  - `controlbot`: Wrapper launching the Telegram PC remote control bot.
  - `epic`: Wrapper for the in-browser Epic Games Store claimer.
  - `twitch`: Wrapper for the in-browser DST Twitch Drops claimer.
  - `gfn`: Background launcher for GeForce NOW (`com.nvidia.geforcenow`).
  - `roblox`: Background launcher for Sober / Roblox (`org.vinegarhq.Sober`).
  - `tlauncher`: Minecraft TLauncher wrapper with auto-downloader and `steam-run` Java 17 execution.

---

## 🪟 Desktop Compositors & Window Management

### 🥭 MangoWM (`config/mango/`)
MangoWM is a dynamic tiling Wayland compositor built on the **Scroller layout** paradigm:
- **`config.conf`**: Master configuration entrypoint that includes all sub-modules and loads optional overrides from `~/hakuspace-control/mango-custom.conf`.
- **`layout.conf`**: Scroller layout configuration with 20 memory structures, default proportion `0.5`, auto center focusing, and single-window expansion (`1.0`). Also provides Master-Stack and Dwindle layout options.
- **`effect.conf`**: GPU-accelerated visual styling with 2-pass Gaussian blur, custom brightness (`0.8`), contrast (`1.4`), saturation (`1.6`), and 24px blurred drop shadows.
- **`animation.conf`**: Smooth cubic-bezier zoom transitions for window opening, closing, moving, and tag switching.
- **`autostart.conf`**: Starts `awww-daemon` (wallpaper), `swaync`, `hypridle`, `cliphist` (clipboard manager), `fcitx5`, and startup bar scripts.
- **`bind.conf`**: Full hotkey bindings:

| Hotkey | Action |
| :--- | :--- |
| `Super + Q` | Open Kitty terminal |
| `Super + R` | Open Rofi application launcher |
| `Super + B` | Launch Firefox |
| `Super + E` | Open Thunar file manager |
| `Super + N` | Toggle SwayNC notification control center |
| `Super + C` | Close / kill active client window |
| `Super + M` / `Super + K` | Lock screen via Hyprlock |
| `Super + P` | Capture area screenshot (`screenshot.sh`) |
| `Super + Shift + P` | Capture fullscreen screenshot |
| `Super + Ctrl + Shift + P` | Start screen recording |
| `Super + V` | Open clipboard history menu |
| `Super + Alt + C` | Cycle to next Waybar theme preset |
| `Super + Alt + B` | Toggle bottom dockbar visibility |
| `Super + L` | Toggle nightlight (Gammastep) |
| `Super + [A/S/W/D]` | Focus window Left / Down / Up / Right |
| `Super + Shift + [A/S/W/D]` | Move window Left / Down / Up / Right |
| `Super + Z` | Toggle window floating state |
| `Super + Shift + F` | Toggle maximized window state |
| `Super + Ctrl + Shift + F` | Toggle true fullscreen mode |
| `Super + I` | Minimize window to scratchpad |
| `Super + Shift + I` | Restore minimized window |
| `Super + 1..9` | Switch to Workspace / Tag 1 through 9 |

### 🔒 Hyprland Utilities (`config/hypr/`)
- **`hypridle.conf`**: Context-aware power-saving daemon:
  - **On Battery**: Lock at 2 min (`120s`), turn display off (DPMS) at 3 min (`180s`), suspend at 5 min (`300s`), shutdown at 1 hour (`3600s`).
  - **On AC / Charging**: Lock at 3 min (`180s`), turn display off at 10 min (`600s`), suspend at 20 min (`1200s`), shutdown at 3 hours (`10800s`).
- **`hyprlock.conf`**: Refined lockscreen rendering a 2-pass blurred snapshot of the active desktop, extra-bold golden hour / white minute typography, date label, and a minimalist password input box with auth feedback dots.

---

## 🎨 UI Customization, Bars & Themes

### 📊 Waybar Theme Library (`config/waybar/`)
The repository contains **over 80 modular Waybar themes** that can be cycled dynamically via `Super + Alt + C` or `waybar_manager.sh`:
- **Hancore Collection**:
  - `hancore-v1` through `hancore-v7` (with progressive micro-iterations `v1-1` to `v1-9d`, `v2-1` to `v2-9e`, `v3-1` to `v3-7`, `v4`, `v5`, `v6`, `v7`).
  - Aesthetic variants: `hancore-compact`, `hancore-cyber`, `hancore-glass`, `hancore-neon`, `hancore-pill`, `hancore-rounded`.
- **Jakoolit Collection**:
  - `jakoolit-camellia`, `jakoolit-everforest`, `jakoolit-minimal`, `jakoolit-sleek`, `jakoolit-summitsplit`.
  - Top bar styles: `jakoolit-top-arrow`, `jakoolit-top-chrysanthemum`, `jakoolit-top-default`, `jakoolit-top-default-laptop`, `jakoolit-top-gardenia`, `jakoolit-top-peony`, `jakoolit-top-simple`.

### 🔔 Sway Notification Center (`config/swaync/`)
- Sleek 420px slide-out control center with volume level sliders, Do-Not-Disturb toggle, quick action buttons, and a media player widget styled with GTK CSS.

### 🚀 Rofi Application Launcher (`config/rofi/`)
- Configured with `JetBrainsMono Nerd Font`, displaying application icons and sidebar mode for switching between `Apps`, `Run`, and `Window` modes. Offers `vertical.rasi`, `horizontal.rasi`, and `less-rounded.rasi` theme variants.

### 🐾 Bongo Cat Desktop Pet (`config/bongocat/`)
- `wayland-vpet` interactive overlay running at 60 FPS across a 950px roaming width.
- Listens to `/dev/input/` keyboard and mouse event devices to animate typing and wake-up.
- Triggers active "Working / Running" emotes when CPU usage spikes above 25%, and "Happy" emotes when typing speed exceeds 50 KPM.
- Includes sprite catalogs for **Digimon** (Dodomon, Agumon, Alphamon) and **Pokemon** (Mystery Dungeon sprites).

---

## 🐚 Shell & Terminal Workflow

### 🐱 Kitty Terminal (`config/kitty/kitty.conf`)
- **Theme**: Gruvbox Dark with `0.9` background opacity and 20px window margins.
- **Font**: `JetBrainsMono Nerd Font Mono` (size 12).
- **Cursor**: Beam cursor with dynamic trailing decay (`cursor_trail 2`, `cursor_trail_decay 0.1 0.4`).
- **Features**: Unix control socket (`unix:/tmp/kitty`) enabled for programmatic tab and script control.

### 🐟 Fish Shell (`config/fish/config.fish`)
Includes fast shell initialization, tool hooks, and rich workflow abbreviations:

| Category | Abbreviation / Command | Target Action |
| :--- | :--- | :--- |
| **System** | `nixreb` | Sync dotfiles & rebuild NixOS flake (`nixreb.sh`) |
| **System** | `addchans` | Set up nixos-unstable and home-manager channels |
| **System** | `nc` / `delgar` | Delete old Nix generations & garbage collect |
| **System** | `pacsize` / `pacsizefull` | Analyze installed package sizes |
| **Automation** | `epic` | Launch or manage Epic Games freebies claimer |
| **Automation** | `twitch` / `tdrops` | Launch or manage DST Twitch Drops claimer |
| **AI / Tokens** | `tokens` / `agy-tokens` | Run live Antigravity token quota report |
| **AI / AGY** | `agy tokens` | Intercepted by `agy` function to display quota |
| **Graphify** | `gsync` | Re-index entire codebase into knowledge graph (`graphify-all`) |
| **Graphify** | `gobsidian` | Export codebase graph into Obsidian vault |
| **Gaming** | `gfn` | Launch GeForce NOW Flatpak |
| **Gaming** | `roblox` | Launch Roblox via Sober Flatpak |
| **Fun** | `pet` | Launch Wayland virtual desktop pet |
| **Git** | `lg`, `gs`, `gd`, `ga`, `gc`, `gp`, `gl` | `lazygit`, status, diff, add, commit, push, log |
| **Listing** | `l`, `ll`, `la`, `lla` | `eza --icons --group-directories-first` aliases |

### 🚀 Starship Prompt (`config/starship.toml`)
- A modern, two-line connected prompt:
  - **Line 1**: User `@` Hostname, working directory with folder icon, Git branch & status badge, trailing line fill, command execution duration (if >2s), and clock.
  - **Line 2**: Status arrow (`▶︎` on success, `✘` on error) and active Nix development shell indicator.

---

## 🌐 Browser Customization (`browser/`)

- **`userChrome.css`**: Modifies Firefox's internal UI with dark translucent glassmorphism (`rgba(0, 0, 0, 0.8)` background, 16px and 12px rounded popups, URL bar styling, smooth hover highlights, and legible typography).
- **`newtab.html`**: A custom new tab startpage displaying an AMOLED-black background with a large golden glowing digital clock and localized date.

---

## 🤖 Automation Scripts (`nixos/scripts/`)

### 1. `nixreb.sh` (System Rebuild Helper)
```bash
nixreb
```
Syncs the repository configuration to `/etc/nixos/` using `rsync` and executes `nixos-rebuild switch --flake /etc/nixos#nixos` with 8 build cores and impure evaluation.

### 2. `epic` & `epic-games-claimer.user.js` (Epic Games Freebies Claimer)
An in-browser weekly auto-claimer that runs inside native logged-in Firefox:
- **Zero Captchas:** Utilizes the authenticated browser session directly.
- **Calm Paced Checkout:** Navigates store free games, handles mature content prompts, and clicks "Place Order" without aggressive bot patterns.
- **Floating HUD:** Features in-browser `⏹ Stop` and `▶ Resume` buttons to instantly pause or resume checkout.
- **CLI Commands:** `epic start`, `epic stop`, `epic status`.

### 3. `twitch` & `twitch-drops-claimer.user.js` (Twitch Drops Auto-Claimer)
An in-browser auto-claimer tailored for **Don't Starve Together** (DST) Twitch Drops:
- **Ultra-Eco Mode:** Automatically locks stream quality to 160p, mutes audio, and disables low-latency mode.
- **Channel Routing:** Filters out Russian-tagged channels, connects to the highest-viewed valid streamer, tracks progress timers, claims tier rewards, and closes the tab when all DST campaigns are completed.
- **CLI Commands:** `twitch start`, `twitch stop`, `twitch status` (also aliased as `tdrops`).

### 4. `agy-tokens.py` (Antigravity Token & Quota Reporter)
Displays real-time token quotas, tier usage progress bars, and countdown timers across AI model families (Gemini, Claude, GPT):
```bash
tokens
# or
agy tokens
```

### 5. `screenshot.sh`
Interactive screen area selection using `slurp` and `grim`, automatically copying the resulting image to the Wayland clipboard (`wl-copy`) and dispatching a desktop notification (`notify-send`).

---

## 🧠 Knowledge Graph (`graphify-out/`)

This repository maintains an active codebase knowledge graph generated by [Graphify](https://github.com/safishamsi/graphify) (`/home/peng/.local/bin/graphify-all`):

- **Interactive Network Graph (`graphify-out/graph.html`)**: Open in any browser to navigate module dependencies, script calls, configuration relationships, and UI component clusters.
- **Obsidian Knowledge Vault (`graphify-out/obsidian/`)**: A complete Obsidian vault where every configuration file, module, and script has its own bi-directionally linked note with metadata and dependency lists.
- **Audit Report (`graphify-out/GRAPH_REPORT.md`)**: Summary of codebase structure, god nodes (most interconnected components), community cohesion scores, and structural analysis.
- **Raw Graph Data (`graphify-out/graph.json`)**: Graph database in GraphRAG-compatible JSON format.

### Updating the Knowledge Graph
Whenever modifying NixOS modules, scripts, or configurations, update the graph using:
```bash
gsync
# or
graphify-all
```

To export or rebuild the Obsidian vault:
```bash
gobsidian
```

---

## 🚀 Getting Started & Rebuilding

### 1. Initial Setup
Clone the dotfiles into your home directory:
```bash
git clone https://github.com/Boomkaas/dotfiles.git ~/Code/Dotfiles
cd ~/Code/Dotfiles
```

### 2. Rebuild NixOS
Apply the flake configuration to your system:
```bash
nixreb
```

### 3. Cycle Waybar Themes
Press `Super + Alt + C` or run:
```bash
waybar_manager.sh --cycle
```

---

## 📝 License

Personal NixOS dotfiles. Licensed under the MIT License — feel free to adapt and incorporate into your own setups!
