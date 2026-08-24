{ config, pkgs, ... }:

# systemd user service + daily timer for vogler/free-games-claimer
# https://github.com/vogler/free-games-claimer
#
# Prerequisites (one-time manual setup):
#   git clone https://github.com/vogler/free-games-claimer.git ~/free-games-claimer
#   cd ~/free-games-claimer
#   npm install
#   npx playwright install firefox --with-deps
#   SHOW=1 node epic-games    # log in + solve captcha once; cookies saved to data/browser/
#
# Secrets go in ~/free-games-claimer/data/config.env (never committed):
#   EG_EMAIL=you@example.com
#   EG_PASSWORD=yourpassword
#   EG_OTPKEY=BASE32KEY         # only if you use TOTP 2FA

{
  home-manager.users.peng = { ... }: {
    systemd.user.services.epic-free-games = {
      Unit = {
        Description = "Claim free Epic Games weekly freebies";
        After = [ "network-online.target" "graphical-session.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "/home/peng/Code/Dotfiles/nixos/scripts/run-epic.sh";
        # Run inside a proper user session so Firefox/Playwright can find $DISPLAY/$WAYLAND_DISPLAY
        # if ever needed for SHOW=1 debugging
        StandardOutput = "journal";
        StandardError  = "journal";
      };
    };

    systemd.user.timers.epic-free-games = {
      Unit = {
        Description = "Daily timer: claim Epic Games free games";
      };
      Timer = {
        # Run daily at 12:30 — staggered to avoid thundering-herd with other people's cron jobs
        OnCalendar = "*-*-* 12:30:00";
        # If the system was off at 12:30, run as soon as it comes back up
        Persistent = true;
        # Randomise start up to 10 minutes to be a polite bot
        RandomizedDelaySec = "10min";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
