#!/usr/bin/env bash
# Update the standalone Qoder app (package `qoder`) to the latest version on
# Ubuntu/Debian (amd64). Idempotent: re-running installs nothing when the
# installed build already matches the current release.
#
# Source of truth: the official electron-updater manifest
#   https://download.qoder.com/qoder-app/releases/latest-linux.yml
# which names the current version, the .deb URL, and that .deb's sha256.
#
# This is the standalone product that owns /usr/bin/qoder (alternatives
# priority 100). It coexists with the separate `qoder-ide` package; update that
# one with bin/update-qoder-ide.sh.
#
# Usage:
#   update-qoder.sh                # fetch manifest, verify sha256, install if changed
#   update-qoder.sh --check-only   # fetch manifest + deb, print versions, exit
#   update-qoder.sh --deb FILE     # install from a local .deb instead of downloading
#   update-qoder.sh --force        # reinstall even if already up to date
#   update-qoder.sh --help         # show this header
#
# Note: --check-only still downloads the full .deb (~200 MB) to compute its sha.

set -euo pipefail

PRODUCT_LABEL="Qoder (standalone app)"
MANIFEST_URL="https://download.qoder.com/qoder-app/releases/latest-linux.yml"
DIRECT_URL="https://download.qoder.com/qoder-app/releases/latest/Qoder-linux-amd64.deb"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/qoder-common.sh"
usage() { awk '/^set -euo pipefail$/{exit} NR>1' "${BASH_SOURCE[0]}"; }
qoder_main "$@"
