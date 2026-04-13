#!/bin/bash
# stop-remote-access.sh - Stop remote access services and tmux session
# NOTE: This script is designed for WSL (Windows Subsystem for Linux) only.
# It stops manually-run sshd and tailscaled processes (not systemd services).
# Do not run on native Linux systems that use systemd.

# Check if running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Error: This script should only run in WSL."
    echo "Native Linux systems should use systemctl to stop services."
    exit 1
fi

SESSION_NAME="remote-access"

echo "Stopping remote access services..."

# Kill tailscaled first (more graceful)
sudo pkill -SIGTERM tailscaled 2>/dev/null && echo "✓ tailscaled stopped" || echo "○ tailscaled not running"

# Kill sshd
sudo pkill -SIGTERM sshd 2>/dev/null && echo "✓ sshd stopped" || echo "○ sshd not running"

# Clean up tailscale socket
sudo rm -f /var/run/tailscale/tailscaled.sock 2>/dev/null && echo "✓ tailscale socket cleaned" || true

# Destroy tmux session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    echo "✓ tmux session '$SESSION_NAME' destroyed"
else
    echo "✓ No tmux session to destroy"
fi

echo ""
echo "Services stopped. WSL will shut down when idle."