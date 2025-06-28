# Uninstaller for dotfiles auto-update scripts
# This script removes scheduled tasks and startup entries but keeps all files

$taskName = "DotfilesAutoUpdate"
$startupBatPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\auto-update.bat"

Write-Host "=== Dotfiles Auto-Update Uninstaller ===" -ForegroundColor Cyan
Write-Host "This will disable auto-update but keep all script files." -ForegroundColor Gray

$removed = $false

# Remove scheduled task
Write-Host "Checking for scheduled task..." -ForegroundColor Yellow
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Removed scheduled task" -ForegroundColor Green
        $removed = $true
    } catch {
        Write-Error "Failed to remove scheduled task: $($_.Exception.Message)"
    }
} else {
    Write-Host "- Scheduled task not found" -ForegroundColor Gray
}

# Remove startup batch file
Write-Host "Checking for startup batch file..." -ForegroundColor Yellow
if (Test-Path $startupBatPath) {
    try {
        Remove-Item $startupBatPath -Force
        Write-Host "Removed startup batch file: $startupBatPath" -ForegroundColor Green
        $removed = $true
    } catch {
        Write-Error "Failed to remove startup batch file: $($_.Exception.Message)"
    }
} else {
    Write-Host "- Startup batch file not found" -ForegroundColor Gray
}

# Summary
Write-Host "" 
Write-Host "=== Uninstall Summary ===" -ForegroundColor Cyan
if ($removed) {
    Write-Host "Auto-update has been disabled" -ForegroundColor Green
    Write-Host "Your dotfiles will no longer automatically update on startup." -ForegroundColor Gray
    Write-Host ""
    Write-Host "All script files have been preserved in your dotfiles directory:" -ForegroundColor Gray
    Write-Host "  - auto-update.ps1" -ForegroundColor Gray
    Write-Host "  - auto-update.sh" -ForegroundColor Gray
    Write-Host "  - auto-update-setup.ps1" -ForegroundColor Gray
    Write-Host "  - auto-update-uninstall.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To re-enable auto-update, run: auto-update-setup.ps1" -ForegroundColor Cyan
} else {
    Write-Host "- No auto-update components were found to remove" -ForegroundColor Yellow
    Write-Host "Auto-update was not installed or already disabled." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Uninstall completed!" -ForegroundColor Cyan
