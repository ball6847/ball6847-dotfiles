#!/bin/bash

# VERSION-AWARE DEV TOOLS INSTALLATION SCRIPT
# ============================================================================
# Checks current versions before installing, skips if already up-to-date
#
# This script provides significant performance improvements by:
# - Checking installed versions before installing
# - Skipping installation when tools are already up-to-date
# - Caching version information to minimize API calls
# - Providing clear feedback about what's happening
#
# Usage:
#   ./dev-tools-install.sh [OPTIONS]
#
# Options:
#   --deno-only         Install only Deno packages
#   --golang-only       Install only Go tools
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

# Flags
DENO_ONLY=false
GOLANG_ONLY=false

# ============================================================================
# MAIN INSTALLATION LOGIC (SAFE TO MODIFY)
# ============================================================================

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --deno-only)
            DENO_ONLY=true
            shift
            ;;
        --golang-only)
            GOLANG_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --deno-only         Install only Deno packages"
            echo "  --golang-only       Install only Go tools"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Install all tools (default)"
            echo "  $0 --deno-only              # Install only Deno packages"
            echo "  $0 --golang-only            # Install only Go tools"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate flag combinations
if [[ "$DENO_ONLY" = true && "$GOLANG_ONLY" = true ]]; then
    echo "Warning: Both --deno-only and --golang-only specified, installing all tools"
fi

# Main installation logic
colorize "boldgreen" "🚀 Starting version-aware dev tools installation..."
echo

# Deno packages
if [[ "$DENO_ONLY" = true || "$GOLANG_ONLY" = false ]]; then
    colorize "boldblue" "📦 Deno packages:"
    install_deno_package "jsr:@ball6847/workspace-manager" "workspace-manager"
    install_deno_package "jsr:@ball6847/git-commit-ai" "git-commit-ai"
    echo

    # Reshim deno
    reshim_language "deno"
fi

# Go tools
if [[ "$GOLANG_ONLY" = true || "$DENO_ONLY" = false ]]; then
    colorize "boldblue" "📦 Go tools:"
    install_go_tool "github.com/vektra/mockery/v2" "mockery"
    install_go_tool "github.com/mitranim/gow" "gow"
    install_go_tool "golang.org/x/tools/gopls" "gopls"
    echo

    # Reshim golang
    reshim_language "golang"
fi

colorize "boldgreen" "✅ Dev tools installation completed!"
