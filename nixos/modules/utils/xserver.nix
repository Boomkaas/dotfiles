{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;
  };

  # Display Manager: GDM
  # GDM properly supports Wayland session packages (MangoWM, Hyprland).
  # 'ly' was launching MangoWM as an X11 session without $DISPLAY, causing
  # the gray screen + "Failed to open config file: /etc/mango/config.conf" error.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;

  # Hyprlock PAM integration (required for password auth on lock screen)
  programs.hyprlock.enable = true;

  # Fish shell (system-wide enables vendor completions and man-db)
  programs.fish.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
}
