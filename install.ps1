# PowerShell script to create symlinks for dotfiles
# Symlinks config files from this directory to the user's home directory

# ============================================
# Helper Functions
# ============================================

function Test-IsSymlink {
    param ([string]$Path)
    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    return ($null -ne $item -and $item.Attributes -match "ReparsePoint")
}

function Test-IsDirectory {
    param ([string]$Path)
    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    return ($null -ne $item -and $item.PSIsContainer)
}

function Get-SymlinkTarget {
    param ([string]$Path)
    $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
    return $item.Target
}

function Remove-Target {
    param (
        [string]$Path,
        [string]$SourcePath
    )

    if (-not (Test-Path $Path)) {
        return $true  # doesn't exist, can create
    }

    if (Test-IsSymlink $Path) {
        if (Get-SymlinkTarget $Path -eq $SourcePath) {
            Write-Host "Symlink already correct: $Path"
            return $false  # skip, already correct
        }
        Write-Host "Removing existing symlink: $Path"
        Remove-Item $Path -Force
        return $true
    }

    if (Test-IsDirectory $Path) {
        Write-Host "Removing existing directory: $Path"
        Remove-Item $Path -Force -Recurse
        return $true
    }

    # Regular file - backup first
    Write-Host "Backing up existing: $Path"
    $backupParent = Split-Path $backupPath -Parent
    if ($backupParent -and -not (Test-Path $backupParent)) {
        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
    }
    if (Test-Path $backupPath) {
        Remove-Item $backupPath -Force -Recurse
    }
    Move-Item $Path $backupPath -Force
    Write-Host "  -> $backupPath"
    return $true
}

function New-Symlink {
    param (
        [string]$Target,
        [string]$Source
    )

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
    Write-Host "  -> $Source"
}

function Install-ClaudeSkillsLink {
    $claudeDir = Join-Path $homeDir ".claude"
    $source = Join-Path $homeDir ".agents\skills"
    $target = Join-Path $claudeDir "skills"

    if (-not (Test-Path $source)) {
        Write-Host "Note: ~/.agents/skills does not exist, skipping"
        return
    }

    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    if (Test-IsSymlink $target) {
        if (Get-SymlinkTarget $target -eq $source) {
            Write-Host "Claude skills symlink already correct"
            return
        }
        Write-Host "Removing existing symlink: $target"
        Remove-Item $target -Force
    }

    if (-not (Test-Path $target)) {
        Write-Host "Creating Claude skills symlink"
        New-Symlink -Target $target -Source $source
        Write-Host "  ~/.claude/skills -> ~/.agents/skills"
    }
}

# ============================================
# Main Script
# ============================================

$sourceDir = $PSScriptRoot
$homeDir = $env:USERPROFILE
$backupDir = Join-Path $homeDir ".dotfiles_old"

Write-Host "Dotfiles Installation Script"
Write-Host "==========================="
Write-Host "Source directory: $sourceDir"
Write-Host "Home directory: $homeDir"
Write-Host "Backup directory: $backupDir"
Write-Host ""

# Create backup directory if needed
if (-not (Test-Path $backupDir)) {
    Write-Host "Creating backup directory: $backupDir"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host ""
}

# Files to symlink
$files = @(
    "bashrc"
    "bash_aliases"
    "profile"
    "npmrc"
    "gitconfig"
    "config/nvim"
    "config/opencode"
    "config/git-commit-ai"
    "qwen/settings.json"
    "agents"
    "kimi"
    "vibe"
    "agent-browser"
    "qoder"
    "gemini"
)

# Process each file
foreach ($file in $files) {
    $sourcePath = Join-Path $sourceDir $file
    $targetPath = Join-Path $homeDir ".$file"
    $backupPath = Join-Path $backupDir $file

    # Skip if source doesn't exist
    if (-not (Test-Path $sourcePath)) {
        Write-Host "Skipping $file - source does not exist"
        continue
    }

    # Create parent directory if needed
    $targetParent = Split-Path $targetPath -Parent
    if ($targetParent -and -not (Test-Path $targetParent)) {
        Write-Host "Creating directory: $targetParent"
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    # Handle existing target
    if (-not (Remove-Target -Path $targetPath -SourcePath $sourcePath)) {
        continue  # symlink was already correct
    }

    # Create symlink
    Write-Host "Creating symlink: $targetPath"
    New-Symlink -Target $targetPath -Source $sourcePath
}

Write-Host ""

# Claude skills symlink
Install-ClaudeSkillsLink

Write-Host ""
Write-Host "Operation completed successfully!"
Write-Host "Dotfiles are now linked to your home directory."
