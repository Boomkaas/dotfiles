{ config, pkgs, inputs, pkgs_unstable, ... }:

let
  controlbot = pkgs.writeShellScriptBin "controlbot" ''
    cd /home/peng/Code/PcControlBot && exec venv/bin/python -m bot.main "$@"
  '';
  epic = pkgs.writeShellScriptBin "epic" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/epic "$@"
  '';
  twitch = pkgs.writeShellScriptBin "twitch" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/twitch "$@"
  '';
  gfn = pkgs.writeShellScriptBin "gfn" ''
    nohup flatpak run com.nvidia.geforcenow > /dev/null 2>&1 &
  '';
  roblox = pkgs.writeShellScriptBin "roblox" ''
    nohup flatpak run org.vinegarhq.Sober > /dev/null 2>&1 &
  '';
  tlauncher = let
    tlauncher-bin = pkgs.writeShellScriptBin "tlauncher" ''
      mkdir -p "$HOME/.local/share/tlauncher"
      JAR_PATH="$HOME/.local/share/tlauncher/TLauncher.jar"
      if [ ! -f "$JAR_PATH" ]; then
        echo "Downloading TLauncher.jar..."
        ${pkgs.curl}/bin/curl -L -o "/tmp/tlauncher.zip" "https://tlauncher.org/jar"
        ${pkgs.unzip}/bin/unzip -o "/tmp/tlauncher.zip" -d "$HOME/.local/share/tlauncher"
        find "$HOME/.local/share/tlauncher" -maxdepth 1 -name "TLauncher*.jar" -exec mv {} "$JAR_PATH" \; 2>/dev/null || true
        rm -f "/tmp/tlauncher.zip"
      fi
      exec ${pkgs.steam-run}/bin/steam-run ${pkgs.openjdk17}/bin/java -jar "$JAR_PATH" "$@"
    '';
    tlauncher-desktop = pkgs.makeDesktopItem {
      name = "tlauncher";
      exec = "tlauncher";
      icon = "minecraft";
      comment = "Minecraft Launcher";
      desktopName = "TLauncher";
      categories = [ "Game" ];
    };
  in pkgs.symlinkJoin {
    name = "tlauncher";
    paths = [ tlauncher-bin tlauncher-desktop ];
  };
in
{
  environment.systemPackages = with pkgs; [
    # Antigravity from unstable
    pkgs_unstable.antigravity-ide

    # Noctalia
    inputs.noctalia.packages.${pkgs.system}.default

    # Terminal & Shell
    kitty
    foot
    fastfetch
    htop
    zsh-powerlevel10k
    eza
    bat
    nix-output-monitor

    # Browser
    firefox

    # Communication
    telegram-desktop
    discord
    #ayugram-desktop
    teams-for-linux

    # Dev Tools
    git
    codex
    go
    gcc
    gnumake
    cmake
    gdb
    gradle
    (python3.withPackages (ps: with ps; [
      numpy
      matplotlib
      selenium
      beautifulsoup4
      requests
      tkinter
      scipy
      pandas
      pillow
      sqlalchemy
      psycopg2-binary 
      openpyxl
      flask
      python-telegram-bot
      aiogram
      telethon
      python-dotenv
      aiosqlite
      yt-dlp
      ffmpeg-python
      faster-whisper
      librosa
      google-api-python-client
      google-auth
      google-auth-oauthlib
      apscheduler
      pydantic
      pydantic-settings
      aiofiles
    ]))
    nodejs
    dotnet-sdk_9
    docker
    docker-compose
    krb5
    sqlite
    rsync
    ffmpeg
    yt-dlp

    # Wayland / Desktop Utilities
    hyprpolkitagent
    xwayland-satellite
    wl-clipboard
    libnotify
    playerctl
    brightnessctl
    pamixer
    grim
    slurp
    wev
    libdbusmenu-gtk3
    nwg-look
    upower
    networkmanagerapplet
    bibata-cursors
    pavucontrol
    blueman
    dconf

    # Qt & Theming
    adw-gtk3
    qt6.qtwayland
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qt5compat
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only

    # Office & Media
    libreoffice-fresh
    obs-studio
    vlc
    obsidian
    evince
    (shutter.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        substituteInPlace bin/shutter \
          --replace-fail "unless (scalar @\$apps) {" "unless (defined \$apps && scalar @\$apps) {"
      '';
    }))
    
    # File Manager
    ranger
    kdePackages.dolphin
    kdePackages.gwenview
    kdePackages.ark
    kdePackages.konsole
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kio-extras
    ffmpegthumbnailer

    # Wine & Gaming
    wineWowPackages.stable
    winetricks
    bottles
    tlauncher
    gfn
    roblox
    controlbot
    epic
    twitch

    # Archive
    zip
    unzip
    unrar
    p7zip

    # System / Misc
    jq
    gparted
    postman
    pgadmin4-desktopmode
    glib
    procps
    iputils
    libgcc
    jmtpfs

    # Meme
    cmatrix
    nyancat
    asciiquarium
    cbonsai
  ];
}
