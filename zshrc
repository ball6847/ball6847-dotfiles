#mask 022

# we link this file to multiple user's home, and many resource sharing located on our user's home
if [ $SUDO_USER ] ; then
    SUDO_HOME=$(sudo -H -u $SUDO_USER env | grep HOME= | sed 's/HOME=//g')
else
    SUDO_HOME=$HOME
fi

export DOTFILES=$SUDO_HOME/.dotfiles

# Path to your oh-my-zsh installation.
export ZSH=$SUDO_HOME/.oh-my-zsh
export ZSH_CUSTOM=$SUDO_HOME/.dotfiles/zsh_custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="af-magic"
#ZSH_THEME="amuse"
ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"
#ZSH_THEME="bira"
#ZSH_THEME="random"
#ZSH_THEME="intheloop"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-autosuggestions ansible kubectl helm asdf z)

# the zsh-completions.plugin.zsh seems not working
# so, we manually add plugin to $fpath to enable completions the plugin provides
fpath=($ZSH_CUSTOM/plugins/zsh-completions/src $fpath)
#fpath=($DOTFILES/desk/shell_plugins/zsh $fpath)

# init zsh-completions
autoload -Uz compinit

for dump in ~/.zcompdump(N.mh+24); do
  compinit
done

compinit -C

# User configuration
source $ZSH/oh-my-zsh.sh

# ================================================
# detect wsl
# TODO: confirm this return 1 on macos

is_wsl() {
    if uname -r | grep -q microsoft; then
        return 0
    else
        return 1
    fi
}

# ================================================
# activate various command line tool

# load local zsh script
if [ -f $SUDO_HOME/.lzshrc ]; then
    source $SUDO_HOME/.lzshrc
fi

# ================================================

export ASDF_DATA_DIR="$SUDO_HOME/.asdf"

# asdf rust plugin requires manually PATH setup, we should keep this align with ~/.tool-versions
export ASDF_RUST_BIN="$ASDF_DATA_DIR/installs/rust/1.84.1"

# General environment variable
export LC_ALL="en_US.UTF-8"
export LANG=en_US.UTF-8
export EDITOR='nvim'
export TERM=xterm-256color
export WINEARCH=win32
export WINEPREFIX=$SUDO_HOME/.wine
export PATH="$ASDF_DATA_DIR/shims:$ASDF_RUST_DIR/bin:/opt/homebrew/bin:$SUDO_HOME/.dotfiles/bin:$SUDO_HOME/.local/bin:$SUDO_HOME/.composer/vendor/bin:$SUDO_HOME/.config/composer/vendor/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin:/mnt/c/Users/ball6/AppData/Local/Programs/Microsoft VS Code/bin:/snap/bin:$PATH"

# ================================================
# set up bash alias

alias c="clear"
alias f='$(thefuck $(fc -ln -1 | tail -n 1)); fc -R'
alias fuck='$(thefuck $(fc -ln -1 | tail -n 1)); fc -R'
alias vimrc="nvim ~/.vimrc"
alias zshrc="nvim ~/.zshrc"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
alias clipboard="xsel --clipboard"
alias software-update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias gs="git status"
alias ga="git add -A"
alias gcm="git commit -am"
alias gco="git checkout"
alias gp="git push -u"
alias gd="git diff"
alias gb="git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias git-clean="git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D"
alias tm="tmux new-session -A -s main"
alias dc="docker-compose"
alias dcx="docker-compose exec"
alias dcl="docker-compose logs -f"
alias a="ansible-playbook"
alias ap="ansible-playbook"
alias direnv-init-node="(echo \"layout node\" > .envrc) && direnv allow"
alias direnv-init-python="(echo \"layout python\" > .envrc) && direnv allow"
alias gen-cert="openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem"
alias gen-prettier="cp ~/.dotfiles/prettierrc .prettierrc"
alias wsl2-reclaim="sudo sh -c \"echo 1 > /proc/sys/vm/drop_caches; echo 1 > /proc/sys/vm/compact_memory\""
alias v="nvim"
alias t="task"
alias m="make"


# add custom alias for wsl
if is_wsl; then
  alias open="explorer.exe"
  alias explorer="explorer.exe"
fi

# ================================================

# use ctrl+space to accept suggesstion (zsh-autosuggestions)
bindkey '^ ' autosuggest-accept
#bindkey '^@' autosuggest-toggle

# fix up/down broken in tmux
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# 10ms for key sequences
KEYTIMEOUT=1

# ================================================
# in large project tslint requires a lot of ulimit
# make sure you correctly set /etc/security/limits.conf
# @see: https://askubuntu.com/questions/162229/how-do-i-increase-the-open-files-limit-for-a-non-root-user

ulimit -Sn 4096

# ================================================
# show virtualenv if available

show_virtual_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "($(basename $VIRTUAL_ENV))"
    fi
}

# ================================================
# set direnv hooks if it already installed

if which direnv > /dev/null; then
    eval "$(direnv hook zsh)"
fi

# ================================================
# set z integraion, see https://github.com/ajeetdsouza/zoxide?tab=readme-ov-file#installation

if which zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi

# ================================================
# Allow parent to initialize shell
#
# This is awesome for opening terminals in VSCode.

if [[ -n $ZSH_INIT_COMMAND ]]; then
    echo "Running: $ZSH_INIT_COMMAND"
    eval "$ZSH_INIT_COMMAND"
fi

# ================================================
# grc zsh integration (generic colorizer)

[[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh
