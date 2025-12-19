# PowerShell script to create symlinks for rio config
# Creates %LOCALAPPDATA%\rio directory and symlinks config files into it

$sourceDir = Join-Path $PSScriptRoot "config\rio"
$sourceFile = Join-Path $sourceDir "windows.toml"
$targetDir = Join-Path $env:LOCALAPPDATA "rio"
$targetFile = Join-Path $targetDir "config.toml"

Write-Host "Rio Symlink Creation Script"
Write-Host "=========================="
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

# Remove target file if it exists
if (Test-Path $targetFile) {
    Remove-Item $targetFile -Force
}

# Create symlink
Write-Host "Creating config.toml symlink..."
New-Item -ItemType SymbolicLink -Path $targetFile -Target $sourceFile -Force | Out-Null
Write-Host "  ✓ config.toml -> $sourceFile"
Write-Host ""

Write-Host "Operation completed successfully!"
Write-Host "Rio configuration is now linked."
