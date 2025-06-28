#!/bin/bash

# Auto-update dotfiles on startup (Mac/Linux version)
dotfiles_dir="$HOME/.dotfiles"
log_file="$dotfiles_dir/auto-update.log"
stash_created=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to write log with timestamp
write_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

write_log "Starting dotfiles auto-update"

# Validate dotfiles directory exists
if [ ! -d "$dotfiles_dir" ]; then
    echo -e "${RED}ERROR: Dotfiles directory not found: $dotfiles_dir${NC}" >&2
    write_log "ERROR: Dotfiles directory not found: $dotfiles_dir"
    exit 1
fi

# Change to dotfiles directory
if cd "$dotfiles_dir"; then
    write_log "Changed to directory: $dotfiles_dir"
else
    echo -e "${RED}ERROR: Failed to change to dotfiles directory${NC}" >&2
    write_log "ERROR: Failed to change to dotfiles directory"
    exit 1
fi

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}ERROR: Not a git repository${NC}" >&2
    write_log "ERROR: Not a git repository"
    exit 1
fi

# Check for uncommitted changes
echo -e "${YELLOW}Checking for uncommitted changes...${NC}"
if status=$(git status --porcelain 2>&1); then
    # If there are uncommitted changes, stash them
    if [ -n "$status" ]; then
        echo -e "${YELLOW}Uncommitted changes detected, stashing them...${NC}"
        write_log "Uncommitted changes detected, stashing them"
        if stash_output=$(git stash push -m "Auto-update stash" 2>&1); then
            write_log "Stash output: $stash_output"
            stash_created=true
            echo -e "${GREEN}✓ Changes stashed successfully${NC}"
        else
            echo -e "${RED}ERROR: Failed to stash changes${NC}" >&2
            write_log "ERROR: Failed to stash changes: $stash_output"
        fi
    else
        echo -e "${GREEN}✓ No uncommitted changes detected${NC}"
        write_log "No uncommitted changes detected"
    fi
else
    echo -e "${RED}ERROR: Failed to check git status${NC}" >&2
    write_log "ERROR: Failed to check git status: $status"
    exit 1
fi

# Perform git pull
echo -e "${YELLOW}Updating dotfiles...${NC}"
if output=$(git pull 2>&1); then
    write_log "Git pull output: $output"
    
    if echo "$output" | grep -q "Already up to date"; then
        echo -e "${GREEN}✓ Dotfiles already up to date${NC}"
        write_log "SUCCESS: Already up to date"
    else
        echo -e "${GREEN}✓ Dotfiles updated successfully${NC}"
        write_log "SUCCESS: Git pull completed successfully"
    fi
else
    echo -e "${RED}ERROR: Git pull failed${NC}" >&2
    write_log "ERROR: Git pull failed: $output"
    exit 1
fi

# Apply stashed changes if any were stashed
if [ "$stash_created" = true ]; then
    echo -e "${YELLOW}Applying stashed changes...${NC}"
    write_log "Applying stashed changes"
    if stash_pop_output=$(git stash pop 2>&1); then
        write_log "Stash pop output: $stash_pop_output"
        echo -e "${GREEN}✓ Stashed changes applied successfully${NC}"
    else
        echo -e "${RED}ERROR: Failed to apply stashed changes${NC}" >&2
        write_log "ERROR: Failed to apply stashed changes: $stash_pop_output"
    fi
fi

# Push changes to repository
echo -e "${YELLOW}Pushing changes to repository...${NC}"
write_log "Pushing changes to repository"
if push_output=$(git push 2>&1); then
    write_log "Push output: $push_output"
    echo -e "${GREEN}✓ Changes pushed successfully${NC}"
    write_log "SUCCESS: Git push completed successfully"
else
    echo -e "${RED}ERROR: Git push failed${NC}" >&2
    write_log "ERROR: Git push failed: $push_output"
fi

write_log "Auto-update completed"
