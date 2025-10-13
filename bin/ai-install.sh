#!/bin/bash

npm install -g @qwen-code/qwen-code@latest
npm install -g @google/gemini-cli@latest
npm install -g @anthropic-ai/claude-code@latest
npm install -g opencode-ai@latest

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is not installed. This may degrade opencode's file searching capabilities. Consider installing it with your package manager (e.g., 'sudo apt install ripgrep' on Ubuntu)."
fi
