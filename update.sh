#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) return 1;;
        esac
    done
}

convert_to_starship() {
    log "${BLUE}Converting from custom PS1 to Starship...${NC}"
    
    # Run the Starship installation
    ./install.sh -f <<< ""
    
    log ""
    success "Conversion complete!"
    log "The custom PS1 in .bashrc has been disabled (commented out)"
    log "Starship is now active."
    log ""
    log "To switch back, run: ./update.sh and select 'Revert to custom PS1'"
}

revert_to_ps1() {
    log "${BLUE}Reverting from Starship to custom PS1...${NC}"
    
    local bashrc="$HOME/.bashrc"
    
    # Remove starship init from .bashrc
    if [ -f "$bashrc" ]; then
        if grep -q "starship init bash" "$bashrc"; then
            # Backup first
            cp "$bashrc" "${bashrc}.pre-revert"
            
            # Remove starship lines
            sed -i '/# Initialize Starship prompt/d' "$bashrc"
            sed -i '/starship init bash/d' "$bashrc"
            success "Removed Starship initialization from .bashrc"
        fi
    fi
    
    # Remove starship config symlink
    local starship_target="$HOME/.config/starship.toml"
    if [ -L "$starship_target" ]; then
        rm -f "$starship_target"
        success "Removed Starship config symlink"
    fi
    
    log ""
    success "Reverted to custom PS1!"
    log "Restart your terminal or run: source ~/.bashrc"
}

show_prompt_menu() {
    log "${BLUE}=== Prompt Configuration ===${NC}"
    log ""
    log "Current prompt status:"
    
    # Check if starship is installed
    if command -v starship &> /dev/null; then
        log "  Starship: ${GREEN}Installed${NC}"
    else
        log "  Starship: ${YELLOW}Not installed${NC}"
    fi
    
    # Check if starship is active in bashrc
    if [ -f "$HOME/.bashrc" ] && grep -q "starship init bash" "$HOME/.bashrc"; then
        log "  Starship active: ${GREEN}Yes${NC}"
    else
        log "  Starship active: ${YELLOW}No${NC}"
    fi
    
    # Check if custom PS1 is present
    if [ -f "$HOME/.bashrc" ] && grep -q "PROMPT_SYS_INFO" "$HOME/.bashrc"; then
        log "  Custom PS1: ${GREEN}Present${NC}"
    else
        log "  Custom PS1: ${YELLOW}Not found${NC}"
    fi
    
    log ""
    log "Options:"
    log "  1) Install/enable Starship (modern cross-shell prompt)"
    log "  2) Revert to custom PS1 (disable Starship)"
    log "  3) Skip prompt configuration"
    log ""
    
    read -p "Select an option [1-3]: " choice
    
    case $choice in
        1)
            convert_to_starship
            ;;
        2)
            if prompt_confirm "This will disable Starship and use the custom PS1. Continue?"; then
                revert_to_ps1
            else
                log "Cancelled."
            fi
            ;;
        3)
            log "Skipping prompt configuration."
            ;;
        *)
            warn "Invalid option. Skipping prompt configuration."
            ;;
    esac
}

# Main update flow
log "${BLUE}=== Updating Dotfiles ===${NC}"
log ""

# Update the local repository from the remote
echo "Checking for updates..."
BRANCH=$(git branch --show-current)
git pull origin "$BRANCH"

if [ $? -ne 0 ]; then
    error "Failed to pull updates. Please resolve any conflicts and try again."
    exit 1
fi

log ""
success "Repository updated successfully."
log ""

# Prompt configuration section
if prompt_confirm "Would you like to configure your prompt (PS1 vs Starship)?"; then
    show_prompt_menu
else
    log "Skipping prompt configuration."
fi

log ""
log "Re-applying configurations..."
./install.sh

log ""
success "Update complete!"
log ""
log "Next steps:"
log "  - Restart your terminal or run: source ~/.bashrc"
