# dotfiles

Managed configuration files for Bash, Tmux, WezTerm, Starship, and PowerShell.

**Version:** 0.3.1

## Features

- **Bash**: Modular configuration (aliases, exports, wrappers) with a robust custom prompt.
- **Tmux**: Streamlined status bar and shortcuts.
- **Starship**: Optional, high-performance cross-shell prompt. Easily toggleable.
- **WezTerm**: GPU-accelerated terminal emulator configuration.
- **Ripgrep**: Custom ignore rules for better performance.
- **Management Utilities**: Bash (`manage.sh`) and PowerShell (`manage.ps1`) managers for platform-native workflows.
- **Interactive Mode**: Running either manager with no arguments opens a simple command menu.

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

Management is handled via platform-native scripts.

```bash
./manage.sh [command] [options]
./manage.sh --interactive
./manage.sh
```

```powershell
./manage.ps1 [command] [options]
./manage.ps1 -Interactive
./manage.ps1
```

If no command is provided, each manager opens an interactive menu.

### Commands

| Command | `manage.sh` (Bash) | `manage.ps1` (PowerShell) |
| :--- | :--- | :--- |
| `install` | Symlinks Bash/Tmux/WezTerm dotfiles and optionally configures Starship. | Configures Starship for PowerShell and links Starship config. |
| `uninstall` | Removes symlinks and restores backups. | Removes Starship config link and managed PowerShell profile block. |
| `update` | Pulls latest changes from Git and re-runs install. | Pulls latest changes from Git and re-runs Starship setup. |
| `status` | Checks symlink, WezTerm, Bash, Starship, and PowerShell integration state. | Checks Starship + PowerShell profile integration state. |
| `toggle-starship` | Enables or disables Starship prompt via marker file. | Enables or disables Starship prompt via the same marker file. |
| `import-starship` | Imports current `~/.config/starship.toml` into `.config/starship.host.toml` as a local alternative. | Same behavior. |
| `use-starship` | Selects active Starship variant (`default` or `host`). | Same behavior. |
| `restore` | Restores a specific file from its `.dtbak` backup without full uninstall. | Same behavior. |
| `help` | Shows the help menu. | Shows the help menu. |

### Options

- `manage.sh`: `-i`, `--interactive`, `-n`, `--dry-run`, `-f`, `--force`
- `manage.ps1`: `-Interactive`, `-DryRun`, `-Force`

Selective restore examples:

```bash
./manage.sh restore .config/starship.toml
./manage.sh restore .bashrc
```

```powershell
./manage.ps1 restore .config/starship.toml
./manage.ps1 restore .bashrc
```

## Starship Prompt

[Starship](https://starship.rs) is an optional prompt that can be toggled on/off.

- **Enable/Disable**: `./manage.sh toggle-starship`
- **Check Status**: `./manage.sh status` or `./manage.ps1 status`

The configuration is linked to `~/.config/starship.toml`.

On Linux systems where `pwsh` is installed, `manage.sh` also configures the PowerShell profile with a managed Starship block.

### Optional Host Starship Variant

You can keep the repo-customized Starship config as default and maintain a local host alternative.

1. Import your current host config:

    ```bash
    ./manage.sh import-starship
    ```

    ```powershell
    ./manage.ps1 import-starship
    ```

2. Switch between variants:

    ```bash
    ./manage.sh use-starship default
    ./manage.sh use-starship host
    ```

    ```powershell
    ./manage.ps1 use-starship default
    ./manage.ps1 use-starship host
    ```

`host` variant is stored as `.config/starship.host.toml` and is ignored by Git by default.

## Documentation

- PowerShell usage and troubleshooting: `docs/powershell.md`
