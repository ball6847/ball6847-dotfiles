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
    
    # Check if target exists and is already a hard link
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.LinkType -eq "HardLink") {
            # Only calculate hashes when the file is a hard link
            $sourceHash = Get-FileHash -Path $sourcePath -Algorithm SHA256
            $targetHash = Get-FileHash -Path $targetPath -Algorithm SHA256
            
            if ($sourceHash.Hash -eq $targetHash.Hash) {
                $existingLinks += $file
                continue
            } else {
                $failedLinks += @{
                    File = $file
                    Reason = "Hard link points to incorrect location"
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
    Write-Host "Backing up $($backup.Source) to $($backup.Backup)"
    Copy-Item $backup.Source $backup.Backup -Force
    Remove-Item $backup.Source
}

foreach ($link in $successfulLinks) {
    try {
        New-Item -ItemType HardLink -Path $link.Target -Target $link.Source -ErrorAction Stop
        Write-Host "✓ Created hard link for $($link.File)" -ForegroundColor Green
    } catch {
        $failedLinks += @{
            File = $link.File
            Reason = $_.Exception.Message
        }
    }
}

# Report results
foreach ($link in $existingLinks) {
    Write-Host "✓ Hard link already exists for $link" -ForegroundColor Green
}

foreach ($failure in $failedLinks) {
    if ($failure.Current) {
        Write-Error "Hard link $($failure.File) points to incorrect location: $($failure.Current)"
        Write-Error "Expected location: $($failure.Expected)"
        Write-Host "Please manually remove the existing hard link and run this script again." -ForegroundColor Yellow
    } else {
        Write-Error "Failed to process $($failure.File): $($failure.Reason)"
    }
}

$success = $failedLinks.Count -eq 0

if ($success) {
    Write-Host "`nTrae configuration sync setup complete!" -ForegroundColor Cyan
    Write-Host "Your settings and keybindings will now stay in sync with the source directory." -ForegroundColor Gray
} else {
    Write-Host "`nTrae configuration sync completed with errors. Please review the messages above." -ForegroundColor Red
}