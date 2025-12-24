# PowerShell script to manage persistent PATH environment variables
# Handles User PATH (user-level) and Machine PATH (system-level) deduplication

Write-Host "=== Machine PATH Manager ===" -ForegroundColor Cyan
Write-Host "This script manages persistent PATH environment variables"
Write-Host ""

# Function to get PATH from different levels
function Get-PATHLevel {
    param([string]$Level)

    switch ($Level) {
        "User" { return [Environment]::GetEnvironmentVariable("PATH", "User") }
        "System" { return [Environment]::GetEnvironmentVariable("PATH", "Machine") }
    }
}

# Function to set PATH at different levels
function Set-PATHLevel {
    param([string]$Path, [string]$Level)

    switch ($Level) {
        "User" { [Environment]::SetEnvironmentVariable("PATH", $Path, "User") }
        "System" { [Environment]::SetEnvironmentVariable("PATH", $Path, "Machine") }
    }
}

# Function to deduplicate PATH entries
function Remove-PATHDuplicates {
    param([string]$InputPath)

    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        return "", 0, 0, @()
    }

    $pathEntries = $InputPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $seen = @{}
    $uniqueEntries = @()
    $duplicateEntries = @{}

    # First pass: identify duplicates
    foreach ($entry in $pathEntries) {
        $normalizedEntry = $entry.Trim()
        if (-not $duplicateEntries.ContainsKey($normalizedEntry)) {
            $duplicateEntries[$normalizedEntry] = 0
        }
        $duplicateEntries[$normalizedEntry]++
    }

    # Second pass: keep only first occurrence
    foreach ($entry in $pathEntries) {
        $normalizedEntry = $entry.Trim()
        if (-not $seen.ContainsKey($normalizedEntry)) {
            $seen[$normalizedEntry] = $true
            $uniqueEntries += $normalizedEntry
        }
    }

    $newPath = $uniqueEntries -join ';'
    $duplicatesRemoved = $pathEntries.Count - $uniqueEntries.Count
    $actualDuplicates = $duplicateEntries.GetEnumerator() | Where-Object { $_.Value -gt 1 }

    return $newPath, $duplicatesRemoved, $uniqueEntries.Count, $actualDuplicates
}

# Get current PATH from both persistent levels
$userPath = Get-PATHLevel "User"
$systemPath = Get-PATHLevel "System"

# Count entries
$userCount = if ($userPath) { ($userPath -split ';').Count } else { 0 }
$systemCount = if ($systemPath) { ($systemPath -split ';').Count } else { 0 }

Write-Host "Current PATH Status:" -ForegroundColor Yellow
Write-Host "User PATH entries: $userCount" -ForegroundColor Gray
Write-Host "System PATH entries: $systemCount" -ForegroundColor Gray
Write-Host ""

# Check admin status for System PATH operations
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Administrator privileges: $(if ($isAdmin) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($isAdmin) { 'Green' } else { 'Yellow' })

Write-Host ""
Write-Host "=== Available Actions ===" -ForegroundColor Cyan
Write-Host "1. Deduplicate User PATH (recommended - no admin needed)"
if ($isAdmin) {
    Write-Host "2. Deduplicate System PATH (requires admin)"
} else {
    Write-Host "2. Deduplicate System PATH (requires admin - run as admin)"
}
Write-Host "3. Clean BOTH User and System PATH"
Write-Host "4. Show User PATH"
Write-Host "5. Show System PATH"
Write-Host "6. Cancel"

$choice = Read-Host "`nEnter your choice (1-6)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== User PATH Deduplication ===" -ForegroundColor Cyan

        if ([string]::IsNullOrWhiteSpace($userPath)) {
            Write-Host "User PATH is empty or not set." -ForegroundColor Yellow
            exit 0
        }

        $newUserPath, $duplicatesRemoved, $uniqueCount, $duplicates = Remove-PATHDuplicates $userPath

        Write-Host "User PATH analysis:" -ForegroundColor Yellow
        Write-Host "  Current entries: $userCount"
        Write-Host "  After deduplication: $uniqueCount"
        Write-Host "  Duplicates to remove: $duplicatesRemoved"

        if ($duplicates.Count -gt 0) {
            Write-Host ""
            Write-Host "Duplicate entries that will be removed:" -ForegroundColor Yellow
            foreach ($entry in $duplicates) {
                Write-Host "  - $($entry.Key) (appears $($entry.Value) times)" -ForegroundColor Gray
            }
        }

        if ($duplicatesRemoved -eq 0) {
            Write-Host ""
            Write-Host "No duplicates found in User PATH! It's already clean." -ForegroundColor Green
            exit 0
        }

        $confirm = Read-Host "`nApply User PATH changes? (y/n)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            Set-PATHLevel -Path $newUserPath -Level "User"
            Write-Host ""
            Write-Host "User PATH updated successfully!" -ForegroundColor Green
            Write-Host "Changes will take effect in new terminal sessions." -ForegroundColor Gray
        } else {
            Write-Host ""
            Write-Host "User PATH changes cancelled." -ForegroundColor Yellow
        }
    }

    "2" {
        Write-Host ""
        Write-Host "=== System PATH Deduplication ===" -ForegroundColor Cyan

        if (-not $isAdmin) {
            Write-Host "ERROR: Administrator privileges required for System PATH changes!" -ForegroundColor Red
            Write-Host ""
            Write-Host "To fix this:" -ForegroundColor Yellow
            Write-Host "1. Close this PowerShell window"
            Write-Host "2. Right-click PowerShell"
            Write-Host "3. Select 'Run as Administrator'"
            Write-Host "4. Run this script again"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($systemPath)) {
            Write-Host "System PATH is empty or not set." -ForegroundColor Yellow
            exit 0
        }

        $newSystemPath, $duplicatesRemoved, $uniqueCount, $duplicates = Remove-PATHDuplicates $systemPath

        Write-Host "System PATH analysis:" -ForegroundColor Yellow
        Write-Host "  Current entries: $systemCount"
        Write-Host "  After deduplication: $uniqueCount"
        Write-Host "  Duplicates to remove: $duplicatesRemoved"

        if ($duplicates.Count -gt 0) {
            Write-Host ""
            Write-Host "Duplicate entries that will be removed:" -ForegroundColor Yellow
            foreach ($entry in $duplicates) {
                Write-Host "  - $($entry.Key) (appears $($entry.Value) times)" -ForegroundColor Gray
            }
        }

        if ($duplicatesRemoved -eq 0) {
            Write-Host ""
            Write-Host "No duplicates found in System PATH! It's already clean." -ForegroundColor Green
            exit 0
        }

        $confirm = Read-Host "`nApply System PATH changes? (y/n)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            Set-PATHLevel -Path $newSystemPath -Level "System"
            Write-Host ""
            Write-Host "System PATH updated successfully!" -ForegroundColor Green
            Write-Host "Changes will take effect in new terminal sessions." -ForegroundColor Gray
            Write-Host "You may need to restart applications for the changes to take effect." -ForegroundColor Gray
        } else {
            Write-Host ""
            Write-Host "System PATH changes cancelled." -ForegroundColor Yellow
        }
    }

    "3" {
        Write-Host ""
        Write-Host "=== Complete PATH Cleanup ===" -ForegroundColor Cyan
        Write-Host "This will deduplicate both User and System PATH"
        Write-Host ""

        $totalDuplicatesRemoved = 0

        # Clean User PATH
        if (-not [string]::IsNullOrWhiteSpace($userPath)) {
            $newUserPath, $dupRemoved, $uniqueCount, $duplicates = Remove-PATHDuplicates $userPath
            if ($dupRemoved -gt 0) {
                $totalDuplicatesRemoved += $dupRemoved
                $confirm = Read-Host "Clean User PATH (remove $dupRemoved duplicates)? (y/n)"
                if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                    Set-PATHLevel -Path $newUserPath -Level "User"
                    Write-Host "User PATH: $dupRemoved duplicates removed" -ForegroundColor Green
                }
            } else {
                Write-Host "User PATH: Already clean" -ForegroundColor Gray
            }
        } else {
            Write-Host "User PATH: Not set" -ForegroundColor Gray
        }

        # Clean System PATH
        if (-not [string]::IsNullOrWhiteSpace($systemPath)) {
            if (-not $isAdmin) {
                Write-Host "System PATH: Skipped (requires admin privileges)" -ForegroundColor Yellow
            } else {
                $newSystemPath, $dupRemoved, $uniqueCount, $duplicates = Remove-PATHDuplicates $systemPath
                if ($dupRemoved -gt 0) {
                    $totalDuplicatesRemoved += $dupRemoved
                    $confirm = Read-Host "Clean System PATH (remove $dupRemoved duplicates)? (y/n)"
                    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                        Set-PATHLevel -Path $newSystemPath -Level "System"
                        Write-Host "System PATH: $dupRemoved duplicates removed" -ForegroundColor Green
                    }
                } else {
                    Write-Host "System PATH: Already clean" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "System PATH: Not set" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "Total duplicates removed: $totalDuplicatesRemoved" -ForegroundColor Green
        Write-Host "PATH cleanup completed!" -ForegroundColor Cyan
    }

    "4" {
        Write-Host ""
        Write-Host "=== User PATH ===" -ForegroundColor Cyan
        if ($userPath) {
            $entries = $userPath -split ';'
            Write-Host "Total entries: $($entries.Count)"
            Write-Host ""
            Write-Host "User PATH content:"
            $entries | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host "User PATH is not set or empty." -ForegroundColor Yellow
        }
    }

    "5" {
        Write-Host ""
        Write-Host "=== System PATH ===" -ForegroundColor Cyan
        if ($systemPath) {
            $entries = $systemPath -split ';'
            Write-Host "Total entries: $($entries.Count)"
            Write-Host ""
            Write-Host "System PATH content:"
            $entries | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host "System PATH is not set or empty." -ForegroundColor Yellow
        }
    }

    "6" {
        Write-Host ""
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }

    default {
        Write-Host ""
        Write-Host "Invalid choice. Please run the script again and select 1-6." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Script Complete ===" -ForegroundColor Cyan
