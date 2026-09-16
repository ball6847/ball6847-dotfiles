#!/bin/sh
# sudo askpass helper — shows a GTK password dialog via zenity.
# Used as: SUDO_ASKPASS=askpass.sh sudo -A <cmd...>
# Exits non-zero if user cancels or no GUI is available.
if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  zenity --password --title="sudo password required" --text="Enter your password to update Qoder:" 2>/dev/null && exit 0
  exit 1
fi
if command -v kdialog >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  kdialog --password "Enter your password to update Qoder:" && exit 0
  exit 1
fi
exit 1
