#!/usr/bin/env bash
# Shared implementation for update-qoder.sh and update-qoder-ide.sh.
#
# The sourcing wrapper must define, before calling qoder_main:
#   PRODUCT_LABEL  human-readable name shown in logs, e.g. "Qoder"
#   MANIFEST_URL   electron-updater `latest-linux.yml` URL, or "" if none is published
#   DIRECT_URL     .deb URL; used directly when MANIFEST_URL is empty, else as fallback
# and must define its own usage() (called for --help).

LOG() { printf '\033[1;34m[%s]\033[0m %s\n' "${PROG%.sh}" "$*" >&2; }
DIE() { printf '\033[1;31m[%s]\033[0m %s\n' "${PROG%.sh}" "$*" >&2; exit 1; }

qoder_main() {
  local CHECK_ONLY=0 LOCAL_DEB="" FORCE=0
  PROG="$(basename "${BASH_SOURCE[1]:-$0}")"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check-only|-n) CHECK_ONLY=1; shift ;;
      --deb) [[ -n "${2:-}" ]] || DIE "--deb requires a file path"; LOCAL_DEB="$2"; shift 2 ;;
      --deb=*) LOCAL_DEB="${1#--deb=}"; shift ;;
      --force|-f) FORCE=1; shift ;;
      --help|-h) usage; exit 0 ;;
      --) shift; break ;;
      -*) DIE "Unknown arg: $1 (try --help)" ;;
      *)  DIE "Unknown arg: $1 (try --help)" ;;
    esac
  done

  local ARCH
  ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
  [[ "$ARCH" == amd64 || "$ARCH" == x86_64 ]] || DIE "Unsupported arch: $ARCH (only amd64)"

  local WORKDIR DEB
  WORKDIR="${TMPDIR:-/tmp}/qoder-update.$$"
  mkdir -p "$WORKDIR"
  trap 'rm -rf "$WORKDIR"' EXIT
  DEB="$WORKDIR/qoder.deb"

  local MANIFEST_VER="" DOWNLOAD_URL="" EXPECTED_SHA=""
  if [[ -n "$LOCAL_DEB" ]]; then
    [[ -f "$LOCAL_DEB" ]] || DIE "No such file: $LOCAL_DEB"
    LOG "Using local package: $LOCAL_DEB"
    cp -- "$LOCAL_DEB" "$DEB"
  else
    if [[ -n "$MANIFEST_URL" ]]; then
      LOG "Fetching $MANIFEST_URL"
      local MANIFEST
      MANIFEST="$(curl -fsSL --retry 2 --connect-timeout 15 "$MANIFEST_URL" 2>/dev/null || true)"
      if [[ -n "$MANIFEST" ]]; then
        MANIFEST_VER="$(printf '%s\n' "$MANIFEST" | awk '/^version:/{print $2; exit}')"
        DOWNLOAD_URL="$(printf '%s\n' "$MANIFEST" | awk '/url:.*\.deb$/{sub(/^.*url:[[:space:]]*/,""); print; exit}')"
        EXPECTED_SHA="$(printf '%s\n' "$MANIFEST" | awk '/url:.*\.deb$/{f=1} f && /sha256:/{print $2; exit}')"
      fi
      if [[ -z "$DOWNLOAD_URL" ]]; then
        LOG "Manifest unavailable/unparseable; using fallback URL (sha not verifiable)."
        DOWNLOAD_URL="$DIRECT_URL"
      fi
    else
      DOWNLOAD_URL="$DIRECT_URL"
      LOG "No upstream manifest published; checksum cannot be verified."
    fi
    LOG "Downloading $DOWNLOAD_URL"
    curl -fsSL --retry 3 --connect-timeout 15 -o "$DEB" "$DOWNLOAD_URL"
  fi

  [[ -s "$DEB" ]] || DIE "Downloaded file is empty"
  file "$DEB" | grep -qi 'debian binary package' || DIE "Downloaded file is not a .deb"

  local DEB_SHA
  DEB_SHA="$(sha256sum "$DEB" | cut -d' ' -f1)"
  if [[ -n "$EXPECTED_SHA" ]]; then
    [[ "$DEB_SHA" == "$EXPECTED_SHA" ]] || \
      DIE "sha256 mismatch for $DOWNLOAD_URL: expected $EXPECTED_SHA, got $DEB_SHA"
    LOG "sha256 verified: $DEB_SHA"
  else
    LOG "sha256: $DEB_SHA (not verified)"
  fi

  local PKG LATEST_VERSION INSTALLED_VERSION
  PKG="$(dpkg-deb -f "$DEB" Package 2>/dev/null || echo unknown)"
  [[ "$PKG" != unknown ]] || DIE "Cannot read Package from downloaded .deb"
  LATEST_VERSION="$(dpkg-deb -f "$DEB" Version 2>/dev/null || echo unknown)"
  [[ -n "$MANIFEST_VER" ]] || MANIFEST_VER="$LATEST_VERSION"
  INSTALLED_VERSION="$(dpkg-query -W -f='${Version}' "$PKG" 2>/dev/null || echo none)"

  local CACHE_DIR CACHE_FILE CACHED_SHA
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/${PKG}"
  CACHE_FILE="$CACHE_DIR/installed.sha256"
  CACHED_SHA=""
  [[ -r "$CACHE_FILE" ]] && CACHED_SHA="$(cat "$CACHE_FILE")"

  LOG "Product:   $PRODUCT_LABEL (package $PKG)"
  LOG "Latest:    $MANIFEST_VER ($LATEST_VERSION)"
  LOG "Installed: $INSTALLED_VERSION"
  LOG "Cached sha: ${CACHED_SHA:-<none>}"

  if [[ $CHECK_ONLY -eq 1 ]]; then
    echo "package=$PKG latest=$MANIFEST_VER deb_version=$LATEST_VERSION installed=$INSTALLED_VERSION sha256=$DEB_SHA"
    exit 0
  fi

  # Latest iff installed AND this run's sha matches the sha recorded at the last
  # install. With no cache file we reinstall once (self-healing).
  local STALE=1
  if [[ $FORCE -eq 0 && "$INSTALLED_VERSION" != "none" \
        && -n "$CACHED_SHA" && "$CACHED_SHA" == "$DEB_SHA" ]]; then
    STALE=0
  fi

  if [[ $STALE -eq 0 ]]; then
    LOG "Already up to date ($PKG $INSTALLED_VERSION, sha ${DEB_SHA:0:12}); nothing to install."
  else
    local SUDO
    if [[ $EUID -eq 0 ]]; then
      SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
      # No TTY (e.g. launched from a GUI launcher)? Use zenity askpass for a GUI prompt.
      if [[ ! -t 0 ]] && [[ -z "${SUDO_ASKPASS:-}" ]]; then
        local ASKPASS
        ASKPASS="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")/.." && pwd)/lib/zenity-askpass.sh"
        if [[ -x "$ASKPASS" ]] && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
          export SUDO_ASKPASS="$ASKPASS"
          SUDO="sudo -A"
          LOG "No TTY; will prompt for sudo password via GUI (zenity)."
        fi
      fi
    else
      DIE "Need root to install; sudo not found."
    fi
    LOG "Installing $PKG $MANIFEST_VER"
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$DEB"
    # Refresh launcher/icon caches so entries show without a re-login. Best-effort.
    if command -v update-desktop-database >/dev/null 2>&1; then
      $SUDO update-desktop-database -q /usr/share/applications 2>/dev/null || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
      $SUDO gtk-update-icon-cache -qtf /usr/share/icons/hicolor 2>/dev/null || true
    fi
    # Record the installed sha so the next run is a true no-op.
    mkdir -p "$CACHE_DIR" && printf '%s\n' "$DEB_SHA" >"$CACHE_FILE" || true
  fi

  dpkg-query -W -f='${Package} ${Version} ${Status}\n' "$PKG" 2>/dev/null | head -1 || true
  LOG "Done."
}
