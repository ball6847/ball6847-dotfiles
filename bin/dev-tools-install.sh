#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../lib/dev-tools-lib.sh" ]]; then
    source "$SCRIPT_DIR/../lib/dev-tools-lib.sh"
else
    echo "Error: Library file not found"
    exit 1
fi

INSTALL_DENO_PKG=false
INSTALL_GO_PKG=false

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
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ "$INSTALL_DENO_PKG" = false && "$INSTALL_GO_PKG" = false ]]; then
    INSTALL_DENO_PKG=true
    INSTALL_GO_PKG=true
fi

if [[ "$INSTALL_DENO_PKG" = true ]]; then
    deno install -fr --no-lock --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/workspace-manager
    deno install -fr --no-lock --global --allow-run --allow-env --allow-read --allow-write --allow-net jsr:@ball6847/git-commit-ai
    asdf reshim deno
fi

if [[ "$INSTALL_GO_PKG" = true ]]; then
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
    go install github.com/evilmartians/lefthook@latest
    asdf reshim golang
fi
