#!/usr/bin/env pwsh

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$CommandArg,

    [Alias("n")]
    [switch]$DryRun,

    [Alias("f")]
    [switch]$Force,

    [Alias("i")]
    [switch]$Interactive
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$STARSHIP_CONFIG_DEFAULT = ".config/starship.toml"
$STARSHIP_CONFIG_HOST = ".config/starship.host.toml"
$STARSHIP_TARGET_CONFIG = ".config/starship.toml"
$STARSHIP_VARIANT_FILE = ".config/starship_variant"
$POWERSHELL_BLOCK_START = "# >>> dotfiles starship >>>"
$POWERSHELL_BLOCK_END = "# <<< dotfiles starship <<<"

function Log {
    param([string]$Message)
    Write-Host $Message
}

function Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Error-Log {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Prompt-Confirm {
    param([string]$Prompt)

    if ($Force) {
        return $true
    }

    $response = Read-Host "$Prompt [y/N]"
    return $response -match '^[Yy]'
}

function Get-PowerShellProfilePaths {
    $paths = [System.Collections.Generic.List[string]]::new()

    if ($PROFILE.CurrentUserCurrentHost) {
        $paths.Add($PROFILE.CurrentUserCurrentHost)
    }

    $documents = [Environment]::GetFolderPath("MyDocuments")
    if ($documents) {
        $paths.Add((Join-Path $documents "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"))
        $paths.Add((Join-Path $documents "PowerShell\Microsoft.PowerShell_profile.ps1"))
    }

    return $paths | Select-Object -Unique
}

function Get-StarshipVariant {
    $variantPath = Join-Path $HOME $STARSHIP_VARIANT_FILE
    if (Test-Path -LiteralPath $variantPath) {
        $variant = (Get-Content -LiteralPath $variantPath -Raw).Trim()
        if ($variant -eq "host") {
            return "host"
        }
    }

    return "default"
}

function Get-StarshipSourceConfig {
    $variant = Get-StarshipVariant
    $hostPath = Join-Path $ScriptDir $STARSHIP_CONFIG_HOST
    if ($variant -eq "host" -and (Test-Path -LiteralPath $hostPath)) {
        return $hostPath
    }

    return (Join-Path $ScriptDir $STARSHIP_CONFIG_DEFAULT)
}

function Set-StarshipVariant {
    param([string]$Variant)

    if ($Variant -ne "default" -and $Variant -ne "host") {
        Error-Log "Invalid variant '$Variant'. Use 'default' or 'host'."
        exit 1
    }

    $hostPath = Join-Path $ScriptDir $STARSHIP_CONFIG_HOST
    if ($Variant -eq "host" -and -not (Test-Path -LiteralPath $hostPath)) {
        Error-Log "Host variant config is missing at $hostPath"
        Warn "Import one first with: ./manage.ps1 import-starship"
        exit 1
    }

    $variantPath = Join-Path $HOME $STARSHIP_VARIANT_FILE
    $sourcePath = if ($Variant -eq "host") { $hostPath } else { Join-Path $ScriptDir $STARSHIP_CONFIG_DEFAULT }
    $targetPath = Join-Path $HOME $STARSHIP_TARGET_CONFIG

    if ($DryRun) {
        Log "[DRY-RUN] Would set Starship variant to '$Variant' in $variantPath"
        Log "[DRY-RUN] Would link $sourcePath -> $targetPath"
        return
    }

    $variantDir = Split-Path -Parent $variantPath
    if (-not (Test-Path -LiteralPath $variantDir)) {
        New-Item -ItemType Directory -Path $variantDir -Force | Out-Null
    }

    Set-Content -LiteralPath $variantPath -Value $Variant
    Success "Starship variant set to '$Variant'"
    Link-ItemSafe -SourcePath $sourcePath -TargetPath $targetPath -Name "Starship Config"
}

function Import-HostStarshipConfig {
    $hostConfigPath = Join-Path $HOME $STARSHIP_TARGET_CONFIG
    $repoHostPath = Join-Path $ScriptDir $STARSHIP_CONFIG_HOST

    if (-not (Test-Path -LiteralPath $hostConfigPath)) {
        Error-Log "No host Starship config found at $hostConfigPath"
        exit 1
    }

    if ($DryRun) {
        if (Test-Path -LiteralPath $repoHostPath) {
            Log "[DRY-RUN] Would back up $repoHostPath to $repoHostPath.dtbak"
        }
        Log "[DRY-RUN] Would copy $hostConfigPath -> $repoHostPath"
        return
    }

    if (Test-Path -LiteralPath $repoHostPath) {
        if (-not (Prompt-Confirm "Host variant already exists. Overwrite and back up?")) {
            Warn "Skipping import."
            return
        }

        Copy-Item -LiteralPath $repoHostPath -Destination "$repoHostPath.dtbak" -Force
        Success "Backed up $repoHostPath"
    }

    Copy-Item -LiteralPath $hostConfigPath -Destination $repoHostPath -Force
    Success "Imported host Starship config to $repoHostPath"
    Warn "This file is intended as a local alternative and is gitignored by default."
}

function Test-IsCorrectSymlink {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        return $false
    }

    $item = Get-Item -LiteralPath $TargetPath -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }

    if ($null -eq $item.LinkType -or $null -eq $item.Target) {
        return $false
    }

    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
    $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
    return $resolvedTarget -eq $resolvedSource
}

function Link-ItemSafe {
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Warn "Source $SourcePath does not exist. Skipping."
        return
    }

    if (Test-IsCorrectSymlink -SourcePath $SourcePath -TargetPath $TargetPath) {
        Success "$Name is already linked correctly."
        return
    }

    if (Test-Path -LiteralPath $TargetPath) {
        if ($DryRun) {
            Log "[DRY-RUN] Would back up $TargetPath to $TargetPath.dtbak"
            Log "[DRY-RUN] Would link $SourcePath -> $TargetPath"
            return
        }

        if (-not (Prompt-Confirm "$Name exists at $TargetPath. Overwrite and back up?")) {
            Warn "Skipping $TargetPath"
            return
        }

        Move-Item -LiteralPath $TargetPath -Destination "$TargetPath.dtbak" -Force
        Success "Backed up $TargetPath"
    }

    if ($DryRun) {
        Log "[DRY-RUN] Would link $SourcePath -> $TargetPath"
        return
    }

    $targetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    try {
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
        Success "Linked $Name"
    }
    catch {
        Error-Log "Failed to link ${Name}: $($_.Exception.Message)"
        throw
    }
}

function Unlink-ItemSafe {
    param(
        [string]$TargetPath,
        [string]$Name
    )

    if (Test-Path -LiteralPath $TargetPath) {
        $item = Get-Item -LiteralPath $TargetPath -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType) {
            if ($DryRun) {
                Log "[DRY-RUN] Would remove symlink for $Name"
            }
            else {
                Remove-Item -LiteralPath $TargetPath -Force
                Log "Removed symlink for $Name"
            }
        }
    }

    if (Test-Path -LiteralPath "$TargetPath.dtbak") {
        if ($DryRun) {
            Log "[DRY-RUN] Would restore backup for $Name"
        }
        else {
            Move-Item -LiteralPath "$TargetPath.dtbak" -Destination $TargetPath -Force
            Success "Restored backup for $Name"
        }
    }
}

function Install-PowerShellStarshipProfiles {
    $managedBlock = @'
# >>> dotfiles starship >>>
if (Get-Command starship -ErrorAction SilentlyContinue) {
    if (-not (Test-Path "$HOME/.config/starship_disabled")) {
        $env:STARSHIP_CONFIG = "$HOME/.config/starship.toml"
        Invoke-Expression (&starship init powershell)
    }
}
# <<< dotfiles starship <<<
'@

    foreach ($profilePath in Get-PowerShellProfilePaths) {
        $profileDir = Split-Path -Parent $profilePath

        if ($DryRun) {
            Log "[DRY-RUN] Would ensure profile exists at $profilePath"
        }
        else {
            if (-not (Test-Path -LiteralPath $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $profilePath)) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }
        }

        $content = ""
        if (Test-Path -LiteralPath $profilePath) {
            $content = Get-Content -LiteralPath $profilePath -Raw
        }

        if ($content -match [regex]::Escape($POWERSHELL_BLOCK_START)) {
            Success "PowerShell profile already has Starship integration: $profilePath"
            continue
        }

        if ($DryRun) {
            Log "[DRY-RUN] Would add managed Starship block to $profilePath"
            continue
        }

        if ($content.Length -gt 0 -and -not (Test-Path -LiteralPath "$profilePath.dtbak")) {
            Copy-Item -LiteralPath $profilePath -Destination "$profilePath.dtbak"
            Success "Backed up $profilePath"
        }

        Add-Content -LiteralPath $profilePath -Value "`r`n$managedBlock`r`n"
        Success "Configured Starship in $profilePath"
    }
}

function Uninstall-PowerShellStarshipProfiles {
    $pattern = '(?ms)^# >>> dotfiles starship >>>\r?\n.*?^# <<< dotfiles starship <<<\r?\n?'

    foreach ($profilePath in Get-PowerShellProfilePaths) {
        if (-not (Test-Path -LiteralPath $profilePath)) {
            continue
        }

        $content = Get-Content -LiteralPath $profilePath -Raw
        if ($content -notmatch [regex]::Escape($POWERSHELL_BLOCK_START)) {
            continue
        }

        if ($DryRun) {
            Log "[DRY-RUN] Would remove managed Starship block from $profilePath"
            continue
        }

        $updated = [regex]::Replace($content, $pattern, '')
        Set-Content -LiteralPath $profilePath -Value $updated
        Success "Removed managed Starship block from $profilePath"
    }
}

function Install-Starship {
    Log "Checking Starship..."
    $sourceConfigPath = Get-StarshipSourceConfig

    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        if ($DryRun) {
            Log "[DRY-RUN] Would install Starship binary"
        }
        elseif (Prompt-Confirm "Starship not found. Install with winget?") {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install --id Starship.Starship -e
            }
            else {
                Warn "winget not available. Install Starship manually from https://starship.rs"
            }
        }
        else {
            Warn "Skipping Starship binary installation."
        }
    }
    else {
        Success "Starship binary is installed"
    }

    Link-ItemSafe -SourcePath $sourceConfigPath -TargetPath (Join-Path $HOME $STARSHIP_TARGET_CONFIG) -Name "Starship Config"
    Install-PowerShellStarshipProfiles
}

function Uninstall-Starship {
    Unlink-ItemSafe -TargetPath (Join-Path $HOME $STARSHIP_TARGET_CONFIG) -Name "Starship Config"
    Uninstall-PowerShellStarshipProfiles
    Log "Starship configuration removed."
    Log "Note: The Starship binary was NOT removed. Remove it manually if desired."
}

function Toggle-Starship {
    $disabledMarker = Join-Path $HOME ".config/starship_disabled"

    if (Test-Path -LiteralPath $disabledMarker) {
        if ($DryRun) {
            Log "[DRY-RUN] Would remove $disabledMarker (enable Starship)"
        }
        else {
            Remove-Item -LiteralPath $disabledMarker -Force
            Success "Starship enabled. Reload shell for changes."
        }
    }
    else {
        if ($DryRun) {
            Log "[DRY-RUN] Would create $disabledMarker (disable Starship)"
        }
        else {
            $configDir = Split-Path -Parent $disabledMarker
            if (-not (Test-Path -LiteralPath $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }
            New-Item -ItemType File -Path $disabledMarker -Force | Out-Null
            Success "Starship disabled. Reload shell for changes."
        }
    }
}

function Resolve-RestoreTargetPath {
    param([string]$Target)

    if ([System.IO.Path]::IsPathRooted($Target)) {
        return $Target
    }

    if ($Target.StartsWith("~/") -or $Target.StartsWith("~\")) {
        return (Join-Path $HOME $Target.Substring(2))
    }

    return (Join-Path $HOME $Target)
}

function Restore-BackupItem {
    param([string]$Target)

    if (-not $Target) {
        Error-Log "Missing restore target. Usage: ./manage.ps1 restore <home-relative-or-absolute-path>"
        Warn "Example: ./manage.ps1 restore .config/starship.toml"
        exit 1
    }

    $targetPath = Resolve-RestoreTargetPath -Target $Target
    $backupPath = "$targetPath.dtbak"

    if (-not (Test-Path -LiteralPath $backupPath)) {
        Error-Log "Backup not found: $backupPath"
        exit 1
    }

    if ($DryRun) {
        Log "[DRY-RUN] Would restore $backupPath -> $targetPath"
        return
    }

    if (Test-Path -LiteralPath $targetPath) {
        if (-not (Prompt-Confirm "Target exists at $targetPath. Overwrite with backup?")) {
            Warn "Restore cancelled."
            return
        }
        Remove-Item -LiteralPath $targetPath -Force -Recurse
    }

    $targetDir = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Move-Item -LiteralPath $backupPath -Destination $targetPath -Force
    Success "Restored $targetPath from backup"
}

function Update-Repo {
    Log "=== Updating Dotfiles ==="

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Error-Log "git is required for update command."
        exit 1
    }

    $branch = (git branch --show-current).Trim()
    if (git pull origin $branch) {
        Success "Repository updated successfully."
        if (Prompt-Confirm "Update/Install Starship configuration?") {
            Install-Starship
        }
    }
    else {
        Error-Log "Failed to pull updates."
        exit 1
    }
}

function Print-Status {
    Write-Host "--- Prompt Status ---" -ForegroundColor Blue

    if (Get-Command starship -ErrorAction SilentlyContinue) {
        $version = (starship --version | Select-Object -First 1)
        Write-Host "Starship:         Installed ($version)" -ForegroundColor Green
    }
    else {
        Write-Host "Starship:         Not Installed" -ForegroundColor Yellow
    }

    $disabledMarker = Join-Path $HOME ".config/starship_disabled"
    if (Test-Path -LiteralPath $disabledMarker) {
        Write-Host "Starship Status:  Disabled (via config)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Starship Status:  Enabled" -ForegroundColor Green
    }

    $configPath = Join-Path $HOME $STARSHIP_TARGET_CONFIG
    if (Test-Path -LiteralPath $configPath) {
        $item = Get-Item -LiteralPath $configPath -Force
        if ($item.LinkType) {
            Write-Host "Starship Config:  Linked" -ForegroundColor Green
        }
        else {
            Write-Host "Starship Config:  File exists (not symlinked)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Starship Config:  Not Found" -ForegroundColor Yellow
    }

    $variant = Get-StarshipVariant
    if ($variant -eq "host") {
        Write-Host "Starship Variant: Host" -ForegroundColor Green
    }
    else {
        Write-Host "Starship Variant: Default" -ForegroundColor Green
    }

    $hostVariantPath = Join-Path $ScriptDir $STARSHIP_CONFIG_HOST
    if (Test-Path -LiteralPath $hostVariantPath) {
        Write-Host "Host Variant:     Available" -ForegroundColor Green
    }
    else {
        Write-Host "Host Variant:     Not imported" -ForegroundColor Yellow
    }

    foreach ($profilePath in Get-PowerShellProfilePaths) {
        if (-not (Test-Path -LiteralPath $profilePath)) {
            Write-Host "Profile:          Missing ($profilePath)" -ForegroundColor Yellow
            continue
        }

        $content = Get-Content -LiteralPath $profilePath -Raw
        if ($content -match [regex]::Escape($POWERSHELL_BLOCK_START)) {
            Write-Host "Profile:          Starship managed block present ($profilePath)" -ForegroundColor Green
        }
        else {
            Write-Host "Profile:          Block missing ($profilePath)" -ForegroundColor Yellow
        }
    }

    $policy = $null
    try {
        $policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction Stop
    }
    catch {
        $policyKey = "HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
        if (Test-Path -LiteralPath $policyKey) {
            $policy = (Get-ItemProperty -Path $policyKey -Name ExecutionPolicy -ErrorAction SilentlyContinue).ExecutionPolicy
        }
    }

    if (-not $policy) {
        Write-Host "ExecutionPolicy:  Unknown (could not query policy)" -ForegroundColor Yellow
    }
    elseif ($policy -eq "Restricted") {
        Write-Host "ExecutionPolicy:  Restricted (profile scripts may be blocked)" -ForegroundColor Yellow
    }
    else {
        Write-Host "ExecutionPolicy:  $policy" -ForegroundColor Green
    }
}

function Show-Help {
    Write-Host "Dotfiles Manager (PowerShell)" -ForegroundColor Blue
    Write-Host "Usage: ./manage.ps1 [command] [options]"
    Write-Host "       ./manage.ps1 -Interactive"
    Write-Host "       ./manage.ps1               (no args opens menu)"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  install          Link Starship config and configure PowerShell profiles"
    Write-Host "  uninstall        Remove Starship links/managed PowerShell profile blocks"
    Write-Host "  update           Pull latest changes and re-sync Starship"
    Write-Host "  status           Check health of Starship and profile integration"
    Write-Host "  toggle-starship  Enable/Disable Starship prompt"
    Write-Host "  import-starship  Import current host Starship config as local variant"
    Write-Host "  use-starship     Select Starship variant (default|host)"
    Write-Host "  restore          Restore one file from .dtbak backup"
    Write-Host "  help             Show this menu"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Interactive     Open interactive menu"
    Write-Host "  -DryRun          Run without making changes"
    Write-Host "  -Force           Skip confirmation prompts"
}

function Interactive-Menu {
    Write-Host "Dotfiles Manager (PowerShell)" -ForegroundColor Blue
    Write-Host ""
    Write-Host "1) install"
    Write-Host "2) uninstall"
    Write-Host "3) update"
    Write-Host "4) status"
    Write-Host "5) toggle-starship"
    Write-Host "6) import-starship"
    Write-Host "7) use-starship (default)"
    Write-Host "8) use-starship (host)"
    Write-Host "9) help"
    Write-Host "10) restore backup"
    Write-Host "11) quit"
    Write-Host ""

    $choice = Read-Host "Select an option [1-11]"
    switch ($choice) {
        "1" { $script:Command = "install" }
        "2" { $script:Command = "uninstall" }
        "3" { $script:Command = "update" }
        "4" { $script:Command = "status" }
        "5" { $script:Command = "toggle-starship" }
        "6" { $script:Command = "import-starship" }
        "7" { $script:Command = "use-starship"; $script:CommandArg = "default" }
        "8" { $script:Command = "use-starship"; $script:CommandArg = "host" }
        "9" { $script:Command = "help" }
        "10" {
            $script:Command = "restore"
            $script:CommandArg = Read-Host "Enter path to restore (home-relative or absolute)"
        }
        default { $script:Command = "" }
    }
}

if (-not $Command) {
    $Interactive = $true
}

if ($Interactive) {
    Interactive-Menu
    if (-not $Command) {
        exit 0
    }
}

switch ($Command) {
    "install" {
        Install-Starship
        Log ""
        Success "Installation complete. Restart your terminal."
    }
    "uninstall" {
        Uninstall-Starship
        Log ""
        Success "Uninstallation complete."
    }
    "update" {
        Update-Repo
    }
    "status" {
        Print-Status
    }
    "toggle-starship" {
        Toggle-Starship
    }
    "import-starship" {
        Import-HostStarshipConfig
    }
    "use-starship" {
        if (-not $CommandArg) {
            Error-Log "Missing variant. Usage: ./manage.ps1 use-starship [default|host]"
            exit 1
        }
        Set-StarshipVariant -Variant $CommandArg
    }
    "restore" {
        Restore-BackupItem -Target $CommandArg
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
