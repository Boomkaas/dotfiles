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

  # Fix for Realtek ALC256 microphone issues (common on ASUS laptops like VivoBook X409FA)
  # Forces the driver to map the audio pins correctly for the internal and headset mic.
  # If alc256-asus-mic does not work after reboot, other options you can try:
  # - "options snd-hda-intel model=dell-headset-multi"
  # - "options snd-hda-intel model=headset-mic"
  # - "options snd-hda-intel model=alc256-asus"
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=alc256-asus-mic
  '';
}
