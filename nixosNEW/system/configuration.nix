{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  imports =
    [
      ../modules/default.nix
    ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };


  services.logind = {
    powerKey = "suspend";
    powerKeyLongPress = "poweroff";
    suspendKey = "suspend";
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs pkgs_unstable; };
  home-manager.users.peng = { config, pkgs, inputs, pkgs_unstable, ... }: {
    home.username = "peng";
    home.homeDirectory = "/home/peng";
    home.stateVersion = "25.05";

    programs.git = {
      enable = true;
      userEmail = "boomeceeb@gmail.com";
      userName = "Peng";
    };

    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-theme = "adw-gtk3";
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-theme = "adw-gtk3";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" ];
      };

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];

      shellAliases = {
        nixreb = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
        delgar = "sudo nix-collect-garbage --delete-older-than 1d";
        c = "clear";
      };

      initExtra = ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '';
    };
  };
}
