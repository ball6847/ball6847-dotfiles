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
alias x="docker compose exec"

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
    local cmd_str
    cmd_str="$(printf '%q ' "$@")"
    # Create session, run the command, and keep session alive
    tmux new-session -s main "bash -c 'source ~/.bashrc; $cmd_str; exec bash'"
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
