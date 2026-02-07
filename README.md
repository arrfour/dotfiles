# dotfiles

## TL;DR

Customized configuration files for Bash, Vim, and Tmux.

- **Bash**: Modularized with separate aliases, exports, and wrappers. Colored man pages and enhanced prompt.
- **Vim**: Plugin-ready with Pathogen, pre-configured for NERDTree, Airline, and DevOps tools (Ansible/Terraform).
- **Tmux**: Streamlined status bar with network/VPN info and pane-resize shortcuts.

### Prompt Preview

The new prompt is multiline, color-coded, and includes dynamic status indicators:

```text
┌──[user@hostname]─[~/Projects/dotfiles]
└──╼ $ 
```

*(If a command fails, a red `[✗]` indicator appears in the top line.)*

---

## Requirements

To fully utilize these dotfiles, the following tools and plugins are recommended/required:

- **Shell**: `bash`, `rsync`, `colordiff`, `yamllint`
- **Vim**: `pathogen`, `NERDTree`, `vim-airline`, `ansible-vim`, `vim-hashicorp-terraform`
- **Tmux**: `tmux` (v2.1+)

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

### Security Fixes

- Removed `alias _='sudo'` from `.bashrc`.
- Added strict file allowlist to `install.sh` and `uninstall.sh`.
- Added pre-commit hook to block secrets.

### Improvements

- `install.sh` now supports `-n` (dry-run) and `-f` (force).
- Added safety prompts before overwriting files.
- Added backup creation (`.dtbak`) for existing files.
