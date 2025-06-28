# Auto-update dotfiles on startup
$dotfilesDir = Join-Path $HOME ".dotfiles"
$logFile = Join-Path $dotfilesDir "auto-update.log"

# Validate dotfiles directory exists
if (-not (Test-Path $dotfilesDir)) {
    Write-Error "Dotfiles directory not found: $dotfilesDir"
    exit 1
}

# Function to write log with timestamp
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $logFile
}

Write-Log "Starting dotfiles auto-update"

# Change to dotfiles directory
try {
    Set-Location $dotfilesDir
    Write-Log "Changed to directory: $dotfilesDir"
} catch {
    Write-Log "ERROR: Failed to change to dotfiles directory: $($_.Exception.Message)"
    exit 1
}

# Check if it's a git repository
if (-not (Test-Path ".git")) {
    Write-Log "ERROR: Not a git repository"
    exit 1
}

# Perform git pull
try {
    $output = git pull 2>&1
    Write-Log "Git pull output: $output"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "SUCCESS: Git pull completed successfully"
    } else {
        Write-Log "WARNING: Git pull returned exit code $LASTEXITCODE"
    }
} catch {
    Write-Log "ERROR: Git pull failed: $($_.Exception.Message)"
}

Write-Log "Auto-update completed"
