# Dotfiles Repository - AI Coding Agent Instructions

## Architecture Overview

This is a **symlink-based dotfiles management system** for Linux/Unix shell environments. The core pattern:
- Dotfiles live in `~/dotfiles` (this repo)
- `install.sh` creates symlinks from `~/.bashrc` → `~/dotfiles/.bashrc`
- `uninstall.sh` removes symlinks and restores `.dtbak` backups

## Critical Install/Uninstall Mechanism

**Install pattern** (`install.sh`):
```bash
# Finds all dotfiles (.*), backs up existing files to {file}.dtbak, creates symlinks
for file in $(find . -maxdepth 1 -name ".*" -type f  -printf "%f\n" ); do
    if [ -e ~/$file ]; then
        mv -f ~/$file{,.dtbak}  # Backs up ~/.bashrc to ~/.bashrc.dtbak
    fi
    ln -s $PWD/$file ~/$file     # Creates symlink: ~/.bashrc → ~/dotfiles/.bashrc
done
```

**Uninstall pattern** (`uninstall.sh`):
```bash
# Removes symlinks, restores backups
for file in $(find . -maxdepth 1 -name ".*" -type f  -printf "%f\n" ); do
    if [ -h ~/$file ]; then
        rm -f ~/$file               # Removes symlink
    fi
    if [ -e ~/${file}.dtbak ]; then
        mv -f ~/$file{.dtbak,}      # Restores ~/.bashrc.dtbak to ~/.bashrc
    fi
done
```

## Bash Configuration Structure

Multi-file modular bash setup loaded in this order:
1. **`.bash_profile`** - Sources `.profile` if in tmux, then sources `.bashrc`
2. **`.bashrc`** - Main config (144 lines): PS1 prompt, history, colors, sources `.bash_aliases`
3. **`.bash_aliases`** - Command shortcuts (`gti='git'`, `yams`, `glog`, `cpv='rsync -ah --info=progress2'`)
4. **`.bash_exports`** - Environment variables (GOPATH, rbenv, EDITOR, LESSOPEN)
5. **`.bash_wrappers`** - Function definitions (`man()` coloring, `whatsgoingon()` git status check)

## Project-Specific Conventions

### Custom Backup Extension
- Uses `.dtbak` suffix (not `.bak` or `.backup`) for all backups
- Example: `~/.vimrc.dtbak` is the backup of `~/.vimrc`

### Colored Terminal Aesthetics
- Custom PS1 prompt with Unicode box-drawing characters: `┌──[user@host]─[path]\n└──╼ $`
- Shows red ✗ on command failure: `$([[ $? != 0 ]] && echo "[✗]─")`
- Colored man pages via `LESS_TERMCAP_*` environment variables in both `.bashrc` and `.bash_wrappers`

### Notable Aliases & Functions
- `yams` - Finds and lints all YAML files, excluding kitchen/molecule directories
- `glog` - Git log with `--oneline --graph --color --all --decorate`
- `whatsgoingon()` - Recursively checks git status in all subdirectories (one level deep)
- `cpv='rsync -ah --info=progress2'` - Copy with progress bar

### Language Environment Setup
Configured for:
- **Go**: `GOPATH=~/gocode`, adds `$GOPATH/bin` and `/usr/local/go/bin` to PATH
- **Ruby**: Uses rbenv with `eval "$(rbenv init -)"`
- **Perl**: Plenv config present but commented out

## Editing Dotfiles

When modifying dotfiles in this repo:
1. Edit files in `~/dotfiles/` directory (not in `~/`)
2. Changes take effect immediately via symlinks - no reinstall needed
3. For bash configs: Run `source ~/.bashrc` to reload without logout
4. Always preserve the modular structure (don't merge `.bash_aliases` into `.bashrc`)

## Testing Changes

```bash
# Test install without disrupting current setup
cd ~/dotfiles
./install.sh          # Backs up existing files automatically

# Verify symlinks created correctly
ls -la ~ | grep "\.bashrc\|\.vimrc"

# Test uninstall restores backups
./uninstall.sh
ls -la ~ | grep "\.dtbak"
```

## Vim Configuration Notes

`.vimrc` (342 lines) includes:
- Backup/undo/swap files stored in `~/.vim/tmp/{undo,backup,swap}/`
- Auto-creates those directories if missing
- `cmap w!! w !sudo tee > /dev/null %` - Save file with sudo after opening without it

## Tmux/Screen Setup

- **`.tmux.conf`**: 256-color, mouse off, status bar shows network interfaces (eth0/eth1/tun0/ppp0) and time
- **`.screenrc`**: 256-color, 30k scrollback, hardstatus line with window list
