# dotfiles

## TL;DR

Customized configuration files for Bash and Tmux.

- **Bash**: Modularized with separate aliases, exports, and wrappers. Enhanced multiline prompt with system info.
- **Tmux**: Streamlined status bar with network/VPN info and pane-resize shortcuts.
- **Optional**: [Starship](https://starship.rs/) prompt for a modern, cross-shell experience.

### Prompt Preview

The prompt is multiline, color-coded, and includes dynamic status indicators:

**Normal state:**
```text
┌──[user@hostname]─[debian 5.15.0 | 4C | 15Gi]─[~/Projects/dotfiles]
└──╼ $ 
```

**After a failed command:**
```text
┌──[✗]─[user@hostname]─[debian 5.15.0 | 4C | 15Gi]─[~/Projects/dotfiles]
└──╼ $ 
```

**Components:**
- **Exit status**: Red `[✗]` appears when the previous command fails
- **User@hostname**: Color-coded (red for root, white for normal user)
- **System info**: Shows distro, kernel version, CPU cores, and total RAM
- **Working directory**: Current path in green

---

## Requirements

To fully utilize these dotfiles, the following tools are recommended/required:

- **Shell**: `bash`, `rsync`, `colordiff`, `yamllint`
- **Tmux**: `tmux` (v2.1+)
- **Optional**: `starship` (modern cross-shell prompt, auto-installed via script)

### Starship Requirements

If you choose to use Starship (offered during installation):
- **Font**: A [Nerd Font](https://www.nerdfonts.com/) for full icon support (e.g., FiraCode Nerd Font, JetBrainsMono Nerd Font)
- **Compatibility**: Works on Linux, macOS, and Windows (via WSL)

## Installation

```bash
cd ~
git clone https://github.com/arrfour/dotfiles.git

cd dotfiles
```

### Run install

```bash
./install.sh
```

## Notes

- Ripgrep ignore rules are included to avoid runaway scans on large folders
  (cache directories, container/flatpak storage, and GoogleDrive), which can
  spike CPU usage when file searches recurse through the home directory.

## Updating

To pull the latest changes and refresh your configurations:

```bash
./update.sh
```

## Starship Prompt (Optional)

[Starship](https://starship.rs/) is a minimal, blazing-fast, and infinitely customizable cross-shell prompt written in Rust.

### Features

- **Fast**: Renders in under 5ms, even in large Git repositories
- **Cross-platform**: Same configuration works on Linux, macOS, and Windows
- **Rich context**: Shows Git status, programming language versions, AWS/Kubernetes context, and more
- **Easy configuration**: Single TOML file for all settings

### Installation

Starship is offered as an optional component during `./install.sh`. Simply answer "y" when prompted.

### Manual Installation

```bash
# Install Starship
curl -sS https://starship.rs/install.sh | sh

# The install script will automatically:
# - Install the starship binary
# - Link the configuration file
# - Add initialization to .bashrc
```

### Switching Between Prompts

Use the update script to switch between your custom PS1 and Starship:

```bash
./update.sh
```

This will show a menu allowing you to:
- Convert to Starship (install and enable)
- Revert to custom PS1 (disable Starship)

### Configuration

The Starship configuration is located at `~/.config/starship.toml`. The default configuration mimics your custom PS1 structure while adding Git and language support.

**Key differences from custom PS1:**
- Git branch and status shown automatically in Git repositories
- Programming language versions (Python, Node.js, Rust, Go) when in project directories
- AWS profile and Kubernetes context (if enabled)
- Asynchronous rendering - no prompt lag

### Uninstallation

To remove Starship configuration while keeping the binary:

```bash
./manage.sh status  # Check current prompt status
./update.sh         # Select "Revert to custom PS1"
```

To completely remove the Starship binary:

```bash
rm ~/.local/bin/starship  # or wherever it was installed
```

---

## Uninstallation

### Change to dotfiles folder

```bash
cd ~/dotfiles
```

### Run uninstaller

```bash
./uninstall.sh
```

## Changelog

### Major Changes

- **Removed Vim configuration**: The project no longer manages Vim/Neovim configuration files.
- **Added Starship support**: Optional modern cross-shell prompt with PS1/Starship conversion via update script.
- **Enhanced update script**: Now offers prompt configuration switching between custom PS1 and Starship.

### Security Fixes

- Removed `alias _='sudo'` from `.bashrc`.
- Added strict file allowlist to `install.sh` and `uninstall.sh`.
- Added pre-commit hook to block secrets.

### Improvements

- `install.sh` now supports `-n` (dry-run) and `-f` (force).
- Added safety prompts before overwriting files.
- Added backup creation (`.dtbak`) for existing files.
- Added Starship installation option with automatic .bashrc configuration.
