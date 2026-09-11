{ config, pkgs, inputs, ... }:

{
  networking.hostName = "peng";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8080 5432 ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_retries2" = 5;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Name = "peng";
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = { AutoEnable = "true"; };
      LE = { EnableAdvMonInterleaveScan = "true"; };
    };
  };

  services.blueman.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-cli;
  };

  systemd.services.unblock-bluetooth = {
    description = "Unblock Bluetooth using rfkill";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      RemainAfterExit = true;
    };
  };
}
