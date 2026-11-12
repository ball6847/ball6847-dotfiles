#!/bin/bash

update_pi_extensions() {
    echo "Updating pi extensions..."

    if ! command -v pi &> /dev/null; then
        echo "Warning: pi command not found, skipping extension update."
        echo "  Install pi first: curl -fsSL https://pi.dev/install.sh | sh"
        return 0
    fi

    pi update --extensions
}

echo "Installing AI tools..."

bun add -g --ignore-scripts @earendil-works/pi-coding-agent &
uv tool install "scrapling[fetchers,shell]" &
npm install -g opencode-ai@latest &
npm install -g @agegr/pi-web &
npm install -g @deepseek-ai/dsh &

# agent-browser ships on npm/bun, crates.io is stuck at 0.19.0.
# The asdf shim shadows ~/.bun/bin on PATH, so drop the cargo install too.
cargo uninstall agent-browser 2> /dev/null || true
rm -f "$HOME"/.asdf/installs/rust/*/bin/agent-browser
rm -f "$HOME/.asdf/shims/agent-browser"
bun add -g agent-browser@latest &

wait

# runs after wait so it does not race the other bun installs.
# --trust runs the postinstall script, which downloads the native binary and the
# macOS helper. Without it the CLI aborts with "Native binary not found".
bun add -g agent-desktop@latest --trust

update_pi_extensions

# build the pi-diff fork (TypeScript -> JS) so the extension can run
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

# reshim so the new binaries are on PATH
if command -v asdf &> /dev/null; then
    asdf reshim golang
    asdf reshim bun
    asdf reshim nodejs
    asdf reshim rust
fi

# Chrome for Testing, safe to run more than once
agent-browser install

# Playwright + Patchright Chromium for Scrapling's DynamicFetcher/StealthyFetcher.
# pi-webfetch falls back to these for JS-rendered pages.
SCRAPLING_PY="$(dirname "$(command -v scrapling)")/../share/uv/tools/scrapling/bin/python"
if [ -x "$SCRAPLING_PY" ]; then
    echo "Installing Scrapling browsers (Playwright + Patchright Chromium)..."
    "$SCRAPLING_PY" -m playwright install chromium
    "$SCRAPLING_PY" -m patchright install chromium
else
    echo "Warning: scrapling python not found at $SCRAPLING_PY, skipping browser install"
fi

# dependency checks
if ! command -v rg &> /dev/null; then
    echo "Warning: ripgrep (rg) is missing. Install: brew install ripgrep | sudo apt install ripgrep"
fi

if ! command -v grpcurl &> /dev/null; then
    echo "Warning: grpcurl is missing. Install: brew install grpcurl | sudo apt install grpcurl"
fi

# scrapling is required by pi-webfetch for general web page fetching
if ! command -v scrapling &> /dev/null; then
    echo "Warning: scrapling is missing. Install: uv tool install 'scrapling[fetchers,shell]'"
elif [ -x "${SCRAPLING_PY:-/nonexistent}" ]; then
    # the CLI can exist while Chromium is missing
    CHROMIUM_PATH=$("$SCRAPLING_PY" -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p: print(p.chromium.executable_path)
" 2>/dev/null | tail -1)
    if [ -z "$CHROMIUM_PATH" ] || [ ! -e "$CHROMIUM_PATH" ]; then
        echo "Warning: scrapling's Chromium is missing. Run: $SCRAPLING_PY -m playwright install chromium && $SCRAPLING_PY -m patchright install chromium"
    fi
fi

# gh is required by pi-webfetch for GitHub URL fetching
if ! command -v gh &> /dev/null; then
    echo "Warning: gh (GitHub CLI) is missing. Install: brew install gh | sudo apt install gh"
fi

# yt-dlp is required by pi-webfetch for YouTube URL fetching
if ! command -v yt-dlp &> /dev/null; then
    echo "Warning: yt-dlp is missing. Install: brew install yt-dlp | sudo apt install yt-dlp"
fi

# agent-desktop needs macOS permissions for screen and UI work
if ! command -v agent-desktop &> /dev/null; then
    echo "Warning: agent-desktop is missing. Install: bun add -g agent-desktop@latest --trust"
else
    AD_PERMS=$(agent-desktop permissions 2> /dev/null)
    AD_ACCESSIBILITY=$(echo "$AD_PERMS" | grep -o '"accessibility":{"state":"[a-z_]*"' | head -1 | sed 's/.*"state":"//; s/"$//')
    AD_SCREEN=$(echo "$AD_PERMS" | grep -o '"screen_recording":{"state":"[a-z_]*"' | head -1 | sed 's/.*"state":"//; s/"$//')
    if [ "$AD_ACCESSIBILITY" != "granted" ] && [ "$AD_ACCESSIBILITY" != "not_required" ]; then
        echo "Warning: agent-desktop accessibility permission is '${AD_ACCESSIBILITY:-unknown}'. Grant it with: agent-desktop permissions --guide"
        AD_NEEDS_PROMPT=1
    fi
    if [ "$AD_SCREEN" != "granted" ] && [ "$AD_SCREEN" != "not_required" ]; then
        echo "Warning: agent-desktop screen recording permission is '${AD_SCREEN:-unknown}'. Grant it with: agent-desktop permissions --guide"
        AD_NEEDS_PROMPT=1
    fi

    # `agent-desktop permissions --request` asks macOS to show the prompts, and only
    # an Aqua session can show them. Over SSH macOS refuses to prompt and auto-denies,
    # so the request lands in System Settings under the SSH session instead of the
    # agent-desktop binary. Grant Terminal/Ghostty under Privacy & Security >
    # Accessibility, and the agent-desktop binary too when macOS lists it separately.
    if [ "${AD_NEEDS_PROMPT:-0}" = "1" ] && [ "$(launchctl managername 2> /dev/null)" = "Aqua" ]; then
        agent-desktop permissions --request
    fi
fi
