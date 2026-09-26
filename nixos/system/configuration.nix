{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  imports =
    [
      ../modules/default.nix
      inputs.mangowm.nixosModules.mango
    ];

  programs.mango.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      tmux = prev.tmux.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace input.c --replace "#define INPUT_BUF_LIMIT 1048576" "#define INPUT_BUF_LIMIT 104857600"
        '';
      });
      yazi-unwrapped = prev.yazi-unwrapped.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          ../modules/patches/yazi-disable-trt.patch
        ];
      });
    })
  ];

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
  home-manager.users.peng = { config, pkgs, lib, inputs, pkgs_unstable, ... }: {
    home.username = "peng";
    home.homeDirectory = "/home/peng";
    home.stateVersion = "25.05";
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
    ];

    # Auto-clean any conflicting .backup file if mimeapps.list was rewritten by external GUI apps
    home.activation.cleanMimeappsBackup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -f "$HOME/.config/mimeapps.list" ] && [ ! -L "$HOME/.config/mimeapps.list" ] && [ -e "$HOME/.config/mimeapps.list.backup" ]; then
        rm -f "$HOME/.config/mimeapps.list.backup"
      fi
    '';

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

        # Text & Code Files (Neovim)
        "text/plain" = [ "nvim.desktop" ];
        "text/markdown" = [ "nvim.desktop" ];
        "text/x-c" = [ "nvim.desktop" ];
        "text/x-csrc" = [ "nvim.desktop" ];
        "text/x-chdr" = [ "nvim.desktop" ];
        "text/x-c++" = [ "nvim.desktop" ];
        "text/x-c++src" = [ "nvim.desktop" ];
        "text/x-c++hdr" = [ "nvim.desktop" ];
        "text/x-python" = [ "nvim.desktop" ];
        "text/x-shellscript" = [ "nvim.desktop" ];
        "text/x-lua" = [ "nvim.desktop" ];
        "text/x-rust" = [ "nvim.desktop" ];
        "text/x-diff" = [ "nvim.desktop" ];
        "application/json" = [ "nvim.desktop" ];
        "application/xml" = [ "nvim.desktop" ];
        "application/x-yaml" = [ "nvim.desktop" ];
        "text/yaml" = [ "nvim.desktop" ];
        "text/javascript" = [ "nvim.desktop" ];
        "application/javascript" = [ "nvim.desktop" ];

        # Web / Browsers
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/chrome" = [ "firefox.desktop" ];
        "application/x-extension-htm" = [ "firefox.desktop" ];
        "application/x-extension-html" = [ "firefox.desktop" ];
        "application/x-extension-shtml" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "application/x-extension-xhtml" = [ "firefox.desktop" ];
        "application/x-extension-xht" = [ "firefox.desktop" ];
        "application/x-zerosize" = [ "firefox.desktop" ];

        # Messaging / Chat
        "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/msteams" = [ "teams-for-linux.desktop" ];

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

        # Images (Viewnior)
        "image/bmp" = [ "viewnior.desktop" ];
        "image/jpeg" = [ "viewnior.desktop" ];
        "image/gif" = [ "viewnior.desktop" ];
        "image/png" = [ "viewnior.desktop" ];
        "image/tiff" = [ "viewnior.desktop" ];
        "image/webp" = [ "viewnior.desktop" ];
        "image/x-bmp" = [ "viewnior.desktop" ];
        "image/x-ico" = [ "viewnior.desktop" ];
        "image/x-png" = [ "viewnior.desktop" ];
        "image/x-pcx" = [ "viewnior.desktop" ];
        "image/x-tga" = [ "viewnior.desktop" ];
        "image/xpm" = [ "viewnior.desktop" ];
        "image/svg+xml" = [ "viewnior.desktop" ];

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

    programs.yazi = {
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
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
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
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.hypridle = {
      Unit = {
        Description = "Hyprland's idle daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs_unstable.hypridle}/bin/hypridle";
        Restart = "always";
        RestartSec = "2s";
        # PATH consolidated here — replaces xdg.configFile drop-in and services.nix .path injection
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/peng/bin:/home/peng/.local/bin:/run/wrappers/bin:/usr/bin:/bin"
        ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
    # xdg.configFile hypridle drop-in removed: was redundantly setting the same PATH as Service.Environment above
  };
}


