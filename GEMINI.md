# Dotfiles Rule: Test Coordination Protocol

**Scope:** This rule applies exclusively to the `/home/peng/Code/Dotfiles` workspace and all its subdirectories (`nixos/`, `config/`, etc.).

Whenever making changes, updates, upgrades, removals, or refactors to any system code, configuration, script, service, or package in this repository, you **MUST** coordinate the change with the test suite (`nixos/scripts/nixtest`).

---

## 1. Core Principles

1. **Test-Coordinated Changes:** Every change to the dotfiles must have a matching verification step using `nixtest`.
2. **Synchronized Test Assertions:** If you add, modify, rename, or remove a feature, configuration, script, wrapper, or service, you must also update the corresponding check in `nixos/scripts/nixtest`. Never leave obsolete test assertions that cause false failures or leave new features untested.
3. **Zero Regressions:** Never conclude a task with failing tests in `nixtest`. All affected modules must report 0 failures.

---

## 2. Module Mapping Reference

Select the relevant module(s) based on the files being modified:

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

---

## 3. Workflow for Any Modification

### Step 1: Pre-Change Baseline
Before modifying code, run the target module(s) to verify current state:
```bash
nixtest <module>
```

### Step 2: Implement Code Change & Update Tests
- Apply the code modification in `nixos/` or `config/`.
- **Coordinate with `nixtest`:**
  - If a service, script, package, or config option was **added**: Add an appropriate check to the corresponding module in `nixos/scripts/nixtest`.
  - If a service, script, package, or config option was **modified**: Update the pattern or expectation in `nixos/scripts/nixtest` to reflect the new behavior.
  - If a service, script, package, or config option was **removed**: Remove or replace the corresponding check in `nixos/scripts/nixtest`.

### Step 3: Post-Change Verification
Run the module test(s) to verify the change:
```bash
nixtest <module>
```
If multiple subsystems were touched, or before completing a major task or rebuild:
```bash
nixtest all
```
Ensure the result is `✅ 0 failed`.

### Step 4: Nix Evaluation Check (for `.nix` edits)
If any `.nix` file was touched, always verify that `nix-instantiate --parse` and `nixos-rebuild dry-build` pass:
```bash
nixtest nix
```
