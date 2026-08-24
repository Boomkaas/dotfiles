#!/usr/bin/env bash
# run-epic.sh — wrapper for vogler/free-games-claimer (Epic Games weekly freebies)
#
# Secrets (EG_EMAIL, EG_PASSWORD, EG_OTPKEY) are sourced from a local,
# untracked config file — they are NEVER stored in the nix store.
#
# Place your credentials in: ~/free-games-claimer/data/config.env
# Example config.env:
#   EG_EMAIL=you@example.com
#   EG_PASSWORD=yourpassword
#   EG_OTPKEY=YOUROTPBASE32KEY   # only if you use TOTP 2FA

set -euo pipefail

CLAIMER_DIR="$HOME/free-games-claimer"
CONFIG_ENV="$CLAIMER_DIR/data/config.env"
LOG_FILE="$CLAIMER_DIR/data/epic.log"

# On NixOS, Playwright's bundled Firefox needs libs from nix-ld.
# nix-ld provides these at runtime via the ELF interpreter, but Playwright's
# pre-flight ldd-based check doesn't see them — explicitly add them here.
NIX_LD_LIBS="/run/current-system/sw/share/nix-ld/lib"
if [ -d "$NIX_LD_LIBS" ]; then
  export LD_LIBRARY_PATH="${NIX_LD_LIBS}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

if [ ! -d "$CLAIMER_DIR" ]; then
  echo "[run-epic] ERROR: $CLAIMER_DIR not found. Clone it first:" >&2
  echo "  git clone https://github.com/vogler/free-games-claimer.git $CLAIMER_DIR && cd $CLAIMER_DIR && npm install && npx playwright install firefox" >&2
  exit 1
fi

if [ -f "$CONFIG_ENV" ]; then
  # shellcheck disable=SC1090
  set -a; source "$CONFIG_ENV"; set +a
fi

cd "$CLAIMER_DIR"
echo "[run-epic] $(date -Iseconds) — starting claim run" >> "$LOG_FILE"
node epic-games >> "$LOG_FILE" 2>&1
echo "[run-epic] $(date -Iseconds) — done" >> "$LOG_FILE"
