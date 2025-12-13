#!/bin/bash
# Shell script to create symlinks for alacritty config on macOS/Linux
# Creates ~/.config/alacritty directory and symlinks config files into it

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "Unsupported OS: $OSTYPE" >&2
    exit 1
fi

SOURCE_DIR="$SCRIPT_DIR/config/alacritty"
TARGET_DIR="$HOME/.config/alacritty"
PLATFORM_FILE="$OS.toml"

echo "Alacritty Symlink Creation Script"
echo "=================================="
echo "Source directory: $SOURCE_DIR"
echo "Target directory: $TARGET_DIR"
echo "Platform: $OS"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR" >&2
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating target directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    echo "  ✓ Directory created"
    echo ""
fi

# Symlink common.toml
COMMON_SOURCE="$SOURCE_DIR/common.toml"
COMMON_TARGET="$TARGET_DIR/common.toml"
if [ -e "$COMMON_TARGET" ]; then
    rm -f "$COMMON_TARGET"
fi
echo "Creating common.toml symlink..."
ln -sf "$COMMON_SOURCE" "$COMMON_TARGET"
echo "  ✓ common.toml -> $COMMON_SOURCE"

# Symlink platform file (macos.toml or linux.toml)
PLATFORM_SOURCE="$SOURCE_DIR/$PLATFORM_FILE"
PLATFORM_TARGET="$TARGET_DIR/$PLATFORM_FILE"
if [ ! -f "$PLATFORM_SOURCE" ]; then
    echo "Error: Platform config file does not exist: $PLATFORM_SOURCE" >&2
    exit 1
fi
if [ -e "$PLATFORM_TARGET" ]; then
    rm -f "$PLATFORM_TARGET"
fi
echo "Creating $PLATFORM_FILE symlink..."
ln -sf "$PLATFORM_SOURCE" "$PLATFORM_TARGET"
echo "  ✓ $PLATFORM_FILE -> $PLATFORM_SOURCE"

# Symlink alacritty.toml -> platform file
ALACRITTY_TARGET="$TARGET_DIR/alacritty.toml"
if [ -e "$ALACRITTY_TARGET" ]; then
    rm -f "$ALACRITTY_TARGET"
fi
echo "Creating alacritty.toml symlink..."
ln -sf "$PLATFORM_SOURCE" "$ALACRITTY_TARGET"
echo "  ✓ alacritty.toml -> $PLATFORM_SOURCE"

# Symlink alacritty-theme directory for theme imports
THEME_SOURCE="$SCRIPT_DIR/alacritty-theme"
THEME_TARGET="$TARGET_DIR/alacritty-theme"
if [ -d "$THEME_SOURCE" ]; then
    if [ -e "$THEME_TARGET" ]; then
        rm -rf "$THEME_TARGET"
    fi
    echo "Creating alacritty-theme directory symlink..."
    ln -sf "$THEME_SOURCE" "$THEME_TARGET"
    echo "  ✓ alacritty-theme -> $THEME_SOURCE"
else
    echo "  ⚠ alacritty-theme directory not found at $THEME_SOURCE"
fi
echo ""

echo "Operation completed successfully!"
echo "Alacritty configuration is now linked."
