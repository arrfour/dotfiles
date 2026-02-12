# PowerShell Profile for Windows Terminal Integration
# Place this at: $PROFILE (usually C:\Users\<username>\Documents\PowerShell\profile.ps1)
#
# This file mirrors the bash aliases and exports in the dotfiles repository
# for consistent command-line experience across Linux and Windows environments.

# Check if running in Windows Terminal
$isWindowsTerminal = $env:WT_SESSION -ne $null

# Import bash-like aliases (when implemented)
# TODO: Add PowerShell equivalents of .bash_aliases

# Set up common environment variables (similar to .bash_exports)
$env:EDITOR = "code"
$env:VISUAL = "code"
$env:TERM = "xterm-256color"

# Example: Git aliases
if (Get-Command git -ErrorAction SilentlyContinue) {
    Set-Alias -Name git-log-pretty -Value { git log --oneline --graph --all }
    Set-Alias -Name git-status -Value { git status --short }
}

# Example: Custom prompt (optional)
# function Prompt {
#     $host.ui.RawUI.WindowTitle = "$env:USERNAME@$env:COMPUTERNAME"
#     "[$(Get-Location)]> "
# }

Write-Host "PowerShell profile loaded." -ForegroundColor Green
