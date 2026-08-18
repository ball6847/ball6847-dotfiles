#!/usr/bin/env bash
# Unlock the GNOME screen for the current user's graphical session.
# Usage: unlock-screen.sh

set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"

# Find the graphical session on seat0 for this user (the physical screen).
SES="$(loginctl list-sessions --no-legend | awk -v u="$USER_NAME" '$3==u && /seat0/{print $1; exit}')"

if [ -z "$SES" ]; then
    echo "No seat0 session found for user '$USER_NAME'." >&2
    exit 1
fi

echo "Unlocking session $SES ..."
loginctl unlock-session "$SES"

sleep 1

STATE="$(loginctl show-session "$SES" -p LockedHint --value)"
if [ "$STATE" = "no" ]; then
    echo "OK: screen unlocked."
else
    echo "WARNING: still locked (LockedHint=$STATE)."
    echo "If this is a Wayland session, try running as root: sudo $0"
    exit 1
fi
