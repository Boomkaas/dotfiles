# ❄️ NixOS & MangoWM / Hyprland Dotfiles

A fully declarative, high-performance, and aesthetically refined **NixOS (25.05)** flake configuration featuring **MangoWM** (Scroller tiling compositor), **Hyprland** ecosystem utilities, **Hancore Waybar theme**, **Tmux & Yazi terminal workflow**, **Rofi interactive control menus**, **Fish shell with Starship**, custom browser skins, automation scripts, and an integrated **Graphify** knowledge graph.

---

## 🖥️ System Architecture & Stack

| Component | Technology / Tool | Details |
| :--- | :--- | :--- |
| **Operating System** | [NixOS](https://nixos.org/) (25.05 / unstable) | Pure Flake-based declarative system configuration |
| **Compositor** | [MangoWM](https://github.com/Mangowm/mangowm) (v0.3.4) | Wayland tiling compositor with dynamic Scroller layout & 2-pass blur |
| **Idle & Lockscreen** | [Hypridle](https://github.com/hyprwm/hypridle) + [Hyprlock](https://github.com/hyprwm/hyprlock) | Intelligent AC/Battery dual power saving, blurred lockscreen, & `awake` caffeine tool |
| **Display Manager** | [GDM](https://wiki.gnome.org/Projects/GDM) | Native Wayland session display manager |
| **Status Bar** | [Waybar](https://github.com/Alexays/Waybar) | Minimalist status bar running active `hancore-v1-9b` theme with toggle controls |
| **Notification Center**| [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) | GTK-based control center with quick toggles, sliders, and media widget |
| **App Launcher & Menus**| [Rofi](https://github.com/davatorium/rofi) (Wayland) | Multi-mode launcher + interactive submenus (Wi-Fi, Bluetooth, Audio, Processes, Disk, Clean, Config) |
| **Terminal & Multiplexer**| [Kitty](https://sw.kovidgoyal.net/kitty/) + [Tmux](https://github.com/tmux/tmux) | GPU-accelerated terminal (Gruvbox Dark) + Tmux patched for 100MB buffer limit |
| **TUI Control Center** | [`s`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/s) + 21 TUI Suite | Master CLI/FZF launcher & 21 unified interactive TUIs for system, network, dev & desktop |
| **Code Editor** | [Neovim](https://neovim.io/) | LazyVim IDE with OLED #000000 theme, full VS Code key parity, & Antigravity AI |
| **File Managers** | [Yazi](https://github.com/sxyazi/yazi) + [Thunar](https://docs.xfce.org/xfce/thunar/start) | Lightning-fast TUI file manager with Ueberzug++ previews & shell cd integration + GUI fallback |
| **Shell** | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) | Interactive shell with Zoxide, Direnv, Eza, Yazi `Ctrl+O` hotkey, and smart `agy` token wrapper |
| **Audio Stack** | [PipeWire](https://pipewire.org/) + WireMix | PipeWire + ALSA + Pulse + JACK + WireMix TUI + Realtek ALC256 ASUS mic pin routing |
| **Network & Diagnostics**| NetworkManager + Wireshark | System-wide packet capturing (GUI & CLI `wireshark`, `termshark`) with user permissions |
| **VPN & File Sharing** | TunnelBear + Hamachi + Samba | TunnelBear VPN (21 TUI tools, per-app split tunneling, cloud quota) + Hamachi & Samba LAN share (`~/Shared`, `~/Code`) |
| **Virtualization** | Docker, KVM / Libvirt | Container and virtual machine virtualization with SPICE USB redirection |
| **Media & Images** | Viewnior + Swappy + VLC | Lightweight image viewer (`viewnior`), Wayland snapshot annotator (`swappy`), and media player |
| **Browser Theme** | Custom Firefox `userChrome.css` | Glassmorphic dark translucent panels & AMOLED gold startpage |
| **Desktop Pet** | [Wayland-VPet](https://github.com/Boomkaas/dotfiles) (Bongo Cat) | Hardware input & CPU-reactive overlay pet with Digimon/Pokemon sprites (patched fullscreen behavior) |
| **Knowledge Graph** | [Graphify](https://github.com/safishamsi/graphify) | AST + semantic codebase knowledge graph & interactive HTML |
| **System Test Suite** | [nixtest](file:///home/peng/Code/Dotfiles/nixos/scripts/nixtest) | Modular 14-subsystem verification suite (~150+ checks) covering Nix evaluation, security, power, and audio |

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
│   │   ├── config.fish                 # Environment variables, Tmux/Yazi shortcuts, 'y' cd wrapper, 'agy' tokens
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
│   │   ├── bind.conf                   # Keybindings (WASD navigation, Kitty+Tmux, Antigravity IDE, Rofi menus, media)
│   │   ├── layout.conf                 # Scroller layout engine rules, master-stack, and dwindle settings
│   │   ├── effect.conf                 # Visual effects: 2-pass blur, noise, brightness/saturation, 24px drop-shadows
│   │   ├── animation.conf              # Cubic-bezier zoom, slide, and fade window transitions
│   │   ├── rule.conf                   # Tag/workspace layout bindings and layer animation exceptions
│   │   ├── settings.conf               # Hot corners, cursor theme (Bibata-Modern-Ice), and XWayland persistence
│   │   └── pkg-mango.txt               # Package dependencies list (mangowm-git, gammastep, xdg-desktop-portal-wlr)
│   ├── nvim/                           # Neovim configuration powered by LazyVim starter
│   │   ├── init.lua                    # Neovim entrypoint
│   │   ├── lazy-lock.json              # Locked plugin dependencies
│   │   ├── lazyvim.json                # LazyVim extra configuration and settings
│   │   └── lua/
│   │       ├── config/                 # LazyVim options, keymaps, autocmds, and lazy.nvim bootstrap
│   │       └── plugins/                # Antigravity AI, OLED black theme, VS Code keys, glance, undotree
│   ├── rofi/                           # Rofi application launcher and menu themes
│   │   ├── config.rasi                 # Master configuration (drun & Processes modes, keyboard navigation bindings)
│   │   ├── horizontal.rasi             # Horizontal card layout theme variant
│   │   ├── less-rounded.rasi           # Crisp square corner theme variant
│   │   └── vertical.rasi               # Default sleek vertical list theme
│   ├── starship.toml                   # Starship two-line connected prompt with Git status, duration, & Nix shell status
│   ├── swaync/                         # Sway Notification Center styling & configuration
│   │   ├── config.json                 # Panel dimensions (420px), notification width (500px), widget layout
│   │   └── style.css                   # GTK stylesheet with JetBrainsMono Nerd Font and translucent cards
│   ├── Thunar/
│   │   ├── accels.scm                  # Thunar keyboard accelerator bindings (Ctrl+Shift+H highlight shortcut)
│   │   └── uca.xml                     # Thunar custom actions (Finder-like color tagging, terminal, zip)
│   ├── tmux/                           # Tmux terminal multiplexer suite
│   │   ├── tmux.conf                   # Gruvbox styling, Vi keybindings, statusbar format, prefix configuration
│   │   └── cheatsheet.sh               # Interactive floating cheat-sheet script for tmux shortcuts
│   ├── waybar/                         # Waybar configuration and style
│   │   ├── config                      # Active Waybar module configuration
│   │   ├── config.jsonc                # Alternative / extended JSONC module definition
│   │   ├── style.css                   # Active Waybar stylesheet (polished and deduplicated)
│   │   └── hancore-v1-9b/              # Active Hancore v1-9b reference theme
│   └── yazi/                           # Yazi terminal file manager configuration
│       ├── keymap.toml                 # Custom keybindings (quick editor, cd-on-exit, shell integrations)
│       └── yazi.toml                   # Ratio layout (1:4:3), natural sort, image previews, trash behavior
│
├── nixos/
│   ├── flake.nix                       # Nix Flake entrypoint (nixpkgs 25.05, nixpkgs-unstable, mangowm, home-manager)
│   ├── flake.lock                      # Locked input dependency revisions
│   ├── modules/
│   │   ├── default.nix                 # Module aggregator importing core, utils, and package configurations
│   │   ├── pkgs.nix                    # System packages, custom script wrappers (wifi-menu, awake, etc.), overlays
│   │   ├── patches/                    # Custom source patches applied to nixpkgs builds
│   │   │   ├── wayland-vpet-fullscreen.patch  # Prevents wayland-vpet from auto-hiding during fullscreen apps
│   │   │   └── yazi-disable-trt.patch         # Disables unwanted terminal reset behaviors in Yazi
│   │   ├── core/
│   │   │   ├── audio.nix               # PipeWire sound server + Realtek ALC256 ASUS mic pin routing fix
│   │   │   ├── connections.nix         # NetworkManager, Bluetooth, Wireshark CLI, rfkill unblock, firewall
│   │   │   ├── services.nix            # Virtualization (Docker, Libvirt/KVM), PostgreSQL 16, Samba VM shares, UPower
│   │   │   ├── system.nix              # systemd-boot, kernel params (mem_sleep_default, i915), nix-ld, Wayland flags
│   │   │   └── user.nix                # User 'peng' (groups: wheel, video, docker, libvirtd, input, uinput, wireshark)
│   │   └── utils/
│   │       └── xserver.nix             # GDM Wayland display manager, Hyprlock PAM auth, XDG desktop portals
│   ├── scripts/
│   │   ├── tui/                        # Unified FZF interactive terminal control suite (21 tools + launcher)
│   │   │   ├── s                       # Master TUI command center & script launcher
│   │   │   ├── app                     # Application launcher & .desktop browser with theme sync
│   │   │   ├── audio                   # PipeWire & WirePlumber audio mixer & node routing
│   │   │   ├── bluetooth               # Bluetooth device scanner, pairing, and battery status
│   │   │   ├── clip                    # Wayland clipboard history & snippet manager (`cliphist`)
│   │   │   ├── conf                    # Dotfiles & config picker with syntax preview (`bat`)
│   │   │   ├── container               # Docker containers & Libvirt/KVM VM management
│   │   │   ├── disk                    # Storage, partition usage, USB mount/eject, & Nix GC
│   │   │   ├── log                     # Systemd journal & dmesg kernel error explorer
│   │   │   ├── nixos                   # NixOS generations, closure diffs & rollback manager
│   │   │   ├── pkg                     # Declared package explorer & ephemeral nix-shell tester
│   │   │   ├── ports                   # Real-time listening ports, sockets & server killer
│   │   │   ├── ram                     # Memory recovery, process pruner & boot state restorer
│   │   │   ├── repo                    # Multi-repository Git radar & project status dashboard
│   │   │   ├── service                 # Systemd user & system service daemon controller
│   │   │   ├── setting                 # Desktop settings (brightness, power, idle, DND, volume)
│   │   │   ├── share                   # Samba LAN/VM shares & LogMeIn Hamachi VPN manager
│   │   │   ├── task                    # Process monitor & MangoWM window controller
│   │   │   ├── tb                      # TunnelBear VPN & per-app split tunneling manager (`tunnelbear` / `tb`)
│   │   │   ├── theme                   # Theme manager, wallpapers, and fonts
│   │   │   ├── tm                      # Tmux session manager & project workspace jumper
│   │   │   └── wifi                    # Wi-Fi network scanner, connection & signal monitor
│   │   ├── s -> tui/s                  # Canonical symlink to master command center
│   │   ├── app -> tui/app              # Application launcher CLI wrapper
│   │   ├── audio -> tui/audio          # PipeWire terminal mixer CLI wrapper
│   │   ├── bluetooth -> tui/bluetooth  # Bluetooth device manager CLI wrapper
│   │   ├── clip -> tui/clip            # Clipboard history CLI wrapper
│   │   ├── conf -> tui/conf            # Dotfile config selector CLI wrapper
│   │   ├── container -> tui/container  # Docker & VM manager CLI wrapper
│   │   ├── disk -> tui/disk            # Disk & storage cleaner CLI wrapper
│   │   ├── log -> tui/log              # Systemd journal explorer CLI wrapper
│   │   ├── nixos -> tui/nixos          # NixOS generations & rollback CLI wrapper
│   │   ├── pkg -> tui/pkg              # Nix packages explorer CLI wrapper
│   │   ├── ports -> tui/ports          # Network ports & dev server CLI wrapper
│   │   ├── ram -> tui/ram              # Memory recovery CLI wrapper
│   │   ├── repo -> tui/repo            # Git repositories dashboard CLI wrapper
│   │   ├── restore-ram -> tui/ram      # Boot state memory restore symlink
│   │   ├── restore_boot_state.sh       # Script to return system to post-boot RAM state
│   │   ├── service -> tui/service      # Systemd service manager CLI wrapper
│   │   ├── setting -> tui/setting      # Desktop settings dispatcher CLI wrapper
│   │   ├── share -> tui/share          # File sharing & VPN manager CLI wrapper
│   │   ├── task -> tui/task            # Process & window controller CLI wrapper
│   │   ├── tb -> tui/tb                # TunnelBear VPN CLI wrapper
│   │   ├── theme -> tui/theme          # Desktop theme switcher CLI wrapper
│   │   ├── tm -> tui/tm                # Tmux session manager CLI wrapper
│   │   ├── tui-popup                   # Centered floating Wayland modal window launcher
│   │   ├── tunnelbear -> tui/tb        # TunnelBear VPN full command wrapper
│   │   ├── wifi -> tui/wifi            # Wi-Fi network scanner CLI wrapper
│   │   ├── agy-tokens.py               # Antigravity Global Token & Quota Reporter CLI
│   │   ├── audio_menu.sh               # Rofi-driven PipeWire audio switcher (`audio-menu`)
│   │   ├── awake                       # CLI wake-lock / caffeine inhibitor (`awake on/off/status`)
│   │   ├── bluetooth_menu.sh           # Rofi interactive Bluetooth control menu (`bluetooth-menu`)
│   │   ├── clean_menu.sh               # Rofi system cleaner (`clean-menu`)
│   │   ├── config_menu.sh              # Rofi rapid configuration editor (`config-menu`)
│   │   ├── disk_menu.sh                # Rofi visual disk usage breakdown (`disk-menu`)
│   │   ├── dpms_handler.sh             # Unified DPMS monitor sleep/wake dispatcher
│   │   ├── epic                        # CLI launcher for native Epic Games Store claimer
│   │   ├── epic-games-claimer.user.js  # Userscript for calm Epic free game checkout
│   │   ├── gfn.sh                      # GeForce NOW Flatpak launcher
│   │   ├── gtk_theme_menu.sh           # Rofi GTK theme switcher (`gtk-theme-menu`)
│   │   ├── idle_inhibit.sh             # Activity & power state validator before sleep/poweroff
│   │   ├── idle_sleep_poweroff.sh      # RTC hardware wake timer and dual-tier idle daemon
│   │   ├── lock.sh                     # Multi-compositor screen lock script
│   │   ├── nixreb.sh                   # Dotfiles sync to /etc/nixos and system rebuild helper
│   │   ├── nixtest                     # Modular NixOS verification test suite (14 modules, ~150+ checks)
│   │   ├── process_menu.sh             # Rofi interactive process monitor (`process-menu`)
│   │   ├── roblox.sh                   # Roblox launcher via Sober Flatpak
│   │   ├── screenshot.sh               # Region and fullscreen screenshot utility
│   │   ├── share_menu.sh               # Interactive menu wrapper for network sharing (`share-menu`)
│   │   ├── twitch                      # CLI launcher for Twitch Drops claimer (`twitch` / `tdrops`)
│   │   ├── twitch-drops-claimer.user.js# Userscript for DST Twitch Drops (160p eco, auto-claim)
│   │   ├── unlock_screen.sh            # Reliable screen unlocker (DPMS wake, wtype auth)
│   │   ├── waybar_manager.sh           # Waybar theme switcher, cycle manager, and daemon controller
│   │   └── wifi_menu.sh                # Rofi interactive Wi-Fi selector menu (`wifi-menu`)
│   └── system/
│       ├── configuration.nix           # System entrypoint (Tmux/Yazi overlays, Viewnior defaults, awww daemon service)
│       └── hardware-configuration.nix  # Hardware-specific scan (Intel CPU, NVMe, EXT4 root, VFAT boot, swap partition)
│
├── graphify-out/                       # Codebase knowledge graph generated by Graphify
│   ├── graph.html                      # Interactive 2D/3D visual network graph for browser exploration
│   ├── GRAPH_REPORT.md                 # Analysis report detailing god nodes, community cohesion, and architecture
│   └── graph.json                      # Raw graph dataset (nodes, AST symbols, dependencies, communities)
│
├── AGENTS.md                           # AI Agent workspace guidelines & test coordination protocols
├── GEMINI.md                           # AI Agent workspace guidelines & Graphify-first indexing rules
└── README.md                           # Complete documentation for all files and directories
```

---

## ⚙️ NixOS System Architecture & Overlays

The NixOS configuration is built on flakes with a modular separation of concerns located in `nixos/modules/`:

### 1. Core Modules (`nixos/modules/core/`)
- **`system.nix`**:
  - **Bootloader**: `systemd-boot` with EFI variables and a 5-generation configuration limit.
  - **Kernel & VM Sysctl Parameters**:
    - `mem_sleep_default=deep`: Ensures deep sleep (`s3`) power saving during suspend.
    - `i915.enable_psr=0`: Disables Intel Panel Self Refresh to eliminate display stutter/flicker on mobile Intel UHD graphics.
    - `vm.swappiness=10`: Keeps application pages in RAM and minimizes premature disk paging.
    - `vm.vfs_cache_pressure=50`: Favors retaining directory and inode caches for snappy filesystem responsiveness.
  - **Localization**: Timezone set to `Europe/Kyiv`, default locale `en_US.UTF-8`, console keymap `ua-utf`.
  - **Keyboard Layout**: `us,ua` switching via `Win + Space` (`grp:win_space_toggle`).
  - **Binary Compatibility (`nix-ld`)**: Enables running unpatched foreign dynamically-linked binaries (prebuilt language servers, CLI binaries, IDE tooling).
  - **Session Flags**: `NIXOS_OZONE_WL = "1"` and `QT_QPA_PLATFORM = "wayland"` for native Wayland execution across Electron and Qt apps.
- **`audio.nix`**:
  - **Sound Server**: PipeWire with ALSA (including 32-bit support), PulseAudio replacement, and JACK.
  - **ASUS ALC256 Audio Fix**: Injects kernel module option `snd-hda-intel model=alc256-asus-mic` to resolve internal and headset microphone pin routing on ASUS VivoBook laptops (e.g. X409FA).
- **`connections.nix`**:
  - **Networking & Firewall**: NetworkManager enabled with open TCP firewall port `8080` (web dev). PostgreSQL port 5432 is strictly bound to localhost for security.
  - **Trusted Interfaces**: `ham0` (LogMeIn Hamachi VPN adapter) added to `networking.firewall.trustedInterfaces` for seamless LAN gaming and file transfers.
  - **Bluetooth**: Auto-powered on boot, Dual Controller Mode, FastConnectable, `EnableAdvMonInterleaveScan = 1` integer type, `blueman` integration, and a systemd service running `rfkill unblock bluetooth`.
  - **Wireshark**: `programs.wireshark` enabled with full package (`pkgs.wireshark`) and packet capture capabilities for user `peng`.
- **`services.nix`**:
  - **Virtualization**: Docker daemon and Libvirt / KVM with SPICE USB redirection and `virt-manager`.
  - **Database Hardening**: PostgreSQL 16 server pre-configured with `mydatabase`, enforced `peer` authentication for local sockets, and `scram-sha-256` for TCP connections.
  - **Samba LAN Sharing**: Dedicated `[Shared]` folder restricted exclusively to `/home/peng/Shared` (`valid users = peng`, `guest ok = no`). Autostart on boot is disabled (`wantedBy = []`) for zero idle resource drain; invoked on-demand via `share`.
  - **Hamachi VPN**: LogMeIn Hamachi daemon (`logmein-hamachi`) with IPC user `peng`. Autostart on boot disabled (`wantedBy = []`) for on-demand launch via `share` or Haguichi GUI.
  - **Polkit**: Scoped permissions for specific desktop actions (udisks2, login1, networkmanager, flatpak).
  - **Power & System**: UPower, `power-profiles-daemon`, UDisks2, GVFS, CUPS printing, and Android udev permissions.
- **`user.nix`**:
  - User `peng` configured with default shell `pkgs.fish` and membership in `networkmanager`, `wheel`, `video`, `docker`, `libvirtd`, `input`, `uinput`, and `wireshark`.

### 2. Nixpkgs Overlays & Patches (`nixos/system/configuration.nix` & `nixos/modules/patches/`)
- **Tmux Buffer Patch**: Overrides `tmux` input buffer size from 1MB to 100MB (`#define INPUT_BUF_LIMIT 104857600`) in `input.c`, eliminating scrollback truncations during large build or log outputs.
- **Yazi Terminal Reset Patch**: Applies `yazi-disable-trt.patch` onto `yazi-unwrapped` to prevent spurious terminal state clears when transitioning between preview filters.
- **Wayland-VPet Fullscreen Patch**: Applies `wayland-vpet-fullscreen.patch` to allow the desktop pet overlay to persist during full-screen applications without auto-hiding.
- **Default Applications**: Default text and code MIME associations (text/plain, markdown, python, C/C++, Rust, shell, lua, yaml, json, js) mapped to [Neovim](https://neovim.io/) (`nvim.desktop`); default images mapped to lightweight [Viewnior](https://github.com/hellnest/viewnior) with [Swappy](https://github.com/jtheoof/swappy) for annotations.

### 3. Package Management & System Menu Wrappers (`nixos/modules/pkgs.nix`)
- Declares development toolchains (`gh`, `lazygit`, `lazydocker`, `lazysql`, `git`, `neovim`), networking & VPN utilities (`openvpn`, `haguichi`, `cifs-utils`), audio tools (`pkgs_unstable.wiremix`), desktop applications, Wayland utilities (`wtype` typing tool, `wl-clipboard`), and custom binary wrappers:
  - **Master TUI Launcher**: `s` (interactive CLI & fzf command center unifying all 21 system tools).
  - **21 Interactive TUI Tools**: `wifi`, `bluetooth` (`bt`), `tb` (`tunnelbear`), `ports` (`port`), `share`, `nixos` (`gens`), `service` (`services`), `disk` (`storage`), `task` (`tasks`), `ram` (`restore`, `restore-ram`), `log` (`logs`, `journal`), `app` (`apps`, `launch`), `repo` (`repos`, `gitui`), `tm` (`project`), `pkg` (`pkgs`), `container` (`containers`, `vm`), `conf` (`config`, `configs`), `audio`, `setting` (`settings`), `theme`, `clip` (`clips`).
  - **System Test Suite**: `nixtest` (modular 14-subsystem verification suite).
  - **GUI / Rofi Menus**: `wifi-menu`, `bluetooth-menu`, `audio-menu`, `process-menu`, `disk-menu`, `clean-menu`, `config-menu`, `gtk-theme-menu`, `share-menu`.
  - **Core Helpers**: `share`, `nixreb`, `awake`, `ram`, `restore-boot-state`, `restore-ram`, `controlbot`, `epic`, `twitch` (`tdrops`), `gfn`, `roblox`, `libredb-studio`.

---

## 🪟 Desktop Compositors & Window Management

### 🥭 MangoWM (`config/mango/`)
MangoWM is a dynamic tiling Wayland compositor built on the **Scroller layout** paradigm:
- **`config.conf`**: Master configuration entrypoint that includes all sub-modules and loads optional overrides from `~/hakuspace-control/mango-custom.conf`.
- **`layout.conf`**: Scroller layout configuration with 20 memory structures, default proportion `0.5`, auto center focusing, and single-window expansion (`1.0`). Also provides Master-Stack and Dwindle layout options.
- **`effect.conf`**: GPU-accelerated visual styling with 2-pass Gaussian blur, custom brightness (`0.8`), contrast (`1.4`), saturation (`1.6`), and 24px blurred drop shadows.
- **`animation.conf`**: Smooth cubic-bezier zoom transitions for window opening, closing, moving, and tag switching.
- **`autostart.conf`**: Starts `awww-daemon` (wallpaper), `swaync`, `hypridle`, `cliphist` (clipboard manager), and startup bar scripts.
- **`bind.conf`**: Keybindings:

| Hotkey | Action |
| :--- | :--- |
| `Super + Q` | Open standalone clean Kitty terminal |
| `Super + Shift + Q` | Open Kitty terminal running **Tmux** in fullscreen |
| `Super + R` | Launch **Neovim** in Kitty (`kitty -e nvim`) |
| `Super + Shift + R` | Launch **Antigravity IDE** (`antigravity-ide`) |
| `Super + Escape` | Open Master TUI Command Center modal (`tui-popup s`) |
| `Super + ,` | Open Quick Settings modal (`tui-popup setting`) |
| `Super + TAB` | Open Application launcher modal (`tui-popup app`) |
| `Super + Shift + TAB` | Open task & process monitor modal (`tui-popup task`) |
| `Super + V` | Open clipboard history modal (`tui-popup clip`) |
| `Super + Shift + V` | Wipe clipboard history modal (`tui-popup clip wipe`) |
| `Super + X` | Toggle Waybar visibility (`waybar_manager.sh --toggle`) |
| `Super + B` | Launch Firefox |
| `Super + E` | Open Thunar file manager |
| `Super + T` | Launch Telegram Desktop |
| `Super + N` | Toggle SwayNC notification control center |
| `Super + C` | Close / kill active client window |
| `Super + M` / `Super + K` | Lock screen via Hyprlock |
| `Super + P` | Capture area screenshot (`screenshot.sh`) |
| `Super + Shift + P` | Capture fullscreen screenshot (`screenshot.sh --fullscreen`) |
| `Super + Ctrl + Shift + P` / `F11` | Start screen recording (`record.sh`) |
| `Super + Alt + B` | Toggle bottom dockbar visibility |
| `Super + L` | Toggle nightlight (Gammastep) |
| `Super + [A/S/W/D]` | Focus Left / Next Desktop / Prev Desktop / Right |
| `Super + Shift + [A/S/W/D]` | Move window Left / Down / Up / Right |
| `Super + Z` | Toggle window floating state |
| `Super + Shift + F` | Toggle maximized window state |
| `Super + Ctrl + Shift + F` | Toggle true fullscreen mode |
| `Super + I` | Minimize window to scratchpad |
| `Super + Shift + I` | Restore minimized window |
| `Super + 1..9` | Switch to Workspace / Tag 1 through 9 |
| `3-finger Swipe Up / Down` | Switch workspace / viewport (Scroller column) |
| `3-finger Swipe Left / Right` | Switch focused window direction |
| `4-finger Swipe Left / Right` | Jump to next workspace with active clients |
| `4-finger Swipe Up / Down` | Toggle workspace overview |

### 🔒 Hyprland Utilities & Power Management (`config/hypr/`)
- **`hypridle.conf`**: Context-aware power-saving daemon respecting native DBus and systemd idle inhibitors (media players, browser video playback, games):
  - **On Battery**: Lock at 2 min (`120s`), turn display off (DPMS) at 3 min (`180s`), suspend at 5 min (`300s`), and automatically wake up via hardware RTC to power off at 1 hour (`3600s`) if undisturbed.
  - **On AC / Charging**: Lock at 3 min (`180s`), turn display off at 10 min (`600s`), suspend at 20 min (`1200s`), and automatically wake up via hardware RTC to power off at 3 hours (`10800s`) if undisturbed.
- **`awake` Utility (`nixos/scripts/awake`)**:
  - Caffeine CLI that inhibits sleep, screen lock, DPMS timeouts, and poweroff during presentations, downloads, or builds.
  - When disabled, automatically restarts `hypridle` to immediately refresh inactivity listeners.
- **`dpms_handler.sh`**: Dynamic DPMS display sleep/wake dispatcher across MangoWM (with dynamic monitor name resolution via `wlr-randr`), Hyprland, Niri, and Labwc.
- **`lock.sh`**: Pre-lock visual process suspension (live wallpapers, desktop pets) right before locking the screen with Hyprlock.
- **`hyprlock.conf`**: Refined lockscreen rendering a blurred screenshot of the desktop with 3-pass blur, extra-bold golden hour / white minute typography, date label, and a minimalist password input box with auth feedback dots.

---

## 🧰 Interactive Rofi Control Menus (`nixos/scripts/`)

All custom system scripts are wrapped directly into NixOS binaries via `nixos/modules/pkgs.nix`:

| Menu Command | Backend Script | Purpose & Description |
| :--- | :--- | :--- |
| `wifi-menu` | [`wifi_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/wifi_menu.sh) | Interactive Wi-Fi network scanner, connection manager, and password prompter using NetworkManager (`nmcli`). |
| `bluetooth-menu` | [`bluetooth_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/bluetooth_menu.sh) | Interactive Bluetooth device manager: toggle power, scan, pair, trust, and connect audio devices & peripherals. |
| `audio-menu` | [`audio_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/audio_menu.sh) | PipeWire audio output sink and input source selector with instant volume level adjustments. |
| `process-menu` | [`process_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/process_menu.sh) | Top process monitor with CPU/memory consumption stats, search filter, and interactive `SIGTERM` / `SIGKILL` signals. |
| `disk-menu` | [`disk_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/disk_menu.sh) | Graphical disk usage inspector showing used/free space per mount point with direct `ncdu` / file manager launch. |
| `clean-menu` | [`clean_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/clean_menu.sh) | One-click system maintenance: delete old Nix generations, run `nix-store --gc`, clean user cache, and journal logs. |
| `config-menu` | [`config_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/config_menu.sh) | Rapid configuration file selector opening dotfiles or NixOS modules directly in `$EDITOR`. |
| `gtk-theme-menu` | [`gtk_theme_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/gtk_theme_menu.sh) | Live GTK theme and icon theme switcher for desktop consistency. |
| `share-menu` | [`share_menu.sh`](file:///home/peng/Code/Dotfiles/nixos/scripts/share_menu.sh) | Interactive TUI network sharing menu for LogMeIn Hamachi VPN status/networks and Samba `/home/peng/Shared` management. |

---

## 🎛️ Unified TUI Command Center & 21 Interactive Terminal Tools (`nixos/scripts/tui/`)

In addition to graphical Rofi menus, the system features a complete, standalone terminal control suite built on `fzf`, ANSI styling, live previews, and keyboard navigation.

### 🚀 Master Command Center (`s`)
Run `s` anywhere in the terminal to summon the interactive launcher. Filter tools across 4 categories or launch them directly with their dedicated CLI commands and short aliases:

```bash
s               # Open interactive fzf launcher with live category filters and preview
s <tool>        # Directly invoke any tool or alias (e.g., 's wifi', 's bt', 's tb', 's port', 's ram', 's app')
s list          # Print clean, formatted tabular list of all 21 tools and aliases
tui-popup <cmd> # Summon any TUI tool in a floating, centered Wayland modal window
```

### 📋 Complete Tool Suite

| Command | Aliases | Category | Purpose & Interactive Features |
| :--- | :--- | :--- | :--- |
| [`s`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/s) | — | **Launcher** | **Master Command Center**: Unified launcher searching all 21 tools by name, alias, and description. |
| [`wifi`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/wifi) | `wifi` | **Network** | **Wi-Fi Manager**: Scan nearby APs, monitor live signal dBm, connect with password prompt, display Wi-Fi QR codes, and WPS. |
| [`bluetooth`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/bluetooth) | `bt` | **Network** | **Bluetooth Manager**: Controller power, scan, pair, trust, connect/disconnect audio devices & peripherals, battery % gauges. |
| [`tb`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/tb) | `tunnelbear`, `vpn` | **Network** | **TunnelBear VPN & Split Tunneling**: Connect servers, usage-based ranking, per-app split tunneling (`tb run <cmd>`), live cloud quota sync, auto-connect disabled on boot. |
| [`ports`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/ports) | `port`, `net` | **Network** | **Listening Ports & Dev Servers**: Real-time listening TCP/UDP sockets, bound processes, PIDs, and instant `kill` for stuck servers. |
| [`share`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/share) | `share` | **Network** | **Samba & Hamachi File Sharing**: Manage Samba `/home/peng/Shared` & VM `/home/peng/Code`, view Hamachi mesh VPN peers, mount CIFS shares. |
| [`nixos`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/nixos) | `gens` | **System** | **NixOS Generations & Rollback**: Generation history, active boot entry, closure size diffing (`nix profile diff-closures`), rollbacks, and GC. |
| [`service`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/service) | `services` | **System** | **Systemd Service Manager**: Filter user & system units, start, stop, restart, reload, inspect unit status, and tail live logs. |
| [`disk`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/disk) | `storage` | **System** | **Storage & USB Cleaner**: Filesystem usage gauges, USB auto-mount/safe-eject, interactive `ncdu`, `nh clean`, and nix-store GC. |
| [`task`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/task) | `tasks` | **System** | **Process & MangoWM Window Controller**: Top CPU/RAM consumers, filter processes, Wayland window focus, `SIGTERM`/`SIGKILL`, freeze. |
| [`ram`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/ram) | `restore`, `restore-ram` | **System** | **Memory Recovery & Boot State Restorer**: Prunes background apps, closes windows, drops caches, and restores post-boot ~1.0 GB RAM footprint without restarting Wayland. |
| [`log`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/log) | `logs`, `journal` | **System** | **Journal & Kernel Explorer**: Systemd journal filter by priority (`-p err`), systemd unit logs, `dmesg` kernel ring buffer, live `-f` tailing. |
| [`app`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/app) | `apps`, `launch` | **Desktop** | **Application Launcher & .desktop Browser**: Fast fuzzy desktop launcher parsing system & user applications with dark theme synchronization and systemd-run isolation. |
| [`repo`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/repo) | `repos`, `gitui` | **Dev** | **Git Multi-Repo Radar**: Discovers all Git repositories under `~/Code`, branch state, dirty working tree status, fetch, pull, and push. |
| [`tm`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/tm) | `project` | **Dev** | **Tmux Sessions & Projects**: Interactive session switcher, window/pane preview, kill/detach sessions, and new project session bootstrap. |
| [`pkg`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/pkg) | `pkgs` | **Dev** | **Nix Package Explorer**: Search systemPackages, view derivation details, copy package names, or spawn instant `nix-shell -p <pkg>`. |
| [`container`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/container) | `containers`, `vm` | **Dev** | **Docker & Libvirt VM Manager**: Inspect running/stopped containers, start/stop/restart, follow container logs, and attach `/bin/sh`. |
| [`conf`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/conf) | `config`, `configs` | **Dev** | **Dotfiles & Config Picker**: Syntax-highlighted `bat` previews, Git diff indicators, and instant jump into Neovim for any dotfile. |
| [`audio`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/audio) | `audio` | **Desktop** | **PipeWire & WirePlumber Mixer**: Terminal volume faders, sink/source routing, mute toggles, WireMix integration, ALC256 mic testing. |
| [`setting`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/setting) | `settings` | **Desktop** | **Quick Settings**: Backlight brightness faders (`brightnessctl`), volume sliders, power governor, screen idle inhibit, SwayNC DND toggle. |
| [`theme`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/theme) | `theme` | **Desktop** | **Themes & Wallpapers**: Wallpaper transitions, fonts, and cava audio visualizer styles. |
| [`clip`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/clip) | `clips`, `clipboard` | **Desktop** | **Clipboard & Snippets**: Wayland clipboard history (`cliphist`), decode text/image entries with syntax preview, auto-paste on Enter, wipe history. |

### 🐻 TunnelBear VPN & Per-App Split Tunneling (`tb`)
The system integrates official TunnelBear OpenVPN profiles directly with NetworkManager, offering both full-system VPN routing and lightweight, application-specific split tunneling:
- **Interactive TUI & Usage-Based Sorting**: Running `tb` opens an interactive FZF selector showing server locations ranked dynamically by usage frequency and recency.
- **Per-App Split Tunneling**: Run specific commands or GUI applications exclusively through VPN without routing normal system traffic:
  ```bash
  tb run claude                     # Run Claude Desktop/browser exclusively over TunnelBear VPN
  tb run curl https://ipinfo.io/ip  # Verify public VPN egress IP
  tb app add claude                 # Configure application to always route via VPN
  tb mode split                     # Toggle split-tunneling proxy mode (127.0.0.1:10808)
  ```
- **Cloud Quota Tracking & Live Sync**:
  - `tb account` / `tb quota`: Displays remaining monthly GB allowance and active plan details.
  - `tb sync`: Queries TunnelBear API to synchronize live quota usage.
  - Automatic bandwidth tracking updates local usage metrics upon disconnection.
- **Boot Safety**: All NetworkManager TunnelBear VPN profiles have `autoconnect=false` enforced to prevent unexpected routing or data leakage during system startup.

---

## 🐚 Shell, Multiplexer & Terminal Workflow

### 🐱 Kitty Terminal (`config/kitty/kitty.conf`)
- **Theme**: Gruvbox Dark with `0.9` background opacity and 20px window margins.
- **Font**: `JetBrainsMono Nerd Font Mono` (size 12).
- **Cursor**: Beam cursor with dynamic trailing decay (`cursor_trail 2`, `cursor_trail_decay 0.1 0.4`).
- **Features**: Unix control socket (`unix:/tmp/kitty`) enabled for programmatic tab and script control.

### ⚡ Neovim & LazyVim (`config/nvim/`)
- **Starter Architecture**: Powered by the official [LazyVim](https://www.lazyvim.org/) starter configuration for ultra-fast startup, robust LSP diagnostics, syntax highlighting, and modular plugin management.
- **Visual Design & OLED Theme (`lua/plugins/colorscheme.lua`)**:
  - **Total Black OLED Theme**: Pure pitch-black (`#000000`) background across all normal windows, floating dialogues, statuslines, sidebars, telescope pickers, and gutter columns.
  - Transparent floating borders and subtle contrast highlights tuned for high-contrast readability.
- **VS Code Key Parity (`lua/plugins/vscode.lua`)**:
  - Full IDE keymap parity matching VS Code muscle memory seamlessly across Normal, Insert, Visual, and Select modes:
    - **Editing & Deletion**: True `Backspace` and `Delete` behavior in all modes (deleting character left/right, joining lines, clearing selections without register pollution), `Ctrl+Backspace` / `Ctrl+Delete` (word deletion).
    - **Navigation & Selection**: `Shift + Arrows` (visual selection), `Ctrl + Arrows` (subword/word jump), `Home` / `End`, `Shift + Home` / `Shift + End`.
    - **Clipboard & History**: `Ctrl+S` (save file), `Ctrl+Z` (undo), `Ctrl+Y` / `Ctrl+Shift+Z` (redo), `Ctrl+C` / `Ctrl+X` / `Ctrl+V` (system clipboard sync).
    - **Search & Replace**: `Ctrl+F` (buffer find), `Ctrl+H` (find & replace modal), `Ctrl+P` (fast file finder), `Ctrl+Shift+P` (command palette).
    - **Lines & Comments**: `Alt+Up/Down` (move lines), `Shift+Alt+Up/Down` (duplicate lines), `Ctrl+/` (toggle comment).
    - **LSP & Modals**: `F2` (live symbol rename), `F1` (interactive full keymap picker across all modes), `Ctrl+B` (toggle Neo-tree), `Ctrl+~` (toggle terminal).
- **Antigravity AI Copilot (`lua/plugins/antigravity.lua`, `completion.lua`)**:
  - Integrated with local `antigravity-cli` for context-aware inline code suggestions and ghost text generation.
  - Dedicated keybindings: `Ctrl + Alt + A` to trigger completions, `<Tab>` to accept, and `<Esc><Esc>` to dismiss without compositor or terminal interference.
- **Enhanced Productivity & Git Plugins**:
  - **Glance (`glance.nvim`)**: VS Code-style peek windows for definitions (`gpd`), references (`gpr`), implementations (`gpi`), and type definitions (`gpt`).
  - **Undotree (`undotree.lua`)**: Visual interactive undo-history tree view (`<leader>u`).
  - **Smart Open (`smart-open.nvim`)**: Advanced frecency algorithm combining recency, frequency, and Git status for lightning-fast file jumping.
  - **Highlight Undo (`highlight-undo.nvim`)**: Visual flashes highlighting modified lines during undo/redo operations.
  - **Hlslens (`nvim-hlslens`)**: Search lens showing total matches, current match index, and offscreen indicators.
  - **Spider (`nvim-spider`)**: CamelCase and snake_case subword motions replacing standard `w`/`e`/`b`.
  - **Flash (`flash.nvim`)**: Two-character bidirectional jump navigation for fast hopping across open buffers.
  - **Git Suite & Lazygit (`lua/plugins/gitsigns.lua`, `pkgs.nix`)**: `<leader>gg` opens Lazygit in a floating terminal, alongside `<leader>g` hunks staging, resets, inline diffs, and blame previews.

### 🪟 Tmux Multiplexer (`config/tmux/`)
- **Configuration (`tmux.conf`)**:
  - Vi-mode copy/paste keybindings, custom statusbar formatting with clean window lists, active window highlight, and clock.
  - Seamless pane splitting (`|` and `-`), navigation, and window resizing.
  - **Extended Keys (`extended-keys on`)**: `terminal-features 'xterm*:extkeys'` enabled to forward complex key combinations (e.g. `Ctrl+Alt+A`) to Neovim and shell processes reliably.
- **Cheat Sheet (`cheatsheet.sh`)**:
  - Interactive popup cheat sheet summarizing essential Tmux shortcuts for session, window, and pane manipulation.

### 📂 Yazi Terminal File Manager (`config/yazi/`)
- **Configuration (`yazi.toml`, `keymap.toml`)**:
  - Clean `1:4:3` ratio three-column layout (parent, current, preview).
  - High-performance image and media previews via `ueberzugpp`.
- **Fish Shell Integration (`config/fish/config.fish`)**:
  - Smart `y` wrapper function that automatically changes the shell working directory (`cd`) to Yazi's last active directory upon exiting.
  - Global `Ctrl + O` hotkey to summon Yazi instantly from anywhere on the command line.

### 📁 Thunar GUI File Manager (`config/Thunar/`)
- **Finder-Style Color Tagging (`uca.xml`)**: Custom context menu actions with macOS Finder-style color emblems (Red, Orange, Yellow, Green, Blue, Purple, Gray) and color removal for visual organization.
- **Custom Keyboard Shortcuts (`accels.scm`)**: Persisted accelerator configuration with `Ctrl + Shift + H` bound to toggle file highlighting.

### 🐟 Fish Shell (`config/fish/config.fish`)
Includes fast shell initialization, tool hooks, and rich workflow abbreviations:

| Category | Abbreviation / Command | Target Action |
| :--- | :--- | :--- |
| **Control Center** | `s` / `s <tool>` | Master TUI launcher & interactive command center for 19 system tools |
| **System** | `nixreb` | Sync dotfiles & rebuild NixOS flake (`nixreb.sh`) |
| **System** | `gens` / `nixos` | Interactive NixOS generations, closure diffs & rollback manager |
| **System** | `service` / `services` | Interactive Systemd user & system service manager |
| **System** | `disk` / `storage` | Storage, partition usage, USB mount/eject, and cache cleaner |
| **System** | `task` / `tasks` | Process monitor & MangoWM window focus / killer |
| **System** | `nc` | Delete old Nix generations & run garbage collection |
| **System** | `addchans` | Set up nixos-unstable and home-manager channels |
| **Network** | `wifi` / `bt` / `bluetooth` | Interactive Wi-Fi & Bluetooth device managers |
| **Network** | `tb` / `tunnelbear` | TunnelBear VPN with per-app split tunneling & cloud quota tracking |
| **Network** | `ports` / `port` | Inspect listening TCP/UDP sockets and kill dev servers |
| **Sharing** | `share` / `share-menu` | Interactive Hamachi VPN & Samba network file sharing manager |
| **Dev** | `repo` / `repos` / `gitui` | Multi-repository Git radar across `~/Code` |
| **Dev** | `tm` / `project` | Interactive Tmux sessions & project workspaces manager |
| **Dev** | `pkg` / `pkgs` | Search declared packages and test in temporary `nix-shell` |
| **Dev** | `conf` / `config` | Dotfiles & config picker with syntax preview & Neovim jump |
| **Dev** | `container` / `vm` | Docker container and Libvirt VM controller |
| **Desktop** | `audio` / `setting` / `theme` / `clip` | Volume mixer, quick settings, Waybar/wallpapers, and clipboard history |
| **Testing** | `nixtest` | Run modular NixOS verification test suite (`all`, `modules`, or `<module>`) |
| **Tmux** | `t` / `ta` / `tls` / `tn` / `tk` | `tmux`, attach, list sessions, new session, kill session |
| **File Manager**| `y` / `Ctrl + O` | Launch Yazi with auto-`cd` on exit |
| **Menus** | `menu` | Launch Rofi application menu (`rofi -show drun`) |
| **Automation** | `epic` | Launch or manage Epic Games freebies claimer (`start`/`stop`/`status`) |
| **Automation** | `twitch` / `tdrops` | Launch or manage DST Twitch Drops claimer (`start`/`stop`/`status`) |
| **AI / Tokens** | `tokens` / `agy tokens` | Run live Antigravity token quota and reset timer report |
| **Power** | `awake on` / `awake off` | Inhibit or resume screen lock, display sleep, and poweroff |
| **Gaming** | `gfn` / `roblox` | Launch GeForce NOW / Roblox (Sober) Flatpaks |
| **Dev** | `ld` / `lazydocker` | Interactive terminal UI for Docker containers & images (`lazydocker`) |
| **Dev** | `lsql` / `lazysql` | Interactive terminal UI for databases & SQL queries (`lazysql`) |
| **Dev** | `gh` | Official GitHub CLI for issues, pull requests & auth |
| **Git** | `lg` | `lazygit` (interactive project selector if run outside a git repository) |
| **Git** | `gs`, `gd`, `ga`, `gc`, `gp`, `gl` | Git status, diff, add, commit, push, log |
| **Listing** | `l`, `ll`, `la`, `lla` | `eza --icons --group-directories-first` aliases |

### 🚀 Starship Prompt (`config/starship.toml`)
- A modern, two-line connected prompt:
  - **Line 1**: User `@` Hostname, working directory with folder icon, Git branch & status badge, trailing line fill, command execution duration (if >2s), and clock.
  - **Line 2**: Status arrow (`▶︎` on success, `✘` on error) and active Nix development shell indicator.

---

## 🎨 UI Customization, Bars & Themes

### 📊 Waybar (`config/waybar/`)
The system runs the sleek and refined **`hancore-v1-9b`** theme, tailored for high-contrast visibility and minimal resource usage:
- **Active Theme Architecture**: Modular layout with workspaces, window title, clock/calendar, network status, audio faders, battery indicators, and SwayNC notification triggers.
- **Deduplicated & Polished CSS**: Clean CSS styling without redundant rules, utilizing hardware-accelerated rendering and consistent Gruvbox/translucent dark accents.
- **Toggle Control**: Instantly hide or restore Waybar with `Super + X` or `waybar_manager.sh --toggle`.

### 🔔 Sway Notification Center (`config/swaync/`)
- Sleek 420px slide-out control center with volume level sliders, Do-Not-Disturb toggle, quick action buttons, and a media player widget styled with GTK CSS.

### 🐾 Bongo Cat Desktop Pet (`config/bongocat/`)
- `wayland-vpet` interactive overlay running at 60 FPS across a 950px roaming width.
- Listens to `/dev/input/` keyboard and mouse event devices to animate typing and wake-up.
- Triggers active "Working / Running" emotes when CPU usage spikes above 25%, and "Happy" emotes when typing speed exceeds 50 KPM.
- Patched via `wayland-vpet-fullscreen.patch` to stay visible without being hidden during fullscreen activities.

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
Syncs the repository configuration to `/etc/nixos/` using `rsync` and executes `nixos-rebuild switch --flake /etc/nixos#nixos` with 4 build cores (matching hardware CPU threads) and impure evaluation.

### 2. `screenshot.sh` (Enhanced Wayland Screen Capture)
```bash
screenshot.sh              # Interactive region capture with slurp
screenshot.sh --fullscreen # Fullscreen capture
```
Captures the screen to `~/Pictures/Screenshots/`, automatically copies the image to the Wayland clipboard (`wl-copy`), and dispatches a desktop notification with thumbnail preview (`notify-send`).

### 3. `awake` (Caffeine & Wake Lock Tool)
```bash
awake on     # Inhibit screen lock, display DPMS sleep, and auto-poweroff
awake off    # Resume standard idle timers and restart hypridle
awake status # Inspect active caffeine state
```

### 4. `epic` & `epic-games-claimer.user.js` (Epic Games Freebies Claimer)
An in-browser weekly auto-claimer that runs inside native logged-in Firefox:
- **Zero Captchas:** Utilizes the authenticated browser session directly.
- **Calm Paced Checkout:** Navigates store free games, handles mature content prompts, and clicks "Place Order" without aggressive bot patterns.
- **Floating HUD:** Features in-browser `⏹ Stop` and `▶ Resume` buttons to instantly pause or resume checkout.
- **CLI Commands:** `epic start`, `epic stop`, `epic status`.

### 5. `twitch` & `twitch-drops-claimer.user.js` (Twitch Drops Auto-Claimer)
An in-browser auto-claimer tailored for **Don't Starve Together** (DST) Twitch Drops:
- **Ultra-Eco Mode:** Automatically locks stream quality to 160p, mutes audio, and disables low-latency mode.
- **Channel Routing:** Filters out Russian-tagged channels, connects to the highest-viewed valid streamer, tracks progress timers, claims tier rewards, and closes the tab when all DST campaigns are completed.
- **CLI Commands:** `twitch start`, `twitch stop`, `twitch status` (also aliased as `tdrops`).

### 6. `agy-tokens.py` (Antigravity Token & Quota Reporter)
Displays real-time token quotas, tier usage progress bars, and countdown timers across AI model families (Gemini, Claude, GPT):
```bash
tokens
# or
agy tokens
```

### 7. `unlock_screen.sh` (Desktop Unlock & Recovery Utility)
```bash
unlock_screen.sh "<password>"
```
Performs reliable desktop unlocking across Wayland compositors:
- **Display Wakeup**: Powers on monitors across MangoWM, Hyprland, Niri, and Sway.
- **Automated Authentication**: Enters passwords into `hyprlock` via `wtype` with sub-second feedback verification.
- **Fail-Safe Session Recovery**: Detects gray-screen lock freezes in MangoWM (when `hyprlock` crashes or terminates unexpectedly) and directly resets `locked_bg` scene nodes via `gdb`.

### 8. `nixtest` (Modular NixOS System Verification Test Suite)
```bash
nixtest all              # Run all 14 test modules (~150+ checks)
nixtest modules          # List available test modules
nixtest <module>         # Run specific module (e.g. nixtest nix, nixtest security)
nixtest <m1> <m2> ...    # Run multiple specific modules
```
A 100% read-only, non-destructive verification suite designed to validate the NixOS system state, security hardening, service health, and configuration integrity before and after any modification.

### 9. `share` & `share_menu.sh` (Network File Sharing & Hamachi VPN Manager)
```bash
share                   # Interactive TUI/FZF manager matching wifi & bluetooth style
share status            # Show Hamachi VPN & Samba service and network status
share-menu              # Terminal-based quick control menu
```
Unified network sharing controller:
- **Hamachi VPN**: On-demand service startup, account login, join/leave mesh networks, peer listing, and nickname assignment.
- **Samba LAN & VM Sharing**: On-demand daemon startup, manage LAN `/home/peng/Shared` & VM-restricted `/home/peng/Code` (`192.168.122.0/24`), set SMB user passwords, and mount remote network shares into `/mnt` via `cifs-utils`.

---

## 🧪 System Test Suite (`nixtest`)

This repository enforces a strict **Test Coordination Protocol** (defined in [`GEMINI.md`](file:///home/peng/Code/Dotfiles/GEMINI.md) and [`AGENTS.md`](file:///home/peng/Code/Dotfiles/AGENTS.md)). Any modification to system code, scripts, configurations, or packages must be coordinated with and verified by `nixtest`:

| Module | Test Command | Scope & Checks Description |
| :--- | :--- | :--- |
| **`nix`** | `nixtest nix` | Flake dry-build evaluation (`nixos-rebuild dry-build`), syntax evaluation (`nix-instantiate --parse`), garbage collection options |
| **`security`** | `nixtest security` | PostgreSQL local peer & TCP scram-sha-256 auth, closed port 5432, Samba valid users, Polkit scoped desktop actions, `nix-ld` |
| **`network`** | `nixtest network` | NetworkManager state, TCP/VM sysctl tunables (`swappiness`, `vfs_cache_pressure`), Wireshark permissions, internet connectivity |
| **`bluetooth`** | `nixtest bluetooth` | Bluetoothd config integer types (`EnableAdvMonInterleaveScan`), journal error detection, rfkill status, service health |
| **`audio`** | `nixtest audio` | PipeWire sound stack, ALSA 32-bit, PulseAudio emulation, JACK, Realtek ALC256 microphone pin routing quirk |
| **`power`** | `nixtest power` | `hypridle` native DBus/systemd inhibitor adherence, AC/Battery thresholds, S3 deep sleep, logind sleep parameters |
| **`display`** | `nixtest display` | Waybar JSON/JSONC comment-stripped syntax, wallpaper daemon (`awww`), Hyprlock PAM config, DPMS dispatcher, SwayNC |
| **`shell`** | `nixtest shell` | Fish shell environment, Starship prompt, Zoxide single-init, Tmux abbreviations, Yazi shell wrapper, CLI tools presence |
| **`scripts`** | `nixtest scripts` | Syntax validation (`bash -n` / `fish -n`) and executable permissions for all 31+ shell and Python scripts |
| **`services`** | `nixtest services` | Active systemd system & user units, timer states, Docker/Libvirt virtualisation daemons, failed unit detection |
| **`storage`** | `nixtest storage` | Root/boot disk space thresholds, RAM/swap pressure metrics, Nix store garbage collection configuration |
| **`kernel`** | `nixtest kernel` | Bootloader generation limits, Intel CPU/GPU drivers, kernel parameters (`mem_sleep_default`, `i915.enable_psr`), environment |
| **`configs`** | `nixtest configs` | JSON/JSONC/TOML syntax integrity (Kitty, Rofi, Tmux, Yazi, MangoWM, Hyprland, SwayNC, Starship) |
| **`packages`** | `nixtest packages` | Package deduplication (GTK/GLib/Fonts), insecure packages whitelist, essential development & desktop tools |

---

## 🧠 Knowledge Graph (`graphify-out/`)

This repository maintains an active codebase knowledge graph generated by [Graphify](https://github.com/safishamsi/graphify):

- **Interactive Network Graph (`graphify-out/graph.html`)**: Open in any browser to navigate module dependencies, script calls, configuration relationships, and UI component clusters.
- **Audit Report (`graphify-out/GRAPH_REPORT.md`)**: Summary of codebase structure, god nodes (most interconnected components), community cohesion scores, and structural analysis.
- **Raw Graph Data (`graphify-out/graph.json`)**: Graph database in GraphRAG-compatible JSON format.

### Updating the Knowledge Graph
Whenever modifying NixOS modules, scripts, or configurations, update the graph using:
```bash
graphify . --code-only
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

### 3. Toggle Waybar
Press `Super + X` or run:
```bash
waybar_manager.sh --toggle
```

---

## 📝 License

Personal NixOS dotfiles. Licensed under the MIT License — feel free to adapt and incorporate into your own setups!
