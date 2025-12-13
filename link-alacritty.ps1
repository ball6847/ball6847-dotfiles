# PowerShell script to create symlinks for alacritty config
# Creates %APPDATA%\alacritty directory and symlinks config files into it

$sourceDir = Join-Path $PSScriptRoot "config\alacritty"
$targetDir = Join-Path $env:APPDATA "alacritty"

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

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    Write-Host "Creating target directory: $targetDir"
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "  ✓ Directory created"
    Write-Host ""
}

# Symlink common.toml
$commonSource = Join-Path $sourceDir "common.toml"
$commonTarget = Join-Path $targetDir "common.toml"
if (Test-Path $commonTarget) {
    Remove-Item $commonTarget -Force
}
Write-Host "Creating common.toml symlink..."
New-Item -ItemType SymbolicLink -Path $commonTarget -Target $commonSource -Force | Out-Null
Write-Host "  ✓ common.toml -> $commonSource"

# Symlink windows.toml
$windowsSource = Join-Path $sourceDir "windows.toml"
$windowsTarget = Join-Path $targetDir "windows.toml"
if (Test-Path $windowsTarget) {
    Remove-Item $windowsTarget -Force
}
Write-Host "Creating windows.toml symlink..."
New-Item -ItemType SymbolicLink -Path $windowsTarget -Target $windowsSource -Force | Out-Null
Write-Host "  ✓ windows.toml -> $windowsSource"

# Symlink alacritty.toml -> windows.toml
$alacrittyTarget = Join-Path $targetDir "alacritty.toml"
if (Test-Path $alacrittyTarget) {
    Remove-Item $alacrittyTarget -Force
}
Write-Host "Creating alacritty.toml symlink..."
New-Item -ItemType SymbolicLink -Path $alacrittyTarget -Target $windowsSource -Force | Out-Null
Write-Host "  ✓ alacritty.toml -> $windowsSource"
Write-Host ""

# Symlink alacritty-theme folder
$themeSource = Join-Path $PSScriptRoot "alacritty-theme"
$themeTarget = Join-Path $targetDir "alacritty-theme"
if (Test-Path $themeTarget) {
    Remove-Item $themeTarget -Force -Recurse
}
Write-Host "Creating alacritty-theme folder symlink..."
New-Item -ItemType SymbolicLink -Path $themeTarget -Target $themeSource -Force | Out-Null
Write-Host "  ✓ alacritty-theme -> $themeSource"
Write-Host ""

Write-Host "Operation completed successfully!"
Write-Host "Alacritty configuration is now linked."
