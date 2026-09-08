{ config, pkgs, inputs, ... }:

{
  programs.fish.enable = true;
  programs.zsh.enable = true;

  users.users.peng = {
    isNormalUser = true;
    description = "Peng";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "libvirtd" "input" "uinput" ];
    packages = with pkgs; [];
  };
}
