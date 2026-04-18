# Windows Symlink Permission Errors

## What We Did

We encountered this issue and solved it by **enabling Developer Mode** (Solution 1 below).

**Steps taken:**
1. Enabled Developer Mode via registry:
   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -Value 1
   ```
2. Restored symlinks from git:
   ```bash
   git checkout -- agents/skills/
   ```
3. Verified `vibe` (and other tools) now work without permission errors

**Result:** Symlinks work normally, no admin elevation needed for future operations.

## Problem

On Windows, accessing symbolic links (symlinks) results in:
```
PermissionError: [WinError 5] Access is denied: 'C:\\path\\to\\symlink'
```

This occurs when programs try to traverse or check symlinked directories/files.

## Root Cause

Windows requires special permissions to create/follow symbolic links:
- By default, only Administrators can create symlinks
- Standard user processes cannot follow symlinks
- `stat()` and similar operations on symlinks fail with permission errors

Common scenarios:
- Python's `pathlib.is_dir()` fails on symlinked directories
- Git cannot checkout repositories containing symlinks
- Build tools scanning directories fail on symlink entries
- Scripts working on Linux/Mac fail on Windows

## Solutions

### Solution 1: Enable Developer Mode (Recommended)

Enables symlink creation and traversal for all users without elevation.

**Via PowerShell (Admin):**
```powershell
$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
if (-not (Test-Path $path)) {
    New-Item -Path $path -Force
}
Set-ItemProperty -Path $path -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 -Type DWord
```

**Via Settings UI:**
Settings → Privacy & Security → For Developers → Developer Mode → ON

**Verify it's enabled:**
```powershell
(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense').AllowDevelopmentWithoutDevLicense
# Should return: 1
```

### Solution 2: Run as Administrator

- Elevated processes can create and follow symlinks
- Not recommended for daily development
- Only applies to the current session

### Solution 3: Use Junctions instead of Symlinks

For directories, junctions work without special permissions:

```cmd
mklink /J linkname targetpath
```

**Comparison:**
| Feature | Symbolic Link | Junction |
|---------|---------------|----------|
| Requires special permissions | Yes | No |
| Works for files | Yes | No |
| Works for directories | Yes | Yes |
| Cross-drive | Yes | Yes |
| Relative paths | Yes | Yes |

## Git and Symlinks

### Configuration
```bash
git config --global core.symlinks true
```

### Common Issues

**Checkout fails with symlink error:**
```
error: unable to create symlink <filename>: Permission denied
```

**Fix:** Enable Developer Mode (see Solution 1), then:
```bash
git checkout -- .
```

## Python Best Practices

### Problematic Code

```python
from pathlib import Path

for item in Path('.').iterdir():
    if item.is_dir():  # May crash on Windows with symlinks!
        process(item)
```

**Why it fails:** `is_dir()` internally calls `stat()` on symlink targets, requiring permission to follow the link.

### Cross-Platform Solution

```python
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

for item in Path('.').iterdir():
    try:
        if item.is_dir():
            process(item)
    except PermissionError:
        logger.debug("Skipping inaccessible directory: %s", item)
        continue
    except OSError as e:
        logger.warning("Cannot access %s: %s", item, e)
        continue
```

### Alternative: Check for Symlinks First

```python
from pathlib import Path

for item in Path('.').iterdir():
    # Skip symlinks entirely if you don't need to follow them
    if item.is_symlink():
        continue
    if item.is_dir():
        process(item)
```

## Commands Reference

```powershell
# Check Developer Mode status
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense'

# Find all symlinks in current directory
Get-ChildItem -Path . -Attributes ReparsePoint

# Find all symlinks recursively
Get-ChildItem -Path . -Recurse -Attributes ReparsePoint

# Create a symbolic link (requires permissions)
New-Item -ItemType SymbolicLink -Path linkname -Target targetpath

# Create a junction (no permissions needed)
New-Item -ItemType Junction -Path linkname -Target targetpath
```

```cmd
# Create symbolic link (cmd, requires permissions)
mklink linkname targetpath

# Create junction (cmd, no permissions needed)
mklink /J linkname targetpath
```

## Key Takeaways

1. **Windows symlink support is opt-in** - Not enabled by default for security
2. **Developer Mode is the best solution** - Enables symlink access for all users
3. **Cross-platform code must handle PermissionError** - Don't assume `is_dir()` will succeed
4. **Junctions are a good alternative** - For directories only, no permissions needed
5. **Git needs explicit configuration** - `core.symlinks true` must be set
6. **Always test on Windows** - Symlink issues only appear on Windows

## See Also

- `windows-reserved-device-names.md` - Related Windows filesystem issues
