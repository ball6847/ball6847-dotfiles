#!/bin/bash

dir=~/.dotfiles         # dotfiles directory
olddir=~/.dotfiles_old  # old dotfiles backup directory

# list of files/folders to symlink in homedir
files="
    profile
    bashrc
    bash_aliases
    envrc
    vimrc
    zshrc
    npmrc
    direnvrc
    gitconfig
    xbindkeysrc
    tmux.conf
    pip/pip.conf
    config/terminator
    config/kitty
    ansible.cfg
    coffeelint.json"

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
    basedir="$(dirname $file)"

    if [[ "$basedir" != "." ]]; then
        [ ! -d $olddir/$basedir ] && mkdir -p $olddir/$basedir
        [ ! -d ~/.$basedir ] && mkdir -p ~/.$basedir
    fi

    # backup to $olddir if neccessary
    echo "Moving any existing dotfiles from ~ to $olddir"

    [ -f ~/.$file ] && mv -f ~/.$file $olddir/$file

    # create link at home directory
    echo "Creating symlink to $file in home directory."
    ln -sf $dir/$file ~/.$file
done

