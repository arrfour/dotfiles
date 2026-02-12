# Dotfiles AI Instructions

## Core Architecture
- **Symlink-based**: Repo at `~/dotfiles`. Symlinks in `~` point to repo files.
- **Management**: `manage.sh` links files (backups as `*.dtbak`), unlinks them, and provides status checks.
- **Strict Allowlist**: Only files explicitly listed in `manage.sh` arrays are managed.
- **No Vim**: This project no longer manages Vim/Neovim configurations.

## Bash Modularity
- **Entry**: `.bash_profile` -> `.bashrc`.
- **Components**: 
  - `.bashrc`: Core config (history, completions, basic settings).
  - `.bash_aliases`: Command shortcuts.
  - `.bash_exports`: Environment variables.
  - `.bash_wrappers`: Functions.
- **Rule**: Maintain separation of concerns. Do not pollute `.bashrc` with aliases/exports.

## Prompt Options
This project supports two prompt systems:

1. **Custom PS1** (default): Traditional bash prompt with multiline system info
   - Configured in `.bashrc` via `PROMPT_SYS_INFO` variable
   - Shows: user@host, distro/kernel, CPU count, RAM, working directory, exit status

2. **Starship** (optional): Modern cross-shell prompt
   - Installed via `./manage.sh install` (interactive prompt)
   - Config: `~/.config/starship.toml`
   - Features: Git status, programming languages, cloud contexts, async rendering
   - Switch via: `./manage.sh update` (offers conversion menu)

## Conventions
- **Backups**: Always use `.dtbak` extension.
- **Safety**: Script changes must support `dry-run` (`-n`) and confirmation prompts.
- **Git**: Pre-commit hook (implemented in `.git/hooks/pre-commit`) blocks secrets and credentials from being committed.

## Development Rules
1. **Edit Location**: Always edit files in `~/dotfiles/`, never the symlink target in `~/`.
2. **Reloading**: Suggest `source ~/.bashrc` for shell changes.
3. **New Files**: If creating a new dotfile, you MUST add it to the `FILES_TO_LINK` and `CONFIG_DIRS` arrays in `manage.sh`.
4. **Starship Changes**: When modifying Starship support:
   - Update `manage.sh` (install_starship and uninstall_starship functions)
   - Update symlink logic for `.config/starship.toml`
   - Maintain `.config/starship.toml` in the repo
   - Ensure `manage.sh status` shows correct prompt state
