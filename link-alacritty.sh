#!/bin/bash
# Shell script to create symlinks for alacritty config on macOS/Linux
# Symlinks the entire config/alacritty directory to ~/.config/alacritty
# Then creates alacritty.toml as a symlink to {macos,linux}.toml

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
TARGET_FILE="$TARGET_DIR/alacritty.toml"
SOURCE_FILE="$SOURCE_DIR/$OS.toml"

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

# Check if platform file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Platform config file does not exist: $SOURCE_FILE" >&2
    exit 1
fi

# Remove existing target if it exists (file or directory)
if [ -e "$TARGET_DIR" ]; then
    echo "Target exists: $TARGET_DIR"
    echo "Removing existing target..."
    rm -rf "$TARGET_DIR"
    echo "  ✓ Target removed"
    echo ""
fi

# Create symlink for the directory
echo "Creating directory symlink..."
ln -sf "$SOURCE_DIR" "$TARGET_DIR"
echo "  ✓ Directory symlink created: $TARGET_DIR -> $SOURCE_DIR"
echo ""

# Remove the alacritty.toml symlink that was created as part of the directory symlink
# (the directory symlink will have created a symlink to $OS.toml as alacritty.toml)
if [ -L "$TARGET_FILE" ]; then
    rm -f "$TARGET_FILE"
fi

# Create symlink for alacritty.toml -> $OS.toml
echo "Creating alacritty.toml symlink..."
ln -sf "$SOURCE_FILE" "$TARGET_FILE"
echo "  ✓ File symlink created: $TARGET_FILE -> $SOURCE_FILE"
echo ""

echo "Operation completed successfully!"
echo "Alacritty will now use the configuration from: $SOURCE_FILE"
