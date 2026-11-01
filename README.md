# ❄️ NixOS + niri Dotfiles

A declarative **NixOS 25.05** flake for a single laptop, running the
[niri](https://github.com/YaLTeR/niri) scrollable-tiling compositor with the
black-and-white look from
[niri-creation-of-adam](https://github.com/klautizm/niri-creation-of-adam),
plus a suite of fzf TUIs for managing the system.

---

## 🖥️ Stack

| Component | Tool | Details |
| :--- | :--- | :--- |
| **OS** | NixOS 25.05 (+ nixpkgs unstable as `pkgs_unstable`) | Flake + home-manager |
| **Compositor** | niri (`programs.niri`) | Config in `config/niri/config.kdl`: gaps 16, 1px white window border (grey when unfocused) drawn inside each window, shadows, other windows at 0.95 opacity |
| **Wallpaper** | swaybg | `config/niri/wallpaper.jpeg` (from niri-creation-of-adam) |
| **Terminal** | Kitty | `#030303` background, `#E0E0E0` text, 0.9 opacity, 12px padding |
| **Lock & idle** | swaylock-effects + swayidle | Ly-styled black lock screen (monospace clock/date, always-visible ring); same AC/battery idle chain as before (lock, DPMS, suspend, poweroff) |
| **Notifications** | mako | Black/white; click a notification to run its default action |
| **GTK** | adw-gtk3-dark + `config/gtk/gtk.css` | Pure-black surfaces, white accents; file pickers (Zed, browsers) go through the GTK portal |
| **Firefox** | `config/firefox/` → default profile | Pure-black `userChrome.css` (toolbars, tabs, panels) and `userContent.css` (new tab/about: pages); `user.js` enables them and forces dark mode |
| **Fetch** | fastfetch + [fetch](https://github.com/areofyl/fetch) | White/gray NixOS logo; `fetch` spins the logo in 3D |
| **Display manager** | Ly (TUI) | Pick the *niri* session; unlocks gnome-keyring at login |
| **Shell** | Fish + Starship, Tmux, Yazi | `config/fish`, `config/tmux`, `config/yazi` |
| **Editor** | Zed (`pkgs_unstable.zed-editor`) | `$EDITOR` is `zed-wait`; `nvim` is installed clean (no config) for quick viewing and small edits |
| **TUIs** | [`s`](nixos/scripts/tui/s) + 22 tools | fzf control center for network, system, dev and desktop |

Terminal toys from the adam setup are installed too: `tty-clock -c -C 7`,
`cmatrix -C white`.

---

## 📁 Layout

```
config/
  niri/        config.kdl (compositor, binds, rules) + wallpaper.jpeg
  kitty/       kitty.conf
  fastfetch/   config.jsonc
  fetch/       config
  swaylock/    config
  mako/        config
  firefox/     userChrome.css, userContent.css, user.js
  gtk/         gtk.css
  fish/ tmux/ yazi/
nixos/
  flake.nix, flake.lock
  system/      configuration.nix (overlays, home-manager, user services), hardware-configuration.nix
  modules/     core/*.nix, utils/xserver.nix, pkgs.nix, patches/
  scripts/     bash tools; scripts/tui/ holds the fzf TUIs
```

`niri`, `kitty`, `fastfetch`, `fetch`, `swaylock` and `mako` configs are
symlinked into `~/.config` by home-manager (`mkOutOfStoreSymlink`), so repo
edits are live. niri reloads its config on save; run `niri validate` to check it.

---

## ⌨️ niri keybindings

Ported from the old Mango binds. `Mod` is Super. `Mod+Shift+/` shows the full list.

| Keys | Action |
| :--- | :--- |
| `Mod+Q` / `Mod+Shift+Q` | Kitty / fullscreen Kitty with tmux |
| `Mod+R`, `Mod+B`, `Mod+E`, `Mod+T` | Zed, Firefox, Thunar, Telegram |
| `Mod+C` | Close window |
| `Mod+L` (F9) / `Mod+K` | Lock (`lock.sh` → swaylock) |
| `Mod+M` | Log out to the Ly greeter (ends the session; open apps close) |
| `Mod+Shift+L` | Night light toggle |
| `Mod+P` / `Mod+Print` | Region screenshot (niri built-in) |
| `Mod+Shift+P` / `Print` | Full-screen screenshot (niri built-in) |
| `Mod+Ctrl+Shift+P`, `Mod+F11` | Screen recording (`record.sh`) |
| `Mod+Esc` / `Mod+,` / `Mod+Tab` / `Mod+Shift+Tab` | TUI popups: `s`, `setting`, `app`, `task` |
| `Mod+V` / `Mod+Shift+V` | Clipboard history / wipe |
| `Alt+Tab` | Overview |
| `Mod+Z` | Toggle floating |
| `Mod+F` | Cycle column width (50% / 80% / 100%) |
| `Mod+Shift+F` / `Mod+Ctrl+Shift+F` / `Alt+Shift+F` | Maximize column / fullscreen / windowed fullscreen |
| `Mod+A`/`D` or `Mod+←`/`→` | Focus column left/right |
| `Mod+W`/`S` or `Mod+↑`/`↓` | Previous/next workspace |
| `Mod+Shift+W`/`S` | Move column to previous/next workspace |
| `Mod+Shift+A`/`D`, `Alt+Shift+A`/`D` | Move column left/right |
| `Alt+Shift+W`/`S` | Move window up/down within column |
| `Mod+Ctrl+A`/`D` | Consume/expel window into the neighbouring column |
| `Mod+Ctrl+W`/`S` | Focus window up/down in column |
| `Ctrl+Alt+Arrows` | Resize column width / window height by 50px |
| `Mod+1..9` / `Mod+Shift+1..9` | Go to / move column to workspace |
| `Mod+Alt+Ctrl+WASD` / `Mod+Alt+WASD` | Focus monitor / move column to monitor |
| `Mod+Shift+E` | Quit niri |
| `Fn+F1` / `Fn+F2` / `Fn+F3` (XF86 mute / volume down / up) | Mute toggle / volume down / up (5% steps, capped at 150%); each shows the current volume as a notification (`nixos/scripts/volume_osd.sh`) |
| `Fn+F4` / `Fn+F5` (XF86 brightness down / up) | Backlight down / up (5% steps); shows the level as a notification (`nixos/scripts/brightness_osd.sh`) |
| `Fn+F6` (XF86 touchpad toggle) | Enable / disable the touchpad, with a notification (`nixos/scripts/touchpad_toggle.sh`; holds an evdev grab while disabled, so it needs the `input` group) |

Keyboard layouts are `us,ua`, switched with `Win+Space`.

---

## ⚙️ NixOS modules

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
  - **ASUS ALC256 Audio Fix**: Injects kernel module option `snd-hda-intel patch=alc256-vivobook.fw` with pin routing firmware (`alc256-vivobook.fw`) to resolve internal and headset microphone pin routing on ASUS VivoBook laptops (e.g. X409FA / X509JP).
- **`connections.nix`**:
  - **Networking & Firewall**: NetworkManager enabled with open TCP firewall port `8080` (web dev). PostgreSQL port 5432 is strictly bound to localhost for security.
  - **Trusted Interfaces**: `ham0` (LogMeIn Hamachi VPN adapter) added to `networking.firewall.trustedInterfaces` for seamless LAN gaming and file transfers.
  - **Bluetooth**: Auto-powered on boot, Dual Controller Mode, FastConnectable, `EnableAdvMonInterleaveScan = 1` integer type, `blueman` integration, and a systemd service running `rfkill unblock bluetooth`.
  - **Wireshark**: `programs.wireshark` enabled with full package (`pkgs.wireshark`) and packet capture capabilities for user `peng`.
- **`services.nix`**:
  - **Virtualization**: Docker daemon and Libvirt / KVM with SPICE USB redirection and `virt-manager`. Neither starts on boot: `docker.socket` and `libvirtd.socket` start the daemons on first use (`libvirt-guests` is not enabled either).
  - **Database Hardening**: PostgreSQL 16 server pre-configured with `mydatabase`, enforced `peer` authentication for local sockets, and `scram-sha-256` for TCP connections. Autostart on boot disabled (`wantedBy = []`); start on demand with `sudo systemctl start postgresql`.
  - **Samba LAN Sharing**: Dedicated `[Shared]` folder restricted exclusively to `/home/peng/Shared` (`valid users = peng`, `guest ok = no`). Autostart on boot is disabled (`wantedBy = []`) for zero idle resource drain; invoked on-demand via `share`.
  - **Hamachi VPN**: LogMeIn Hamachi daemon (`logmein-hamachi`) with IPC user `peng`. Autostart on boot disabled (`wantedBy = []`) for on-demand launch via `share` or Haguichi GUI.
  - **Tailscale VPN**: `services.tailscale` enables `tailscaled` and the `tailscale` CLI. The module trusts the `tailscale0` interface and opens UDP `41641`. Not yet logged in: run `sudo tailscale up` once after the rebuild.
  - **Polkit**: Scoped permissions for specific desktop actions (udisks2, login1, networkmanager, flatpak).
  - **Power & System**: UPower, `power-profiles-daemon`, UDisks2, GVFS, CUPS printing, and Android udev permissions.
- **`user.nix`**:
  - User `peng` configured with default shell `pkgs.fish` and membership in `networkmanager`, `wheel`, `video`, `docker`, `libvirtd`, `input`, `uinput`, and `wireshark`.


### Overlays & patches
- **Tmux**: input buffer raised from 1 MB to 100 MB.
- **Yazi**: `yazi-disable-trt.patch` stops spurious terminal resets between previews.
- **Wayland-VPet**: `wayland-vpet-fullscreen.patch` keeps the desktop pet visible over fullscreen apps.

### Packages (`nixos/modules/pkgs.nix`)
Packages by section, plus the `writeShellScriptBin` wrappers that turn
`nixos/scripts/*` into commands (all TUIs and their aliases, `nixreb`,
`awake`, `epic`, `twitch`, `tunnelbear`/`tb`, menu scripts) and
local derivations (`fetch`, `wayland-vpet`, `tlauncher`, `libredb-studio`).

### User services (`nixos/system/configuration.nix`)
- `swayidle`: battery 120 s lock → 180 s DPMS off → 300 s suspend → 1 h poweroff;
  AC 180 s lock → 600 s DPMS off → 1200 s suspend → 3 h poweroff. Each step is
  gated by `idle_inhibit.sh` (caffeine via `awake`, audio playback).
- `polkit-mate`: polkit authentication agent.

---

## 🎛️ Unified TUI Command Center & 22 Interactive Terminal Tools (`nixos/scripts/tui/`)

The system features a complete, standalone terminal control suite built on `fzf`, ANSI styling, live previews, and keyboard navigation.

### 🚀 Master Command Center (`s`)
Run `s` anywhere in the terminal to summon the interactive launcher. Filter tools across 4 categories or launch them directly with their dedicated CLI commands and short aliases:

```bash
s               # Open interactive fzf launcher with live category filters and preview
s <tool>        # Directly invoke any tool or alias (e.g., 's wifi', 's bt', 's tb', 's port', 's ram', 's app')
s list          # Print clean, formatted tabular list of all 22 tools and aliases
tui-popup <cmd> # Summon any TUI tool in a floating Kitty window (niri rule for app-id tui-overlay)
```

### 📋 Complete Tool Suite

| Command | Aliases | Category | Purpose & Interactive Features |
| :--- | :--- | :--- | :--- |
| [`s`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/s) | — | **Launcher** | **Master Command Center**: Unified launcher searching all 22 tools by name, alias, and description. |
| [`wifi`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/wifi) | `wifi` | **Network** | **Wi-Fi Manager**: Scan nearby APs, monitor live signal dBm, connect with password prompt, display Wi-Fi QR codes, and WPS. |
| [`bluetooth`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/bluetooth) | `bt` | **Network** | **Bluetooth Manager**: Controller power, scan, pair, trust, connect/disconnect audio devices & peripherals, battery % gauges. |
| [`tb`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/tb) | `tunnelbear`, `vpn` | **Network** | **TunnelBear VPN & Split Tunneling**: Connect servers, usage-based ranking, per-app split tunneling (`tb run <cmd>`), live cloud quota sync, auto-connect disabled on boot. |
| [`tailscale`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/tailscale) | `ts`, `tailscale-tui` | **Network** | **Tailscale Mesh VPN**: Connect or disconnect this device, show tailnet IP and peers, accept subnet routes, control the `tailscaled` daemon. Run `sudo tailscale up` once after a rebuild to log in. |
| [`ports`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/ports) | `port`, `net` | **Network** | **Listening Ports & Dev Servers**: Real-time listening TCP/UDP sockets, bound processes, PIDs, and instant `kill` for stuck servers. |
| [`share`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/share) | `share` | **Network** | **Samba & Hamachi File Sharing**: Manage Samba `/home/peng/Shared` & VM `/home/peng/Code`, view Hamachi mesh VPN peers, mount CIFS shares. |
| [`nixos`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/nixos) | `gens` | **System** | **NixOS Generations & Rollback**: Generation history, active boot entry, closure size diffing (`nix profile diff-closures`), rollbacks, and GC. |
| [`service`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/service) | `services` | **System** | **Systemd Service Manager**: Filter user & system units, start, stop, restart, reload, inspect unit status, and tail live logs. |
| [`disk`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/disk) | `storage` | **System** | **Storage & USB Cleaner**: Filesystem usage gauges, USB auto-mount/safe-eject, interactive `ncdu`, `nh clean`, and nix-store GC. |
| [`task`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/task) | `tasks` | **System** | **Process & niri Window Controller**: Top CPU/RAM consumers, filter processes, window focus/close/float via `niri msg`, `SIGTERM`/`SIGKILL`, freeze. |
| [`ram`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/ram) | `restore`, `restore-ram` | **System** | **Memory Recovery & Boot State Restorer**: Prunes background apps, closes windows, drops caches, and restores post-boot ~1.0 GB RAM footprint without restarting Wayland. |
| [`log`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/log) | `logs`, `journal` | **System** | **Journal & Kernel Explorer**: Systemd journal filter by priority (`-p err`), systemd unit logs, `dmesg` kernel ring buffer, live `-f` tailing. |
| [`app`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/app) | `apps`, `launch` | **Desktop** | **Application Launcher & .desktop Browser**: Fast fuzzy desktop launcher parsing system & user applications with dark theme synchronization and systemd-run isolation. |
| [`repo`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/repo) | `repos`, `gitui` | **Dev** | **Git Multi-Repo Radar**: Discovers all Git repositories under `~/Code`, branch state, dirty working tree status, fetch, pull, and push. |
| [`tm`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/tm) | `project` | **Dev** | **Tmux Sessions & Projects**: Interactive session switcher, window/pane preview, kill/detach sessions, and new project session bootstrap. |
| [`pkg`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/pkg) | `pkgs` | **Dev** | **Nix Package Explorer**: Search systemPackages, view derivation details, copy package names, or spawn instant `nix-shell -p <pkg>`. |
| [`container`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/container) | `containers`, `vm` | **Dev** | **Docker & Libvirt VM Manager**: Inspect running/stopped containers, start/stop/restart, follow container logs, and attach `/bin/sh`. |
| [`conf`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/conf) | `config`, `configs` | **Dev** | **Dotfiles & Config Picker**: Syntax-highlighted `bat` previews, Git diff indicators, and instant jump into Zed for any dotfile. |
| [`audio`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/audio) | `audio` | **Desktop** | **PipeWire & WirePlumber Mixer**: Terminal volume faders, sink/source routing, mute toggles, WireMix integration, ALC256 mic testing. |
| [`setting`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/setting) | `settings` | **Desktop** | **Quick Settings**: Backlight brightness faders (`brightnessctl`), volume sliders, power governor, screen idle inhibit. |
| [`theme`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/theme) | `theme` | **Desktop** | **Themes & Wallpapers**: Wallpaper, accent colour and visualizer helpers from `~/.local/bin` (still written for the old awww setup). |
| [`clip`](file:///home/peng/Code/Dotfiles/nixos/scripts/tui/clip) | `clips`, `clipboard` | **Desktop** | **Clipboard & Snippets**: Wayland clipboard history (`cliphist`), decode text/image entries with syntax preview, auto-paste on Enter, wipe history. |

### 🐻 TunnelBear VPN & Per-App Split Tunneling (`tb`)
The system integrates official TunnelBear OpenVPN profiles directly with NetworkManager, offering both full-system VPN routing and lightweight, application-specific split tunneling:
- **Interactive TUI & Usage-Based Sorting**: Running `tb` opens an interactive FZF selector showing server locations ranked dynamically by usage frequency and recency.
- **Per-App Split Tunneling**: Run specific commands or GUI applications exclusively through VPN without routing normal system traffic:
  ```bash
  tb run claude                     # Run Claude Desktop/browser exclusively over TunnelBear VPN
  tb run curl https://ipinfo.io/ip  # Verify public VPN egress IP
  tb run -c japan claude            # Pick the server (default: active one, else last used)
  tb japan                          # Shorthand for `tb connect japan` (also ISO codes: jp, de, us-west)
  tb app add claude                 # Configure application to always route via VPN
  tb mode split                     # Toggle split-tunneling proxy mode (127.0.0.1:10808)
  ```
- **Cloud Quota Tracking & Live Sync**:
  - `tb account` / `tb quota`: Displays remaining monthly GB allowance and active plan details.
  - `tb sync`: Queries TunnelBear API to synchronize live quota usage.
  - While connected, the meter subtracts live tunnel traffic (TunnelBear only books a session ~1 min after disconnect); right after disconnect a local estimate is shown until the cloud catches up.
- **Boot Safety**: All NetworkManager TunnelBear VPN profiles have `autoconnect=false` enforced to prevent unexpected routing or data leakage during system startup.

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
awake off    # Resume standard idle timers and restart swayidle
awake status # Inspect active caffeine state
```

### 4. `epic` & `epic-games-claimer.user.js` (Epic Games Freebies Claimer)
An in-browser weekly auto-claimer (Violentmonkey userscript) that runs inside native logged-in Firefox:
- **Layout-proof Discovery:** Reads the current free games from Epic's promotions API, falling back to the "Free Now" cards on the free-games page.
- **Current Checkout Flow:** Handles the "This is free → Add to library" checkout (and the older zero-total "Place Order" one), EULA / "I Accept" prompts, mature-content gates, and verifies every claim via "In Library".
- **Safe by Design:** The checkout frame only acts during a run it was armed for, so manual purchases are never touched; captchas pause the run until solved.
- **Floating HUD:** Per-game results plus `⏹ Stop` / `▶ Resume`; the tab closes itself after a clean run.
- **CLI Commands:** `epic start`, `epic stop` (halts a run from any terminal), `epic install` (installs/replaces the userscript in Violentmonkey), `epic status`.

### 5. `twitch` & `twitch-drops-claimer.user.js` (Twitch Drops Auto-Claimer)
A Violentmonkey userscript that farms **Don't Starve Together** (DST) Twitch Drops in a Firefox tab:
- **Real-page driven:** Reads campaigns and watched minutes from the data Twitch's own Drops Campaigns/Inventory pages load (so Twitch's integrity checks are handled by Twitch itself), and claims with the page's own "Claim Now" button.
- **Channel Routing:** Watches the highest-viewed live, drops-enabled DST stream (skipping Russian-language streams and channels outside a campaign's allow-list), muted at 160p, and switches channels when a stream ends or progress stalls.
- **Progress Checks:** Returns to the inventory page when the next drop should be done (at most every 15 min), claims it, and stops once every watchable DST drop is claimed.
- **CLI Commands:** `twitch start`, `twitch stop`, `twitch install` (also aliased as `tdrops`).

### 6. `unlock_screen.sh` (Desktop Unlock & Recovery Utility)
```bash
unlock_screen.sh "<password>"
```
Performs reliable desktop unlocking across Wayland compositors:
- **Display Wakeup**: Powers on monitors across niri, Hyprland and Sway.
- **Automated Authentication**: Enters passwords into `swaylock` via `wtype` with sub-second feedback verification.

### 7. `share` & `share_menu.sh` (Network File Sharing & Hamachi VPN Manager)
```bash
share                   # Interactive TUI/FZF manager matching wifi & bluetooth style
share status            # Show Hamachi VPN & Samba service and network status
share-menu              # Terminal-based quick control menu
```
Unified network sharing controller:
- **Hamachi VPN**: On-demand service startup, account login, join/leave mesh networks, peer listing, and nickname assignment.
- **Samba LAN & VM Sharing**: On-demand daemon startup, manage LAN `/home/peng/Shared` & VM-restricted `/home/peng/Code` (`192.168.122.0/24`), set SMB user passwords, and mount remote network shares into `/mnt` via `cifs-utils`.

---

---

## 🚀 Rebuilding

```bash
nixreb            # rsync this repo to /etc/nixos and nixos-rebuild switch
```

After the first rebuild onto niri, log out and pick the **niri** session in Ly.
