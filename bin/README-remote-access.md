# Remote Access Scripts for WSL

These scripts allow you to run `sshd` and `tailscaled` in WSL without systemd by using tmux to manage the processes.

## Prerequisites

### WSL Only
These scripts are designed **only for WSL (Windows Subsystem for Linux)**. They will not work on native Linux systems that use systemd.

### Required Software

1. **tmux** - Terminal multiplexer
2. **openssh-server** - SSH server
3. **tailscale** - Tailscale client

## Installation Instructions

### Step 1: Install tmux

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install tmux

# Fedora
sudo dnf install tmux

# Arch
sudo pacman -S tmux
```

### Step 2: Install openssh-server (without systemd)

```bash
# Ubuntu/Debian
sudo apt install openssh-server

# Generate SSH host keys (if not automatically created)
sudo ssh-keygen -A

# Verify sshd is available
sudo /usr/sbin/sshd -t
```

**Disable systemd management (important):**

```bash
# Stop and disable sshd systemd services
sudo systemctl stop sshd 2>/dev/null || true
sudo systemctl disable sshd 2>/dev/null || true
sudo systemctl stop ssh.socket 2>/dev/null || true
sudo systemctl disable ssh.socket 2>/dev/null || true
```

**Note:** Do NOT start sshd as a systemd service. The script will run it manually.

### Step 3: Install Tailscale (without systemd)

```bash
# Ubuntu/Debian (recommended)
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.asc >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale.list | sudo tee /etc/apt/sources.list.d/tailscale-focal.list >/dev/null
sudo apt update
sudo apt install tailscale

# Alternative: Simple install script
curl -fsSL https://tailscale.com/install.sh | sh

# Fedora
curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo | sudo tee /etc/yum.repos.d/tailscale.repo
sudo dnf install tailscale

# Arch
sudo pacman -S tailscale
```

**Disable systemd management (important):**

```bash
# Stop and disable tailscaled systemd services
sudo systemctl stop tailscaled 2>/dev/null || true
sudo systemctl disable tailscaled 2>/dev/null || true
sudo systemctl stop tailscale-socket 2>/dev/null || true
sudo systemctl disable tailscale-socket 2>/dev/null || true
```

### Step 4: First-Time Authentication

After installation, you need to authenticate Tailscale once:

```bash
# Kill any running tailscaled instance
sudo pkill tailscaled 2>/dev/null || true

# Start tailscaled manually (the script does this)
~/.dotfiles/bin/start-remote-access.sh

# In a separate terminal (not tmux), authenticate:
sudo tailscale up --hostname=wsl-yourname
```

This will:
1. Output an authentication URL (e.g., `https://login.tailscale.com/a/XXXXX`)
2. Visit the URL in your browser
3. Authenticate with your Tailscale account
4. Your WSL machine will appear in the admin dashboard with the custom hostname

**Note:** Do NOT use `/etc/tailscale/config.json` - it locks the configuration and prevents `tailscale up` from working. Settings are stored in `/var/lib/tailscale/tailscaled.state` and persist across restarts.

## Usage

### Start Remote Access

```bash
~/.dotfiles/bin/start-remote-access.sh
```

This will:
- Create a tmux session named `remote-access`
- Start `sshd` in window 0
- Start `tailscaled` in window 1
- Attach you to the session

**First time:** You'll need to authenticate Tailscale:
1. The script starts tailscaled
2. In a separate terminal, run: `sudo tailscale up --hostname=wsl-yourname`
3. Visit the URL shown to authenticate
4. Your machine will appear in the Tailscale admin dashboard

**Detach from session:** Press `Ctrl+B` then `D`

### Stop Remote Access

```bash
~/.dotfiles/bin/stop-remote-access.sh
```

This will:
- Kill the sshd and tailscaled processes
- Destroy the tmux session
- WSL will shut down when idle

## Authentication

### SSH Authentication

After starting the service, you may need to configure SSH authentication:

```bash
# Set up SSH key authentication (recommended)
# On your client machine, add your public key to WSL's authorized_keys
echo "your-public-key" >> ~/.ssh/authorized_keys
```

### Tailscale Authentication

You may need to authenticate Tailscale on first run:

```bash
# In the tailscaled tmux window, if prompted
tailscale up --auth-key=<your-auth-key>

# Or visit the URL provided in the output
```

## Troubleshooting

### sshd fails to start

```bash
# Check configuration
sudo /usr/sbin/sshd -t

# Check if port 22 is already in use
sudo ss -tlnp | grep :22

# Ensure privilege separation directory exists
sudo mkdir -p /run/sshd
sudo chmod 755 /run/sshd
```

### tailscaled fails to start

```bash
# Kill any existing instance
sudo pkill tailscaled

# Remove socket file
sudo rm -f /var/run/tailscale/tailscaled.sock

# Check if systemd is still managing it
sudo systemctl status tailscaled
```

### Tailscale shows "NeedsLogin"

```bash
# Authenticate in a separate terminal
sudo tailscale up --hostname=wsl-yourname
```

### Tailscale machine not appearing in admin dashboard

1. Ensure you've authenticated: `sudo tailscale up`
2. Visit the URL shown in the output
3. Wait a few seconds for the machine to register

### tmux session issues

```bash
# List existing sessions
tmux ls

# Kill a specific session
tmux kill-session -t remote-access

# Kill any remaining processes
sudo pkill sshd
sudo pkill tailscaled
```

## Security Considerations

1. **SSH**: Ensure you use key-based authentication and disable password authentication in `/etc/ssh/sshd_config`
2. **Tailscale**: Review Tailscale ACLs and ensure only necessary devices have access
3. **WSL**: Remember that WSL shares your Windows network stack, so ensure Windows firewall rules are appropriate

## Why WSL Only?

These scripts are designed for WSL because:
- WSL does not use systemd by default (on WSL1, and WSL2 typically doesn't either)
- WSL sessions are temporary and shut down when idle
- Manual process management via tmux is more appropriate than systemd in WSL
- Native Linux systems should use systemd services for proper service management