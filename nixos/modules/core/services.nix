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

  programs.virt-manager.enable = true;
  programs.dconf.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      # peer: Unix socket — OS user must match DB user (peng→peng works, no password needed)
      local all       all     peer
      # scram-sha-256: TCP loopback — set passwords via: sudo -u postgres psql -c "ALTER USER <name> PASSWORD '<pw>'"
      host  all       all     127.0.0.1/32   scram-sha-256
      host  all       all     ::1/128        scram-sha-256
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
        "hosts allow" = "192.168. 10. 172.16. 25. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "Shared" = {
        "path" = "/home/peng/Shared";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "peng";
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

  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;

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
  # hypridle PATH is set via Service.Environment in configuration.nix (single source of truth)
}

