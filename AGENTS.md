# AGENTS.md - AI Coding Guidelines for Dotfiles Repository

## Project Overview

This is a **dotfiles management repository** providing Bash shell configurations, Tmux settings, and optional Starship prompt integration. The project uses a **symlink-based architecture** where files in `~/dotfiles/` are symlinked to `~/`.

## Build, Lint, and Test Commands

### Linting

```bash
# Lint all shell scripts
shellcheck *.sh .config/*.sh

# Lint specific file
shellcheck manage.sh

# Lint with severity filter
shellcheck --severity=warning manage.sh
```

### Testing

This project has **no automated test suite**. Testing is manual:

```bash
# Check installation status
./manage.sh status

# Test symlink creation (dry-run)
./manage.sh install -n

# Verify specific file is linked
ls -la ~/.bashrc  # Should show symlink to dotfiles

# Test Starship configuration
export STARSHIP_CONFIG=~/dotfiles/.config/starship.toml
starship config validate
starship prompt

# Test in different directories
cd /tmp && starship prompt
cd ~/dotfiles && starship prompt
```

### Running Single Components

```bash
# Source specific configuration files
source ~/.bash_aliases
source ~/.bash_exports

# Test bash configuration
bash -n ~/.bashrc  # Syntax check only

# Test manage.sh subcommands
./manage.sh install -n  # Dry-run
./manage.sh status
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

## Pre-commit Hook

A security hook blocks commits containing:
- Private keys (RSA, OpenSSH, PGP)
- AWS access keys
- Password/secret/api_key patterns

To bypass (if false positive): `git commit --no-verify`

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
- [ ] Run `shellcheck` on modified scripts
- [ ] Test with `./manage.sh status`
- [ ] Test dry-run: `./manage.sh install -n`
- [ ] Verify symlinks created correctly
- [ ] Test Starship config: `starship config validate`
- [ ] Check pre-commit hook passes: `git commit` (will block if secrets found)
