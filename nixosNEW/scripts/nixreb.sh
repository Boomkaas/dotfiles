#!/usr/bin/env bash

# Rebuild the NixOS configuration from the current dotfiles directory.
# We pass the trusted-public-keys option to bypass the broken base64 key in your current system's nix.conf.
sudo nixos-rebuild switch --flake /home/peng/Code/Dotfiles/nixosNEW#nixos \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" \
  --cores 8 --impure
