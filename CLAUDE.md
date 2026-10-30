# Dotfiles — NixOS flake + desktop configs

Single-host NixOS 25.05 flake (`nixos#nixos`, user `peng`, x86_64) running the
niri Wayland compositor (black-and-white "niri-creation-of-adam" look), plus
the dotfiles it uses. `README.md` is the
feature reference; this file covers how the repo is wired and how to change it
safely.

## Layout

- `nixos/flake.nix` — inputs: nixpkgs 25.05, `nixpkgs_unstable` (passed as
  `pkgs_unstable`), home-manager.
- `nixos/system/configuration.nix` — `programs.niri`, overlays (tmux, yazi),
  home-manager user block (config symlinks, swayidle and polkit user services). `hardware-configuration.nix` is generated; don't edit.
- `nixos/modules/core/*.nix` — system, user, connections, audio, services.
- `nixos/modules/pkgs.nix` — packages **and** the `writeShellScriptBin`
  wrappers that turn `nixos/scripts/*` into commands.
- `nixos/modules/patches/` — patches applied to yazi, wayland-vpet.
- `nixos/scripts/` — bash tools; `nixos/scripts/tui/` — fzf TUIs launched by `s`.
- `config/` — app configs: `niri` (+ wallpaper), `kitty`, `fastfetch`,
  `fetch`, `swaylock`, `mako`, `fish`, `tmux`, `yazi`.

## How changes go live

- **Nix changes** need a rebuild: `nixreb` rsyncs this whole directory to
  `/etc/nixos` (`--delete`, only `.git` excluded) and runs
  `nixos-rebuild switch --flake /etc/nixos#nixos --impure`. The flake is built
  from the `/etc/nixos` copy, so untracked files are included.
- **Scripts** are live immediately: wrappers exec
  `bash /home/peng/Code/Dotfiles/nixos/scripts/<name>` by absolute path. A *new*
  command still needs a wrapper in `pkgs.nix` and a rebuild.
- **Configs** depend on how each one is linked:
  - Live through home-manager `mkOutOfStoreSymlink`: `niri/config.kdl`,
    `kitty/kitty.conf`, `fastfetch/config.jsonc`, `fetch/config`,
    `swaylock/config`, `mako/config` (adding a new one needs a rebuild).
    niri reloads its config on save. `tmux` and `yazi` are symlinked dirs.
  - Fish: the home-manager `config.fish` sources `config/fish/config.fish`, so
    edits are live in new shells.
- The repo must stay at `/home/peng/Code/Dotfiles`; that path is hardcoded in
  `pkgs.nix`, `configuration.nix` and several scripts.

## Rules

- Don't run `nixreb`, `nixos-rebuild switch`/`boot`, or anything under `sudo`
  without asking. sudo needs an interactive password; hand the user the exact
  command to run as `! <command>`.
- Scripts start with `#!/usr/bin/env bash`. Ones launched from niri binds,
  systemd units or udev run with a minimal environment, so they export a full
  `PATH` up front (see `camera_toggle.sh`).
- Add new packages to the matching commented section of `pkgs.nix`. Use
  `pkgs_unstable.<pkg>` only when stable is too old.
- Keybindings live in the `binds` block of `config/niri/config.kdl`. Check for an existing binding on
  the key before adding one, and don't move bindings the user didn't ask about.
- When a user-facing feature changes, update its section in `README.md`.
- Commits use conventional style with a component scope:
  `fix(niri): …`, `feat(tui): …`, `fix(audio): …`, `chore(scripts): …`.

## Verifying

- `niri validate -c config/niri/config.kdl` after editing the niri config,
  and `bash -n` on any script you touched.
- `nixos-rebuild dry-build --flake ./nixos#nixos --impure` after Nix changes
  to check the full system evaluates (~30s).
