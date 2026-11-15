{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  imports =
    [
      ../modules/default.nix
    ];

  programs.niri.enable = true;

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
      # Upstream regression tests fail on 26.05, so Hydra has no cached build; skip them.
      pgadmin4-desktopmode = prev.pgadmin4-desktopmode.overridePythonAttrs { doCheck = false; };
    })
  ];

  hardware.uinput.enable = true;

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    HandleSuspendKey = "suspend";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
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
      settings.user.email = "vilatiimakohin@gmail.com";
      settings.user.name = "SyntaxTears";
      # Same as `gh auth setup-git`, which can't write this read-only config.
      settings.credential."https://github.com".helper = [ "" "!${pkgs.gh}/bin/gh auth git-credential" ];
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
      # Black overrides live in config/gtk/gtk.css (linked below).
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.theme = config.gtk.theme;
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "thunar.desktop" ];

        # Text & Code Files (Zed)
        "text/plain" = [ "dev.zed.Zed.desktop" ];
        "text/markdown" = [ "dev.zed.Zed.desktop" ];
        "text/x-c" = [ "dev.zed.Zed.desktop" ];
        "text/x-csrc" = [ "dev.zed.Zed.desktop" ];
        "text/x-chdr" = [ "dev.zed.Zed.desktop" ];
        "text/x-c++" = [ "dev.zed.Zed.desktop" ];
        "text/x-c++src" = [ "dev.zed.Zed.desktop" ];
        "text/x-c++hdr" = [ "dev.zed.Zed.desktop" ];
        "text/x-python" = [ "dev.zed.Zed.desktop" ];
        "text/x-shellscript" = [ "dev.zed.Zed.desktop" ];
        "text/x-lua" = [ "dev.zed.Zed.desktop" ];
        "text/x-rust" = [ "dev.zed.Zed.desktop" ];
        "text/x-diff" = [ "dev.zed.Zed.desktop" ];
        "application/json" = [ "dev.zed.Zed.desktop" ];
        "application/xml" = [ "dev.zed.Zed.desktop" ];
        "application/x-yaml" = [ "dev.zed.Zed.desktop" ];
        "text/yaml" = [ "dev.zed.Zed.desktop" ];
        "text/javascript" = [ "dev.zed.Zed.desktop" ];
        "application/javascript" = [ "dev.zed.Zed.desktop" ];

        # Web / Browsers
        "text/html" = [ "brave-browser.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/chrome" = [ "brave-browser.desktop" ];
        "application/x-extension-htm" = [ "brave-browser.desktop" ];
        "application/x-extension-html" = [ "brave-browser.desktop" ];
        "application/x-extension-shtml" = [ "brave-browser.desktop" ];
        "application/xhtml+xml" = [ "brave-browser.desktop" ];
        "application/x-extension-xhtml" = [ "brave-browser.desktop" ];
        "application/x-extension-xht" = [ "brave-browser.desktop" ];
        "application/x-zerosize" = [ "brave-browser.desktop" ];

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
      shellWrapperName = "yy";
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

    # Desktop configs from the repo, symlinked so edits are live.
    xdg.configFile = let
      link = path: config.lib.file.mkOutOfStoreSymlink "/home/peng/Code/Dotfiles/config/${path}";
    in {
      "niri/config.kdl".source = link "niri/config.kdl";
      "kitty/kitty.conf".source = link "kitty/kitty.conf";
      "fastfetch/config.jsonc".source = link "fastfetch/config.jsonc";
      "fetch/config".source = link "fetch/config";
      "swaylock/config".source = link "swaylock/config";
      "mako/config".source = link "mako/config";
      "gtk-3.0/gtk.css".source = link "gtk/gtk.css";
      "gtk-4.0/gtk.css".source = link "gtk/gtk.css";
      # No tray to show it in; connection-notify and wifi_menu cover its jobs.
      # The package stays for nm-connection-editor.
      "autostart/nm-applet.desktop".text = "[Desktop Entry]\nHidden=true\n";
    };

    # Idle chain (same timings as the old hypridle setup): idle_inhibit.sh
    # gates each step on battery/AC, caffeine and audio playback.
    systemd.user.services.swayidle = let
      sh = script: "${pkgs.bash}/bin/bash /home/peng/.local/bin/${script}";
      idle = timeout: cmd: "timeout ${toString timeout} '${cmd}'";
      idleResume = timeout: cmd: resume: "timeout ${toString timeout} '${cmd}' resume '${resume}'";
    in {
      Unit = {
        Description = "Idle manager (swayidle)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.swayidle}/bin/swayidle"
          "lock '${sh "lock.sh"}'"
          "before-sleep 'loginctl lock-session'"
          "after-resume '${sh "dpms_handler.sh"} on'"
          (idle 120 "${sh "idle_inhibit.sh"} --battery && loginctl lock-session")
          (idleResume 180 "${sh "idle_inhibit.sh"} --battery && ${sh "dpms_handler.sh"} off" "${sh "dpms_handler.sh"} on")
          (idle 300 "${sh "idle_sleep_poweroff.sh"} --battery")
          (idle 3600 "${sh "idle_inhibit.sh"} --battery && systemctl poweroff")
          (idle 180 "${sh "idle_inhibit.sh"} --ac && loginctl lock-session")
          (idleResume 600 "${sh "idle_inhibit.sh"} --ac && ${sh "dpms_handler.sh"} off" "${sh "dpms_handler.sh"} on")
          (idle 1200 "${sh "idle_sleep_poweroff.sh"} --ac")
          (idle 10800 "${sh "idle_inhibit.sh"} --ac && systemctl poweroff")
        ];
        Restart = "always";
        RestartSec = "2s";
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/peng/bin:/home/peng/.local/bin:/run/wrappers/bin:/usr/bin:/bin"
          "XDG_CURRENT_DESKTOP=niri"
        ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.polkit-mate = {
      Unit = {
        Description = "MATE polkit authentication agent";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Wi-Fi and Bluetooth connect/disconnect notifications (connection_notify.sh).
    systemd.user.services.connection-notify = {
      Unit = {
        Description = "Wi-Fi and Bluetooth connection notifications";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/connection_notify.sh";
        Restart = "always";
        RestartSec = "2s";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}


