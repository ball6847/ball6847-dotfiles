#!/usr/bin/env bash
# Prepare this machine for remote RDP access:
#   1. Unlock the GNOME screen (RDP refuses to start while locked)
#   2. Ensure gnome-remote-desktop is running
#   3. Print the Tailscale IP + RDP connection details
# Usage: rdp-up.sh

set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 1/3 Unlocking screen ..."
if [ -x "$BIN_DIR/unlock-screen.sh" ]; then
    "$BIN_DIR/unlock-screen.sh" || { echo "unlock failed"; exit 1; }
else
    echo "unlock-screen.sh not found in $BIN_DIR; skipping." >&2
fi

echo "==> 2/3 Ensuring gnome-remote-desktop is running ..."
if ! systemctl --user is-active gnome-remote-desktop.service >/dev/null 2>&1; then
    systemctl --user start gnome-remote-desktop.service
    echo "started gnome-remote-desktop.service"
else
    echo "already active"
fi

echo "==> 3/3 Connection details ..."
PORT="$(grdctl status 2>/dev/null | awk '/^[[:space:]]*Port:/{print $2; exit}')"
PORT="${PORT:-3389}"
TS_IP="$(tailscale ip -4 2>/dev/null | head -1 || true)"

if [ -n "$TS_IP" ]; then
    echo "  Connect (RDP):  $TS_IP:$PORT"
else
    echo "  Tailscale not up; use your LAN IP. RDP port: $PORT"
fi

echo ""
echo "NOTE: the screen stays unlocked (RDP needs it). Lock it after with:"
echo "  $BIN_DIR/lock-screen.sh"
