# PowerShell script to remove symlinks and restore backup files as actual files
# For Trae/VSCodium settings in AppData\Roaming\Trae\User
# Can be run from any directory

$targetDir = "$env:APPDATA\Trae\User"

Write-Host "Trae Settings Symlink Removal Script"
Write-Host "===================================="
Write-Host "Target directory: $targetDir"
Write-Host ""

# Check if target directory exists
if (!(Test-Path $targetDir)) {
    Write-Error "Target directory does not exist: $targetDir"
    exit 1
}

# Check current status
Write-Host "Current status:"
Get-ChildItem -Path $targetDir -Name "settings.json", "keybindings.json", "settings.json.backup", "keybindings.json.backup" -ErrorAction SilentlyContinue | ForEach-Object {
    $item = Get-Item "$targetDir\$_"
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "  [SYMLINK] $item -> $($item.Target)"
    } else {
        Write-Host "  [FILE]    $item ($($item.Length) bytes)"
    }
}

Write-Host ""

# Check if symlinks exist
$settingsPath = "$targetDir\settings.json"
$keybindingsPath = "$targetDir\keybindings.json"

# More accurate symlink check
$settingsIsSymlink = (Get-Item $settingsPath -ErrorAction SilentlyContinue).Attributes -band [System.IO.FileAttributes]::ReparsePoint
$keybindingsIsSymlink = (Get-Item $keybindingsPath -ErrorAction SilentlyContinue).Attributes -band [System.IO.FileAttributes]::ReparsePoint

if (!$settingsIsSymlink -and !$keybindingsIsSymlink) {
    Write-Host "No symlinks found. Files appear to be regular files already."
    exit 0
}

# Check if backup files exist
$settingsBackupExists = Test-Path "$targetDir\settings.json.backup"
$keybindingsBackupExists = Test-Path "$targetDir\keybindings.json.backup"

if (!$settingsBackupExists -or !$keybindingsBackupExists) {
    Write-Error "Backup files missing! Cannot proceed without backups."
    Write-Host "Missing: $(if (!$settingsBackupExists) { 'settings.json.backup' }) $(if (!$keybindingsBackupExists) { 'keybindings.json.backup' })"
    exit 1
}

Write-Host "Proceeding with symlink removal and backup restoration..."
Write-Host ""

# Remove symlinks if they exist
if ($settingsIsSymlink) {
    Write-Host "Removing settings.json symlink..."
    Remove-Item $settingsPath -Force
    Write-Host "  ✓ Symlink removed"
}

if ($keybindingsIsSymlink) {
    Write-Host "Removing keybindings.json symlink..."
    Remove-Item $keybindingsPath -Force
    Write-Host "  ✓ Symlink removed"
}

# Copy backup files to replace symlinks
Write-Host "Copying backup files..."
Copy-Item "$targetDir\settings.json.backup" $settingsPath -Force
Write-Host "  ✓ settings.json restored from backup"

Copy-Item "$targetDir\keybindings.json.backup" $keybindingsPath -Force
Write-Host "  ✓ keybindings.json restored from backup"

Write-Host ""
Write-Host "Operation completed successfully!"
Write-Host ""
Write-Host "Final status:"
Get-ChildItem -Path $targetDir -Name "settings.json", "keybindings.json" | ForEach-Object {
    $item = Get-Item "$targetDir\$_"
    Write-Host "  [FILE] $item ($($item.Length) bytes)"
}

Write-Host ""
Write-Host "Your Trae settings are now stored as regular files."
