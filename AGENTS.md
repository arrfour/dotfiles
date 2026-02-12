# AGENTS.md - AI Coding Guidelines for Dotfiles Repository

**Table of Contents:**
- [Project Overview](#project-overview)
- [Validation Workflow](#validation-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Architecture Rules](#architecture-rules)
- [Prompt Systems](#prompt-systems)
- [Platform Support](#platform-support)
- [Security & Hooks](#security--hooks)
- [Common Tasks](#common-tasks)
- [Testing Checklist](#testing-checklist)

## Project Overview

This is a **dotfiles management repository** providing Bash shell configurations, Tmux settings, and optional Starship prompt integration. The project uses a **symlink-based architecture** where files in `~/dotfiles/` are symlinked to `~/`.

## Validation Workflow

This project uses **pre-commit** for automated code validation. Catches errors before commits.  
**Install once**: `pip install pre-commit && pre-commit install`  
**Validates**: Shell syntax (shellcheck), YAML/TOML config, s***ets detection, file formatting

### Local Validation (Before Commit)

```bash
# Run all checks on staged files (automatic on git commit, or manual):
pre-commit run --all-files

# Run specific hook:
pre-commit run shellcheck --all-files

# Bypass if false positive (NOT recommended):
git commit --no-verify
```

### Manual Testing (Development)

```bash
# Check installation status:
./manage.sh status

# Test symlink creation (dry-run):
./manage.sh install -n

# Source and test bash modules:
source ~/.bash_aliases
source ~/.bash_exports
bash -n ~/.bashrc  # Syntax check

# Test Starship (if installed):
export STARSHIP_CONFIG=~/dotfiles/.config/starship.toml
starship config validate
starship prompt
```

## Code Style Guidelines

### Bash Scripts

**Indentation**: Use 4 spaces (no tabs)

**Function Names**: lowercase with underscores
```bash
# Good
link_file() { ... }
prompt_confirm() { ... }
install_starship() { ... }

# Bad
LinkFile() { ... }
linkfile() { ... }
```

**Variable Names**:
- Constants/Colors: UPPERCASE (e.g., `RED`, `FILES_TO_LINK`)
- Local variables: lowercase (e.g., `source_file`, `target_dir`)
- Flags: UPPERCASE (e.g., `DRY_RUN`, `FORCE`)

**Array Declaration**:
```bash
FILES_TO_LINK=(
    ".bash_aliases"
    ".bash_exports"
    ".bash_profile"
)
```

**Comments**: Full sentences with periods
```bash
# Check if target is already the correct symlink.
if [ -L "$target_file" ]; then
    ...
fi
```

**Error Handling**:
- Always check command exit codes
- Use `|| exit 1` for cd commands
- Provide meaningful error messages via `error()` function

**Color Coding**: Use the standard color functions
```bash
log() { echo -e "$1"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
success() { echo -e "${GREEN}[OK] $1${NC}"; }
```

### TOML Configuration (Starship)

**Section Headers**: Use descriptive comments
```toml
# ============================================
# LEFT SIDE - Essential Context
# ============================================

[username]
style_user = "bold white"
format = "[$user]($style)"
```

**String Quotes**:
- Use double quotes for strings with special characters
- Use triple quotes for multi-line commands
```toml
format = "[$path](bold green)"
command = """distro=$(grep ^ID= /etc/os-release); echo $distro"""
```

**Formatting**:
- Indent with 4 spaces
- Group related modules together
- Use `disabled = true/false` explicitly for clarity

## Architecture Rules

### Core Principles (from .github/copilot-instructions.md)

1. **Symlink-Based**: Files live in `~/dotfiles/`, symlinks point from `~/`
2. **Strict Allowlist**: Only files in `FILES_TO_LINK` and `CONFIG_DIRS` arrays are managed
3. **Modular Bash**: Separate concerns into:
   - `.bashrc`: Core config (history, completions)
   - `.bash_aliases`: Command shortcuts
   - `.bash_exports`: Environment variables  
   - `.bash_wrappers`: Functions
4. **No Vim**: This project does not manage Vim/Neovim configs

### File Management

**When Adding New Files**:
1. Add to `FILES_TO_LINK` array in `manage.sh`
2. Add to uninstall logic if cleanup needed
3. Update `manage.sh status` to check for the file

**Backup Convention**: Always use `.dtbak` extension for backups

**Safety Requirements**:
- Support `-n` (dry-run) flag
- Support `-f` (force) flag  
- Use confirmation prompts before destructive operations

**Adding Config Directories**:
1. Create directory under `.config/newdir/`
2. Add `"newdir"` to `CONFIG_DIRS` array in `manage.sh`
3. Update status check logic if special handling needed
4. Document in README

## Prompt Systems

This project supports **two prompt options**:

1. **Custom PS1** (default): Traditional bash prompt
   - Configured in `.bashrc` via `PROMPT_SYS_INFO`
   - Shows: user@host, distro/kernel, CPU, RAM, directory, exit status

2. **Starship** (optional): Modern cross-shell prompt
   - Config: `~/.config/starship.toml`
   - Install: `./manage.sh install` (select Starship option)
   - Switch: `./manage.sh update` (offers conversion menu)

When modifying Starship:
- Update `manage.sh` install_starship() function
- Update `manage.sh` uninstall_starship() function
- Maintain `.config/starship.toml` and `.config/system_info.sh`
- Ensure `manage.sh status` shows correct prompt state

## Platform Support

### Current Status

- **Linux**: ✅ Full support (primary target: Ubuntu 20.04+, Fedora 35+, Debian 11+)
- **macOS**: 📋 In development (cross-platform system info queries implemented)
- **PowerShell**: 📋 Planned (profile template at `.config/powershell/profile.ps1`)
- **BSD**: 📋 Experimental (FreeBSD/OpenBSD system info adapted, untested)

### Cross-Platform Pattern

Use `uname -s` to detect OS and call platform-appropriate commands:

```bash
# Example: Cross-platform CPU count
OS=$(uname -s)
if [[ "$OS" == "Linux" ]]; then
    cpu=$(nproc)
elif [[ "$OS" == "Darwin" ]]; then
    cpu=$(sysctl -n hw.ncpu)
else
    cpu="?"
fi
```

**Applied locations**:
- `.bashrc`: System info for prompt (lines ~58-84)
- `.config/system_info.sh`: Helper script for system info display

### Adding PowerShell Support

1. Edit `.config/powershell/profile.ps1` to add aliases/exports
2. Add to manage.sh `CONFIG_DIRS` array if not present
3. Document in README platform support matrix
4. Test on Windows Terminal: `$PROFILE` location varies

### Pre-commit Hook (Implemented in `.git/hooks/pre-commit`)

Blocks commits containing sensitive data:
- Private keys: RSA, OpenSSH, PGP
- AWS credentials: Access key ID, s***et keys
- Generic s***ets: Patterns matching `password`, `s***et`, `api_key`

**To bypass** (only if false positive): `git commit --no-verify`  
**Best practice**: Use `.local` files for sensitive config (ignored via `.gitignore`)

## Git Workflow

- **master**: Stable branch (roadmap and infrastructure only)
- **starship**: Feature branch for Starship prompt development
- Create feature branches for major changes
- Use descriptive commit messages

## Common Tasks

**Add a new alias**:
1. Edit `.bash_aliases`
2. Test: `source ~/.bash_aliases`
3. Commit

**Modify Starship config**:
1. Edit `.config/starship.toml`
2. Test: `export STARSHIP_CONFIG=~/dotfiles/.config/starship.toml && starship prompt`
3. Commit

**Add new management script**:
1. Create script in repo root
2. Add to `FILES_TO_LINK` in manage.sh
3. Make executable: `chmod +x scriptname`
4. Test with `./manage.sh install -n`
5. Commit

## Testing Checklist

Before committing changes:
- [ ] Auto-validation passes: `pre-commit run --all-files` (catches shellcheck, YAML, s***ets)
- [ ] Manual test: `./manage.sh status` (check symlinks)
- [ ] Dry-run test: `./manage.sh install -n` (safe verification)
- [ ] Verify symlinks created: `ls -la ~/.bashrc` (should point to dotfiles)
- [ ] Config validation: `starship config validate` (if Starship installed)
- [ ] Git commit: `git commit -m "..."` (hooks run automatically, block on issues)
