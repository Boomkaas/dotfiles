#!/usr/bin/env bash
set -euo pipefail

# Rebuild the NixOS configuration from the current dotfiles directory.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="/etc/nixos"

echo "==> Syncing dotfiles from $DOTFILES_DIR to $TARGET_DIR..."
sudo rsync -av --delete \
  --exclude=".git" \
  "$DOTFILES_DIR/" "$TARGET_DIR/"

echo "==> Rebuilding NixOS system..."
sudo nixos-rebuild switch --flake "$TARGET_DIR#nixos" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" \
  --cores 4 --impure

echo "==> Done! Rebuilt NixOS successfully."