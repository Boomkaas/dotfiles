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

  hardware.uinput.enable = true;

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

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs pkgs_unstable; };
  home-manager.users.peng = { config, pkgs, inputs, pkgs_unstable, ... }: {
    home.username = "peng";
    home.homeDirectory = "/home/peng";
    home.stateVersion = "25.05";
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
    ];

    xdg.desktopEntries = {
      ranger = {
        name = "Ranger";
        genericName = "File Manager";
        comment = "Vim-like file manager";
        exec = "kitty --class ranger ranger %F";
        icon = "utilities-terminal";
        terminal = false;
        categories = [ "System" "FileTools" "FileManager" ];
        mimeType = [ "inode/directory" ];
      };
    };

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

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "ranger.desktop" "org.kde.dolphin.desktop" ];

        # Office Documents
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "calc.desktop" ];
        "application/vnd.ms-excel" = [ "calc.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "calc.desktop" ];
        "text/csv" = [ "calc.desktop" ];

        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];
        "application/vnd.ms-word" = [ "writer.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];
        "application/rtf" = [ "writer.desktop" ];
        "text/rtf" = [ "writer.desktop" ];

        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "impress.desktop" ];
        "application/vnd.ms-powerpoint" = [ "impress.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "impress.desktop" ];

        "application/pdf" = [ "org.gnome.Evince.desktop" ];

        # Images (Gwenview)
        "image/bmp" = [ "org.kde.gwenview.desktop" ];
        "image/jpeg" = [ "org.kde.gwenview.desktop" ];
        "image/gif" = [ "org.kde.gwenview.desktop" ];
        "image/png" = [ "org.kde.gwenview.desktop" ];
        "image/tiff" = [ "org.kde.gwenview.desktop" ];
        "image/webp" = [ "org.kde.gwenview.desktop" ];
        "image/x-bmp" = [ "org.kde.gwenview.desktop" ];
        "image/x-ico" = [ "org.kde.gwenview.desktop" ];
        "image/x-png" = [ "org.kde.gwenview.desktop" ];
        "image/x-pcx" = [ "org.kde.gwenview.desktop" ];
        "image/x-tga" = [ "org.kde.gwenview.desktop" ];
        "image/xpm" = [ "org.kde.gwenview.desktop" ];
        "image/svg+xml" = [ "org.kde.gwenview.desktop" ];

        # Audio (VLC)
        "audio/mpeg" = [ "vlc.desktop" ];
        "audio/ogg" = [ "vlc.desktop" ];
        "audio/wav" = [ "vlc.desktop" ];
        "audio/x-wav" = [ "vlc.desktop" ];
        "audio/flac" = [ "vlc.desktop" ];
        "audio/x-flac" = [ "vlc.desktop" ];
        "audio/aac" = [ "vlc.desktop" ];
        "audio/m4a" = [ "vlc.desktop" ];
        "audio/mp4" = [ "vlc.desktop" ];
        "audio/x-matroska" = [ "vlc.desktop" ];

        # Video (VLC)
        "video/mp4" = [ "vlc.desktop" ];
        "video/mpeg" = [ "vlc.desktop" ];
        "video/ogg" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "video/webm" = [ "vlc.desktop" ];
        "video/x-matroska" = [ "vlc.desktop" ];
        "video/x-flv" = [ "vlc.desktop" ];
        "video/x-msvideo" = [ "vlc.desktop" ];
        "video/x-ms-wmv" = [ "vlc.desktop" ];
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
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
        nixreb = "/home/peng/Code/Dotfiles/nixos/scripts/nixreb.sh";
        epic = "/home/peng/Code/Dotfiles/nixos/scripts/epic";
        twitch = "/home/peng/Code/Dotfiles/nixos/scripts/twitch";
        tdrops = "/home/peng/Code/Dotfiles/nixos/scripts/twitch";
        delgar = "sudo nix-collect-garbage --delete-older-than 1d";
        c = "clear";
      };

      initContent = ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '';
    };
  };
}
