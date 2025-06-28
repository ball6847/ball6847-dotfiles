# Auto-update dotfiles on startup
$dotfilesDir = Join-Path $HOME ".dotfiles"
$logFile = Join-Path $dotfilesDir "auto-update.log"
$stashCreated = $false

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

# Check for uncommitted changes
try {
    $status = git status --porcelain 2>&1
    
    # If there are uncommitted changes, stash them
    if ($status) {
        Write-Log "Uncommitted changes detected, stashing them"
        $stashOutput = git stash push -m "Auto-update stash" 2>&1
        Write-Log "Stash output: $stashOutput"
        $stashCreated = $true
    } else {
        Write-Log "No uncommitted changes detected"
    }
} catch {
    Write-Log "ERROR: Failed to check git status: $($_.Exception.Message)"
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

# Apply stashed changes if any were stashed
if ($stashCreated) {
    try {
        Write-Log "Applying stashed changes"
        $stashPopOutput = git stash pop 2>&1
        Write-Log "Stash pop output: $stashPopOutput"
    } catch {
        Write-Log "ERROR: Failed to apply stashed changes: $($_.Exception.Message)"
    }
}

# Add and commit changes
try {
    Write-Log "Adding and committing changes"
    
    # First add all changes
    $addOutput = git add -A 2>&1
    Write-Log "Git add output: $addOutput"
    
    # Then commit
    $commitMessage = "Auto-update commit $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $commitOutput = git commit -m $commitMessage 2>&1
    Write-Log "Commit output: $commitOutput"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "SUCCESS: Git commit completed successfully"
    } else {
        # Check if there was nothing to commit
        if ($commitOutput -match "nothing to commit") {
            Write-Log "INFO: No changes to commit"
        } else {
            Write-Log "WARNING: Git commit returned exit code $LASTEXITCODE"
        }
    }
} catch {
    Write-Log "ERROR: Git add/commit failed: $($_.Exception.Message)"
}

# Check for unpushed commits and push if needed
try {
    Write-Log "Checking for unpushed commits"
    $unpushedCommits = git log @{u}.. --oneline 2>&1
    
    if ($unpushedCommits) {
        Write-Log "Unpushed commits detected: $unpushedCommits"
        Write-Log "Pushing changes to repository"
        $pushOutput = git push 2>&1
        Write-Log "Push output: $pushOutput"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SUCCESS: Git push completed successfully"
        } else {
            Write-Log "WARNING: Git push returned exit code $LASTEXITCODE"
        }
    } else {
        Write-Log "No unpushed commits detected, skipping push"
    }
} catch {
    Write-Log "ERROR: Failed during push check/operation: $($_.Exception.Message)"
}

Write-Log "Auto-update completed"
