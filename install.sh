#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/.dotfiles                    # dotfiles directory
olddir=~/.dotfiles_old             # old dotfiles backup directory

# list of files/folders to symlink in homedir
files="
    profile
    bashrc
    bash_aliases
    vimrc
    zshrc
    bang
    gitconfig
    xbindkeysrc
    tmux.conf
    eslintrc.json
    pip/pip.conf
    config/terminator/config
    ansible.cfg
    coffeelint.json"

##########

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

# link any files in ~/dotfiles/.vim/ to $HOME/.vim/
mkdir -p $olddir/.vim/

for d in $dir/.vim/*; do
    dirname=$(basename $d)
    mv -f $HOME/.vim/$dirname $olddir/.vim/
    ln -sf $d $HOME/.vim/$dirname
done
