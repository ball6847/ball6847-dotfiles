#!/bin/bash

echo "Cleaning previous npm installations..."

# Clean up any existing npm installations
npm uninstall -g @qwen-code/qwen-code 2>/dev/null || true
npm uninstall -g @google/gemini-cli 2>/dev/null || true
npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
npm uninstall -g opencode-ai 2>/dev/null || true
npm uninstall -g mongodb-mcp-server 2>/dev/null || true

# Reshim nodejs to ensure npm is properly recognized
asdf reshim nodejs

echo "Installing AI tools..."

echo "Installing Qwen Code..."
bun install --global @qwen-code/qwen-code@latest

echo "Installing Gemini CLI..."
bun install --global @google/gemini-cli@latest

# no longer use claude code
# echo "Installing Claude Code..."
# bun install --global @anthropic-ai/claude-code@latest

echo "Installing OpenCode AI..."
bun install --global opencode-ai@latest

# MCP Servers

echo "Installing MCP Language Server..."
go install github.com/isaacphi/mcp-language-server@latest

# echo "Installing MCP gRPCurl..."
# go install github.com/wricardo/mcp-grpcurl@latest
# grpcurl-mcp cannot be isntalled via `go install`
# need to clone, build and add to PATH
# git clone https://github.com/wricardo/grpcurl-mcp.git && cd grpcurl-mcp && go build -o ~/.local/bin/grpcurl-mcp ./main.go
# TODO: make this idempotent so we can run multiple times without issues

echo "Installing MCP Kafka Server..."
go install github.com/kanapuli/mcp-kafka@latest

echo "Installing MCP MongoDB Server..."
bun install --global mongodb-mcp-server@latest

# reshim golang, bun, and nodejs to make sure newly installed binaries are available
asdf reshim golang
asdf reshim bun
asdf reshim nodejs

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is not installed. This may degrade opencode's file searching capabilities. Consider installing it with your package manager (e.g., 'sudo apt install ripgrep' on Ubuntu)."
fi

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo "Warning: grpcurl is not installed. This may be needed for gRPC testing and debugging. Consider installing it with your package manager (e.g., 'sudo apt install grpcurl' on Ubuntu)."
fi
