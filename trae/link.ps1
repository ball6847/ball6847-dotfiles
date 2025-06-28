# Define source and target paths
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetDir = Join-Path $HOME "AppData\Roaming\Trae\User"
$files = @("settings.json", "keybindings.json")

# Create target directory if it doesn't exist
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force
}

# Initialize collections
$successfulLinks = @()
$failedLinks = @()
$existingLinks = @()
$backupFiles = @()

# Collect phase
foreach ($file in $files) {
    $sourcePath = Join-Path $sourceDir $file
    $targetPath = Join-Path $targetDir $file
    
    # Check if source file exists
    if (-not (Test-Path $sourcePath)) {
        $failedLinks += @{
            File = $file
            Reason = "Source file does not exist"
            Path = $sourcePath
        }
        continue
    }
    
    # Check if target exists and is already a symbolic link
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.LinkType -eq "SymbolicLink") {
            # Check if symbolic link points to correct location
            if ($item.Target -eq $sourcePath) {
                $existingLinks += $file
                continue
            } else {
                $failedLinks += @{
                    File = $file
                    Reason = "Symbolic link points to incorrect location"
                    Current = $item.Target
                    Expected = $sourcePath
                }
                continue
            }
        } else {
            $backupFiles += @{
                File = $file
                Source = $targetPath
                Backup = "$targetPath.backup"
            }
        }
    }
    
    # Add to pending links
    $successfulLinks += @{
        File = $file
        Source = $sourcePath
        Target = $targetPath
    }
}

# Save phase
foreach ($backup in $backupFiles) {
    try {
        Write-Host "Backing up $($backup.Source) to $($backup.Backup)"
        Copy-Item $backup.Source $backup.Backup -Force
        Remove-Item $backup.Source
        Write-Host "Backed up $($backup.File)" -ForegroundColor Green
    } catch {
        $failedLinks += @{
            File = $backup.File
            Reason = "Failed to backup existing file: $($_.Exception.Message)"
        }
        continue
    }
}

foreach ($link in $successfulLinks) {
    try {
        New-Item -ItemType SymbolicLink -Path $link.Target -Target $link.Source -ErrorAction Stop
        Write-Host "Created symbolic link for $($link.File)" -ForegroundColor Green
    } catch {
        $failedLinks += @{
            File = $link.File
            Reason = $_.Exception.Message
        }
    }
}

# Report results
foreach ($link in $existingLinks) {
    Write-Host "Symbolic link already exists for $link" -ForegroundColor Green
}

foreach ($failure in $failedLinks) {
    if ($failure.Current) {
        Write-Error "Symbolic link $($failure.File) points to incorrect location: $($failure.Current)"
        Write-Error "Expected location: $($failure.Expected)"
        Write-Host "Please manually remove the existing symbolic link and run this script again." -ForegroundColor Yellow
    } else {
        Write-Error "Failed to process $($failure.File): $($failure.Reason)"
    }
}

$success = $failedLinks.Count -eq 0

if ($success) {
    Write-Host "Trae configuration sync setup complete!" -ForegroundColor Cyan
    Write-Host "Your settings and keybindings will now stay in sync with the source directory." -ForegroundColor Gray
} else {
    Write-Host "Trae configuration sync completed with errors. Please review the messages above." -ForegroundColor Red
}
