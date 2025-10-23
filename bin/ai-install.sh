#!/bin/bash

# TODO: we might need to move away from node(and npm) and run these ai agent via deno or bun instead

echo "Installing AI tools..."

echo "Installing Qwen Code..."
npm install -g @qwen-code/qwen-code@latest

echo "Installing Gemini CLI..."
npm install -g @google/gemini-cli@latest

echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code@latest

echo "Installing OpenCode AI..."
npm install -g opencode-ai@latest

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
npm install -g mongodb-mcp-server@latest

echo "Installing MCP Wait Tool..."
npm install -g @automation-ai-labs/mcp-wait@latest

# reshim golang to make sure newly installed go binaries are available
asdf reshim golang
asdf reshim nodejs

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is not installed. This may degrade opencode's file searching capabilities. Consider installing it with your package manager (e.g., 'sudo apt install ripgrep' on Ubuntu)."
fi

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo "Warning: grpcurl is not installed. This may be needed for gRPC testing and debugging. Consider installing it with your package manager (e.g., 'sudo apt install grpcurl' on Ubuntu)."
fi


