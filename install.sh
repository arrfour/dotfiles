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
)

# Optional: Starship prompt configuration
STARSHIP_CONFIG=".config/starship.toml"

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

install_starship() {
    log "Installing Starship prompt..."
    
    if command -v starship &> /dev/null; then
        success "Starship is already installed"
    else
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would install Starship via official install script"
        else
            log "Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            if [ $? -eq 0 ]; then
                success "Starship installed successfully"
            else
                error "Failed to install Starship"
                return 1
            fi
        fi
    fi
    
    # Check if starship config should be linked
    local starship_source="$PWD/$STARSHIP_CONFIG"
    local starship_target="$HOME/$STARSHIP_CONFIG"
    
    if [ -f "$starship_source" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would link Starship config: $starship_source -> $starship_target"
        else
            # Backup existing config if present
            if [ -f "$starship_target" ] && [ ! -L "$starship_target" ]; then
                mv -f "$starship_target" "${starship_target}.dtbak"
                success "Backed up existing Starship config"
            fi
            
            # Create parent directory if needed
            mkdir -p "$(dirname "$starship_target")"
            
            # Remove existing symlink if present
            if [ -L "$starship_target" ]; then
                rm -f "$starship_target"
            fi
            
            ln -s "$starship_source" "$starship_target"
            success "Linked Starship config"
        fi
    else
        warn "Starship config not found at $STARSHIP_CONFIG. Skipping config link."
    fi
    
    # Link system_info.sh helper script
    local system_info_source="$PWD/.config/system_info.sh"
    local system_info_target="$HOME/.config/system_info.sh"
    
    if [ -f "$system_info_source" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would link system_info.sh: $system_info_source -> $system_info_target"
        else
            if [ -f "$system_info_target" ] && [ ! -L "$system_info_target" ]; then
                mv -f "$system_info_target" "${system_info_target}.dtbak"
                success "Backed up existing system_info.sh"
            fi
            
            if [ -L "$system_info_target" ]; then
                rm -f "$system_info_target"
            fi
            
            ln -s "$system_info_source" "$system_info_target"
            success "Linked system_info.sh"
        fi
    fi
    
    # Add starship init to .bashrc if not present
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        if ! grep -q "starship init bash" "$bashrc"; then
            if [ "$DRY_RUN" = true ]; then
                log "[DRY-RUN] Would add Starship initialization to .bashrc"
            else
                echo "" >> "$bashrc"
                echo "# Initialize Starship prompt" >> "$bashrc"
                echo 'eval "$(starship init bash)"' >> "$bashrc"
                success "Added Starship initialization to .bashrc"
            fi
        else
            success "Starship initialization already present in .bashrc"
        fi
    fi
    
    log ""
    log "NOTE: Starship requires a Nerd Font for full functionality."
    log "Install one from: https://www.nerdfonts.com/"
    log ""
}

uninstall_starship() {
    log "Removing Starship..."
    
    # Remove starship init from .bashrc
    local bashrc="$HOME/.bashrc"
    if [ -f "$bashrc" ]; then
        if grep -q "starship init bash" "$bashrc"; then
            if [ "$DRY_RUN" = true ]; then
                log "[DRY-RUN] Would remove Starship initialization from .bashrc"
            else
                # Create a backup and remove starship lines
                sed -i '/# Initialize Starship prompt/d' "$bashrc"
                sed -i '/starship init bash/d' "$bashrc"
                success "Removed Starship initialization from .bashrc"
            fi
        fi
    fi
    
    # Remove starship config symlink
    local starship_target="$HOME/$STARSHIP_CONFIG"
    if [ -L "$starship_target" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would remove Starship config symlink"
        else
            rm -f "$starship_target"
            success "Removed Starship config symlink"
        fi
    fi
    
    # Remove system_info.sh symlink
    local system_info_target="$HOME/.config/system_info.sh"
    if [ -L "$system_info_target" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would remove system_info.sh symlink"
        else
            rm -f "$system_info_target"
            success "Removed system_info.sh symlink"
        fi
    fi
    
    # Note: We don't uninstall the starship binary itself - user can do that manually
    log "Starship configuration removed. Binary remains installed."
    log "To remove the binary: rm ~/.local/bin/starship (or your install location)"
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

# Prompt for Starship installation
log ""
log "${YELLOW}--- Optional Components ---${NC}"
if prompt_confirm "Would you like to install Starship (modern cross-shell prompt)?"; then
    install_starship
else
    log "Skipping Starship installation."
fi

log ""
success "Installation complete."
log ""
log "Next steps:"
log "  - Restart your terminal or run: source ~/.bashrc"
log "  - If you installed Starship, install a Nerd Font from: https://www.nerdfonts.com/"
