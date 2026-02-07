#!/bin/bash

# Configuration (Must match install.sh)
FILES_TO_LINK=(
    ".bash_aliases"
    ".bash_exports"
    ".bash_profile"
    ".bash_wrappers"
    ".bashrc"
    ".screenrc"
    ".tmux.conf"
    ".vimrc"
)

CONFIG_DIRS=(
    "ripgrep"
    "wezterm"
)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

remove_link() {
    local target_file="$HOME/$1"
    
    if [ -L "$target_file" ]; then
        rm -f "$target_file"
        echo -e "${BLUE}Removed symlink for $1${NC}"
    fi

    if [ -e "${target_file}.dtbak" ]; then
        mv -f "${target_file}.dtbak" "$target_file"
        echo -e "${GREEN}Restored backup for $1${NC}"
    fi
}

remove_config_link() {
    local target_dir="$HOME/.config/$1"

    if [ -L "$target_dir" ]; then
        rm -f "$target_dir"
        echo -e "${BLUE}Removed symlink for .config/$1${NC}"
    fi

    if [ -e "${target_dir}.dtbak" ]; then
        mv -f "${target_dir}.dtbak" "$target_dir"
        echo -e "${GREEN}Restored backup for .config/$1${NC}"
    fi
}

echo "Starting uninstallation..."

for file in "${FILES_TO_LINK[@]}"; do
    remove_link "$file"
done

for dir in "${CONFIG_DIRS[@]}"; do
    remove_config_link "$dir"
done

echo "Uninstalled"