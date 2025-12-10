# PowerShell script to create symlink for alacritty.toml
# Creates a symlink from config\alacritty\windows.toml to %APPDATA%\alacritty\alacritty.toml
# Can be run from any directory

$sourceFile = Join-Path $PSScriptRoot "config\alacritty\windows.toml"
$targetDir = Join-Path $env:APPDATA "alacritty"
$targetFile = Join-Path $targetDir "alacritty.toml"

Write-Host "Alacritty Symlink Creation Script"
Write-Host "=================================="
Write-Host "Source file: $sourceFile"
Write-Host "Target file: $targetFile"
Write-Host ""

# Check if source file exists
if (-not (Test-Path $sourceFile)) {
    Write-Error "Source file does not exist: $sourceFile"
    exit 1
}

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    Write-Host "Creating target directory: $targetDir"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "  ✓ Directory created"
    Write-Host ""
}

# Remove existing file if it exists
if (Test-Path $targetFile) {
    Write-Host "Target file exists: $targetFile"
    Write-Host "Removing existing file..."
    Remove-Item $targetFile -Force
    Write-Host "  ✓ File removed"
    Write-Host ""
}

# Create symlink
Write-Host "Creating symlink..."
New-Item -ItemType SymbolicLink -Path $targetFile -Target $sourceFile -Force | Out-Null
Write-Host "  ✓ Symlink created: $targetFile -> $sourceFile"
Write-Host ""

Write-Host "Operation completed successfully!"
Write-Host "Alacritty will now use the configuration file from: $sourceFile"
