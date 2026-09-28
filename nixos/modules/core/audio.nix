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
    options snd-hda-intel patch=alc256-vivobook.fw
  '';
}
