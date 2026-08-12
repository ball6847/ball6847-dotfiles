#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="/Users/ball6847/.dotfiles"
PASS=0
FAIL=0

check_exists() {
  local file="$1"
  if [[ -f "$REPO_ROOT/$file" ]]; then
    echo "PASS: $file exists"
    PASS=$((PASS+1))
  else
    echo "FAIL: $file missing"
    FAIL=$((FAIL+1))
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  if grep -q "$pattern" "$REPO_ROOT/$file" 2>/dev/null; then
    echo "PASS: $file contains '$pattern'"
    PASS=$((PASS+1))
  else
    echo "FAIL: $file does not contain '$pattern'"
    FAIL=$((FAIL+1))
  fi
}

echo "=== Gitleaks Integration Tests ==="

# Files existence
check_exists ".gitleaks.toml"
check_exists ".gitleaksignore"
check_exists ".github/workflows/gitleaks.yml"
check_exists "scripts/install-gitleaks-hooks.sh"
check_exists "gitleaks-hooks/pre-commit"
check_exists "gitleaks-hooks/pre-push"

# .gitleaks.toml content
check_contains ".gitleaks.toml" "useDefault = true"
check_contains ".gitleaks.toml" "paths"
check_contains ".gitleaks.toml" "kimi"
check_contains ".gitleaks.toml" "qoder"

# .gitleaksignore content
check_contains ".gitleaksignore" "commit:file:rule"

# Workflow content
check_contains ".github/workflows/gitleaks.yml" "gitleaks/gitleaks-action@v2"
check_contains ".github/workflows/gitleaks.yml" "push"
check_contains ".github/workflows/gitleaks.yml" "pull_request"

# Installer script content
check_contains "scripts/install-gitleaks-hooks.sh" "git rev-parse --show-toplevel"
check_contains "scripts/install-gitleaks-hooks.sh" "pre-commit"
check_contains "scripts/install-gitleaks-hooks.sh" "pre-push"

# Hook scripts
check_contains "gitleaks-hooks/pre-commit" "gitleaks git --staged"
check_contains "gitleaks-hooks/pre-push" "gitleaks git --no-banner"

# .gitignore
check_contains ".gitignore" "gitleaks-report.*"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
