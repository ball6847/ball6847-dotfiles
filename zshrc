umask 022

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
plugins=(zsh-syntax-highlighting zsh-autosuggestions docker-compose)

# the zsh-completions.plugin.zsh seems not working
# so, we manually add plugin to $fpath to enable completions the plugin provides
fpath=($ZSH_CUSTOM/plugins/zsh-completions/src $fpath)
fpath=($DOTFILES/desk/shell_plugins/zsh $fpath)

# init zsh-completions
autoload -Uz compinit

for dump in ~/.zcompdump(N.mh+24); do
  compinit
done

compinit -C

# User configuration
source $ZSH/oh-my-zsh.sh

# ================================================
# activate various command line tool

# set direnv hooks if it already installed
if which direnv > /dev/null; then
    eval "$(direnv hook zsh)"
fi

# load gvm if neccessary
if ! which go > /dev/null; then
    [[ -s "$SUDO_HOME/.gvm/scripts/gvm" ]] && source "$SUDO_HOME/.gvm/scripts/gvm"
fi

# load local zsh script
if [ -f $SUDO_HOME/.lzshrc ]; then
    source $SUDO_HOME/.lzshrc
fi

# auto load nvm default node version if any.
# you can create alias for default using `nvm alias default v12.11.0`
if [ -f $SUDO_HOME/.nvm/alias/default ]; then
    export PATH="$PATH:$SUDO_HOME/.nvm/versions/node/`cat $SUDO_HOME/.nvm/alias/default`/bin"
fi


#/home/ball6847/.nvm/versions/node/v10.16.3/bin


# ================================================

# General environment variable
export LANG=en_US.UTF-8
export EDITOR='vim'
export TERM=xterm-256color
export WINEARCH=win32
export WINEPREFIX=$SUDO_HOME/.wine
export YARN_CACHE_FOLDER="$SUDO_HOME/.cache/yarn-cache"
export PATH="$SUDO_HOME/.dotfiles/bin:$SUDO_HOME/.local/bin:$SUDO_HOME/.composer/vendor/bin:$SUDO_HOME/.config/composer/vendor/bin:$SUDO_HOME/.dotnet:$PATH"
export NVM_DIR="$SUDO_HOME/.nvm"
export GIT_AUTHOR_NAME="Porawit Poboonma"
export GIT_AUTHOR_EMAIL="ball6847@gmail.com"
export GIT_COMMITTER_NAME="Porawit Poboonma"
export GIT_COMMITTER_EMAIL="ball6847@gmail.com"

# ================================================
# set up bash alias

alias c="clear"
alias f='$(thefuck $(fc -ln -1 | tail -n 1)); fc -R'
alias fuck='$(thefuck $(fc -ln -1 | tail -n 1)); fc -R'
alias vimrc="vim ~/.vimrc"
alias zshrc="vim ~/.zshrc"
#alias gvim="$SUDO_HOME/.dotfiles/bin/start-gvim-maximized"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
alias rmpy='find . | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf'
alias clipboard="xsel --clipboard"
alias software-update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias docker-rm-all="sh -c 'docker rm -f \$(docker ps -aq)'"
alias connect-iphone="sudo usbmuxd -u -U usbmux"
#alias fix-mic-noise="wget -qO - https://bit.ly/2mBJSJo | sudo bash && pulseaudio -k"
alias dig="dig +nocmd +multiline +noall +answer"
#alias ls="ls --color --group-directories-first"
alias gs="git status"
alias ga="git add -A"
alias gcm="git commit -am"
alias gco="git checkout"
alias gp="git push -u"
alias gb="git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias git-clean="git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D"
alias tm="tmux new-session -A -s main"
alias dc="docker-compose"
alias x="docker-compose exec"
alias ap="ansible-playbook"
alias li="lerna init --independent && npm install && echo node_modules > .gitignore"
alias lb="lerna bootstrap"
alias la="lerna add"
alias lr="lerna run --stream"
alias lx="lerna exec --stream"
alias lu="lerna updated"
alias r="runner"
alias k="kubectl"
alias kl="kubectl logs"
alias kg="kubectl get"
alias kgj="kubectl get jobs"
alias kgs="kubectl get svc"
alias kgp="kubectl get pods"
alias kgd="kubectl get deployment"
alias kd="kubectl describe"
alias kdj="kubectl describe jobs"
alias kds="kubectl describe svc"
alias kdp="kubectl describe pods"
alias kdd="kubectl describe deployment"
alias kdf="kubectl delete -f"
alias kc="kubectl create -f"
alias ka="kubectl apply -f"
alias webcam-enable="sudo modprobe -a uvcvideo"
alias webcam-disable="sudo modprobe -r uvcvideo"
alias direnv-init-node="(echo \"layout node\" > .envrc) && direnv allow"
alias direnv-init-python="(echo \"layout python\" > .envrc) && direnv allow"
alias load-nvm="source $NVM_DIR/nvm.sh"
alias gen-cert="openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem"
alias gen-prettier="cp ~/.dotfiles/prettierrc .prettierrc"
alias ngrok-angular="ngrok http 4200 -region=ap --host-header=rewrite"
alias copy-mobi="mkdir -p ~/Documents/mobi/ && find . -name '*.mobi' -exec cp -f {} ~/Documents/mobi \\;"
alias start-ng-clean="docker ps -aq --filter 'ancestor=ball6847/angular-dev-base:latest' --filter 'status=exited' | xargs --no-run-if-empty docker rm"
alias term="nohup terminator"

curla() {
    curl -H "Content-Type: application/json" -H "Authorization: Bearer $JWT_AUTH_TOKEN" "$@" | jq
}

# to hear sound from input device
# sudo apt-get install linux-kernel-lowlatency to reduce latency
alias load-loopback="pactl load-module module-loopback latency_msec=1 > /dev/null 2>&1"

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

ssh-tmux() {
    ssh -t "$@" tmux new-session -A -s main
}

lazynvm() {
  unset -f nvm node npm npx &> /dev/null
  export NVM_DIR=~/.nvm
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
  if [ -f "$NVM_DIR/bash_completion" ]; then
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
  fi
}

nvm() {
  lazynvm
  nvm $@
}

# ================================================

export AWS_VAULT_BACKEND=secret-service
