{ config, pkgs, inputs, pkgs_unstable, ... }:

let
  controlbot = pkgs.writeShellScriptBin "controlbot" ''
    cd /home/peng/Code/PcControlBot && exec venv/bin/python -m bot.main "$@"
  '';
  awake = pkgs.writeShellScriptBin "awake" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/awake "$@"
  '';
  epic = pkgs.writeShellScriptBin "epic" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/epic "$@"
  '';
  nixreb = pkgs.writeShellScriptBin "nixreb" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/nixreb.sh "$@"
  '';
  twitch = pkgs.writeShellScriptBin "twitch" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/twitch "$@"
  '';
  wifi-menu = pkgs.writeShellScriptBin "wifi-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/wifi_menu.sh "$@"
  '';
  bluetooth-menu = pkgs.writeShellScriptBin "bluetooth-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/bluetooth_menu.sh "$@"
  '';
  audio-menu = pkgs.writeShellScriptBin "audio-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/audio_menu.sh "$@"
  '';
  process-menu = pkgs.writeShellScriptBin "process-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/process_menu.sh "$@"
  '';
  gtk-theme-menu = pkgs.writeShellScriptBin "gtk-theme-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/gtk_theme_menu.sh "$@"
  '';
  disk-menu = pkgs.writeShellScriptBin "disk-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/disk_menu.sh "$@"
  '';
  clean-menu = pkgs.writeShellScriptBin "clean-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/clean_menu.sh "$@"
  '';
  config-menu = pkgs.writeShellScriptBin "config-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/config_menu.sh "$@"
  '';
  share-menu = pkgs.writeShellScriptBin "share-menu" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/share_menu.sh "$@"
  '';
  share = pkgs.writeShellScriptBin "share" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/share "$@"
  '';
  wifi = pkgs.writeShellScriptBin "wifi" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/wifi "$@"
  '';
  bluetooth = pkgs.writeShellScriptBin "bluetooth" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/bluetooth "$@"
  '';
  bt = pkgs.writeShellScriptBin "bt" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/bluetooth "$@"
  '';
  setting = pkgs.writeShellScriptBin "setting" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/setting "$@"
  '';
  settings = pkgs.writeShellScriptBin "settings" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/setting "$@"
  '';
  theme = pkgs.writeShellScriptBin "theme" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/theme "$@"
  '';
  audio = pkgs.writeShellScriptBin "audio" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/audio "$@"
  '';
  nixos-cmd = pkgs.writeShellScriptBin "nixos" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/nixos "$@"
  '';
  gens = pkgs.writeShellScriptBin "gens" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/nixos "$@"
  '';
  tm = pkgs.writeShellScriptBin "tm" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/tm "$@"
  '';
  project = pkgs.writeShellScriptBin "project" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/tm "$@"
  '';
  service-cmd = pkgs.writeShellScriptBin "service" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/service "$@"
  '';
  services-cmd = pkgs.writeShellScriptBin "services" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/service "$@"
  '';
  task-cmd = pkgs.writeShellScriptBin "task" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/task "$@"
  '';
  tasks-cmd = pkgs.writeShellScriptBin "tasks" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/task "$@"
  '';
  conf-cmd = pkgs.writeShellScriptBin "conf" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/conf "$@"
  '';
  configs-cmd = pkgs.writeShellScriptBin "configs" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/conf "$@"
  '';
  config-cmd = pkgs.writeShellScriptBin "config" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/conf "$@"
  '';
  disk-cmd = pkgs.writeShellScriptBin "disk" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/disk "$@"
  '';
  storage-cmd = pkgs.writeShellScriptBin "storage" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/disk "$@"
  '';
  repo-cmd = pkgs.writeShellScriptBin "repo" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/repo "$@"
  '';
  repos-cmd = pkgs.writeShellScriptBin "repos" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/repo "$@"
  '';
  gitui-cmd = pkgs.writeShellScriptBin "gitui" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/repo "$@"
  '';
  ports-cmd = pkgs.writeShellScriptBin "ports" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/ports "$@"
  '';
  port-cmd = pkgs.writeShellScriptBin "port" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/ports "$@"
  '';
  clip-cmd = pkgs.writeShellScriptBin "clip" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/clip "$@"
  '';
  clips-cmd = pkgs.writeShellScriptBin "clips" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/clip "$@"
  '';
  log-cmd = pkgs.writeShellScriptBin "log" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/log "$@"
  '';
  logs-cmd = pkgs.writeShellScriptBin "logs" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/log "$@"
  '';
  journal-cmd = pkgs.writeShellScriptBin "journal" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/log "$@"
  '';
  container-cmd = pkgs.writeShellScriptBin "container" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/container "$@"
  '';
  containers-cmd = pkgs.writeShellScriptBin "containers" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/container "$@"
  '';
  vm-cmd = pkgs.writeShellScriptBin "vm" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/container "$@"
  '';
  pkg-tool = pkgs.writeShellScriptBin "pkg" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/pkg "$@"
  '';
  pkgs-tool = pkgs.writeShellScriptBin "pkgs" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/pkg "$@"
  '';
  s-cmd = pkgs.writeShellScriptBin "s" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tui/s "$@"
  '';
  nixtest = pkgs.writeShellScriptBin "nixtest" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/nixtest "$@"
  '';
  tunnelbear-cmd = pkgs.writeShellScriptBin "tunnelbear" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tunnelbear "$@"
  '';
  tb-cmd = pkgs.writeShellScriptBin "tb" ''
    exec ${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/tunnelbear "$@"
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
  libredb-studio = let
    pname = "libredb-studio";
    version = "0.16.1";
    src = pkgs.fetchurl {
      url = "https://github.com/libredb/libredb-studio/releases/download/${version}/libredb-studio-desktop-${version}-linux-x64.AppImage";
      hash = "sha256-t04PnFPa8thQF/6SplJxosU2qnptiWuPG0v9QgmS2rI=";
    };
    appimageContents = pkgs.appimageTools.extractType2 {
      inherit pname version src;
    };
  in pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/libredb-studio-desktop.desktop $out/share/applications/libredb-studio.desktop
      substituteInPlace $out/share/applications/libredb-studio.desktop \
        --replace-fail 'Exec=libredb-studio-desktop' 'Exec=libredb-studio'
      ln -s $out/share/applications/libredb-studio.desktop $out/share/applications/libredb-studio-desktop.desktop
      cp -r ${appimageContents}/usr/share/icons $out/share/

      mv $out/bin/libredb-studio $out/bin/.libredb-studio-unwrapped
      cat > $out/bin/libredb-studio <<EOF
#!${pkgs.bash}/bin/bash
export LD_PRELOAD="${pkgs.wayland}/lib/libwayland-client.so.0\''${LD_PRELOAD:+:\$LD_PRELOAD}"
exec $out/bin/.libredb-studio-unwrapped "\$@"
EOF
      chmod +x $out/bin/libredb-studio
      ln -s $out/bin/libredb-studio $out/bin/libredb-studio-desktop
    '';
  };
  wayland-vpet = pkgs.llvmPackages_19.stdenv.mkDerivation rec {
    pname = "wayland-vpets";
    version = "5.0.2";

    src = pkgs.fetchFromGitHub {
      owner = "furudbat";
      repo = "wayland-vpets";
      rev = "v${version}";
      hash = "sha256-V5fg4t4uU3kx5b/UaxYujD1ki6MlX17jtuHR6Sxfsq4=";
    };

    patches = [
      ./patches/wayland-vpet-fullscreen.patch
    ];

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      wayland-scanner
      pandoc
    ];

    buildInputs = with pkgs; [
      wayland
      wayland-protocols
      systemd
      cairo
      libevdev
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DFEATURE_LAZY_LOAD_ASSETS=ON"
      "-DFEATURE_MULTI_VERSIONS=ON"
      "-DSKIP_CPM=ON"
      "-DGENERATE_PROTOCOLS=OFF"
    ];

    postInstall = ''
      ln -s $out/bin/bongocat-all $out/bin/wpets
      mkdir -p $out/share/wayland-vpets
      grep -h -oP 'PMD_[A-Z0-9_]+_FQNAME_ARR\[\][^=]*= "\K[^"]+' ../include/embedded_assets/pmd/pmd.hpp | sort -u > $out/share/wayland-vpets/pokemon.txt
      grep -h -oP 'DM(20|C)?_[A-Z0-9_]+_NAME_ARR\[\][^=]*= "\K[^"]+' ../include/embedded_assets/dm*/*.hpp | sort -u > $out/share/wayland-vpets/digimon.txt
      cat $out/share/wayland-vpets/pokemon.txt $out/share/wayland-vpets/digimon.txt | sort -u > $out/share/wayland-vpets/pet_list.txt

      cat <<'EOF' > $out/bin/wayland-vpet
#!/usr/bin/env bash
CONFIG_DIR="$HOME/.config/bongocat"
CONFIG_FILE="$CONFIG_DIR/bongocat.conf"
PKMN_LIST_FILE="@out@/share/wayland-vpets/pokemon.txt"
DM_LIST_FILE="@out@/share/wayland-vpets/digimon.txt"
ALL_LIST_FILE="@out@/share/wayland-vpets/pet_list.txt"

mkdir -p "$CONFIG_DIR"
[ -f "$PKMN_LIST_FILE" ] && cp -u "$PKMN_LIST_FILE" "$CONFIG_DIR/pokemon.txt" 2>/dev/null || true
[ -f "$DM_LIST_FILE" ] && cp -u "$DM_LIST_FILE" "$CONFIG_DIR/digimon.txt" 2>/dev/null || true
[ -f "$ALL_LIST_FILE" ] && cp -u "$ALL_LIST_FILE" "$CONFIG_DIR/pet_list.txt" 2>/dev/null || true

ARG="$1"

if [ "$ARG" == "pokemon" ] || [ "$ARG" == "pkmn" ]; then
  CHOSEN_PET=$(shuf -n 1 "$PKMN_LIST_FILE")
  shift
elif [ "$ARG" == "digimon" ] || [ "$ARG" == "dm" ]; then
  CHOSEN_PET=$(shuf -n 1 "$DM_LIST_FILE")
  shift
elif [ -n "$ARG" ] && [[ "$ARG" != -* ]] && [[ "$ARG" != "random" ]]; then
  shift
  if grep -qi "^pmd:$ARG$" "$ALL_LIST_FILE" 2>/dev/null; then
    CHOSEN_PET=$(grep -i "^pmd:$ARG$" "$ALL_LIST_FILE" | head -n 1)
  elif grep -qi "^$ARG$" "$ALL_LIST_FILE" 2>/dev/null; then
    CHOSEN_PET=$(grep -i "^$ARG$" "$ALL_LIST_FILE" | head -n 1)
  else
    CHOSEN_PET="$ARG"
  fi
else
  [[ "$ARG" == "random" ]] && shift
  COIN=$((RANDOM % 2))
  if [ "$COIN" -eq 0 ] && [ -f "$DM_LIST_FILE" ]; then
    CHOSEN_PET=$(shuf -n 1 "$DM_LIST_FILE")
  elif [ -f "$PKMN_LIST_FILE" ]; then
    CHOSEN_PET=$(shuf -n 1 "$PKMN_LIST_FILE")
  else
    FALLBACK_PETS=("Agumon" "Gabumon" "Patamon" "Gatomon" "pmd:Pikachu" "pmd:Bulbasaur" "pmd:Charmander" "pmd:Squirtle" "pmd:Eevee")
    CHOSEN_PET="''${FALLBACK_PETS[$RANDOM % ''${#FALLBACK_PETS[@]}]}"
  fi
fi

if [ -f "$CONFIG_FILE" ]; then
  sed -i "s|^animation_name=.*|animation_name=$CHOSEN_PET|" "$CONFIG_FILE"
  sed -i "s|^random=.*|random=0|" "$CONFIG_FILE"
  sed -i "s|^movement_speed=.*|movement_speed=4|" "$CONFIG_FILE"
  sed -i "s|^movement_radius=.*|movement_radius=350|" "$CONFIG_FILE"
  sed -i "s|^movement_wait_factor=.*|movement_wait_factor=1.2|" "$CONFIG_FILE"
  if ! grep -q "^evolution=" "$CONFIG_FILE"; then
    echo "evolution=normal" >> "$CONFIG_FILE"
    echo "evolution_speed_factor=200.0" >> "$CONFIG_FILE"
  fi
  if ! grep -q "^disable_fullscreen_hide=" "$CONFIG_FILE"; then
    echo "disable_fullscreen_hide=1" >> "$CONFIG_FILE"
  fi
fi

if [ -f "$HOME/.config/bongocat.conf" ] && [ ! -L "$HOME/.config/bongocat.conf" ]; then
  cp "$CONFIG_FILE" "$HOME/.config/bongocat.conf"
fi

pkill -f bongocat-all 2>/dev/null || true
sleep 0.2

echo "🐾 Spawning walking pet: $CHOSEN_PET (Evolution enabled)"
exec @out@/bin/bongocat-all -c "$CONFIG_FILE" "$@"
EOF
      substituteInPlace $out/bin/wayland-vpet --replace-fail '@out@' "$out"
      chmod +x $out/bin/wayland-vpet
      ln -s $out/bin/wayland-vpet $out/bin/pet
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    # Antigravity from unstable (both IDE and CLI)
    pkgs_unstable.antigravity-ide
    pkgs_unstable.antigravity-cli
    (pkgs.writeShellScriptBin "antigravity" ''
      exec ${pkgs_unstable.antigravity-cli}/bin/agy "$@"
    '')

    # Noctalia
    inputs.noctalia.packages.${pkgs.system}.default

    # Terminal & Shell
    kitty
    foot
    fastfetch
    htop
    btop
    nvtopPackages.full
    fish
    eza
    bat
    fzf
    ripgrep
    fd
    tmux
    stow
    ncdu
    nix-output-monitor
    zoxide
    yazi
    ueberzugpp
    nload
    termshark
    pkgs_unstable.wiremix

    # Browser
    firefox
    chromium

    # Communication
    telegram-desktop
    discord
    #ayugram-desktop
    teams-for-linux

    # Dev Tools
    git
    lazygit
    neovim
    codex
    go
    gcc
    gnumake
    cmake
    gdb
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
      colorthief
      pygobject3
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
    xwayland-satellite
    wl-clipboard
    wtype
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
    imagemagick
    wlr-randr
    cliphist
    hyprpicker
    gammastep
    file
    file-roller
    mpvpaper
    gtk-layer-shell
    gobject-introspection
    vte
    # gtk3 and glib are declared below in the GTK/Theming section
    pango
    gdk-pixbuf
    ffmpegthumbnailer

    # Terminal eye-candy, CLI toys & monitors
    hyfetch
    unimatrix
    cava
    lavat
    figlet
    mapscii
    pipes                   # pipes.sh
    aalib                   # provides aafire
    peaclock
    gtop
    wayland-vpet
    chafa
    cmatrix
    tty-clock
    nyancat
    asciiquarium
    cbonsai

    # Hakuspace Components
    (waybar.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        substituteInPlace src/bar.cpp \
          --replace-fail 'auto group_config = config[ref];' 'const auto& group_config = config[ref];'
      '';
    }))                     # Status bar (with upstream dangling ref fix)
    swaynotificationcenter  # Notifications & control center (swaync)
    pkgs_unstable.hypridle  # Idle management
    hyprlock                # Screen lock
    pkgs_unstable.hyprsunset # Blue light filter
    pkgs_unstable.awww      # Wallpaper daemon (formerly swww)
    (rofi-wayland.override {
      plugins = [ rofi-emoji-wayland ];
    })                      # App launcher with emoji plugin
    fish                    # Shell
    starship                # Shell prompt
    xfce.thunar             # File manager
    xfce.thunar-volman      # Thunar volume management
    xfce.tumbler            # Thunar thumbnail service
    wl-screenrec            # Screen recording
    pulseaudio              # Provides pactl and pacat for audio recording/control
    mate.mate-polkit        # Polkit authentication agent
    ly                      # Display manager

    # GTK, Qt & Theming
    adw-gtk3
    gtk3
    gsettings-desktop-schemas
    papirus-icon-theme
    adwaita-icon-theme
    morewaita-icon-theme
    hicolor-icon-theme
    qt6.qtwayland
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qt5compat
    # nerd-fonts and font-awesome declared in system.nix fonts.packages (canonical NixOS font location)

    # Office & Media
    libreoffice-fresh
    obs-studio
    vlc
    obsidian
    evince
    viewnior
    swappy

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
    nixreb
    awake
    wifi-menu
    bluetooth-menu
    audio-menu
    process-menu
    gtk-theme-menu
    disk-menu
    clean-menu
    config-menu
    share
    share-menu
    wifi
    bluetooth
    bt
    audio
    setting
    settings
    theme
    nixos-cmd
    gens
    tm
    project
    service-cmd
    services-cmd
    task-cmd
    tasks-cmd
    conf-cmd
    configs-cmd
    config-cmd
    disk-cmd
    storage-cmd
    repo-cmd
    repos-cmd
    gitui-cmd
    ports-cmd
    port-cmd
    clip-cmd
    clips-cmd
    log-cmd
    logs-cmd
    journal-cmd
    container-cmd
    containers-cmd
    vm-cmd
    pkg-tool
    pkgs-tool
    s-cmd
    nixtest
    tunnelbear-cmd
    tb-cmd

    # Archive
    zip
    unzip
    unrar
    p7zip

    # System / Misc
    openvpn
    jq
    gparted
    cifs-utils
    postman
    bruno
    pgadmin4-desktopmode
    libredb-studio
    glib
    procps
    iputils
    libgcc
    jmtpfs
  ];
}
