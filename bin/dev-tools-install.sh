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
# TODO: refactor functions into a library file (~/.dotfiles/lib/[package-by-functional].sh)

# ============================================================================
# LIBRARY FUNCTIONS (INTERNAL - DO NOT MODIFY UNLESS NECESSARY)
# ============================================================================

# Function: Colorize text with ANSI escape codes
# Usage: colorize <color> <text>
# Colors: black, red, green, yellow, blue, magenta, cyan, white
#         (add 'bold' prefix for bold text: boldred, boldgreen, etc.)
colorize() {
    local color="$1"
    local text="$2"
    
    case "$color" in
        black)    echo -e "\033[30m${text}\033[0m" ;;
        red)      echo -e "\033[31m${text}\033[0m" ;;
        green)    echo -e "\033[32m${text}\033[0m" ;;
        yellow)   echo -e "\033[33m${text}\033[0m" ;;
        blue)     echo -e "\033[34m${text}\033[0m" ;;
        magenta)  echo -e "\033[35m${text}\033[0m" ;;
        cyan)     echo -e "\033[36m${text}\033[0m" ;;
        white)    echo -e "\033[37m${text}\033[0m" ;;
        boldblack)    echo -e "\033[1;30m${text}\033[0m" ;;
        boldred)      echo -e "\033[1;31m${text}\033[0m" ;;
        boldgreen)    echo -e "\033[1;32m${text}\033[0m" ;;
        boldyellow)   echo -e "\033[1;33m${text}\033[0m" ;;
        boldblue)     echo -e "\033[1;34m${text}\033[0m" ;;
        boldmagenta)  echo -e "\033[1;35m${text}\033[0m" ;;
        boldcyan)     echo -e "\033[1;36m${text}\033[0m" ;;
        boldwhite)    echo -e "\033[1;37m${text}\033[0m" ;;
        *)           echo "${text}" ;;
    esac
}

# Flags
DENO_ONLY=false
GOLANG_ONLY=false

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
    if ! asdf reshim deno 2>/dev/null; then
        echo "⚠️  asdf reshim failed or asdf not available"
    fi
fi

# Go tools
if [[ "$GOLANG_ONLY" = true || "$DENO_ONLY" = false ]]; then
    colorize "boldblue" "📦 Go tools:"
    install_go_tool "github.com/vektra/mockery/v2" "mockery"
    install_go_tool "github.com/mitranim/gow" "gow"
    install_go_tool "golang.org/x/tools/gopls" "gopls"
    echo

    # Reshim golang
    if ! asdf reshim golang 2>/dev/null; then
        echo "⚠️  asdf reshim failed or asdf not available"
    fi
fi

colorize "boldgreen" "✅ Dev tools installation completed!"
