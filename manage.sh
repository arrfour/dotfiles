#!/bin/bash

# Dotfiles Management Utility
# Handles Install, Uninstall, Update, and Status Check

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

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
    
    # Check if Starship is active
    if [ -f "$HOME/.bashrc" ] && grep -q "starship init bash" "$HOME/.bashrc"; then
        echo -e "Starship Active:  ${GREEN}Yes${NC}"
    else
        echo -e "Starship Active:  ${YELLOW}No${NC}"
    fi
    
    # Check Custom PS1
    if [ -f "$HOME/.bashrc" ] && grep -q "PROMPT_SYS_INFO" "$HOME/.bashrc"; then
        echo -e "Custom PS1:       ${GREEN}Present${NC}"
    else
        echo -e "Custom PS1:       ${YELLOW}Not Found${NC}"
    fi
}

show_help() {
    echo -e "${BLUE}Dotfiles Manager${NC}"
    echo -e "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}install${NC}   Symlink dotfiles to home directory"
    echo -e "  ${GREEN}update${NC}    Pull latest changes and re-sync"
    echo -e "  ${GREEN}uninstall${NC} Remove symlinks and restore backups"
    echo -e "  ${GREEN}status${NC}    Check health of the installation"
    echo -e "  ${GREEN}help${NC}      Show this menu"
}

case "$1" in
    install)
        ./install.sh
        ;;
    uninstall)
        ./uninstall.sh
        ;;
    update)
        ./update.sh
        ;;
    status)
        print_status
        ;;
    *)
        show_help
        ;;
esac
