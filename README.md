# Dotfiles

This repository contains my personal dotfiles for configuring various development tools and environments. It includes configuration for shells (Bash, Zsh), editors (Neovim), terminal emulators (Kitty, Terminator), Git, and various development tools. The repository is designed to be cross-platform compatible with specific configurations for both Linux and Windows environments. Setup scripts are included for easy installation and automatic updates. Feel free to explore, fork, and adapt these configurations to suit your own workflow needs.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- Git
- Bash (for Linux/macOS)
- PowerShell (for Windows)
- Zsh (optional, for enhanced shell experience)

### Clone the Repository

Most scripts in this repository expect the dotfiles to be cloned to `~/.dotfiles` (Linux/macOS) or equivalent location on Windows. It's important to clone to the correct location to ensure all scripts work properly.

```bash
# Linux/macOS
git clone https://github.com/ball6847/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

```powershell
# Windows
git clone https://github.com/ball6847/dotfiles.git "$env:USERPROFILE\.dotfiles"
cd "$env:USERPROFILE\.dotfiles"
```

After cloning, initialize and update the git submodules to get all the required plugins:

```bash
# Initialize and update submodules (Zsh plugins, etc.)
# This command works for both initial setup and updates
git submodule update --init --recursive --remote
```

## Installation

### Linux/macOS
```bash
./install.sh  # Creates symlinks and sets up the environment
```

### Windows
```powershell
.\auto-update-setup.ps1  # Sets up a scheduler to automatically pull dotfiles on startup
```

## Automatic Updates
This repository includes scripts for automatic updates:
- Linux/macOS: `auto-update.sh` - Updates dotfiles by pulling latest changes from the repository
- Windows: `auto-update.ps1` - PowerShell script that updates dotfiles on Windows systems
- Windows: `auto-update-uninstall.ps1` - Removes the scheduled task for automatic updates on Windows

## Contents
- Shell configurations (Bash, Zsh)
- Neovim setup with NVChad customizations
- Terminal configurations (Kitty, Terminator, Windows Terminal)
- Git configuration
- Development tools and utilities
- Cross-platform compatibility scripts

## Key Features

### Neovim Configuration
- Custom NVChad configuration with personalized theme (Onedark)
- LSP support for multiple languages (Lua, HTML, CSS, Bash, Go, TypeScript)
- Code formatting with conform.nvim
- Syntax highlighting with Treesitter
- Custom keybindings including Copilot integration
- Relative line numbers and other quality-of-life settings

### Terminal Customizations
- Kitty terminal with extensive configuration options
- Terminator with custom themes
- Windows Terminal configuration with custom actions

### Development Tools
- Kubernetes development environment setup (k3d)
- Docker configurations
- Cross-platform compatibility scripts
- Custom binaries and utilities in the `bin` directory

## Customization

These dotfiles are highly customizable. The main configuration files you might want to modify include:

- `zshrc` and `bashrc` for shell configurations
- `config/nvim/` for Neovim settings
- `config/kitty/kitty.conf` for Kitty terminal settings
- `config/terminator/config` for Terminator settings
- `assets/windows-terminal-config.json` for Windows Terminal configuration
- `gitconfig` for Git settings

## Structure

- `bin/`: Custom scripts and utilities
- `config/`: Configuration files for various applications
- `zsh_custom/`: Custom Zsh plugins and themes
- `assets/`: Additional configuration files and resources

## Troubleshooting

### Common Issues

- **Symlink errors**: Ensure you have the necessary permissions to create symlinks. On Windows, you may need to run PowerShell as Administrator.
- **Submodule errors**: If you encounter issues with submodules, try running `git submodule update --init --recursive --remote` to initialize and update all submodules.
- **Script execution errors**: Make sure scripts have executable permissions (`chmod +x script.sh` on Linux/macOS).

### Getting Help

If you encounter any issues not covered here, please [open an issue](https://github.com/ball6847/dotfiles/issues) on the GitHub repository.

## License

Feel free to use and modify these dotfiles for your personal use.