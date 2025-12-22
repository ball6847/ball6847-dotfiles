#!/bin/bash

# DEV TOOLS LIBRARY
# ============================================================================
# Shared functions for dev tools installation scripts
# This file can be sourced by multiple scripts to avoid code duplication

# ============================================================================
# LOAD COMMON LIBRARY
# ============================================================================

# Get the directory where this library is located
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common library file
if [[ -f "$LIB_DIR/common-lib.sh" ]]; then
    source "$LIB_DIR/common-lib.sh"
else
    echo "Error: Common library file not found at $LIB_DIR/common-lib.sh" >&2
    echo "Please ensure the common library file exists before using this library." >&2
    return 1
fi

# ============================================================================
# VERSION COMPARISON FUNCTIONS
# ============================================================================

# Function: Compare semantic versions (simplified)
# Returns 0 if v1 >= v2, 1 if v1 < v2
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Remove 'v' prefix if present
    v1=${v1#v}
    v2=${v2#v}
    
    # Simple comparison: split by dots and compare numerically
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    for ((i=0; i<${#v1_parts[@]} || i<${#v2_parts[@]}; i++)); do
        local part1="${v1_parts[i]:-0}"
        local part2="${v2_parts[i]:-0}"
        
        if (( part1 > part2 )); then
            return 0  # v1 > v2
        elif (( part1 < part2 )); then
            return 1  # v1 < v2
        fi
    done
    
    return 0  # equal
}

# ============================================================================
# DENO PACKAGE FUNCTIONS
# ============================================================================

# Function: Get installed Deno package version
get_installed_deno_version() {
    local package="$1"
    
    # Extract package name from the full package specifier (e.g., "jsr:@ball6847/workspace-manager")
    # The binary name is just the last part (e.g., "workspace-manager")
    local package_name
    package_name=$(echo "$package" | sed 's/.*://' | sed 's|^@||' | sed 's|.*/||')
    
    # Check if the package is installed globally by checking the deno bin directory
    # This is more reliable than deno info which shows cached versions
    # or command -v which finds shims even when the actual binary is missing
    local deno_bin_dir
    deno_bin_dir=$(realpath "$(dirname "$(command -v deno)")/../installs/deno/$(deno --version | head -1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')/.deno/bin")
    
    if [[ -n "$deno_bin_dir" && -f "$deno_bin_dir/$package_name" ]]; then
        # Package is installed, get version from deno info
        local info_output
        info_output=$(deno info "$package" 2>&1)
        
        if [[ $? -eq 0 && -n "$info_output" ]]; then
            # Extract version from URL in the output (format: /X.Y.Z/main.ts)
            local version
            version=$(echo "$info_output" | grep -oP '/[0-9]+\.[0-9]+\.[0-9]+/' | head -1 | tr -d '/')
            
            if [[ -n "$version" ]]; then
                echo "$version"
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function: Get latest Deno package version from JSR
get_latest_deno_version() {
    local package="$1"
    
    # Query JSR meta.json to get the latest version
    # Extract package name from the full package specifier (e.g., "jsr:@ball6847/workspace-manager")
    local package_name
    package_name=$(echo "$package" | sed 's/.*://' | sed 's|^@||')
    
    # Construct JSR meta.json URL
    local meta_url="https://jsr.io/@$package_name/meta.json"
    
    # Query JSR meta.json with timeout to avoid hanging
    local version
    version=$(curl -s "$meta_url" | grep -oP '"latest":"[^"]*"' | sed 's/.*"latest":"\([^"]*\)".*/\1/')
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    return 1
}

# Function: Install Deno package if needed
install_deno_package() {
    local package="$1"
    local package_name="$2"
    
    # Print package name with color
    colorize "boldblue" "  $package_name:"
    
    # Get installed version
    local installed_version=""
    installed_version=$(get_installed_deno_version "$package" 2>/dev/null)
    
    # Get latest version
    local latest_version=""
    latest_version=$(get_latest_deno_version "$package" 2>/dev/null)
    
    # Show version information
    if [[ -n "$installed_version" ]]; then
        echo "  Installed: $(colorize "boldgreen" "v$installed_version")"
    else
        echo "  ⚠️  Installed version: unknown"
    fi
    
    if [[ -n "$latest_version" ]]; then
        echo "  Latest:    $(colorize "boldgreen" "v$latest_version")"
    else
        echo "  ⚠️  Latest version: unknown"
    fi
    
    # Compare versions
    if [[ -n "$installed_version" && -n "$latest_version" ]]; then
        if compare_versions "$installed_version" "$latest_version"; then
            echo "  ✓ Up-to-date"
            return 0
        fi
    fi
    
    # Install or update (suppress deno output but show errors)
    if [[ -n "$latest_version" ]]; then
        echo "  🔄 Installing/updating to $(colorize "boldgreen" "v$latest_version")..."
    else
        echo "  🔄 Installing/updating (latest version)..."
    fi
    
    # Use a temporary file to capture output and check exit code
    local temp_file=$(mktemp)
    deno install -fr --global --allow-run --allow-env --allow-read --allow-write --allow-net "$package" > "$temp_file" 2>&1
    local exit_code=$?
    rm -f "$temp_file"
    
    if [[ $exit_code -eq 0 ]]; then
        if [[ -n "$latest_version" ]]; then
            echo "  ✓ Installed ($(colorize "boldgreen" "v$latest_version"))"
        else
            echo "  ✓ Installed (latest version)"
        fi
    else
        echo "  ✗ Failed to install"
        return 1
    fi
}

# ============================================================================
# GO TOOL FUNCTIONS
# ============================================================================

# Function: Get installed Go tool version
get_installed_go_version() {
    local tool="$1"
    
    if ! command -v "$tool" &> /dev/null; then
        return 1
    fi
    
    # Try different version flags with timeout to prevent hanging
    # Suppress all output from version commands
    # Use more specific pattern to avoid matching line numbers in help text
    local version
    version=$(timeout 5 "$tool" --version 2>&1 >/dev/null | grep -oP 'v?[0-9]\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    version=$(timeout 5 "$tool" version 2>&1 >/dev/null | grep -oP 'v?[0-9]\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    # If no version found, return success with empty version (tool exists but version unknown)
    return 0
}

# Function: Get latest Go tool version from GitHub API
get_latest_go_version() {
    local repo="$1"
    
    # Query GitHub API (with timeout to avoid hanging)
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local version
    version=$(curl -s "$api_url" | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/' | tr -d 'v')
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    return 1
}

# Function: Install Go tool if needed
install_go_tool() {
    local repo="$1"
    local tool_name="$2"
    
    # Print tool name with color
    colorize "boldblue" "  $tool_name:"
    
    # Get installed version
    local installed_version=""
    installed_version=$(get_installed_go_version "$tool_name" 2>/dev/null)
    
    # Get latest version
    local latest_version=""
    latest_version=$(get_latest_go_version "$repo" 2>/dev/null)
    
    # Show version information
    if [[ -n "$installed_version" ]]; then
        echo "  Installed: $(colorize "boldgreen" "v$installed_version")"
    else
        echo "  ⚠️  Installed version: unknown"
    fi
    
    if [[ -n "$latest_version" ]]; then
        echo "  Latest:    $(colorize "boldgreen" "v$latest_version")"
    else
        echo "  ⚠️  Latest version: unknown"
    fi
    
    # Compare versions
    if [[ -n "$installed_version" && -n "$latest_version" ]]; then
        if compare_versions "$installed_version" "$latest_version"; then
            echo "  ✓ Up-to-date"
            return 0
        fi
    fi
    
    # Install or update with timeout
    if [[ -n "$latest_version" ]]; then
        echo "  🔄 Installing/updating to $(colorize "boldgreen" "v$latest_version")..."
    else
        echo "  🔄 Installing/updating (latest version)..."
    fi
    
    # Use timeout to prevent hanging (300 seconds = 5 minutes)
    # Suppress go install output
    if timeout 300 go install "$repo"@latest >/dev/null 2>&1; then
        if [[ -n "$latest_version" ]]; then
            echo "  ✓ Installed ($(colorize "boldgreen" "v$latest_version"))"
        else
            echo "  ✓ Installed (latest version)"
        fi
    else
        echo "  ⚠️  Installation timed out after 5 minutes"
        echo "     You may need to install it manually: go install $repo@latest"
        return 1
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# No utility functions here - see common-lib.sh for shared utilities
