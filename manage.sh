#!/bin/bash

# Dotfiles Management Utility
# Handles Install, Uninstall, Update, and Status Check

# ==============================================================================
# Configuration
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

# Files/Directories to symlink relative to the repo root
FILES_TO_LINK=(
    ".bash_aliases"
    ".bash_exports"
    ".bash_profile"
    ".bash_wrappers"
    ".bashrc"
    ".screenrc"
    ".tmux.conf"
)

# Config directories to handle separately
CONFIG_DIRS=(
    "ripgrep"
    "wezterm"
)

# Optional components
STARSHIP_CONFIG=".config/starship.toml"
SYSTEM_INFO_SCRIPT=".config/system_info.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
FORCE=false

# ==============================================================================
# Helpers
# ==============================================================================

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

# ==============================================================================
# Core Logic: Symlink Manager
# ==============================================================================

link_item() {
    local source_path="$1"
    local target_path="$2"
    local item_name="$3"

    if [ ! -e "$source_path" ]; then
        warn "Source $source_path does not exist. Skipping."
        return
    fi

    # Check if target is already the correct symlink
    if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
        success "$item_name is already linked correctly."
        return
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would backup $target_path to ${target_path}.dtbak"
            log "[DRY-RUN] Would link $source_path -> $target_path"
            return
        fi

        if prompt_confirm "$item_name exists at $target_path. Overwrite and backup?"; then
            mv -f "$target_path" "${target_path}.dtbak"
            success "Backed up $target_path"
        else
            warn "Skipping $target_path"
            return
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would link $source_path -> $target_path"
    else
        mkdir -p "$(dirname "$target_path")"
        if [ -d "$source_path" ]; then
             ln -snf "$source_path" "$target_path"
        else
             ln -s "$source_path" "$target_path"
        fi
        success "Linked $item_name"
    fi
}

unlink_item() {
    local target_path="$1"
    local item_name="$2"

    if [ -L "$target_path" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would remove symlink for $item_name"
        else
            rm -f "$target_path"
            echo -e "${BLUE}Removed symlink for $item_name${NC}"
        fi
    fi

    if [ -e "${target_path}.dtbak" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would restore backup for $item_name"
        else
            mv -f "${target_path}.dtbak" "$target_path"
            echo -e "${GREEN}Restored backup for $item_name${NC}"
        fi
    fi
}

install_dotfiles() {
    log "Starting installation..."
    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}Running in DRY-RUN mode. No changes will be made.${NC}"
    fi

    for file in "${FILES_TO_LINK[@]}"; do
        link_item "$PWD/$file" "$HOME/$file" "$file"
    done

    for dir in "${CONFIG_DIRS[@]}"; do
        link_item "$PWD/.config/$dir" "$HOME/.config/$dir" ".config/$dir"
    done
}

uninstall_dotfiles() {
    log "Starting uninstallation..."
    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}Running in DRY-RUN mode. No changes will be made.${NC}"
    fi

    for file in "${FILES_TO_LINK[@]}"; do
        unlink_item "$HOME/$file" "$file"
    done

    for dir in "${CONFIG_DIRS[@]}"; do
        unlink_item "$HOME/.config/$dir" ".config/$dir"
    done
}

# ==============================================================================
# Core Logic: Starship Manager
# ==============================================================================

install_starship() {
    log "Checking Starship..."
    
    if ! command -v starship &> /dev/null; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would install Starship binary"
        else
            if prompt_confirm "Starship not found. Install it?"; then
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            else
                warn "Skipping Starship binary installation."
            fi
        fi
    else
        success "Starship binary is installed"
    fi

    # Link Config
    link_item "$PWD/$STARSHIP_CONFIG" "$HOME/$STARSHIP_CONFIG" "Starship Config"
    
    # Link Helper Script
    link_item "$PWD/$SYSTEM_INFO_SCRIPT" "$HOME/$SYSTEM_INFO_SCRIPT" "System Info Script"

    # Note on .bashrc:
    # We no longer modify .bashrc directly here because the user requested
    # a safe check in .bashrc itself. The consolidated management script
    # relies on .bashrc having the "if command -v starship" block.
}

uninstall_starship() {
    unlink_item "$HOME/$STARSHIP_CONFIG" "Starship Config"
    unlink_item "$HOME/$SYSTEM_INFO_SCRIPT" "System Info Script"
    
    log "Starship configuration removed." 
    log "Note: The Starship binary was NOT removed. Remove it manually if desired."
}

# ==============================================================================
# Core Logic: Repo Manager
# ==============================================================================

update_repo() {
    log "${BLUE}=== Updating Dotfiles ===${NC}"
    echo "Checking for updates..."
    BRANCH=$(git branch --show-current)
    
    if git pull origin "$BRANCH"; then
        success "Repository updated successfully."
        # Re-run install to apply any new dotfiles/configs
        install_dotfiles
        # Check specific starship update logic if preferred, or just rely on generic install
        if prompt_confirm "Update/Install Starship configuration?"; then
            install_starship
        fi
    else
         error "Failed to pull updates."
         exit 1
    fi
}

# ==============================================================================
# Core Logic: Status Checker
# ==============================================================================

print_status() {
    echo -e "${BLUE}--- System Status ---${NC}"
    
    # Check WezTerm Flatpak
    if flatpak list | grep -q "org.wezfurlong.wezterm" 2>/dev/null; then
        echo -e "WezTerm Flatpak:  ${GREEN}Installed${NC}"
    else
        echo -e "WezTerm Flatpak:  ${YELLOW}Not Found${NC}"
    fi

    # Check Symlinks
    if [ -h "$HOME/.config/wezterm" ]; then
        echo -e "WezTerm Config:   ${GREEN}Linked${NC}"
    else
        echo -e "WezTerm Config:   ${YELLOW}Missing Link${NC}"
    fi

    # Check KDE Default
    KDE_TERM=$(kreadconfig5 --file kdeglobals --group General --key TerminalApplication 2>/dev/null)
    if [ "$KDE_TERM" == "org.wezfurlong.wezterm" ]; then
        echo -e "KDE Default Term: ${GREEN}Correct ($KDE_TERM)${NC}"
    else
        echo -e "KDE Default Term: ${YELLOW}Different ($KDE_TERM)${NC}"
    fi

    # Check Environment
    if [[ "$TERMINAL" == *"wezterm"* ]]; then
        echo -e "Env Variable:     ${GREEN}Set ($TERMINAL)${NC}"
    else
        echo -e "Env Variable:     ${YELLOW}Not found in current session${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}--- Prompt Status ---${NC}"
    
    # Check Starship
    if command -v starship &> /dev/null; then
        STARSHIP_VERSION=$(starship --version | head -n1)
        echo -e "Starship:         ${GREEN}Installed ($STARSHIP_VERSION)${NC}"
    else
        echo -e "Starship:         ${YELLOW}Not Installed${NC}"
    fi
    
    # Check Starship config
    if [ -h "$HOME/.config/starship.toml" ]; then
        echo -e "Starship Config:  ${GREEN}Linked${NC}"
    elif [ -f "$HOME/.config/starship.toml" ]; then
        echo -e "Starship Config:  ${YELLOW}File exists (not symlinked)${NC}"
    else
        echo -e "Starship Config:  ${YELLOW}Not Found${NC}"
    fi
    
    # Check if Starship logic is present in bashrc
    if [ -f "$HOME/.bashrc" ] && grep -q "command -v starship" "$HOME/.bashrc"; then
        echo -e "Bashrc Logic:     ${GREEN}Safe Check Present${NC}"
    elif [ -f "$HOME/.bashrc" ] && grep -q "starship init bash" "$HOME/.bashrc"; then
        echo -e "Bashrc Logic:     ${YELLOW}Legacy Init (Make conditional!)${NC}"
    else
        echo -e "Bashrc Logic:     ${YELLOW}Not Found${NC}"
    fi
}

show_help() {
    echo -e "${BLUE}Dotfiles Manager${NC}"
    echo -e "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}install${NC}   Symlink dotfiles to home directory"
    echo -e "             Options: -f/--force, -n/--dry-run"
    echo -e "  ${GREEN}uninstall${NC} Remove symlinks and restore backups"
    echo -e "             Options: -n/--dry-run"
    echo -e "  ${GREEN}update${NC}    Pull latest changes and re-sync"
    echo -e "  ${GREEN}status${NC}    Check health of the installation"
    echo -e "  ${GREEN}help${NC}      Show this menu"
}

# ==============================================================================
# Main Execution
# ==============================================================================

# Parse Command
COMMAND="$1"
shift

# Parse Shared Flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true ;;
        -f|--force) FORCE=true ;;
        *) ;;
    esac
    shift
done

case "$COMMAND" in
    install)
        install_dotfiles
        if prompt_confirm "Would you like to install/configure Starship?"; then
            install_starship
        fi
        log ""
        success "Installation complete. Restart your terminal."
        ;;
    uninstall)
        uninstall_dotfiles
        if prompt_confirm "Uninstall Starship configuration?"; then
            uninstall_starship
        fi
        log ""
        success "Uninstallation complete."
        ;;
    update)
        update_repo
        ;;
    status)
        print_status
        ;;
    *)
        show_help
        ;;
esac
