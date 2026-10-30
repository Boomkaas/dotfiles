{ config, pkgs, inputs, ... }:

{
  services.xserver = {
    enable = true;
  };

  # Display Manager: Ly (TUI on tty1), which lists the niri session.
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "none"; # matrix is green; keep the black-and-white look
      bigclock = true;
      clear_password = true;
    };
  };
  # Ly's PAM unlocks the Secret Service keyring at login (GDM did this itself).
  security.pam.services.ly.enableGnomeKeyring = true;

  # swaylock PAM integration (required for password auth on the lock screen)
  security.pam.services.swaylock = { };

  # Fish shell (system-wide enables vendor completions and man-db)
  programs.fish.enable = true;

  # programs.niri adds xdg-desktop-portal-gnome (screencast) and niri's
  # portal preferences; gtk handles file pickers.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    # Replaces niri's packaged niri-portals.conf. Its gnome FileChooser
    # delegates to Nautilus (not installed), so open/save dialogs never appear.
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };
}
