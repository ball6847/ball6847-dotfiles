#!/bin/bash

# ============================================================================
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
#   --no-cache          Skip reading from cache, force fresh queries
#   --deno-only         Install only Deno packages
#   --golang-only       Install only Go tools
#   --help, -h          Show this help message

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

# Configuration
CACHE_FILE="/tmp/dev-tools-versions.cache"
CACHE_TTL=3600  # 1 hour in seconds

# Flags
NO_CACHE=false
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

# Function: Get current timestamp
get_timestamp() {
    date +%s
}

# Function: Check if cache is stale
is_cache_stale() {
    local timestamp="$1"
    local current_time=$(get_timestamp)
    
    if [[ -z "$timestamp" ]]; then
        return 1  # Stale if no timestamp
    fi
    
    local age=$((current_time - timestamp))
    if (( age > CACHE_TTL )); then
        return 0  # Stale
    else
        return 1  # Fresh
    fi
}

# Function: Parse cache entry (format: key: value timestamp)
parse_cache_entry() {
    local entry="$1"
    
    # Extract value and timestamp
    # Format: key: value timestamp
    local value=$(echo "$entry" | cut -d' ' -f2)
    local timestamp=$(echo "$entry" | cut -d' ' -f3-)
    
    echo "$value"
    echo "$timestamp"
}

# Function: Read version from cache
get_cached_version() {
    local key="$1"
    
    if [[ "$NO_CACHE" = true ]]; then
        return 1  # Skip cache if --no-cache flag is set
    fi
    
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi
    
    local entry
    entry=$(grep "^$key:" "$CACHE_FILE" | head -1)
    
    if [[ -n "$entry" ]]; then
        # Parse value and timestamp
        local value
        local timestamp
        read -r value timestamp <<< "$(parse_cache_entry "$entry")"
        
        # Check if cache is stale
        if is_cache_stale "$timestamp"; then
            return 1  # Stale, treat as not found
        fi
        
        echo "$value"
        return 0
    fi
    
    return 1
}

# Function: Write version to cache
cache_version() {
    local key="$1"
    local value="$2"
    
    if [[ "$NO_CACHE" = true ]]; then
        return 0  # Skip cache if --no-cache flag is set
    fi
    
    # Create cache directory if needed
    mkdir -p "$(dirname "$CACHE_FILE")"
    
    # Get current timestamp
    local timestamp=$(get_timestamp)
    
    # Write or update cache (format: key: value timestamp)
    if grep -q "^$key:" "$CACHE_FILE" 2>/dev/null; then
        sed -i "s/^$key:.*/$key: $value $timestamp/" "$CACHE_FILE"
    else
        echo "$key: $value $timestamp" >> "$CACHE_FILE"
    fi
}

# Function: Get installed Deno package version
get_installed_deno_version() {
    local package="$1"
    
    # Try to get version from deno info
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
    
    return 1
}

# Function: Get latest Deno package version from JSR
get_latest_deno_version() {
    local package="$1"
    
    # Try cache first
    local cached_value
    if cached_value=$(get_cached_version "$package"); then
        echo "$cached_value"
        return 0
    fi
    
    # Try to get version from deno info (same as installed, but for latest)
    # This is a fallback - in production we might want to query JSR API
    # Suppress output
    local info_output
    info_output=$(deno info "$package" 2>&1)
    
    if [[ $? -eq 0 && -n "$info_output" ]]; then
        local version
        version=$(echo "$info_output" | grep -oP '/[0-9]+\.[0-9]+\.[0-9]+/' | head -1 | tr -d '/')
        
        if [[ -n "$version" ]]; then
            cache_version "$package" "$version"
            echo "$version"
            return 0
        fi
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
    local cache_key="go-$repo"
    
    # Try cache first
    local cached_value
    if cached_value=$(get_cached_version "$cache_key"); then
        echo "$cached_value"
        return 0
    fi
    
    # Query GitHub API (with timeout to avoid hanging)
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local version
    version=$(curl -s "$api_url" | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/' | tr -d 'v')
    
    if [[ -n "$version" ]]; then
        cache_version "$cache_key" "$version"
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
        --no-cache)
            NO_CACHE=true
            shift
            ;;
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
            echo "  --no-cache          Skip reading from cache, force fresh queries"
            echo "  --deno-only         Install only Deno packages"
            echo "  --golang-only       Install only Go tools"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Install all tools (default)"
            echo "  $0 --no-cache               # Force fresh install, ignore cache"
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
