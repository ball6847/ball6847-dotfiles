# Windows Reserved Device Names

## Problem

Cannot delete or manipulate files named `nul`, `con`, `prn`, `aux`, `com1-9`, `lpt1-9`.

**Example:**
```cmd
C:\Users\ball6\.dotfiles> del nul
Could Not Find C:\Users\ball6\.dotfiles\nul
```

But the file still appears in directory listings:
```cmd
C:\Users\ball6\.dotfiles> dir
04/18/2026  10:31 AM               528 nul
```

## Root Cause

Windows reserves certain names as system devices:

| Name | Device |
|------|--------|
| `CON` | Console (keyboard/screen) |
| `PRN` | Printer |
| `AUX` | Auxiliary device |
| `NUL` | Null device (discards output) |
| `COM1-9` | Serial ports |
| `LPT1-9` | Parallel ports |

These names exist at the DOS/Win32 API level. When you try to access a file named `nul`, Windows redirects to the null device instead of the filesystem.

## How Files Get Created

Unix tools running on Windows can create files with reserved names because:
- They use direct NTFS APIs that bypass the Win32 reserved name check
- WSL, MSYS2, Git Bash, Cygwin can all create these files
- The files exist on disk but are invisible to standard Windows tools

## Solution: Extended UNC Path Syntax

Use `\?\` prefix to bypass Windows name handling:

```cmd
del \\?\C:\full\path\to\nul
```

This works because:
- `\?\` tells Windows to skip the DOS-to-NT path conversion
- Accesses file directly at NTFS level
- Bypasses reserved name restrictions

## Examples

### Delete a file named `nul`
```cmd
del \\?\C:\Users\ball6\.dotfiles\nul
```

### Delete a file named `con`
```cmd
del \\?\C:\Users\ball6\.dotfiles\con
```

### Check if file exists
```cmd
dir \\?\C:\Users\ball6\.dotfiles\nul
```

### Using PowerShell
```powershell
Remove-Item -Path '\\?\C:	emp
ul'
```

### Using Python
```python
import os
os.remove(r'\\?\C:\Users\ball6\.dotfiles\nul')
```

## Prevention

Add to `.gitignore`:
```
# Windows reserved device name artifacts
nul
con
prn
aux
```

## Commands Reference

```cmd
# List directory showing reserved name files
dir

# Delete reserved name file
del \\?\C:\full\path\to\nul

# Check file details
dir \\?\C:\full\path\to\nul

# Rename (move) the file
cmd /c "move \\?\C:\old\path\nul \\?\C:\new\path\renamed.txt"
```

```powershell
# Delete with PowerShell
Remove-Item -LiteralPath '\\?\C:	emp
ul'

# Alternative: use -Path with extended syntax
Remove-Item -Path '\\?\C:	emp
ul'
```

## Key Takeaways

1. Windows reserves certain names as system devices
2. Files with these names can exist (created by Unix tools) but are hard to access
3. Extended path syntax `\?\` is the escape hatch
4. Add these names to `.gitignore` to prevent accidents
5. These files are invisible to most Windows GUI tools

## Related Issues

- WSL creating files named `nul` in Windows directories
- MSYS2/Git Bash accidentally creating reserved name files
- Cross-platform build tools not sanitizing filenames
