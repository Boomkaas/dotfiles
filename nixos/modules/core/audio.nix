{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    audio.enable = true;
    jack.enable = true;

    # Real-time WebRTC noise cancellation, echo suppression, and high-pass DC filtering
    extraConfig.pipewire."99-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "library.name" = "aec/libspa-aec-webrtc";
            "monitor.mode" = false;
            "capture.props" = {
              "node.name" = "echo_cancel_capture";
              "node.description" = "Echo-Cancellation Capture";
            };
            "source.props" = {
              "node.name" = "echo_cancel_source";
              "node.description" = "Noise-Suppressed Microphone";
              "priority.session" = 3000;
            };
          };
        }
      ];
    };

    # Prevent Bluetooth devices from suspending when idle and prevent autoswitching to low-quality headset profile
    wireplumber.extraConfig."10-bluez" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
      "monitor.bluez.rules" = [
        {
          matches = [
            {
              "node.name" = "~bluez_.*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };

  # Ensure ALC256 internal microphone hardware boost stays at 0 dB on startup to prevent saturation
  systemd.user.services.calibrate-mic = {
    description = "Calibrate ALC256 microphone boost gain";
    wantedBy = [ "pipewire.service" ];
    after = [ "pipewire.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -c 0 cset numid=13 0";
      RemainAfterExit = true;
    };
  };

  # Fix for Realtek ALC256 internal microphone on ASUS VivoBook laptops
  # Pin 0x13 is a disconnected phantom pin added by the kernel quirk that PipeWire prefers.
  # Marking pin 0x13 as disabled and keeping headset-jack mic on 0x19 lets pin 0x1b (the real mic) be used.
  hardware.firmware = [
    (pkgs.writeTextDir "lib/firmware/alc256-vivobook.fw" ''
      [codec]
      0x10ec0256 0x10431b12 0

      [pincfg]
      0x13 0x411111f0
      0x19 0x04a11120
    '')
  ];

  boot.extraModprobeConfig = ''
    options snd-hda-intel patch=alc256-vivobook.fw power_save=0
  '';
}
