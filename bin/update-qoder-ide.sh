#!/usr/bin/env bash
# Update the Qoder IDE (package `qoder-ide`) to the latest version on
# Ubuntu/Debian (amd64). Idempotent: re-running installs nothing when the
# installed build already matches the latest published one.
#
# This is a *different* product from the standalone Qoder app. The vendor ships
# two separate packages that coexist by design:
#   qoder-app -> package `qoder`      , binary /opt/Qoder/qoder      , alternatives priority 100
#   qoder-ide -> package `qoder-ide`  , binary /usr/share/qoder-ide/bin/qoder, priority 60
# The IDE therefore loses the bare `qoder` command but stays installed. Neither
# script removes the other product.
#
# Note: no electron-updater manifest is published for this product, so the
# download URL is pinned to the `latest` release path and the sha256 can only be
# recorded (for staleness detection), not verified against an upstream value.
#
# Usage:
#   update-qoder-ide.sh                # download, compare sha256, install if changed
#   update-qoder-ide.sh --check-only    # print versions and sha256, exit
#   update-qoder-ide.sh --deb FILE      # install from a local .deb instead of downloading
#   update-qoder-ide.sh --force         # reinstall even if already up to date
#   update-qoder-ide.sh --help          # show this header
#
# Note: --check-only still downloads the full .deb (~180 MB) to compute its sha.

set -euo pipefail

PRODUCT_LABEL="Qoder IDE"
MANIFEST_URL=""
DIRECT_URL="https://download.qoder.com/release/latest/qoder-ide_amd64.deb"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/qoder-common.sh"
usage() { awk '/^set -euo pipefail$/{exit} NR>1' "${BASH_SOURCE[0]}"; }
qoder_main "$@"
