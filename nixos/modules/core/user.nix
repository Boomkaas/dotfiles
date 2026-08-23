{ config, pkgs, inputs, ... }:

{
  programs.zsh.enable = true;

  users.users.peng = {
    isNormalUser = true;
    description = "Peng";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "libvirtd" ];
    packages = with pkgs; [];
  };
}
