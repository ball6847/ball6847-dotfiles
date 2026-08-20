#!/bin/bash

# =============================================================================
# FUNCTION DEFINITIONS
# =============================================================================

update_pi_extensions() {
    echo "Updating pi extensions..."

    if ! command -v pi &> /dev/null; then
        echo "Warning: pi command not found. Skipping pi extension update."
        echo "  Install pi first: curl -fsSL https://pi.dev/install.sh | sh"
        return 0
    fi

    pi update --extensions
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
uv tool install scrapling &
uv tool install "scrapling[shell]" &
# uv tool install --upgrade kimi-cli
npm install -g opencode-ai@latest &
npm install -g @agegr/pi-web &
# curl -fsSL https://qoder.com/install | bash &
# npm install -g diffx-cli@latest &
# npm install -g skills@latest &
# npm install -g cachebro@latest &
cargo install agent-browser &
# cargo install --git https://github.com/rtk-ai/rtk &
# npm install -g openrtk &

wait

# =============================================================================
# PI EXTENSIONS UPDATE
# =============================================================================

update_pi_extensions

# Build pi-diff fork (TypeScript -> JS) so the extension can run
PI_DIFF_DIR="$HOME/.pi/agent/git/github.com/ball6847/pi-diff"
if [ -d "$PI_DIFF_DIR" ]; then
    echo "Building pi-diff fork at $PI_DIFF_DIR ..."
    (
        cd "$PI_DIFF_DIR"
        if command -v npm &> /dev/null; then
            npm install
            npm run build
        else
            echo "Warning: npm not found, skipping pi-diff build"
        fi
    )
fi

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

# Check if scrapling is installed (required for pi-webfetch general web page fetching)
if ! command -v scrapling &> /dev/null; then
    echo "Warning: scrapling is not installed. pi-webfetch needs it for general web page fetching. Run: uv tool install scrapling && uv tool install 'scrapling[shell]'"
fi

# Check if gh (GitHub CLI) is installed (required for pi-webfetch GitHub URL fetching)
if ! command -v gh &> /dev/null; then
    echo "Warning: gh (GitHub CLI) is not installed. pi-webfetch needs it for GitHub URL fetching. Install with: sudo apt install gh OR brew install gh"
fi

# Check if yt-dlp is installed (required for pi-webfetch YouTube URL fetching)
if ! command -v yt-dlp &> /dev/null; then
    echo "Warning: yt-dlp is not installed. pi-webfetch needs it for YouTube URL fetching. Install with: sudo apt install yt-dlp OR brew install yt-dlp"
fi

# =============================================================================
# PLUGIN UPDATES SECTION
# =============================================================================

# # update opencode-gemini-auth plugin https://github.com/jenslys/opencode-gemini-auth
# sh -c "(cd ~ && sed -i.bak '/\"opencode-gemini-auth\"/d' .cache/opencode/package.json && rm -rf .cache/opencode/node_modules/opencode-gemini-auth && echo \"[Plugin] opencode-gemini-auth - update script finished successfully.\")"
#
# # update opencode-alibaba-qwen3-auth plugin https://github.com/geoh/opencode-alibaba-qwen3-auth
# sh -c "(cd ~ && sed -i.bak '/\"opencode-alibaba-qwen3-auth\"/d' .cache/opencode/package.json && rm -rf .cache/opencode/node_modules/opencode-alibaba-qwen3-auth && echo \"[Plugin] opencode-alibaba-qwen3-auth - update script finished successfully.\")"
