# Dotfiles: Test Coordination Reference

> **Subordinated to Global Rule:** [`~/.gemini/config/rules/test-coordination.md`](file:///home/peng/.gemini/config/rules/test-coordination.md).
> All testing workflows in this workspace follow the global Test Coordination & Granular Verification Rule.

---

## 1. Core Directives for Dotfiles

1. **Granular / Module-Level Testing ONLY**:
   - When modifying files in this workspace, run **ONLY the matching module test** (e.g. `nixtest network` for network changes).
   - **NEVER run `nixtest all`** for small features or localized changes.
   - Run `nixtest all` **ONLY when explicitly requested by the user**.
2. **Shutdown Notification Testing**:
   - When testing the shutdown notification (`night_presence_check.sh`, `nixtest power`, etc.), **automatically press the "I am here" button** (via `(sleep 0.5 && swaync-client -a 0 >/dev/null 2>&1) &` or action invoke). Never leave it waiting for user intervention.
3. **Synchronize Affected Test Assertions**:
   - If adding, modifying, or removing a script, wrapper, package, or config option, update the matching check in `nixos/scripts/nixtest` so the module passes with 0 failures.
4. **Nix Evaluation on `.nix` Edits**:
   - If `.nix` files are touched, verify `nixtest nix` (checks `nix-instantiate --parse` and `nixos-rebuild dry-build`).

---

## 2. Module Mapping Reference

| Subsystem / Files Changed | Test Command | Description |
|---------------------------|--------------|-------------|
| `nixos/flake.nix`, `nixos/modules/core/*.nix`, `nixos/system/*.nix` | `nixtest nix` | Flake dry-build evaluation & `.nix` parsing |
| PostgreSQL, Samba, Firewall (`connections.nix`), Polkit, `nix-ld` | `nixtest security` | Security, auth mechanisms, and privileges |
| NetworkManager, TCP/VM sysctl, network connectivity | `nixtest network` | Network configuration & kernel sysctl tunables |
| Bluetooth configuration (`connections.nix`), bluetoothd | `nixtest bluetooth` | Bluetooth options, integer types, service health |
| PipeWire, ALSA, PulseAudio, JACK, ALC256 quirk (`audio.nix`) | `nixtest audio` | Audio stack & hardware sound quirks |
| `hypridle.conf`, power/idle scripts, logind, sleep params | `nixtest power` | Power management, battery, idle inhibitors, S3 sleep |
| Waybar (`config/waybar/`), wallpaper, `lock.sh`, `dpms_handler.sh`, swaync | `nixtest display` | Display, lock screen, notifications, Waybar themes |
| `config/fish/`, starship, zoxide, shell abbrs, CLI tools | `nixtest shell` | Fish shell environment, prompt, and tool presence |
| `nixos/scripts/*` (bash/fish/python scripts) | `nixtest scripts` | Syntax checks (`bash -n`) and script logic |
| Systemd units, timers, virtualisation (docker/libvirtd) | `nixtest services` | Service states, active timers, failed unit checks |
| Root/boot partitions, swap, RAM thresholds, Nix store | `nixtest storage` | Disk space, memory pressure, and garbage collection |
| Bootloader, Intel CPU/GPU, kernel params, env vars | `nixtest kernel` | Kernel parameters, hardware graphics, and system boot |
| Config files (`config/kitty/`, `rofi/`, `tmux/`, `yazi/`, `mango/`, JSON/TOML) | `nixtest configs` | JSON/JSONC/TOML syntax and config file integrity |
| `nixos/modules/pkgs.nix`, fonts, packages | `nixtest packages` | Package deduplication, font placement, insecure pkgs |
