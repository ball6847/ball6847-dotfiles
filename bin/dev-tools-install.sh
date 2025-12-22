#!/bin/bash

# VERSION-AWARE DEV TOOLS INSTALLATION SCRIPT
# ============================================================================
# Checks current versions before installing, skips if already up-to-date
#
# This script provides significant performance improvements by:
# - Checking installed versions before installing
# - Skipping installation when tools are already up-to-date
# - Providing clear feedback about what's happening
#
# Usage:
#   ./dev-tools-install.sh [OPTIONS]
#
# Options:
#   --deno              Install only Deno packages
#   --golang            Install only Go tools
#   --help, -h          Show this help message

# TODO: go package version detection is flaky

# ============================================================================
# LOAD LIBRARY
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the library file
if [[ -f "$SCRIPT_DIR/../lib/dev-tools-lib.sh" ]]; then
    source "$SCRIPT_DIR/../lib/dev-tools-lib.sh"
else
    echo "Error: Library file not found at $SCRIPT_DIR/../lib/dev-tools-lib.sh"
    echo "Please ensure the library file exists before running this script."
    exit 1
fi

# Installation flags - default to false
INSTALL_DENO_PKG=false
INSTALL_GO_PKG=false

# ============================================================================
# MAIN INSTALLATION LOGIC (SAFE TO MODIFY)
# ============================================================================

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --deno)
            INSTALL_DENO_PKG=true
            shift
            ;;
        --golang)
            INSTALL_GO_PKG=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deno              Install only Deno packages"
            echo "  --golang            Install only Go tools"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Install all tools (default)"
            echo "  $0 --deno                   # Install only Deno packages"
            echo "  $0 --golang                 # Install only Go tools"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# If no flags specified, install all packages by default
if [[ "$INSTALL_DENO_PKG" = false && "$INSTALL_GO_PKG" = false ]]; then
    INSTALL_DENO_PKG=true
    INSTALL_GO_PKG=true
fi

# Main installation logic
colorize "boldgreen" "🚀 Starting version-aware dev tools installation..."
echo

# Deno packages
if [[ "$INSTALL_DENO_PKG" = true ]]; then
    colorize "boldblue" "📦 Deno packages:"
    install_deno_package "jsr:@ball6847/workspace-manager" "workspace-manager"
    install_deno_package "jsr:@ball6847/git-commit-ai" "git-commit-ai"
    echo

    # Reshim deno
    reshim_language "deno"
fi

# Go tools
if [[ "$INSTALL_GO_PKG" = true ]]; then
    colorize "boldblue" "📦 Go tools:"
    install_go_tool "github.com/vektra/mockery/v2" "mockery"
    install_go_tool "github.com/mitranim/gow" "gow"
    install_go_tool "golang.org/x/tools/gopls" "gopls"
    echo

    # Reshim golang
    reshim_language "golang"
fi

colorize "boldgreen" "✅ Dev tools installation completed!"
