# Script to create scheduled task for dotfiles auto-update
$taskName = "DotfilesAutoUpdate"
$dotfilesDir = Join-Path $HOME ".dotfiles"
$scriptPath = Join-Path $dotfilesDir "auto-update.ps1"

# Validate paths exist
if (-not (Test-Path $dotfilesDir)) {
    Write-Error "Dotfiles directory not found: $dotfilesDir"
    Write-Host "Please ensure your dotfiles are located at: $dotfilesDir" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $scriptPath)) {
    Write-Error "Auto-update script not found: $scriptPath"
    Write-Host "Please ensure auto-update.ps1 exists in your dotfiles directory" -ForegroundColor Yellow
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "Task '$taskName' already exists. Removing old task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Create the trigger (at startup)
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create the principal (run as current user)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U

# Create the settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Auto-update dotfiles from git repository on startup"
    Write-Host "✓ Successfully created scheduled task '$taskName'" -ForegroundColor Green
    Write-Host "The task will run at startup and pull updates from your git repository." -ForegroundColor Gray
} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
}

# Show the created task
Write-Host "`nTask details:" -ForegroundColor Cyan
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName, State, LastRunTime, NextRunTime
