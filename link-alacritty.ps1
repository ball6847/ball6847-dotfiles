# PowerShell script to create symlinks for alacritty config
# Symlinks the entire config\alacritty directory to %APPDATA%\alacritty
# Then creates alacritty.toml as a symlink to windows.toml

$sourceDir = Join-Path $PSScriptRoot "config\alacritty"
$targetDir = Join-Path $env:APPDATA "alacritty"
$targetFile = Join-Path $targetDir "alacritty.toml"
$sourceFile = Join-Path $sourceDir "windows.toml"

Write-Host "Alacritty Symlink Creation Script"
Write-Host "=================================="
Write-Host "Source directory: $sourceDir"
Write-Host "Target directory: $targetDir"
Write-Host ""

# Check if source directory exists
if (-not (Test-Path $sourceDir)) {
    Write-Error "Source directory does not exist: $sourceDir"
    exit 1
}

# Remove existing target if it exists (file or directory)
if (Test-Path $targetDir) {
    Write-Host "Target exists: $targetDir"
    Write-Host "Removing existing target..."
    Remove-Item $targetDir -Recurse -Force
    Write-Host "  ✓ Target removed"
    Write-Host ""
}

# Create symlink for the directory
Write-Host "Creating directory symlink..."
New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir -Force | Out-Null
Write-Host "  ✓ Directory symlink created: $targetDir -> $sourceDir"
Write-Host ""

# Remove the alacritty.toml symlink that was created as part of the directory symlink
# (the directory symlink will have created a symlink to windows.toml as alacritty.toml)
if (Test-Path $targetFile) {
    Remove-Item $targetFile -Force
}

# Create symlink for alacritty.toml -> windows.toml
Write-Host "Creating alacritty.toml symlink..."
New-Item -ItemType SymbolicLink -Path $targetFile -Target $sourceFile -Force | Out-Null
Write-Host "  ✓ File symlink created: $targetFile -> $sourceFile"
Write-Host ""

Write-Host "Operation completed successfully!"
Write-Host "Alacritty will now use the configuration from: $sourceFile"
