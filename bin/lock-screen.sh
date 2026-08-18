#!/usr/bin/env bash
# Lock the GNOME screen for the current user's graphical session.
# Usage: lock-screen.sh

set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"

SES="$(loginctl list-sessions --no-legend | awk -v u="$USER_NAME" '$3==u && /seat0/{print $1; exit}')"

if [ -z "$SES" ]; then
    echo "No seat0 session found for user '$USER_NAME'." >&2
    exit 1
fi

echo "Locking session $SES ..."
loginctl lock-session "$SES"

sleep 1

STATE="$(loginctl show-session "$SES" -p LockedHint --value)"
if [ "$STATE" = "yes" ]; then
    echo "OK: screen locked."
else
    echo "WARNING: still unlocked (LockedHint=$STATE)."
    echo "If this is a Wayland session, try running as root: sudo $0"
    exit 1
fi
