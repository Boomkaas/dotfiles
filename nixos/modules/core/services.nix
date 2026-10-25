{ config, pkgs, ... }:

{
  services.printing.enable = true;
  services.flatpak.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  # Secret Service for Zed's credentials (sign-in, AI provider keys); GDM's PAM unlocks it at login.
  services.gnome.gnome-keyring.enable = true;
  services.udev.packages = [ pkgs.android-udev-rules ];
  services.udev.extraRules = ''
    KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess"
    KERNEL=="rtc0", SUBSYSTEM=="rtc", TAG+="uaccess", GROUP="wheel", MODE="0660"
    SUBSYSTEM=="rtc", KERNEL=="rtc0", ATTR{wakealarm}!="", GROUP="wheel", MODE="0664"
  '';

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false; # docker.socket starts it on first use
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
        "smb2 leases" = "no";
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
        "csc policy" = "disable";
      };
      "Code" = {
        "path" = "/home/peng/Code";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "peng";
        "hosts allow" = "192.168.122. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "peng";
        "csc policy" = "disable";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
      "workspace" = {
        "path" = "/home/peng/Code";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "peng";
        "hosts allow" = "192.168.122. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "peng";
        "csc policy" = "disable";
        "oplocks" = "no";
        "level2 oplocks" = "no";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/logmein-hamachi 0755 root root -"
    "f+ /var/lib/logmein-hamachi/h2-engine-override.cfg 0644 root root - Ipc.User peng\n"
  ];

  # Disable boot autostart for Hamachi & Samba — operated on-demand via 'share' menu
  systemd.targets.samba.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.samba-smbd.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.samba-nmbd.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.samba-winbindd.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.samba-wsdd.wantedBy = pkgs.lib.mkForce [ ];

  # Disable boot autostart for libvirt & PostgreSQL — libvirtd.socket starts libvirtd on demand
  # (virt-manager/virsh); start PostgreSQL with: sudo systemctl start postgresql
  systemd.services.libvirtd.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.libvirt-guests.wantedBy = pkgs.lib.mkForce [ ];
  systemd.services.postgresql.wantedBy = pkgs.lib.mkForce [ ];

  systemd.services.logmein-hamachi = {
    wantedBy = pkgs.lib.mkForce [ ];
    preStart = ''
      mkdir -p /var/lib/logmein-hamachi
      echo "Ipc.User peng" > /var/lib/logmein-hamachi/h2-engine-override.cfg
      chmod 0644 /var/lib/logmein-hamachi/h2-engine-override.cfg
    '';
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
  # hypridle PATH is set via Service.Environment in configuration.nix (single source of truth)
}

