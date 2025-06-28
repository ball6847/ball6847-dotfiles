# Trae Configuration Management

This repository manages Trae IDE configuration files (`settings.json` and `keybindings.json`) using Git version control. As Trae does not currently offer built-in configuration synchronization, this manual approach ensures your settings are version-controlled and easily transferable.

## Why Manage These Files in Git?

1. **Version Control**: Track changes to your IDE configuration over time
2. **Backup**: Never lose your carefully crafted settings
3. **Sync Across Machines**: Easily maintain consistent settings across multiple computers
4. **Reproducibility**: Quickly set up a new development environment
5. **Collaboration**: Share and standardize settings across teams

## Installation Instructions

### Windows

1. Open PowerShell as Administrator
2. Run the following commands:
```powershell
cd ~\.dotfiles\trae
.\link.ps1
```

### macOS

1. Open Terminal
2. Run the following commands:
```bash
cd ~/.dotfiles/trae
chmod +x link.sh
./link.sh
```

## How It Works

The installation script creates hard links between:
- The files in this repository (`settings.json`, `keybindings.json`)
- Trae's configuration directory:
  - Windows: `%USERPROFILE%\Library\Application Support\Trae\User`
  - macOS: `~/Library/Application Support/Trae/User`

This ensures any changes made in either location are automatically synchronized.

## Troubleshooting

If you encounter issues:
1. Make sure Trae is not running during installation
2. Verify the target directory exists
3. Check file permissions if the script fails
4. Manually remove any existing files if the script reports conflicts