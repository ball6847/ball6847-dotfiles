#!/bin/bash
# Shell script to create symlink for alacritty.toml on macOS/Linux
# Creates a symlink from config/alacritty/{macos,linux}.toml to ~/.config/alacritty/alacritty.toml

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

SOURCE_FILE="$SCRIPT_DIR/config/alacritty/$OS.toml"
TARGET_DIR="$HOME/.config/alacritty"
TARGET_FILE="$TARGET_DIR/alacritty.toml"

echo "Alacritty Symlink Creation Script"
echo "=================================="
echo "Source file: $SOURCE_FILE"
echo "Target file: $TARGET_FILE"
echo ""

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file does not exist: $SOURCE_FILE" >&2
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating target directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    echo "  ✓ Directory created"
    echo ""
fi

# Remove existing file if it exists
if [ -e "$TARGET_FILE" ]; then
    echo "Target file exists: $TARGET_FILE"
    echo "Removing existing file..."
    rm -f "$TARGET_FILE"
    echo "  ✓ File removed"
    echo ""
fi

# Create symlink
echo "Creating symlink..."
ln -sf "$SOURCE_FILE" "$TARGET_FILE"
echo "  ✓ Symlink created: $TARGET_FILE -> $SOURCE_FILE"
echo ""

echo "Operation completed successfully!"
echo "Alacritty will now use the configuration file from: $SOURCE_FILE"
