# Dotfiles AI Instructions

## Core Architecture
- **Symlink-based**: Repo at `~/dotfiles`. Symlinks in `~` point to repo files.
- **Management**: `install.sh` links files (backups as `*.dtbak`). `uninstall.sh` removes links/restores backups.
- **Strict Allowlist**: Only files explicitly listed in `install.sh` arrays are managed.

## Bash Modularity
- **Entry**: `.bash_profile` -> `.bashrc`.
- **Components**: 
  - `.bashrc`: Core config (prompt, history).
  - `.bash_aliases`: Command shortcuts.
  - `.bash_exports`: Environment variables.
  - `.bash_wrappers`: Functions.
- **Rule**: Maintain separation of concerns. Do not pollute `.bashrc` with aliases/exports.

## Conventions
- **Backups**: Always use `.dtbak` extension.
- **Prompt**: Multiline with system info `[distro kernel | CPU | mem]` and exit code status.
- **Safety**: Script changes must support `dry-run` (`-n`) and confirmation prompts.
- **Git**: Pre-commit hook blocks secrets.

## Development Rules
1. **Edit Location**: Always edit files in `~/dotfiles/`, never the symlink target in `~/`.
2. **Reloading**: Suggest `source ~/.bashrc` for shell changes.
3. **New Files**: If creating a new dotfile, you MUST add it to `install.sh` and `uninstall.sh` arrays.
