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
    config/opencode/opencode.jsonc
    config/opencode/commands
    config/opencode/agents
    config/rio
    config/vite
    qwen/settings.json
    gemini/settings.json
    agents"

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

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

git checkout ~/.opencode/config/kitty

# Setup agent skills symlinks (kimi, vibe, claude, etc.)
# This links only the skills directories, keeping agent configs in ~
if [[ -f "$dir/bin/setup-agent-skills" ]]; then
    echo ""
    bash "$dir/bin/setup-agent-skills"
fi
