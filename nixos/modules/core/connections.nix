{ config, pkgs, inputs, ... }:

{
  networking.hostName = "peng";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8080 ]; # 5432 removed: PostgreSQL is localhost-only, no firewall exposure needed
  };

  boot.kernel.sysctl = {
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 3;
    "net.ipv4.tcp_retries2" = 5;
    # Memory: keep pages in RAM longer — reduces premature swapping on 7.6 GiB system
    # (default swappiness=60 caused 670 MiB in swap while 2.3 GiB RAM was available)
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
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
      LE = { EnableAdvMonInterleaveScan = "1"; }; # was "true" — bluetoothd expects integer, not string
    };
  };

  services.blueman.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
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
