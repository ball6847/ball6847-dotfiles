#!/bin/bash

# COMMON LIBRARY
# ============================================================================
# Common utility functions used across multiple scripts
# This file contains general-purpose functions that can be shared

# ============================================================================
# COLOR FUNCTIONS
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

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Function: Reshim a language plugin with asdf
# Usage: reshim_language <language>
# Example: reshim_language "deno"
reshim_language() {
    local language="$1"
    
    if ! asdf reshim "$language" 2>/dev/null; then
        echo "⚠️  asdf reshim failed or asdf not available"
    fi
}
