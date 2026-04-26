#!/usr/bin/env bash
#
# asdf-cleanup.sh - Remove old ASDF plugin versions that are not in ~/.tool-versions
#
# Usage: ./asdf-cleanup.sh [--dry-run] [--force]
#
# Options:
#   --dry-run    Show what would be removed without actually removing
#   --force      Skip confirmation prompt and remove immediately
#

set -euo pipefail

DRY_RUN=false
FORCE=false
TOOL_VERSIONS_FILE="$HOME/.tool-versions"
ASDF_INSTALLS_DIR="$HOME/.asdf/installs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--force]"
      echo ""
      echo "Remove old ASDF plugin versions not listed in ~/.tool-versions"
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be removed without deleting"
      echo "  --force      Skip confirmation prompt"
      echo "  -h, --help   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check if .tool-versions exists
if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
  echo -e "${RED}Error: $TOOL_VERSIONS_FILE not found${NC}"
  exit 1
fi

# Check if asdf installs directory exists
if [[ ! -d "$ASDF_INSTALLS_DIR" ]]; then
  echo -e "${RED}Error: $ASDF_INSTALLS_DIR not found${NC}"
  exit 1
fi

echo "=================================="
echo "ASDF Old Version Cleanup Tool"
echo "=================================="
echo ""

# Read current versions from .tool-versions
declare -A CURRENT_VERSIONS
while IFS=' ' read -r plugin version rest; do
  # Skip empty lines and comments
  [[ -z "$plugin" || "$plugin" =~ ^# ]] && continue
  CURRENT_VERSIONS["$plugin"]="$version"
done < "$TOOL_VERSIONS_FILE"

echo "Current versions from $TOOL_VERSIONS_FILE:"
for plugin in "${!CURRENT_VERSIONS[@]}"; do
  echo "  $plugin ${CURRENT_VERSIONS[$plugin]}"
done
echo ""

# Find old versions to remove
declare -a TO_REMOVE=()
declare -a PLUGIN_NAMES=()
declare -a OLD_VERSIONS=()

for plugin_dir in "$ASDF_INSTALLS_DIR"/*/; do
  [[ -d "$plugin_dir" ]] || continue

  plugin=$(basename "$plugin_dir")

  # Skip if plugin is not in .tool-versions
  if [[ -z "${CURRENT_VERSIONS[$plugin]:-}" ]]; then
    echo -e "${YELLOW}Warning: Plugin '$plugin' not found in $TOOL_VERSIONS_FILE${NC}"
    echo "  Skipping (manual cleanup required)"
    continue
  fi

  current_version="${CURRENT_VERSIONS[$plugin]}"

  # Check each installed version
  for version_dir in "$plugin_dir"/*/; do
    [[ -d "$version_dir" ]] || continue

    version=$(basename "$version_dir")

    # If version doesn't match current, mark for removal
    if [[ "$version" != "$current_version" ]]; then
      TO_REMOVE+=("$version_dir")
      PLUGIN_NAMES+=("$plugin")
      OLD_VERSIONS+=("$version")
    fi
  done
done

# Check if there's anything to remove
if [[ ${#TO_REMOVE[@]} -eq 0 ]]; then
  echo -e "${GREEN}No old versions found. Everything is up to date!${NC}"
  exit 0
fi

# Calculate space that will be freed
echo "Old versions found for cleanup:"
echo "--------------------------------"
TOTAL_SIZE=0
for i in "${!TO_REMOVE[@]}"; do
  size=$(du -sh "${TO_REMOVE[$i]}" 2>/dev/null | cut -f1 || echo "?")
  size_bytes=$(du -sb "${TO_REMOVE[$i]}" 2>/dev/null | cut -f1 || echo "0")
  TOTAL_SIZE=$((TOTAL_SIZE + size_bytes))
  echo "  ${PLUGIN_NAMES[$i]} ${OLD_VERSIONS[$i]} ($size)"
done
echo ""

# Convert total size to human readable
if command -v numfmt &>/dev/null; then
  TOTAL_HUMAN=$(numfmt --to=iec-i --suffix=B "$TOTAL_SIZE" 2>/dev/null || echo "${TOTAL_SIZE} bytes")
else
  TOTAL_HUMAN="${TOTAL_SIZE} bytes"
fi

echo "Total space to free: $TOTAL_HUMAN"
echo ""

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}DRY RUN MODE: No files were actually removed${NC}"
  echo "Run without --dry-run to perform actual cleanup"
  exit 0
fi

# Confirmation prompt
if [[ "$FORCE" != true ]]; then
  echo -n "Proceed with removal? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

echo ""
echo "Removing old versions..."
echo "--------------------------------"

# Remove old versions
for i in "${!TO_REMOVE[@]}"; do
  version_dir="${TO_REMOVE[$i]}"
  plugin="${PLUGIN_NAMES[$i]}"
  version="${OLD_VERSIONS[$i]}"

  echo -n "Removing $plugin $version... "

  # Fix permissions if needed (Go modules can be read-only)
  if [[ -d "$version_dir" ]]; then
    chmod -R +w "$version_dir" 2>/dev/null || true
  fi

  # Remove the directory
  if rm -rf "$version_dir" 2>/dev/null; then
    echo -e "${GREEN}done${NC}"
  else
    echo -e "${RED}failed${NC} (permission denied)"
  fi
done

echo ""
echo "=================================="
echo -e "${GREEN}Cleanup complete!${NC}"
echo "Freed approximately $TOTAL_HUMAN"
echo "=================================="
