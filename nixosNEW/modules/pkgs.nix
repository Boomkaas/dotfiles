
{ config, pkgs, inputs, pkgs_unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    # Antigravity from unstable
    pkgs_unstable.antigravity

    # Noctalia
    inputs.noctalia.packages.${pkgs.system}.default

    # Terminal & Shell
    kitty
    foot
    fastfetch
    htop
    zsh-powerlevel10k

    # Browser
    google-chrome

    # Communication
    telegram-desktop
    discord
    ayugram-desktop

    # Dev Tools
    git
    go
    gcc
    gnumake
    cmake
    gdb
    python3
    nodejs
    dotnet-sdk_9
    docker
    docker-compose
    krb5

    # Wayland / Desktop Utilities
    xwayland-satellite
    wl-clipboard
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
    wpsoffice
    libreoffice-fresh
    obs-studio
    vlc
    obsidian

    # Wine & Gaming
    wineWowPackages.stable
    winetricks
    bottles
    wine64

    # Archive
    unzip
    unrar
    p7zip

    # System / Misc
    gparted
    postman
    pgadmin4-desktopmode
    glib
    procps
    iputils
    libgcc
    pulseaudio
  ];

  virtualisation.docker.enable = true;
  services.flatpak.enable = true;
}
