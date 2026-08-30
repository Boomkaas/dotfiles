{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  imports =
    [
      ../modules/default.nix
      inputs.mangowm.nixosModules.mango
    ];

  programs.mango.enable = true;

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
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs pkgs_unstable; };
  home-manager.users.peng = { config, pkgs, inputs, pkgs_unstable, ... }: {
    home.username = "peng";
    home.homeDirectory = "/home/peng";
    home.stateVersion = "25.05";
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
    ];

    programs.git = {
      enable = true;
      userEmail = "boomeceeb@gmail.com";
      userName = "Peng";
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 11;
      };
      cursorTheme = {
        name = "Bibata-Modern-Ice";
        size = 24;
        package = pkgs.bibata-cursors;
      };
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
        "inode/directory" = [ "thunar.desktop" ];

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
      enableFishIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        if test -f /home/peng/Code/Dotfiles/config/fish/config.fish
          source /home/peng/Code/Dotfiles/config/fish/config.fish
        end
      '';
    };

    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww wallpaper daemon";
        PartOf = [ "graphical-session.target" "default.target" ];
        After = [ "graphical-session.target" "default.target" ];
      };
      Service = {
        ExecStart = "${pkgs_unstable.awww}/bin/awww-daemon";
        Restart = "always";
        RestartSec = "1s";
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/peng/bin:/home/peng/.local/bin:/usr/bin:/bin"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
