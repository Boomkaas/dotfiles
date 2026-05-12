{
  programs.zsh.shellAliases = {
    nixreb = ''
    /home/peng/Dotfiles/scripts/nixreb.sh
    '';

    addchans = ''
    /home/peng/Dotfiles/scripts/channels.sh
    '';

    delgar = ''
    sudo nix-collect-garbage --delete-older-than 1d
    '';

    c = ''
    clear
    '';
  };
}
