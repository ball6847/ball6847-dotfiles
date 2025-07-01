#!/bin/bash

# Define source and target paths
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME/Library/Application Support/Trae/User"
files=("settings.json" "keybindings.json")
directories=("snippets")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Create target directory if it doesn't exist
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
fi

# Initialize arrays
successful_links=()
failed_links=()
existing_links=()
backup_files=()

# Function to check if file is a symbolic link pointing to expected target
is_correct_symlink() {
    local target_file="$1"
    local expected_source="$2"
    
    if [ -L "$target_file" ]; then
        local actual_target=$(readlink "$target_file")
        [ "$actual_target" = "$expected_source" ]
    else
        return 1
    fi
}

# Collect phase - Files
for file in "${files[@]}"; do
    source_path="$source_dir/$file"
    target_path="$target_dir/$file"
    
    # Check if source file exists
    if [ ! -f "$source_path" ]; then
        failed_links+=("$file:Source file does not exist:$source_path")
        continue
    fi
    
    # Check if target exists and is already a symbolic link
    if [ -e "$target_path" ]; then
        if is_correct_symlink "$target_path" "$source_path"; then
            existing_links+=("$file")
            continue
        elif [ -L "$target_path" ]; then
            actual_target=$(readlink "$target_path")
            failed_links+=("$file:Symbolic link points to incorrect location:$actual_target")
            continue
        else
            backup_files+=("$file:$target_path:$target_path.backup")
        fi
    fi
    
    # Add to pending links
    successful_links+=("$file:$source_path:$target_path")
done

# Collect phase - Directories
for directory in "${directories[@]}"; do
    source_path="$source_dir/$directory"
    target_path="$target_dir/$directory"
    
    # Check if source directory exists
    if [ ! -d "$source_path" ]; then
        # Skip if source directory doesn't exist (optional directory)
        continue
    fi
    
    # Check if target exists and is already a symbolic link
    if [ -e "$target_path" ]; then
        if is_correct_symlink "$target_path" "$source_path"; then
            existing_links+=("$directory")
            continue
        elif [ -L "$target_path" ]; then
            actual_target=$(readlink "$target_path")
            failed_links+=("$directory:Symbolic link points to incorrect location:$actual_target")
            continue
        else
            backup_files+=("$directory:$target_path:$target_path.backup")
        fi
    fi
    
    # Add to pending links
    successful_links+=("$directory:$source_path:$target_path")
done

# Save phase - backup existing items
for backup_info in "${backup_files[@]}"; do
    IFS=':' read -r item source backup <<< "$backup_info"
    echo "Backing up $source to $backup"
    if [ -d "$source" ]; then
        # Handle directory backup
        if mv "$source" "$backup"; then
            echo -e "${GREEN}✓ Backed up directory $item${NC}"
        else
            failed_links+=("$item:Failed to backup existing directory")
            continue
        fi
    else
        # Handle file backup
        if cp "$source" "$backup" && rm "$source"; then
            echo -e "${GREEN}✓ Backed up file $item${NC}"
        else
            failed_links+=("$item:Failed to backup existing file")
            continue
        fi
    fi
done

# Create symbolic links
for link_info in "${successful_links[@]}"; do
    IFS=':' read -r item source target <<< "$link_info"
    if error_msg=$(ln -s "$source" "$target" 2>&1); then
        if [ -d "$source" ]; then
            echo -e "${GREEN}✓ Created symbolic link for directory $item${NC}"
        else
            echo -e "${GREEN}✓ Created symbolic link for file $item${NC}"
        fi
    else
        failed_links+=("$item:Failed to create symbolic link: $error_msg")
    fi
done

# Report results
for link in "${existing_links[@]}"; do
    echo -e "${GREEN}✓ Symbolic link already exists for $link${NC}"
done

for failure_info in "${failed_links[@]}"; do
    IFS=':' read -r file reason path <<< "$failure_info"
    if [[ "$reason" == *"incorrect location"* ]]; then
        echo -e "${RED}Symbolic link $file points to incorrect location: $path${NC}" >&2
        echo -e "${RED}Expected location: $source_dir/$file${NC}" >&2
        echo -e "${YELLOW}Please manually remove the existing symbolic link and run this script again.${NC}"
    else
        echo -e "${RED}Failed to process $file: $reason${NC}" >&2
    fi
done

success=true
if [ ${#failed_links[@]} -gt 0 ]; then
    success=false
fi

if [ "$success" = true ]; then
    echo -e "\n${CYAN}Trae configuration sync setup complete!${NC}"
    echo -e "${GRAY}Your settings, keybindings, and snippets will now stay in sync with the source directory.${NC}"
else
    echo -e "\n${RED}Trae configuration sync completed with errors. Please review the messages above.${NC}"
fi
