#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 Setting up protoc symlink..."

# Define target directory
TARGET_DIR="$HOME/.local/bin"
TARGET_PATH="$TARGET_DIR/protoc"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Find protoc using which command
if command -v protoc >/dev/null 2>&1; then
    PROTOC_PATH=$(which protoc)
    echo "📍 Found protoc at: $PROTOC_PATH"
else
    echo -e "${RED}❌ protoc not found in PATH${NC}"
    echo "💡 Please install protoc first:"
    echo "   macOS: brew install protobuf"
    echo "   Ubuntu/Debian: sudo apt install protobuf-compiler"
    echo "   Other: Check https://grpc.io/docs/protoc-installation/"
    exit 1
fi

echo "📍 Using protoc from: $PROTOC_PATH"

# Remove existing symlink if it exists
if [[ -L "$TARGET_PATH" ]]; then
    echo "🗑️  Removing existing symlink..."
    rm "$TARGET_PATH"
elif [[ -f "$TARGET_PATH" ]]; then
    echo -e "${YELLOW}⚠️  Warning: $TARGET_PATH exists and is not a symlink${NC}"
    read -p "Remove it and create symlink? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$TARGET_PATH"
    else
        echo -e "${RED}❌ Aborted${NC}"
        exit 1
    fi
fi

# Create the symlink
echo "🔗 Creating symlink: $TARGET_PATH -> $PROTOC_PATH"
ln -s "$PROTOC_PATH" "$TARGET_PATH"

# Verify the symlink works
if [[ -x "$TARGET_PATH" ]]; then
    echo -e "${GREEN}✅ Symlink created successfully!${NC}"
    
    # Test the symlink
    echo "🧪 Testing symlink..."
    PROTOC_VERSION=$("$TARGET_PATH" --version 2>/dev/null || echo "Failed to get version")
    echo "📋 protoc version: $PROTOC_VERSION"
    
    # Check if ~/.local/bin is in PATH
    if echo "$PATH" | grep -q "$HOME/.local/bin\|$TARGET_DIR"; then
        echo -e "${GREEN}✅ $TARGET_DIR is in your PATH${NC}"
        echo -e "${GREEN}🎉 Setup complete! You can now use 'protoc' from anywhere.${NC}"
    else
        echo -e "${YELLOW}⚠️  $TARGET_DIR is not in your PATH${NC}"
        echo "💡 Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "   Then run: source ~/.bashrc (or restart your terminal)"
    fi
else
    echo -e "${RED}❌ Failed to create working symlink${NC}"
    exit 1
fi