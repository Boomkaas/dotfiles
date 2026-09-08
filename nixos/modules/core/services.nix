{ config, pkgs, ... }:

{
  services.printing.enable = true;
  services.flatpak.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.udev.packages = [ pkgs.android-udev-rules ];
  services.udev.extraRules = ''
    KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess"
    KERNEL=="rtc0", SUBSYSTEM=="rtc", TAG+="uaccess", GROUP="wheel", MODE="0660"
    SUBSYSTEM=="rtc", KERNEL=="rtc0", ATTR{wakealarm}!="", GROUP="wheel", MODE="0664"
  '';

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.waydroid.enable = true;

  programs.virt-manager.enable = true;
  programs.dconf.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      host  all       all     127.0.0.1/32   trust
      host  all       all     ::1/128        trust
    '';
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "hosts allow" = "192.168.122. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "workspace" = {
        "path" = "/home/peng/Code";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "peng";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Automated hardware-waking night presence check (01:00 - 08:00)
  systemd.services.night-presence-check = {
    description = "Check user presence between 01:00 and 08:00 before auto-shutdown";
    path = [ pkgs.bash pkgs.coreutils pkgs.systemd pkgs.util-linux pkgs.libnotify pkgs.shadow ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/peng/Code/Dotfiles/nixos/scripts/night_presence_check.sh";
    };
  };

  systemd.timers.night-presence-check = {
    description = "Night presence check timer (wakes machine from suspend)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [
        "*-*-* 01..07:00,30:00"
        "*-*-* 08:00:00"
      ];
      WakeSystem = true;
      Persistent = false;
    };
  };

  # Ensure hypridle systemd user service includes bash, utilities, and compositor tools in PATH
  systemd.user.services.hypridle.path = [
    pkgs.bash
    pkgs.coreutils
    pkgs.procps
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.systemd
    pkgs.gawk
    pkgs.jq
    pkgs.libnotify
    pkgs.util-linux
  ];
}

