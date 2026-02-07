#!/bin/bash

# Configuration
# Files/Directories to symlink relative to the repo root
# Add new dotfiles here to be included in the installation
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

# Config directories to handle separately
CONFIG_DIRS=(
    "ripgrep"
    "wezterm"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true ;;
        -f|--force) FORCE=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

log() {
    echo -e "$1"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

prompt_confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) return 1;;
        esac
    done
}

link_file() {
    local source_file="$PWD/$1"
    local target_file="$HOME/$1"

    if [ ! -e "$source_file" ]; then
        warn "Source file $source_file does not exist. Skipping."
        return
    fi

    # Check if target is already the correct symlink
    if [ -L "$target_file" ] && [ "$(readlink -f "$target_file")" == "$source_file" ]; then
        success "$1 is already linked correctly."
        return
    fi

    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would backup $target_file to ${target_file}.dtbak"
            log "[DRY-RUN] Would link $source_file -> $target_file"
            return
        fi

        if prompt_confirm "File $target_file exists. Overwrite and backup?"; then
            # Backup existing file/link
            mv -f "$target_file" "${target_file}.dtbak"
            success "Backed up $target_file"
        else
            warn "Skipping $target_file"
            return
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would link $source_file -> $target_file"
    else
        ln -s "$source_file" "$target_file"
        success "Linked $1"
    fi
}

link_config_dir() {
    local source_dir="$PWD/.config/$1"
    local target_base="$HOME/.config"
    local target_dir="$target_base/$1"

    mkdir -p "$target_base"

    if [ ! -d "$source_dir" ]; then
        warn "Source config dir $source_dir does not exist. Skipping."
        return
    fi

    # Check if target is already the correct symlink
    if [ -L "$target_dir" ] && [ "$(readlink -f "$target_dir")" == "$source_dir" ]; then
        success ".config/$1 is already linked correctly."
        return
    fi

    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would backup $target_dir to ${target_dir}.dtbak"
            log "[DRY-RUN] Would link $source_dir -> $target_dir"
            return
        fi

        if prompt_confirm "Config dir $target_dir exists. Replace with symlink (backup existing)?"; then
             mv -f "$target_dir" "${target_dir}.dtbak"
             success "Backed up $target_dir"
        else
            warn "Skipping $target_dir"
            return
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would link $source_dir -> $target_dir"
    else
        ln -snf "$source_dir" "$target_dir"
        success "Linked .config/$1"
    fi
}

# Main Execution
log "Starting installation..."
if [ "$DRY_RUN" = true ]; then
    log "${YELLOW}Running in DRY-RUN mode. No changes will be made.${NC}"
fi

for file in "${FILES_TO_LINK[@]}"; do
    link_file "$file"
done

for dir in "${CONFIG_DIRS[@]}"; do
    link_config_dir "$dir"
done

log "Installation complete."
