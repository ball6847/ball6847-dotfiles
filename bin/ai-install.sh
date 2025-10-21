#!/bin/bash

echo "Installing AI tools..."

echo "Installing Qwen Code..."
npm install -g @qwen-code/qwen-code@latest

echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli@latest

echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code@latest

echo "Installing OpenCode AI..."
npm install -g opencode-ai@latest

echo "Installing MCP Language Server..."
go install github.com/isaacphi/mcp-language-server@latest
asdf reshim golang

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is not installed. This may degrade opencode's file searching capabilities. Consider installing it with your package manager (e.g., 'sudo apt install ripgrep' on Ubuntu)."
fi

