# dotfiles

Managed configuration files for Bash, Tmux, WezTerm, and more.

**Version:** 0.2.0

## Features

- **Bash**: Modular configuration (aliases, exports, wrappers) with a robust custom prompt.
- **Tmux**: Streamlined status bar and shortcuts.
- **Starship**: Optional, high-performance cross-shell prompt. Easily toggleable.
- **WezTerm**: GPU-accelerated terminal emulator configuration.
- **Ripgrep**: Custom ignore rules for better performance.
- **Management Utility**: A single script (`manage.sh`) to handle installation, updates, and maintenance.
- **Interactive Mode**: Running `manage.sh` with no arguments opens a simple command menu.

## Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/arrfour/dotfiles.git
    cd dotfiles
    ```

2. Run the installer:

    ```bash
    ./manage.sh install
    ```

    - The script will back up existing files to `*.dtbak` before overwriting.
    - You will be prompted to install/configure Starship.

## Usage

All management is handled via `manage.sh`.

```bash
./manage.sh [command] [options]
./manage.sh --interactive
./manage.sh
```

If no command is provided, `manage.sh` opens an interactive menu.

### Commands

| Command | Description |
| :--- | :--- |
| `install` | Symlinks dotfiles to your home directory. |
| `uninstall` | Removes symlinks and restores backups. |
| `update` | Pulls the latest changes from Git and re-runs install. |
| `status` | Checks the health of symlinks, WezTerm, and Starship. |
| `toggle-starship` | Enables or disables the Starship prompt without uninstalling. |
| `help` | Shows the help menu. |

### Options

- `-n`, `--dry-run`: Show what would happen without making changes.
- `-f`, `--force`: Skip confirmation prompts.
- `-i`, `--interactive`: Open the interactive command menu.

## Starship Prompt

[Starship](https://starship.rs) is an optional prompt that can be toggled on/off.

- **Enable/Disable**: `./manage.sh toggle-starship`
- **Check Status**: `./manage.sh status`

The configuration is linked to `~/.config/starship.toml`.
