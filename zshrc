umask 022

# we link this file to multiple user's home, and many resource sharing located on our user's home
if [ $SUDO_USER ] ; then
  SUDO_HOME=$(sudo -H -u $SUDO_USER env | grep HOME= | sed 's/HOME=//g')
else
  SUDO_HOME=$HOME
fi

# Path to your oh-my-zsh installation.
export ZSH=$SUDO_HOME/.oh-my-zsh
export ZSH_CUSTOM=$SUDO_HOME/.dotfiles/zsh_custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="random"
#ZSH_THEME="bira"
#ZSH_THEME="avit"
ZSH_THEME="cloud"

if [[ "$VSCODE_CLI" == "1" ]]; then
    ZSH_THEME="bira"
fi


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
# DISABLE_UNTRACKED_FILES_DIRTY="true"

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
plugins=(zsh-syntax-highlighting zsh-autosuggestions docker-compose zsh-wakatime zsh_reload)

# the zsh-completions.plugin.zsh seems not working
# so, we manually add plugin to $fpath to enable completions the plugin provides
fpath=($ZSH_CUSTOM/plugins/zsh-completions/src $fpath)

# init zsh-completions
autoload -U compinit && compinit

# User configuration
source $ZSH/oh-my-zsh.sh

alias gvim="$SUDO_HOME/.dotfiles/bin/start-gvim-maximized"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
alias clipboard="xsel --clipboard"
alias software-update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias docker-rm-all="sh -c 'docker rm -f \$(docker ps -aq)'"
alias connect-iphone="sudo usbmuxd -u -U usbmux"
alias dig="dig +nocmd +multiline +noall +answer"
alias ls="ls --color --group-directories-first"
alias gs="git status"
alias ga="git add -A"
alias gcm="git commit -am"
alias gco="git checkout"
alias gp="git push -u"
alias tm="tmux new-session -A -s main"
alias dc="docker-compose"
alias x="docker-compose exec"
alias ap="ansible-playbook"
alias li="npx lerna init --independent && npm install && echo node_modules > .gitignore"
alias lb="npx lerna bootstrap --hoist"
alias la="npx lerna add --hoist"
alias lr="npx lerna run --stream"
alias lx="npx lerna exec --stream"
alias lu="npx lerna updated"

ssh-tmux() {
  ssh -t "$@" tmux new-session -A -s main
}

# to hear sound from input device
# sudo apt-get install linux-kernel-lowlatency to reduce latency
alias load-loopback="pactl load-module module-loopback latency_msec=1 > /dev/null 2>&1"

# General environment variable
export LANG=en_US.UTF-8
export EDITOR='vim'
export TERM=xterm-256color

# Setup wine prefix, use win32
export WINEARCH=win32
export WINEPREFIX=$SUDO_HOME/.wine

# use ctrl+space to accept suggesstion (zsh-autosuggestions)
bindkey '^ ' autosuggest-accept

# ================================================

# activate nvm and use stable by version by default
export NVM_DIR="$SUDO_HOME/.nvm"
alias load-nvm=". $NVM_DIR/nvm.sh"

# direnv hook for zsh
which direnv > /dev/null && eval "$(direnv hook zsh)"



# show virtualenv if available
show_virtual_env() {
  if [ -n "$VIRTUAL_ENV" ]; then
    echo "($(basename $VIRTUAL_ENV))"
  fi
}

if [[ "$VSCODE_CLI" != "1" ]]; then
    PS_USER_MACHINE=$FG[154]$USER'@%M'
    PS1='$(show_virtual_env) $PS_USER_MACHINE%{$fg_bold[green]%}%p %{$fg[green]%}%c %{$fg_bold[cyan]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'
fi

export GOPATH=$HOME/.go
export PATH="$HOME/.dotfiles/bin:$HOME/.local/bin:$GOPATH/bin:$HOME/.composer/vendor/bin:$PATH"

# set up gvm
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# load local zsh script
# keep this at bottom of this file
if [ -f $SUDO_HOME/.lzshrc ]; then
  source $SUDO_HOME/.lzshrc
fi

