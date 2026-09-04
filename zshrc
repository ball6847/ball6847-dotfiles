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
plugins=(zsh-autosuggestions ansible kubectl helm asdf z golang)

# the zsh-completions.plugin.zsh seems not working
# so, we manually add plugin to $fpath to enable completions the plugin provides
fpath=($ZSH_CUSTOM/plugins/zsh-completions/src $fpath)
#fpath=($DOTFILES/desk/shell_plugins/zsh $fpath)

# grok completions (must be before compinit)
if [ -x "$HOME/.grok/bin/grok" ]; then
  fpath=(~/.grok/completions/zsh $fpath)
fi

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
# detect termux

is_termux() {
    if [ -d "/data/data/com.termux/files" ]; then
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
export COLORTERM=truecolor
export WINEARCH=win32
export WINEPREFIX=$SUDO_HOME/.wine
export DELTA_PAGER="less -R"
export LESS='--mouse --wheel-lines=3'
export PI_LENS_FORMAT_ENABLED=false
export PI_STYLED_OUTPUTS_DISABLED=1
export PATH="/opt/homebrew/bin:/usr/local/bin:$SUDO_HOME/.dotfiles/bin:$SUDO_HOME/.local/bin:$ASDF_DATA_DIR/shims:$ASDF_RUST_DIR/bin:$SUDO_HOME/.composer/vendor/bin:$SUDO_HOME/.config/composer/vendor/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin:/mnt/c/Users/ball6/AppData/Local/Programs/Microsoft VS Code/bin:/snap/bin:$SUDO_HOME/.exo/bin:$SUDO_HOME/.opencode/bin:$SUDO_HOME/.bun/bin:$SUDO_HOME/.kimi-code/bin:$PATH"
export TMUX_VERSION=$(tmux -V | grep -o '[0-9]\+\.[0-9]\+' | head -1)
# export GIT_COMMIT_AI_MODEL="ollama-cloud/devstral-small-2:24b"

# Set up PATH for Termux if we're in a Termux session
if is_termux; then
  export PATH="/data/data/com.termux/files/bin:/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/home/.cargo/bin:$PATH"
fi

export WM_CONCURRENCY=16

# =========================================================================
# General aliases
# =========================================================================
# alphabetical
alias c="clear"
alias chmodfix='sudo find -type d -print0 | xargs -0 -I {} chmod 755 {} && sudo find -type f -print0 | xargs -0 -I {} chmod 644 {}'
alias clipboard="xsel --clipboard"
alias gen-cert="openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem"
alias gen-prettier="cp ~/.dotfiles/prettierrc .prettierrc"
alias m="SERVE_MD_DOT_WHITELIST=.agents,.context,.pi serve-md serve --network --watch"
alias software-update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
alias t="task"
alias v="nvim"
alias w="wtp"
alias wsl2-reclaim="sudo sh -c \"echo 1 > /proc/sys/vm/drop_caches; echo 1 > /proc/sys/vm/compact_memory\""

# =========================================================================
# WSL-specific (conditional)
# =========================================================================
# add custom alias for wsl
if is_wsl; then
  alias open="explorer.exe"
  alias explorer="explorer.exe"
fi

# =========================================================================
# Optional tooling (conditional)
# =========================================================================
# fall back to batcat if the binary is installed under that name
if command -v batcat >/dev/null 2>&1; then
  alias bat="batcat"
fi

# =========================================================================
# Git aliases
# =========================================================================
# alphabetical
alias ga="git add -A"
alias gan="git add -N"
alias gb="git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias gcm="git commit -am"
alias gcmm="git-commit-ai g --thinking-effort low"
alias gco="git checkout"
alias gd="git diff"
alias gdd="git diff --cached"
alias git-clean="git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D"
alias gl="git log --oneline"
alias gp="git push -u"
alias gs="git status"

# =========================================================================
# Docker aliases
# =========================================================================
# alphabetical
alias dc="docker compose"
alias dcl="docker compose logs -f"
alias dcx="docker compose exec"

# =========================================================================
# Tmux aliases
# =========================================================================
# alphabetical
alias tm-reload="tmux source-file ~/.tmux.conf"

# =========================================================================
# start or attach to a tmux session (default name "main")
# =========================================================================
tm() {
  local session_name="main"
  if [[ -n "$1" ]]; then
    session_name="$1"
  fi
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session_name" 2>/dev/null || tmux new-session -d -s "$session_name" \; switch-client -t "$session_name"
  else
    tmux new-session -A -s "$session_name"
  fi
}

# =========================================================================
# AI tools aliases
# =========================================================================

# helper functions for the split-pane aliases below
# attach to a session (or start one) then run the command inside tmux
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

# open nvim on the left pane and a command on the right pane
_ai_split() {
  local cmd="$1"
  tmux split-window -h -c "$(pwd)" -l 40%
  tmux select-pane -t 0
  tmux send-keys 'v' C-m
  tmux select-pane -t 1
  tmux send-keys "$cmd" C-m
  tmux select-pane -t 0
}

# split-pane helpers: nvim left + AI tool right (run inside tmux)
alias voc='in_tmux _ai_split "oc"'
alias vqw='in_tmux _ai_split "qw"'
alias vg='in_tmux _ai_split "g"'
alias vcc='in_tmux _ai_split "cc"'

# =========================================================================
# model aliases
# =========================================================================
# alphabetical
alias cc="claude"
alias claude='claude --allow-dangerously-skip-permissions'
alias g="gemini -y"
alias gr="grok --always-approve"
alias km="kimi --yolo"
alias muse="muse --yolo"
alias oc="opencode"
alias p="pi"
alias pa="prime-agent"
alias qodercli='qodercli --yolo'
alias qw="qwen --yolo"
alias vb="vibe --agent auto-approve"

# =========================================================================
# Workspace / project tool aliases
# =========================================================================
# alphabetical
alias ap="ansible-playbook"
alias cip="doppler run -p checkinplus -c dev_personal"
alias direnv-init-node="(echo \"layout node\" > .envrc) && direnv allow"
alias direnv-init-python="(echo \"layout python\" > .envrc) && direnv allow"
alias wm="workspace-manager"
alias wme="workspace-manager enable"
alias wmo="workspace-manager open"
alias wms="workspace-manager sync"

# =========================================================================
# Tailscale helpers
# =========================================================================
# Run kimi web with auto-detected tailscale hostname
kmw() {
  local tailscale_ip hostname auth_token port
  tailscale_ip=$(ts_ip) || return 1
  hostname=$(ts_fqdn) || return 1

  # Generate random token
  auth_token=$(openssl rand -hex 32)
  port=${KM_PORT:-5494}

  echo "================================================"
  echo "Kimi Web URL:"
  echo "http://$hostname:$port/?token=$auth_token"
  echo "================================================"

  kimi web --host "$tailscale_ip" --port "$port" --no-open --public --auth-token "$auth_token" --allowed-origins "http://$hostname:$port,https://$hostname:$port" --no-restrict-sensitive-apis "$@"
}


# Resolve the tailscale CLI: prefer $PATH, fall back to the macOS app bundle
ts_bin() {
  command -v tailscale || echo /Applications/Tailscale.app/Contents/MacOS/tailscale
}

# Print the tailscale short hostname (e.g. porawits-macbook-pro)
# First label of the MagicDNS name: porawits-macbook-pro.tail3baa84.ts.net. -> porawits-macbook-pro
ts_hostname() {
  local hostname
  hostname=$($(ts_bin) status --json 2>/dev/null | jq -r '.Self.DNSName // empty' | cut -d. -f1)

  if [ -z "$hostname" ]; then
    echo "Error: Could not detect Tailscale short hostname. Is tailscale running?" >&2
    return 1
  fi

  echo "$hostname"
}

# Print the tailscale full MagicDNS name without trailing dot (e.g. porawits-macbook-pro.tail3baa84.ts.net)
ts_fqdn() {
  local fqdn
  fqdn=$($(ts_bin) status --json 2>/dev/null | jq -r '.Self.DNSName // empty' | sed 's/\.$//')

  if [ -z "$fqdn" ]; then
    echo "Error: Could not detect Tailscale hostname. Is tailscale running?" >&2
    return 1
  fi

  echo "$fqdn"
}

# Print the tailscale IPv4 address (e.g. 100.x.x.x)
ts_ip() {
  local ip
  ip=$($(ts_bin) status --json 2>/dev/null | jq -r '.TailscaleIPs[0] // empty')

  if [ -z "$ip" ]; then
    echo "Error: Could not detect Tailscale IP. Is tailscale running?" >&2
    return 1
  fi

  echo "$ip"
}

# Start pi-web bound to all interfaces, auto-detecting the tailscale short hostname
# so the web UI is reachable at http://<tailscale-hostname>:9999
pw() {
  local hostname
  if hostname=$(ts_hostname 2>/dev/null); then
    echo "================================================"
    echo "pi-web URL:"
    echo "http://$hostname:9999"
    echo "================================================"
    PI_WEB_ALLOWED_HOSTS="$hostname" pi-web -p 9999 -H 0.0.0.0 "$@"
  else
    echo "Warning: Tailscale is not running. Falling back to 0.0.0.0" >&2
    echo "================================================"
    echo "pi-web URL:"
    echo "http://0.0.0.0:9999"
    echo "================================================"
    pi-web -p 9999 -H 0.0.0.0 "$@"
  fi
}

# asdf bin linker as some IDE lsp doesn't work with asdf shims

asdf_link_bin() {
  local plugin="$1"
  local bin_path=`asdf which $plugin`
  if [ -f "$bin_path" ]; then
    ln -sfn "$bin_path" "$SUDO_HOME/.local/bin/$plugin"
  fi
}

# TODO: even linking to .local/bin doesn't work for deno, need deno.path configured in vscode's settings.json for now
# asdf_link_bin deno

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
# fzf is required for interactive selection (zi) and tab completions.
# Minimum fzf version required by zoxide: v0.51.0
# https://github.com/ajeetdsouza/zoxide#3-install-fzf-optional
# $ cd ~/.local/bin
# $ wget https://github.com/junegunn/fzf/releases/download/v0.51.0/fzf-0.51.0-linux_amd64.tar.gz
# $ tar zxf fzf-0.51.0-linux_amd64.tar.gz
# $ rm fzf-0.51.0-linux_amd64.tar.gz



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

if asdf which workspace-manager > /dev/null 2>&1; then
  eval "$(workspace-manager completions zsh)"
fi

# ================================================
# set wtp shell integration

if asdf which wtp > /dev/null 2>&1; then
  eval "$(wtp completion zsh)"
  eval "$(wtp hook zsh)"
fi

# ================================================
# Allow parent to initialize shell
#
# This is awesome for opening terminals in VSCode.

if [[ -n $ZSH_INIT_COMMAND ]]; then
    echo "Running: $ZSH_INIT_COMMAND"
    eval "$ZSH_INIT_COMMAND"
fi

# >>> grok installer >>>
if [ -x "$HOME/.grok/bin/grok" ]; then
  export PATH="$HOME/.grok/bin:$PATH"
fi
# <<< grok installer <<<

# QODER_DISPATCHER_PATH v1
path=("$HOME/.qoder/entry" ${path:#"$HOME/.qoder/entry"})
export PATH
# END QODER_DISPATCHER_PATH v1
