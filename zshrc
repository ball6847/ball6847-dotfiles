#mask 022zshrzshrc

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
#ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"
ZSH_THEME="bira"
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
plugins=(zsh-autosuggestions ansible kubectl helm asdf z deno golang)

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
export EDITOR='vim'
export TERM=xterm-256color
export WINEARCH=win32
export WINEPREFIX=$SUDO_HOME/.wine
export PATH="$ASDF_DATA_DIR/shims:$ASDF_RUST_DIR/bin:/opt/homebrew/bin:/usr/local/bin:$SUDO_HOME/.dotfiles/bin:$SUDO_HOME/.local/bin:$SUDO_HOME/.composer/vendor/bin:$SUDO_HOME/.config/composer/vendor/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin:/mnt/c/Users/ball6/AppData/Local/Programs/Microsoft VS Code/bin:/snap/bin:$SUDO_HOME/.exo/bin:$SUDO_HOME/.opencode/bin:$SUDO_HOME/.bun/bin:$PATH"
export GIT_COMMIT_AI_MODEL="openrouter/google/gemini-2.0-flash-exp:free"

# ================================================
# set up bash alias

alias c="clear"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
alias clipboard="xsel --clipboard"
alias software-update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias gs="git status"
alias ga="git add -A"
alias gcm="git commit -am"
# alias gcmm='echo "$(cat ~/.config/opencode/command/git-commit.md)" | opencode run -m "openrouter/google/gemini-2.0-flash-exp:free"'
alias gcmm="doppler_run -- git-commit-ai g"
alias gco="git checkout"
alias gp="git push -u"
alias gd="git diff"
alias gl="git log --oneline"
alias gb="git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias git-clean="git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D"
alias tm="tmux new-session -A -s main"
alias tm-reload="tmux source-file ~/.tmux.conf"
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
alias g="gemini"
alias oc="opencode"
alias km="kimi"
alias vb="vibe"
alias qw="qwen"
alias cc="claude"
alias cip="doppler run -p checkinplus -c dev_personal"
alias run="doppler_run"
alias wm="workspace-manager"
alias wms="workspace-manager sync"
alias wme="workspace-manager enable"

# add custom alias for wsl
if is_wsl; then
  alias open="explorer.exe"
  alias explorer="explorer.exe"
fi

# ================================================
# doopler wrapper

# wrap doppler run with our default project and config without loading from server and use local cache only, so we save time starting the process
doppler_run() {
  
  if [[ "$DOPPLER_LOADED" == "true" ]]; then
    # Remove leading -- from arguments if present
    if [[ "$1" == "--" ]]; then
      shift
      "$@"
    else
      echo "Command must be prefixed with -- when DOPPLER_LOADED is true"
      return 1
    fi
  else
    doppler run -p personal -c dev --fallback-readonly --fallback-only --no-liveness-ping --silent "$@"
  fi
}

# force update doppler secrets cache
doppler_update() {
  doppler run -p personal -c dev -- echo "doppler secrets updated"
}

# ================================================
# wrap some frequently used tools with doppler_run

# keep actual path to opencode binary, so we can wrap it with doppler without recursion
OPENCODE_BIN="`which opencode`"

opencode() {
  doppler_run -- $OPENCODE_BIN "$@"
}

KIMI_BIN="`which kimi`"

kimi() {
  doppler_run -- $KIMI_BIN --yolo "$@"
}

VIBE_BIN="`which vibe`"

vibe() {
  doppler_run -- $VIBE_BIN --auto-approve "$@"
}

# ================================================
# tmux alias for open new window in pre-configured view

# Helper function to ensure we're in tmux
in_tmux() {
  if [ -z "$TMUX" ]; then
    # Not in tmux, create a new session and run the function properly
    local cmd_str="${(j: :)${@:q}}"
    # Create session, run the command, and keep session alive
    tmux new-session -s main "zsh -c 'source ~/.zshrc; $cmd_str; exec zsh'"
  else
    # Already in tmux, execute directly
    "$@"
  fi
}

# Helper function to open neovim on left pane and specified command on right pane
_ai_split() {
  local cmd="$1"
  tmux split-window -h -c "$(pwd)" -l 40%
  tmux select-pane -t 0
  tmux send-keys 'v' C-m
  tmux select-pane -t 1
  tmux send-keys "$cmd" C-m
  tmux select-pane -t 0
}

# open nvim on left pane, and opencode on right pane
voc() {
  in_tmux _ai_split "oc"
}

# open nvim on left pane, and kimi on right pane
vkm() {
  in_tmux _ai_split "kimi"
}

# open nvim on left pane, and mistral vibe on right pane
vvb() {
  in_tmux _ai_split "vibe"
}

# ================================================
# make ai ide tools work in wsl

qq() {
  if is_wsl; then
    qoder --remote "wsl+${WSL_DISTRO_NAME}" "$(wslpath -a .)" "$@"
  else
    qoder . "$@"
  fi
}

tt() {
  if is_wsl; then
    trae --remote "wsl+${WSL_DISTRO_NAME}" "$(wslpath -a .)" "$@"
  else
    trae . "$@"
  fi
}

aa() {
  if is_wsl; then
    antigravity --remote "wsl+${WSL_DISTRO_NAME}" "$(wslpath -a .)" "$@"
  else
    antigravity . "$@"
  fi
}

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
# zoxide should be installed via github release
# $ wget https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.8/zoxide_0.9.8-1_amd64.deb
# $ sudo apt install zoxide_0.9.8-1_amd64.deb
# $ rm zoxide_0.9.8-1_amd64.deb
#
# fzf latest should be installed as well
# $ cd ~/.local/bin
# $ wget https://github.com/junegunn/fzf/releases/download/v0.66.0/fzf-0.66.0-linux_amd64.tar.gz
# $ tar zxf fzf-0.66.0-linux_amd64.tar.gz
# $ rm fzf-0.66.0-linux_amd64.tar.gz



if which zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi

# ================================================
# set task shell integration

if which task > /dev/null; then
  eval "$(task --completion zsh)"
fi

# ================================================
# set workspace-manager shell integration (powered by cliffy)

if which workspace-manager > /dev/null; then
  eval "$(workspace-manager completions zsh)"
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


# Added by Antigravity
if [ -d "$SUDO_HOME/.antigravity/antigravity/bin" ] ; then
  export PATH="$SUDO_HOME/.antigravity/antigravity/bin:$PATH"
fi
