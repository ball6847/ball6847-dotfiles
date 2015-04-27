
#if [ -f /root/.bashrc ]; then
    #. /root/.bashrc
#fi

alias ls='ls -h --color --group-directories-first'
alias install="sudo apt-get install"
alias search="apt-cache search"

alias ga="git add -A"
alias gcm="git commit -am"
alias gp="git push origin master"

export NVM_DIR="/home/ball6847/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads NVM_DIR

export PATH="$PATH:$HOME/.composer/vendor/bin"

export DOTPROFILE_LOADED=1

