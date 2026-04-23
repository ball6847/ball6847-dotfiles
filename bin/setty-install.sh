#!/usr/bin/env bash
set -euo pipefail

# Fetch latest release metadata
release_json=$(curl -fsSL https://api.github.com/repos/Satty-org/Satty/releases/latest)

# Extract latest version tag
latest_version=$(echo "$release_json" | grep -o '"tag_name": "[^"]*"' | head -n 1 | cut -d '"' -f4 | sed 's/^v//')
if [[ -z "$latest_version" ]]; then
    echo "Failed to determine latest version." >&2
    exit 1
fi
echo "Latest version: $latest_version"

# Check currently installed version
if command -v satty >/dev/null 2>&1; then
    current_version=$(satty --version 2>/dev/null | awk '{print $NF}' || true)
    echo "Installed version: $current_version"

    if [[ "$current_version" == "$latest_version" ]]; then
        echo "satty is already up-to-date ($latest_version)."
        exit 0
    fi
fi

# Get download URL for Linux x86_64 tarball
download_url=$(echo "$release_json" \
    | grep "browser_download_url" \
    | grep "x86_64" \
    | grep "linux" \
    | grep ".tar.gz" \
    | cut -d '"' -f 4 \
    | head -n 1)

if [[ -z "$download_url" ]]; then
    echo "Failed to find a suitable download URL." >&2
    exit 1
fi

# Create isolated temp directory so repeated runs don’t collide
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

basename=$(basename "$download_url")

echo "Downloading $basename..."
curl -fsSL -o "$tmpdir/$basename" "$download_url"

# Ensure the target bin directory exists
mkdir -p ~/.local/bin

# Extract and install
tar -xzf "$tmpdir/$basename" -C ~/.local/bin --strip-components=1 ./satty

echo "satty installed successfully."
satty --version
