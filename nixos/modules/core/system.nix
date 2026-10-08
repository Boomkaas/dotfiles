{ config, pkgs, inputs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "i915.enable_psr=0"
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "25.05";

  # CMOS RTC battery is dead: hardware clock resets to 2021 on every power-up.
  # Load rtc_cmos in initrd so systemd's "advance to last-known timestamp"
  # (/var/lib/systemd/timesync/clock) runs AFTER the RTC sets the clock, not before.
  boot.initrd.kernelModules = [ "rtc_cmos" ];

  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "ua-utf";

  services.xserver.xkb = {
    layout = "us,ua";
    variant = "";
    options = "grp:win_space_toggle";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  security.polkit = {
    enable = true;
    extraConfig = ''
    // Grant wheel members passwordless access to common desktop actions only.
    // Scoped to: disk management, flatpak, power/suspend, network, colord.
    // For anything else, polkit will prompt for the user's own password as normal.
    polkit.addRule(function(action, subject) {
      var allowed = [
        "org.freedesktop.udisks2.",
        "org.freedesktop.login1.",
        "org.freedesktop.NetworkManager.",
        "org.freedesktop.flatpak.",
        "org.freedesktop.color-manager.",
        "org.freedesktop.packagekit.",
      ];
      if (subject.isInGroup("wheel")) {
        for (var i = 0; i < allowed.length; i++) {
          if (action.id.indexOf(allowed[i]) === 0)
            return polkit.Result.YES;
        }
      }
    });
    '';
  };
  security.rtkit.enable = true;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # nix-ld: FHS compatibility for prebuilt binaries (e.g. the `agy` CLI).
  # Without this, dynamically-linked foreign binaries fail with a misleading
  # "No such file or directory" because /lib64/ld-linux-x86-64.so.2 doesn't
  # exist on NixOS. Extend .libraries if `ldd $(which agy)` reveals more missing .so files.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib   # libstdc++, libgcc_s
    zlib
    openssl
    curl
    icu
    glib
  ];

  # System Fonts & Fontconfig for Waybar, Rofi, Terminal & WM icon glyphs
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      dejavu_fonts
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
        sansSerif = [ "DejaVu Sans" "Noto Color Emoji" ];
        serif = [ "DejaVu Serif" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Memory Optimization: zRAM fast compressed in-memory swap for idle/cold background pages
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Journald RAM & disk usage caps to prevent log cache bloat
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=32M
  '';

  # Passwordless permission for dropping clean kernel page caches via `ram drop-caches`
  security.sudo.extraRules = [
    {
      users = [ "peng" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/sysctl -w vm.drop_caches=3";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.procps}/bin/sysctl -w vm.drop_caches=3";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Standard Linux FHS compatibility for shell shebangs (e.g. #!/usr/bin/env bash, #!/bin/bash)
  system.activationScripts.binbash = {
    text = ''
      mkdir -m 0755 -p /bin /usr/bin
      ln -sfn ${pkgs.bash}/bin/bash /bin/bash
      ln -sfn ${pkgs.bash}/bin/bash /usr/bin/bash
    '';
  };
}
