#!/bin/bash
# start-remote-access.sh - Start remote access services in tmux
# NOTE: This script is designed for WSL (Windows Subsystem for Linux) only.
# It starts sshd and tailscaled manually without systemd.
# Do not run on native Linux systems that use systemd.

# Check if running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Error: This script should only run in WSL."
    echo "Native Linux systems should use systemd for these services."
    exit 1
fi

SESSION_NAME="remote-access"

# Function to start service in tmux window
start_service_in_window() {
    local window_num=$1
    local service_name=$2
    local service_cmd=$3
    
    tmux new-window -t "$SESSION_NAME:$window_num" -n "$service_name"
    tmux send-keys -t "$SESSION_NAME:$window_num" "sudo $service_cmd" Enter
}

# Check if tmux session exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists."
    echo "Services are likely already running."
    echo ""
    echo "Attaching to session..."
    tmux attach -t "$SESSION_NAME"
    exit 0
fi

echo "Creating tmux session '$SESSION_NAME'..."

# Create new session (empty first window)
tmux new-session -d -s "$SESSION_NAME"

# Create window 0 for sshd
tmux new-window -t "$SESSION_NAME:0" -n "sshd"

# Wait for window to be created
sleep 0.5

# Start sshd in window 0
echo "Starting sshd..."
tmux send-keys -t "$SESSION_NAME:0" "sudo mkdir -p /run/sshd && sudo chmod 755 /run/sshd && sudo /usr/sbin/sshd -D" Enter

# Create window 1 for tailscaled
tmux new-window -t "$SESSION_NAME:1" -n "tailscaled"

# Wait for window to be created
sleep 0.5

# Start tailscaled in window 1
echo "Starting tailscaled..."
tmux send-keys -t "$SESSION_NAME:1" "sudo /usr/sbin/tailscaled --socket=/var/run/tailscale/tailscaled.sock" Enter

echo ""
echo "✓ Services started in tmux session '$SESSION_NAME'"
echo "  - Window 0: sshd"
echo "  - Window 1: tailscaled"
echo ""
echo "Attaching to session (Ctrl+B D to detach)..."
tmux attach -t "$SESSION_NAME"