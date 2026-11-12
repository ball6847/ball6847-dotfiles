#!/bin/bash

dir=~/.dotfiles
olddir=~/.dotfiles_old

# symlinked into the home dir
files="
    profile
    bashrc
    bash_aliases
    zshrc
    direnvrc
    gitconfig
    xbindkeysrc
    tmux.conf
    pip/pip.conf
    config/terminator
    config/kitty/kitty.conf
    config/nvim
    ansible.cfg
    tool-versions
    config/opencode
    config/git-commit-ai
    config/rio
    config/ghostty
    config/vite
    config/agent-of-empires
    pi/agent/settings.json
    pi/agent/models.json
    pi/agent/configs
    pi/agent/agents
    pi/agent/extensions
    pi/agent/pstack
    pi/agent/APPEND_SYSTEM.md
    pi/agent/keybindings.json
    pi/agent/mcode-token.mjs
    prime/agent/settings.json
    prime/agent/models.json
    prime/agent/keybindings.json
    qwen/settings.json
    agents
    kimi
    vibe
    agent-browser
    qoder
    gemini
    dsh/settings.yaml"

echo "Backing up existing dotfiles to $olddir"
mkdir -p "$olddir"

[ ! -d ~/.agent-browser ] && mkdir -p ~/.agent-browser

cd "$dir" || exit

for file in $files; do
    basedir="$(dirname "$file")"

    if [[ "$basedir" != "." ]]; then
        [ ! -d "$olddir/$basedir" ] && mkdir -p "$olddir/$basedir"
        [ ! -d ~/."$basedir" ] && mkdir -p ~/."$basedir"
    fi

    # move the old copy aside, then link the repo version in its place
    [ -e "$olddir/$file" ] && rm -rf "$olddir/$file"
    [ -e ~/."$file" ] || [ -L ~/."$file" ] && mv -f ~/."$file" "$olddir/$file"

    ln -sf "$dir/$file" ~/."$file"
done

# claude reads skills from ~/.agents/skills
if [ ! -L ~/.claude/skills ]; then
    mkdir -p ~/.claude
    ln -sf ~/.agents/skills ~/.claude/skills
fi

# agent-of-empires lives in ~/.config on mac
if [ "$(uname)" = "Darwin" ] && [ ! -L ~/.agent-of-empires ]; then
    ln -sf ~/.config/agent-of-empires ~/.agent-of-empires
fi

# the loop above can leave a link pointing at a nested copy of itself
fix_nested_symlinks() {
    for subdir in config/*/; do
        nested="$subdir$(basename "$subdir")"
        [ -L "$nested" ] && rm -f "$nested"
    done
    [ -L "agents/agents" ] && rm -f agents/agents
}
fix_nested_symlinks

# opencode.json was renamed to opencode.jsonc
unlink ~/.opencode/opencode.json 2>/dev/null || true

# git checkout needs -C, without it it runs in the wrong directory
git -C ~/.dotfiles checkout config/kitty

# per-OS rio config (macOS/Linux)
bash "$dir/link-rio.sh"
