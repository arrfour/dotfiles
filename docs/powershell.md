# PowerShell Manager Guide

This repository supports a native PowerShell manager at `manage.ps1`.

## Scope

- `manage.sh` remains the primary manager for Bash and POSIX dotfiles.
- `manage.ps1` manages Starship + PowerShell profile integration on Windows.

## Commands

```powershell
./manage.ps1 install
./manage.ps1 uninstall
./manage.ps1 update
./manage.ps1 status
./manage.ps1 toggle-starship
./manage.ps1 import-starship
./manage.ps1 use-starship default
./manage.ps1 use-starship host
./manage.ps1 restore .config/starship.toml
./manage.ps1 help
```

Options:

- `-Interactive`
- `-DryRun`
- `-Force`

## What Install Does

`install` performs these actions:

1. Ensures Starship is installed (offers `winget` install when missing).
2. Links repo Starship config to `~/.config/starship.toml`.
3. Adds a managed Starship block to both profile targets when available:
   - PowerShell 7 profile (`$PROFILE.CurrentUserCurrentHost`)
   - Windows PowerShell 5.1 profile (`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`)

The profile block is idempotent and only managed within marker lines.

## Variant Workflow (Default vs Host)

Default behavior uses repo config: `.config/starship.toml`.

You can import your host config as an optional local alternative:

```powershell
./manage.ps1 import-starship
```

This stores a local copy in `.config/starship.host.toml`.

Switch active variant:

```powershell
./manage.ps1 use-starship default
./manage.ps1 use-starship host
```

The selected variant is tracked in `~/.config/starship_variant`.

## Selective Backup Restore

Use `restore` to recover one file from its `.dtbak` backup without uninstalling.

```powershell
./manage.ps1 restore .config/starship.toml
./manage.ps1 restore .bashrc
./manage.ps1 restore C:\Users\drew\.config\starship.toml
```

## Common Troubleshooting

- **Profile is blocked by execution policy (Windows PowerShell 5.1).**

  Run:

  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```

- **Symlink creation fails on Windows.**

  Use one of:

  - Enable Developer Mode in Windows, or
  - Run shell elevated (Administrator).

- **Changes do not show immediately.**

  Open a new terminal tab/window, or reload profile:

  ```powershell
  . $PROFILE
  ```
