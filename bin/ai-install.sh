#!/bin/bash

# =============================================================================
# FUNCTION DEFINITIONS
# =============================================================================

install_pi_packages() {
    local script_dir repo_dir pi_settings pi_settings_fallback packages

    echo "Installing pi packages from settings.json..."

    if ! command -v pi &> /dev/null; then
        echo "Warning: pi command not found. Skipping pi package installation."
        echo "  Install pi first: curl -fsSL https://pi.dev/install.sh | sh"
        return 0
    fi

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    repo_dir="$(dirname "$script_dir")"

    # Prefer the live symlink; fall back to the repo file if install.sh hasn't run yet
    pi_settings="$HOME/.pi/agent/settings.json"
    pi_settings_fallback="$repo_dir/pi/agent/settings.json"

    if [[ ! -f "$pi_settings" && -f "$pi_settings_fallback" ]]; then
        pi_settings="$pi_settings_fallback"
    fi

    if [[ ! -f "$pi_settings" ]]; then
        echo "No pi settings.json found. Skipping pi package installation."
        return 0
    fi

    # Read packages array from settings.json
    if command -v jq &> /dev/null; then
        packages=$(jq -r '.packages[]? // empty' "$pi_settings" 2>/dev/null)
    elif command -v python3 &> /dev/null; then
        packages=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("\n".join(d.get("packages",[])))' "$pi_settings" 2>/dev/null)
    else
        echo "Warning: jq or python3 not found. Cannot read pi packages from settings.json."
        packages=""
    fi

    if [[ -z "$packages" ]]; then
        echo "No packages configured in pi settings.json."
        return 0
    fi

    echo "$packages" | while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        echo "Installing pi package: $pkg"
        pi install "$pkg"
    done
}

# =============================================================================
# AI TOOLS INSTALLATION SECTION
# =============================================================================

echo "Installing AI tools..."

# bun install --global @qwen-code/qwen-code@latest
# bun install --global @google/gemini-cli@latest
# bun install --global @anthropic-ai/claude-code@latest
bun add -g --ignore-scripts @earendil-works/pi-coding-agent &
uv tool install --upgrade mistral-vibe &
# uv tool install --upgrade kimi-cli
npm install -g opencode-ai@latest &
# curl -fsSL https://qoder.com/install | bash &
# npm install -g diffx-cli@latest &
# npm install -g skills@latest &
# npm install -g cachebro@latest &
cargo install agent-browser &
# cargo install --git https://github.com/rtk-ai/rtk &
# npm install -g openrtk &

wait

# =============================================================================
# PI PACKAGES INSTALLATION
# =============================================================================

install_pi_packages

# bun install --global @th0rgal/ralph-wiggum
# npm install --global vibe-kanban@latest
# npm install -g opencode-orchestrator
# bun add -g opencode-swarm-plugin@latest

# curl -fsSL https://raw.githubusercontent.com/njbrake/agent-of-empires/main/scripts/install.sh | bash

# =============================================================================
# MCP SERVERS INSTALLATION SECTION
# =============================================================================

# echo "Installing MCP Language Server..."
# go install github.com/isaacphi/mcp-language-server@latest

# echo "Installing MCP gRPCurl..."
# go install github.com/wricardo/mcp-grpcurl@latest
# grpcurl-mcp cannot be isntalled via `go install`
# need to clone, build and add to PATH
# git clone https://github.com/wricardo/grpcurl-mcp.git && cd grpcurl-mcp && go build -o ~/.local/bin/grpcurl-mcp ./main.go
# TODO: make this idempotent so we can run multiple times without issues

# echo "Installing MCP Kafka Server..."
# go install github.com/kanapuli/mcp-kafka@latest
#
# echo "Installing MCP MongoDB Server..."
# bun install --global mongodb-mcp-server@latest
#
# echo "Installing vibe-mcp..."
# VIBE_MCP_DIR="$HOME/.local/share/mcp-servers/vibe-mcp"
# if [ -d "$VIBE_MCP_DIR/.git" ]; then
#     # Directory exists and is a git repo, pull latest changes
#     (cd "$VIBE_MCP_DIR" && git pull)
# else
#     # Directory doesn't exist or isn't a git repo, clone fresh
#     mkdir -p "$(dirname "$VIBE_MCP_DIR")"
#     rm -rf "$VIBE_MCP_DIR"
#     git clone https://github.com/DarkPhilosophy/vibe-mcp.git "$VIBE_MCP_DIR"
# fi

# echo "Installing opencode plugin manager (ocx)..."
# npm install -g ocx

# =============================================================================
# RESHIM SECTION - Update PATH for newly installed binaries
# =============================================================================

# reshim golang, bun, and nodejs to make sure newly installed binaries are available
if command -v asdf &> /dev/null; then
    asdf reshim golang
    asdf reshim bun
    asdf reshim nodejs
    asdf reshim rust
fi

# Download Chrome for Testing (safe to run multiple times)
agent-browser install

# =============================================================================
# DEPENDENCY CHECKS SECTION
# =============================================================================

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is not installed. This may degrade opencode's file searching capabilities. Consider installing it with your package manager (e.g., 'sudo apt install ripgrep' on Ubuntu)."
fi

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo "Warning: grpcurl is not installed. This may be needed for gRPC testing and debugging. Consider installing it with your package manager (e.g., 'sudo apt install grpcurl' on Ubuntu)."
fi

# =============================================================================
# PLUGIN UPDATES SECTION
# =============================================================================

# # update opencode-gemini-auth plugin https://github.com/jenslys/opencode-gemini-auth
# sh -c "(cd ~ && sed -i.bak '/\"opencode-gemini-auth\"/d' .cache/opencode/package.json && rm -rf .cache/opencode/node_modules/opencode-gemini-auth && echo \"[Plugin] opencode-gemini-auth - update script finished successfully.\")"
#
# # update opencode-alibaba-qwen3-auth plugin https://github.com/geoh/opencode-alibaba-qwen3-auth
# sh -c "(cd ~ && sed -i.bak '/\"opencode-alibaba-qwen3-auth\"/d' .cache/opencode/package.json && rm -rf .cache/opencode/node_modules/opencode-alibaba-qwen3-auth && echo \"[Plugin] opencode-alibaba-qwen3-auth - update script finished successfully.\")"
