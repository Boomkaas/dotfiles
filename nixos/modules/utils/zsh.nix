{
  programs.zsh.shellAliases = {
    gfn = "nohup flatpak run com.nvidia.geforcenow > /dev/null 2>&1 &";
    roblox = "nohup flatpak run org.vinegarhq.Sober > /dev/null 2>&1 &";

    nixreb = "/home/peng/Code/Dotfiles/nixos/scripts/nixreb.sh";
    addchans = "/home/peng/Code/Dotfiles/nixos/scripts/channels.sh";

    delgar = ''
    sudo nix-collect-garbage --delete-older-than 1d
    '';

    c = ''
    clear
    '';
  };
}
