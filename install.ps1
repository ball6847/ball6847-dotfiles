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
        [string]$SourcePath,
        [string]$BackupPath
    )

    if (-not (Test-Path $Path)) {
        return $true  # doesn't exist, can create
    }

    if (Test-IsSymlink $Path) {
        if ((Get-SymlinkTarget $Path) -eq $SourcePath) {
            Write-Host "Symlink already correct: $Path"
            return $false  # skip, already correct
        }
        Write-Host "Backing up existing symlink: $Path"
    }
    elseif (Test-IsDirectory $Path) {
        Write-Host "Backing up existing directory: $Path"
    }
    else {
        Write-Host "Backing up existing file: $Path"
    }

    # Ensure backup parent directory exists
    $backupParent = Split-Path $BackupPath -Parent
    if ($backupParent -and -not (Test-Path $backupParent)) {
        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
    }

    # Remove any existing backup at this path to avoid collisions
    if (Test-Path $BackupPath) {
        Remove-Item $BackupPath -Force -Recurse
    }

    Move-Item $Path $BackupPath -Force
    Write-Host "  -> $BackupPath"
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
    $source = Join-Path $homeDir ".agents\skills"
    $target = Join-Path $homeDir ".claude\skills"
    $claudeBackupPath = Join-Path $backupDir ".claude\skills"

    if (-not (Test-Path $source)) {
        Write-Host "Note: ~/.agents/skills does not exist, skipping"
        return
    }

    $claudeDir = Split-Path $target -Parent
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    if (-not (Remove-Target -Path $target -SourcePath $source -BackupPath $claudeBackupPath)) {
        return  # already correct
    }

    Write-Host "Creating Claude skills symlink"
    New-Symlink -Target $target -Source $source
    Write-Host "  ~/.claude/skills -> ~/.agents/skills"
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
    "pi/agent/settings.json"
    "pi/agent/models.json"
    "pi/agent/configs"
    "pi/agent/agents"
    "pi/agent/APPEND_SYSTEM.md"
    "pi/agent/keybindings.json"
    "prime/agent/settings.json"
    "prime/agent/models.json"
    "prime/agent/keybindings.json"
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
    if (-not (Remove-Target -Path $targetPath -SourcePath $sourcePath -BackupPath $backupPath)) {
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
