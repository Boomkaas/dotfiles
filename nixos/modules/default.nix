{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  imports = [
    ./core/system.nix
    ./core/user.nix
    ./core/connections.nix
    ./core/audio.nix
    ./core/services.nix
    ./utils/xserver.nix
    ./pkgs.nix
  ];
}
