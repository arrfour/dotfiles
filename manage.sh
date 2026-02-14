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
STARSHIP_CONFIG_DEFAULT=".config/starship.toml"
STARSHIP_CONFIG_HOST=".config/starship.host.toml"
STARSHIP_TARGET_CONFIG=".config/starship.toml"
STARSHIP_VARIANT_FILE=".config/starship_variant"
SYSTEM_INFO_SCRIPT=".config/system_info.sh"
POWERSHELL_BLOCK_START="# >>> dotfiles starship >>>"
POWERSHELL_BLOCK_END="# <<< dotfiles starship <<<"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
FORCE=false
INTERACTIVE=false

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
             if ln -snf "$source_path" "$target_path"; then
                 success "Linked $item_name"
             else
                 error "Failed to link $item_name"
                 return 1
             fi
        else
             if ln -s "$source_path" "$target_path"; then
                 success "Linked $item_name"
             else
                 error "Failed to link $item_name"
                 return 1
             fi
        fi
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

get_starship_variant() {
    local variant_file="$HOME/$STARSHIP_VARIANT_FILE"

    if [ -f "$variant_file" ]; then
        local variant
        variant="$(tr -d '[:space:]' < "$variant_file")"
        if [ "$variant" = "host" ]; then
            echo "host"
            return
        fi
    fi

    echo "default"
}

get_starship_source_config() {
    local variant
    variant="$(get_starship_variant)"

    if [ "$variant" = "host" ] && [ -f "$PWD/$STARSHIP_CONFIG_HOST" ]; then
        echo "$PWD/$STARSHIP_CONFIG_HOST"
        return
    fi

    echo "$PWD/$STARSHIP_CONFIG_DEFAULT"
}

set_starship_variant() {
    local requested_variant="$1"
    local variant_file="$HOME/$STARSHIP_VARIANT_FILE"
    local source_config

    if [ "$requested_variant" != "default" ] && [ "$requested_variant" != "host" ]; then
        error "Invalid variant '$requested_variant'. Use 'default' or 'host'."
        return 1
    fi

    if [ "$requested_variant" = "host" ] && [ ! -f "$PWD/$STARSHIP_CONFIG_HOST" ]; then
        error "Host variant config is missing at $PWD/$STARSHIP_CONFIG_HOST"
        warn "Import one first with: ./manage.sh import-starship"
        return 1
    fi

    source_config="$( [ "$requested_variant" = "host" ] && echo "$PWD/$STARSHIP_CONFIG_HOST" || echo "$PWD/$STARSHIP_CONFIG_DEFAULT" )"

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would set Starship variant to '$requested_variant' in $variant_file"
        log "[DRY-RUN] Would link $source_config -> $HOME/$STARSHIP_TARGET_CONFIG"
        return 0
    fi

    mkdir -p "$HOME/.config"
    printf "%s\n" "$requested_variant" > "$variant_file"
    success "Starship variant set to '$requested_variant'"

    link_item "$source_config" "$HOME/$STARSHIP_TARGET_CONFIG" "Starship Config"
}

import_host_starship_config() {
    local host_config_path="$HOME/$STARSHIP_TARGET_CONFIG"
    local repo_host_config_path="$PWD/$STARSHIP_CONFIG_HOST"

    if [ ! -f "$host_config_path" ] && [ ! -L "$host_config_path" ]; then
        error "No host Starship config found at $host_config_path"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        if [ -e "$repo_host_config_path" ]; then
            log "[DRY-RUN] Would backup $repo_host_config_path to ${repo_host_config_path}.dtbak"
        fi
        log "[DRY-RUN] Would copy $host_config_path -> $repo_host_config_path"
        return 0
    fi

    if [ -e "$repo_host_config_path" ]; then
        if prompt_confirm "Host variant already exists. Overwrite and backup?"; then
            cp "$repo_host_config_path" "${repo_host_config_path}.dtbak"
            success "Backed up $repo_host_config_path"
        else
            warn "Skipping import."
            return 1
        fi
    fi

    cp "$host_config_path" "$repo_host_config_path"
    success "Imported host Starship config to $repo_host_config_path"
    warn "This file is intended as a local alternative and is gitignored by default."
}

restore_backup_item() {
    local requested_path="$1"
    local target_path
    local backup_path

    if [ -z "$requested_path" ]; then
        error "Missing restore target. Usage: ./manage.sh restore <home-relative-or-absolute-path>"
        warn "Example: ./manage.sh restore .config/starship.toml"
        return 1
    fi

    case "$requested_path" in
        ~/*)
            target_path="$HOME/${requested_path#~/}"
            ;;
        /*)
            target_path="$requested_path"
            ;;
        *)
            target_path="$HOME/$requested_path"
            ;;
    esac

    backup_path="${target_path}.dtbak"

    if [ ! -e "$backup_path" ]; then
        error "Backup not found: $backup_path"
        return 1
    fi

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would restore $backup_path -> $target_path"
        return 0
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if ! prompt_confirm "Target exists at $target_path. Overwrite with backup?"; then
            warn "Restore cancelled."
            return 1
        fi
        if [ -d "$target_path" ] && [ ! -L "$target_path" ]; then
            rm -rf "$target_path"
        else
            rm -f "$target_path"
        fi
    fi

    mkdir -p "$(dirname "$target_path")"
    mv -f "$backup_path" "$target_path"
    success "Restored $target_path from backup"
}

get_pwsh_profile_path() {
    if ! command -v pwsh &> /dev/null; then
        return
    fi

    pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost' 2>/dev/null | tr -d '\r'
}

install_pwsh_starship_profile() {
    local profile_path
    local profile_dir
    local managed_block

    if ! command -v pwsh &> /dev/null; then
        return
    fi

    profile_path="$(get_pwsh_profile_path)"
    if [ -z "$profile_path" ]; then
        warn "PowerShell 7 detected, but profile path could not be resolved."
        return
    fi

    profile_dir="$(dirname "$profile_path")"
    managed_block="$POWERSHELL_BLOCK_START
if (Get-Command starship -ErrorAction SilentlyContinue) {
    if (-not (Test-Path \"\$HOME/.config/starship_disabled\")) {
        \$env:STARSHIP_CONFIG = \"\$HOME/.config/starship.toml\"
        Invoke-Expression (&starship init powershell)
    }
}
$POWERSHELL_BLOCK_END"

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would ensure PowerShell profile exists at $profile_path"
        if [ -f "$profile_path" ] && grep -Fq "$POWERSHELL_BLOCK_START" "$profile_path"; then
            log "[DRY-RUN] PowerShell profile already contains managed Starship block"
        else
            log "[DRY-RUN] Would add managed Starship block to PowerShell profile"
        fi
        return
    fi

    mkdir -p "$profile_dir"
    if [ ! -f "$profile_path" ]; then
        touch "$profile_path"
    fi

    if grep -Fq "$POWERSHELL_BLOCK_START" "$profile_path"; then
        success "PowerShell profile already has Starship integration"
        return
    fi

    if [ -s "$profile_path" ] && [ ! -e "${profile_path}.dtbak" ]; then
        cp "$profile_path" "${profile_path}.dtbak"
        success "Backed up PowerShell profile to ${profile_path}.dtbak"
    fi

    printf "\n%s\n" "$managed_block" >> "$profile_path"
    success "Configured Starship for PowerShell profile"
}

uninstall_pwsh_starship_profile() {
    local profile_path

    if ! command -v pwsh &> /dev/null; then
        return
    fi

    profile_path="$(get_pwsh_profile_path)"
    if [ -z "$profile_path" ] || [ ! -f "$profile_path" ]; then
        return
    fi

    if ! grep -Fq "$POWERSHELL_BLOCK_START" "$profile_path"; then
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove managed Starship block from $profile_path"
        return
    fi

    awk -v start="$POWERSHELL_BLOCK_START" -v end="$POWERSHELL_BLOCK_END" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    skip == 0 { print }
    ' "$profile_path" > "${profile_path}.tmp" && mv "${profile_path}.tmp" "$profile_path"

    success "Removed managed Starship block from PowerShell profile"
}

install_starship() {
    log "Checking Starship..."
    local starship_source_config
    
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
    starship_source_config="$(get_starship_source_config)"
    link_item "$starship_source_config" "$HOME/$STARSHIP_TARGET_CONFIG" "Starship Config"
    
    # Link Helper Script
    link_item "$PWD/$SYSTEM_INFO_SCRIPT" "$HOME/$SYSTEM_INFO_SCRIPT" "System Info Script"

    # Configure PowerShell profile for Starship when PowerShell 7 is available.
    install_pwsh_starship_profile

    # Note on .bashrc:
    # We no longer modify .bashrc directly here because the user requested
    # a safe check in .bashrc itself. The consolidated management script
    # relies on .bashrc having the "if command -v starship" block.
}

uninstall_starship() {
    unlink_item "$HOME/$STARSHIP_TARGET_CONFIG" "Starship Config"
    unlink_item "$HOME/$SYSTEM_INFO_SCRIPT" "System Info Script"
    uninstall_pwsh_starship_profile
    
    log "Starship configuration removed." 
    log "Note: The Starship binary was NOT removed. Remove it manually if desired."
}

toggle_starship() {
    if [ -f "$HOME/.config/starship_disabled" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would remove $HOME/.config/starship_disabled (enable Starship)"
        else
            rm "$HOME/.config/starship_disabled"
            success "Starship enabled. Reload shell for changes."
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would create $HOME/.config/starship_disabled (disable Starship)"
        else
            mkdir -p "$HOME/.config"
            touch "$HOME/.config/starship_disabled"
            success "Starship disabled. Reload shell for changes."
        fi
    fi
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
    
    # Check Disabled Status
    if [ -f "$HOME/.config/starship_disabled" ]; then
        echo -e "Starship Status:  ${YELLOW}Disabled (via config)${NC}"
    else
        echo -e "Starship Status:  ${GREEN}Enabled${NC}"
    fi
    
    # Check Starship config
    if [ -h "$HOME/$STARSHIP_TARGET_CONFIG" ]; then
        echo -e "Starship Config:  ${GREEN}Linked${NC}"
    elif [ -f "$HOME/$STARSHIP_TARGET_CONFIG" ]; then
        echo -e "Starship Config:  ${YELLOW}File exists (not symlinked)${NC}"
    else
        echo -e "Starship Config:  ${YELLOW}Not Found${NC}"
    fi

    if [ "$(get_starship_variant)" = "host" ]; then
        echo -e "Starship Variant: ${GREEN}Host${NC}"
    else
        echo -e "Starship Variant: ${GREEN}Default${NC}"
    fi

    if [ -f "$PWD/$STARSHIP_CONFIG_HOST" ]; then
        echo -e "Host Variant:     ${GREEN}Available${NC}"
    else
        echo -e "Host Variant:     ${YELLOW}Not imported${NC}"
    fi
    
    # Check if Starship logic is present in bashrc
    if [ -f "$HOME/.bashrc" ] && grep -q "command -v starship" "$HOME/.bashrc"; then
        echo -e "Bashrc Logic:     ${GREEN}Safe Check Present${NC}"
    elif [ -f "$HOME/.bashrc" ] && grep -q "starship init bash" "$HOME/.bashrc"; then
        echo -e "Bashrc Logic:     ${YELLOW}Legacy Init (Make conditional!)${NC}"
    else
        echo -e "Bashrc Logic:     ${YELLOW}Not Found${NC}"
    fi

    # Check PowerShell 7 profile integration when available.
    if command -v pwsh &> /dev/null; then
        local pwsh_profile
        pwsh_profile="$(get_pwsh_profile_path)"

        if [ -n "$pwsh_profile" ] && [ -f "$pwsh_profile" ]; then
            if grep -Fq "$POWERSHELL_BLOCK_START" "$pwsh_profile"; then
                echo -e "PowerShell 7:     ${GREEN}Managed Starship block present${NC}"
            else
                echo -e "PowerShell 7:     ${YELLOW}Profile found, Starship block missing${NC}"
            fi
        else
            echo -e "PowerShell 7:     ${YELLOW}Not configured${NC}"
        fi
    else
        echo -e "PowerShell 7:     ${YELLOW}Not installed${NC}"
    fi
}

show_help() {
    echo -e "${BLUE}Dotfiles Manager${NC}"
    echo -e "Usage: $0 [command] [options]"
    echo -e "       $0 --interactive"
    echo -e "       $0               (no args opens menu)"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}install${NC}   Symlink dotfiles to home directory"
    echo -e "             Options: -f/--force, -n/--dry-run"
    echo -e "  ${GREEN}uninstall${NC} Remove symlinks and restore backups"
    echo -e "             Options: -n/--dry-run"
    echo -e "  ${GREEN}update${NC}    Pull latest changes and re-sync"
    echo -e "  ${GREEN}status${NC}    Check health of the installation"
    echo -e "  ${GREEN}toggle-starship${NC} Enable/Disable Starship prompt"
    echo -e "  ${GREEN}import-starship${NC} Import current host Starship config as local variant"
    echo -e "  ${GREEN}use-starship${NC} Select Starship variant (default|host)"
    echo -e "  ${GREEN}restore${NC}   Restore one file from .dtbak backup"
    echo -e "  ${GREEN}help${NC}      Show this menu"
    echo -e "             Example: ./manage.sh use-starship host"
    echo -e "             Example: ./manage.sh restore .config/starship.toml"
    echo ""
    echo "Options:"
    echo -e "  -i, --interactive  Open interactive menu"
    echo -e "  -n, --dry-run      Run without making changes"
    echo -e "  -f, --force        Skip confirmation prompts"
}

interactive_menu() {
    echo -e "${BLUE}Dotfiles Manager${NC}"
    echo ""
    echo "1) install"
    echo "2) uninstall"
    echo "3) update"
    echo "4) status"
    echo "5) toggle-starship"
    echo "6) import-starship"
    echo "7) use-starship (default)"
    echo "8) use-starship (host)"
    echo "9) restore backup"
    echo "10) help"
    echo "11) quit"
    echo ""

    read -r -p "Select an option [1-11]: " choice
    case "$choice" in
        1) COMMAND="install" ;;
        2) COMMAND="uninstall" ;;
        3) COMMAND="update" ;;
        4) COMMAND="status" ;;
        5) COMMAND="toggle-starship" ;;
        6) COMMAND="import-starship" ;;
        7) COMMAND="use-starship"; COMMAND_ARG="default" ;;
        8) COMMAND="use-starship"; COMMAND_ARG="host" ;;
        9) COMMAND="restore"; read -r -p "Enter path to restore (home-relative or absolute): " COMMAND_ARG ;;
        10) COMMAND="help" ;;
        11) COMMAND="" ;;
        *) COMMAND="" ;;
    esac
}

# ==============================================================================
# Main Execution
# ==============================================================================

# Parse Args
COMMAND=""
COMMAND_ARG=""
if [ "$#" -eq 0 ]; then
    INTERACTIVE=true
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true ;;
        -f|--force) FORCE=true ;;
        -i|--interactive) INTERACTIVE=true ;;
        install|uninstall|update|status|toggle-starship|import-starship|use-starship|restore|help)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            elif [ -z "$COMMAND_ARG" ]; then
                COMMAND_ARG="$1"
            fi
            ;;
        *)
            if [ -z "$COMMAND" ]; then
                COMMAND="$1"
            elif [ -z "$COMMAND_ARG" ]; then
                COMMAND_ARG="$1"
            fi
            ;;
    esac
    shift
done

if [ "$INTERACTIVE" = true ]; then
    interactive_menu
    if [ -z "$COMMAND" ]; then
        exit 0
    fi
fi

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
    toggle-starship)
        toggle_starship
        ;;
    import-starship)
        import_host_starship_config
        ;;
    use-starship)
        if [ -z "$COMMAND_ARG" ]; then
            error "Missing variant. Usage: ./manage.sh use-starship [default|host]"
            exit 1
        fi
        set_starship_variant "$COMMAND_ARG"
        ;;
    restore)
        restore_backup_item "$COMMAND_ARG"
        ;;
    *)
        show_help
        ;;
esac
