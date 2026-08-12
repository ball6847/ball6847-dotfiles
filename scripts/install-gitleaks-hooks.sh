#!/usr/bin/env bash
set -euo pipefail

# Idempotent installer for Gitleaks git hooks
# Installs pre-commit and pre-push hooks from gitleaks-hooks/

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"
TRACKED_HOOKS_DIR="$REPO_ROOT/gitleaks-hooks"

MARKER="# gitleaks-hook"

install_hook() {
  local name="$1"
  local src="$TRACKED_HOOKS_DIR/$name"
  local dest="$HOOKS_DIR/$name"
  local bak="$HOOKS_DIR/$name.bak"

  if [[ ! -f "$src" ]]; then
    echo "Warning: tracked hook $src not found, skipping"
    return 0
  fi

  # Check if already installed
  if [[ -f "$dest" ]] && grep -q "$MARKER" "$dest" 2>/dev/null; then
    echo "Hook $name already installed, skipping"
    return 0
  fi

  # Backup existing hook if present and not already backed up
  if [[ -f "$dest" ]]; then
    if [[ -f "$bak" ]]; then
      echo "Error: backup $bak already exists, refusing to overwrite"
      exit 1
    fi
    echo "Backing up existing $name to $name.bak"
    mv "$dest" "$bak"
  fi

  echo "Installing $name"
  cp "$src" "$dest"
  chmod +x "$dest"
}

main() {
  if [[ ! -d "$HOOKS_DIR" ]]; then
    echo "Error: not a git repository or hooks directory missing"
    exit 1
  fi

  install_hook "pre-commit"
  install_hook "pre-push"

  echo "Gitleaks hooks installed successfully"
  echo "Repo root: $REPO_ROOT"
}

main "$@"
