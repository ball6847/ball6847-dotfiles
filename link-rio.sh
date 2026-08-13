#!/usr/bin/env bash
# Universal macOS + Linux symlink script for Rio config (sibling of link-rio.ps1).
#
# Links the per-OS config file to rio's config.toml location:
#   Linux  -> linux.toml  (renderer.backend = "Vulkan")
#   macOS  -> macos.toml  (renderer.backend = "Metal")
#   Windows -> use link-rio.ps1 (windows.toml)
#
# Rio only reads config.toml, so this mirrors what link-rio.ps1 does on Windows.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source_dir="$repo_dir/config/rio"

# 1. Detect OS
case "$(uname -s)" in
  Darwin) os="macos" ;;
  Linux)  os="linux" ;;
  *)
    echo "error: unsupported OS '$(uname -s)' — use link-rio.ps1 on Windows" >&2
    exit 1
    ;;
esac

# 2. Pick source file
source_file="$source_dir/$os.toml"
if [ ! -f "$source_file" ]; then
  echo "error: source file not found: $source_file" >&2
  exit 1
fi

# 3. Determine rio config dir (mirrors rio's own resolution in rio-backend)
#    macOS: RIO_CONFIG_HOME or ~/.config/rio
#    Linux: RIO_CONFIG_HOME or $XDG_CONFIG_HOME/rio or ~/.config/rio
if [ -n "${RIO_CONFIG_HOME:-}" ]; then
  config_dir="$RIO_CONFIG_HOME"
elif [ "$os" = "linux" ] && [ -n "${XDG_CONFIG_HOME:-}" ]; then
  config_dir="$XDG_CONFIG_HOME/rio"
else
  config_dir="$HOME/.config/rio"
fi
target_file="$config_dir/config.toml"

echo "Rio Symlink Script ($os)"
echo "========================"
echo "Source file: $source_file"
echo "Target file: $target_file"
echo ""

# 4. Create config dir if missing
mkdir -p "$config_dir"

# 5. Already linked? (idempotent)
physical() { (cd "$1" 2>/dev/null && pwd -P); }
if [ -L "$target_file" ]; then
  link="$(readlink "$target_file")"
  if [ "${link#/}" != "$link" ]; then
    current="$(physical "$(dirname "$link")")/$(basename "$link")"
  else
    current="$(physical "$(dirname "$target_file")/$link")"
  fi
  if [ "$current" = "$source_file" ]; then
    echo "already linked: $target_file -> $source_file"
    exit 0
  fi
fi

# 6. Link. If the config dir itself resolves into the repo (install.sh symlinks
#    the whole config/rio dir), use a relative symlink so the repo stays portable.
if [ "$(physical "$config_dir")" = "$(physical "$source_dir")" ]; then
  rel_target="$(basename "$source_file")"
  rm -f "$target_file"
  ln -s "$rel_target" "$target_file"
  echo "linked: $target_file -> $rel_target"
else
  rm -f "$target_file"
  ln -s "$source_file" "$target_file"
  echo "linked: $target_file -> $source_file"
fi

echo "Operation completed successfully!"
echo "Rio configuration is now linked."
