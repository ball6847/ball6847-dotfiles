#!/bin/bash

dir=~/.dotfiles         # dotfiles directory
olddir=~/.dotfiles_old  # old dotfiles backup directory

# list of files/folders to symlink in homedir
files="
    profile
    bashrc
    bash_aliases
    zshrc
    npmrc
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
    config/vite
    qwen/settings.json
    gemini/settings.json
    agents
    kimi
    vibe
    agent-browser"

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# create ~/.agent-browser directory if it doesn't exist
[ ! -d ~/.agent-browser ] && mkdir -p ~/.agent-browser

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir || exit
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
    basedir="$(dirname "$file")"

    if [[ "$basedir" != "." ]]; then
        [ ! -d $olddir/"$basedir" ] && mkdir -p $olddir/"$basedir"
        [ ! -d ~/."$basedir" ] && mkdir -p ~/."$basedir"
    fi

    # backup to $olddir if neccessary
    echo "Moving any existing dotfiles from ~ to $olddir"

    # Remove existing backup if it exists to avoid conflicts with nested symlinks
    [ -e $olddir/"$file" ] && rm -rf $olddir/"$file"
    # Move existing file/symlink to backup (use -h to detect symlinks before following)
    [ -e ~/."$file" ] || [ -L ~/."$file" ] && mv -f ~/."$file" $olddir/"$file"

    # create link at home directory
    echo "Creating symlink to $file in home directory."
    ln -sf $dir/"$file" ~/."$file"
done

# exclusively create link from ~/.claude/skills to ~/.agents/skills
# check if already linked, then make sure ~/.claude exists the create a link inside
if [ ! -L ~/.claude/skills ]; then
    mkdir -p ~/.claude
    ln -sf ~/.agents/skills ~/.claude/skills
fi

# Fix nested symlinks created by the loop above
fix_nested_symlinks() {
    for subdir in config/*/; do
        dirname="$(basename "$subdir")"
        nested="$subdir$dirname"
        [ -L "$nested" ] && rm -f "$nested"
    done
    [ -L "agents/agents" ] && rm -f agents/agents
}
fix_nested_symlinks

# Cleanup deprecated opencode.json symlink (renamed to opencode.jsonc)
unlink ~/.opencode/opencode.json 2>/dev/null || true

# this is incorrect, must specify -C <directory> to git checkout
git -C ~/.dotfiles checkout config/kitty

