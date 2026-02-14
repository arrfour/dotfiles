# Changelog

All notable changes to this project are documented in this file.

## [0.3.1] - 2026-02-14

### Added
- Added `manage.ps1` as a native PowerShell manager with `install`, `uninstall`, `update`, `status`, `toggle-starship`, `import-starship`, `use-starship`, and `restore` commands.
- Added cross-manager Starship variant support:
  - `import-starship` to capture a host config into `.config/starship.host.toml`
  - `use-starship [default|host]` to switch active Starship source
- Added selective backup restore command (`restore`) in both managers to recover individual files from `.dtbak` without full uninstall.
- Added PowerShell documentation at `docs/powershell.md`.

### Changed
- Expanded `manage.sh` to detect `pwsh` and manage a marked Starship init block in PowerShell profiles.
- Updated `README.md` for dual-manager usage, Starship variants, and selective restore workflows.
- Bumped project version to `0.3.1`.

### Fixed
- Improved symlink error handling in `manage.ps1` so failed link operations report as errors instead of false success.
- Added fallback execution-policy reporting in `manage.ps1 status` when `Get-ExecutionPolicy` is not available.
