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
#ZSH_THEME="robbyrussell"
ZSH_THEME="bira"


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
plugins=(zsh-syntax-highlighting autoenv docker-compose)

# User configuration

#export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:${SUDO_HOME}/.composer/vendor/bin:${SUDO_HOME}/Application/google_appengine/:${SUDO_HOME}/.local/bin"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# activate nvm silently
#nvm use stable &> /dev/null

# You may need to manually set your language environment
export LANG=en_US.UTF-8


# Preferred editor for local and remote sessions
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#alias ls="ls -lX --color --group-directories-first"
alias ls="ls --color --group-directories-first"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
#alias vim="${SUDO_HOME}/dotfiles/scripts/start_gvim_maximized"
#alias gvim="${SUDO_HOME}/dotfiles/scripts/start_gvim_maximized"
alias a2reload="sudo service apache2 reload"
alias a2restart="sudo service apache2 restart"
alias maildump="${SUDO_HOME}/Apps/maildump/.venv/bin/maildump"
alias gs="git status"
alias ga="git add -A"
alias gcm="git commit -am"
alias gp="git push"
alias x="docker-compose exec"
alias tm="tmux new-session -A -s main"
alias nginx-proxy-reload="docker exec -it nginx-proxy /generate.sh"
alias clipboard="xsel --clipboard"
alias software-update="sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y"
alias docker-rm-all="sh -c 'docker rm -f \$(docker ps -aq)'"
alias dc="docker-compose"
alias update-coke="ssh laamped.com -t bash -c \"~/www/cocacola/bin/update\""


export TERM=xterm-256color
export APACHE_LOG_DIR=/var/log/apache2
export APACHE_WWW_DIR=${SUDO_HOME}/www/
export PYTHONPATH=/usr/bin/python

# Setup wine prefix, use win32
export WINEARCH=win32
export WINEPREFIX=${SUDO_HOME}/.wine

# Node environment = development by default
export NODE_ENV=development

#export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_25/
export JAVA_HOME=/usr/lib/jvm/jdk-8u5-tuxjdk-b08/
export ANSIBLE_INVENTORY=~/.ansible/hosts

export GOPATH=$HOME/go


# set git common configuration
git config --global user.email "ball6847@gmail.com"
git config --global user.name "Porawit Poboonma"
git config --global merge.tool meld
git config --global push.default simple



# to hear sound from input device
# sudo apt-get install linux-kernel-lowlatency to reduce latency
#pactl load-module module-loopback latency_msec=1 > /dev/null 2>&1


#use docker on tcp
#export DOCKER_HOST="tcp://127.0.0.1:2375"

# load local zsh script
# keep this at bottom of this file
if [ -f $SUDO_HOME/.lzshrc ]; then
    source $SUDO_HOME/.lzshrc
fi

#export NVM_DIR="/home/ball6847/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

#export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
