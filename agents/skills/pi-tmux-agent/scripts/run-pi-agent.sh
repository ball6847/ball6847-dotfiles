#!/usr/bin/env bash
# run-pi-agent.sh — spawn a pi agent in a tmux pane, run one prompt to
# completion, print its output, and clean up. One call owns the full lifecycle:
#
#   1. pick best split target/direction
#   2. create pane and start pi
#   3. wait for pi to finish (process exit)
#   4. print captured output on stdout
#   5. kill the pane (unless --keep-pane)
#
# Usage:
#   run-pi-agent.sh [options] <prompt>
#   run-pi-agent.sh [options] -              # read prompt from stdin
#   echo "prompt" | run-pi-agent.sh [options]
#
# Options:
#   -t, --timeout SECS   Max seconds to wait for completion (default: 3600)
#   -k, --keep-pane      Leave the pane open after completion
#   -C, --cwd DIR        Working directory for pi (default: caller cwd)
#   --pi PATH            pi binary (default: $PI_BIN, else pi on PATH, else ~/.bun/bin/pi)
#   -v, --verbose        Progress messages on stderr
#   -h, --help           Show this help
#
# Environment:
#   MIN_WIDTH / MIN_HEIGHT   Minimum new-pane size for split selection (80 / 20)
#   PI_BIN                   Override pi binary path
#   PI_ARGS                  Extra arguments inserted before the prompt
#                            (e.g. PI_ARGS='--model foo --thinking low')
#
# Exit codes:
#   0    pi succeeded
#   1    usage / setup error (no tmux, terminal too small, pi missing, …)
#   124  timed out waiting for pi
#   other  pi's own exit code
#
# Stdout: pi's full output (via tee log — not tmux chrome)
# Stderr: progress / diagnostics (only with -v, plus always-on errors)

set -euo pipefail

TIMEOUT="${TIMEOUT:-3600}"
KEEP_PANE=0
VERBOSE=0
CWD="$(pwd)"
PI_BIN="${PI_BIN:-}"
PROMPT=""

# Filled by pick_split
PICK_TARGET=""
PICK_DIR=""

usage() {
  sed -n '2,35p' "$0" | sed 's/^# \?//'
}

log() {
  if (( VERBOSE )); then
    printf 'run-pi-agent: %s\n' "$*" >&2
  fi
}

die() {
  printf 'run-pi-agent: %s\n' "$*" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# pick_split — choose the best pane to split and the direction, maximizing
# the new pane's usable space. (Inlined from the former pick-split.sh.)
#
# A new tmux pane is always created by splitting an existing one, so the
# decision has two parts: which pane to split, and whether to split it
# horizontally (-h, side-by-side) or vertically (-v, stacked). Evaluates every
# pane in the current window for both directions and picks the combination
# that yields the largest *usable* new pane.
#
# "Usable" accounts for:
#   1. Minimums — a pi pane needs ~MIN_WIDTH cols / ~MIN_HEIGHT rows.
#   2. Aspect ratio — cells are ~2x taller than wide, so balance is
#      width ≈ 2 × height. Score = min(width, 2*height).
#
# Sets: PICK_TARGET (pane id), PICK_DIR (h|v)
# Exits 1 if no split satisfies the minimums.
# ---------------------------------------------------------------------------
pick_split() {
  local MIN_WIDTH="${MIN_WIDTH:-80}"
  local MIN_HEIGHT="${MIN_HEIGHT:-20}"

  local best_pane="" best_dir="" best_score=0 best_nw=0 best_nh=0
  local pane_id w h nw nh score

  while read -r pane_id w h; do
    # Horizontal split (side-by-side). New pane ~ (w/2) x h.
    nw=$((w / 2))
    if (( nw >= MIN_WIDTH )); then
      score=$(( nw < 2 * h ? nw : 2 * h ))
      if (( score > best_score )); then
        best_score=$score
        best_pane=$pane_id
        best_dir="h"
        best_nw=$nw
        best_nh=$h
      fi
    fi

    # Vertical split (stacked). New pane ~ w x (h/2).
    nh=$((h / 2))
    if (( nh >= MIN_HEIGHT )); then
      score=$(( w < 2 * nh ? w : 2 * nh ))
      if (( score > best_score )); then
        best_score=$score
        best_pane=$pane_id
        best_dir="v"
        best_nw=$w
        best_nh=$nh
      fi
    fi
  done < <(tmux list-panes -F "#{pane_id} #{pane_width} #{pane_height}")

  if [[ -z "$best_pane" ]]; then
    echo "pick_split: terminal too small — no pane can be split while keeping" >&2
    echo "the new pane at least ${MIN_WIDTH} cols or ${MIN_HEIGHT} rows." >&2
    echo "Maximize the terminal window, or override MIN_WIDTH/MIN_HEIGHT." >&2
    return 1
  fi

  if [[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]]; then
    echo "pick_split: note — the window is currently zoomed; splitting will unzoom it" >&2
  fi

  local kind
  kind=$([[ "$best_dir" == "h" ]] && echo "horizontally (side-by-side)" || echo "vertically (stacked)")
  echo "pick_split: splitting $best_pane $kind -> new pane ~${best_nw}x${best_nh}" >&2

  PICK_TARGET=$best_pane
  PICK_DIR=$best_dir
}

resolve_pi_bin() {
  if [[ -n "$PI_BIN" ]]; then
    [[ -x "$PI_BIN" ]] || die "PI_BIN is not executable: $PI_BIN"
    return
  fi
  if command -v pi >/dev/null 2>&1; then
    PI_BIN=$(command -v pi)
    return
  fi
  if [[ -x "${HOME}/.bun/bin/pi" ]]; then
    PI_BIN="${HOME}/.bun/bin/pi"
    return
  fi
  die "pi not found in PATH or ~/.bun/bin/pi — install pi or pass --pi PATH"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--timeout)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      TIMEOUT=$2
      shift 2
      ;;
    -k|--keep-pane)
      KEEP_PANE=1
      shift
      ;;
    -C|--cwd)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      CWD=$2
      shift 2
      ;;
    --pi)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      PI_BIN=$2
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -)
      PROMPT=$(cat)
      shift
      break
      ;;
    -*)
      die "unknown option: $1 (try --help)"
      ;;
    *)
      PROMPT=$1
      shift
      break
      ;;
  esac
done

# Leftover args after prompt are not accepted (prompt is a single argument;
# use stdin for multi-word without quoting issues, or quote the whole prompt).
if [[ $# -gt 0 ]]; then
  die "unexpected arguments after prompt: $* (quote the full prompt as one argument)"
fi

# Prompt from stdin if none given and stdin is not a tty
if [[ -z "$PROMPT" ]]; then
  if [[ ! -t 0 ]]; then
    PROMPT=$(cat)
  else
    die "missing prompt — pass as argument, as '-', or via stdin"
  fi
fi

[[ -n "$PROMPT" ]] || die "prompt is empty"
[[ -d "$CWD" ]] || die "cwd does not exist: $CWD"
[[ -n "${TMUX:-}" ]] || die "not inside a tmux session — start tmux first"
command -v tmux >/dev/null 2>&1 || die "tmux not found in PATH"

# Validate timeout is a positive integer
[[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]] || die "timeout must be a positive integer (got: $TIMEOUT)"

resolve_pi_bin
log "using pi binary: $PI_BIN"
log "cwd: $CWD"
log "timeout: ${TIMEOUT}s"

pick_split || exit 1
log "split target=$PICK_TARGET dir=$PICK_DIR"

# Workspace for runner + result plumbing
WORK=$(mktemp -d "${TMPDIR:-/tmp}/run-pi-agent.XXXXXX")
PROMPT_FILE="$WORK/prompt.txt"
LOG_FILE="$WORK/output.log"
STATUS_FILE="$WORK/status"
RUNNER="$WORK/runner.sh"
PANE_ID=""

printf '%s' "$PROMPT" >"$PROMPT_FILE"

# NOTE: $? must be captured as the very first word of the trap action.
# Any prior command (including `local`) resets $? to 0 in bash.
cleanup() {
  local ec=$1
  if [[ -n "${PANE_ID:-}" ]] && (( ! KEEP_PANE )); then
    tmux kill-pane -t "$PANE_ID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
  # Re-exit so the caller's $? matches the original status.
  exit "$ec"
}
trap 'cleanup $?' EXIT

# Build an in-pane runner. Using a file avoids quoting hell for multi-line
# prompts and keeps the lifecycle (run → signal done → stay open) explicit.
#
# pi --print (-p) runs non-interactively and exits when the turn is done, so
# completion is process-exit based rather than fragile TUI scraping / send-keys.
{
  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' 'set -euo pipefail'
  printf 'cd %q || exit 1\n' "$CWD"
  # Keep the pane alive after pi exits so the user can still read output
  # until the outer script kills it (remain-on-exit is window-scoped).
  printf '%s\n' 'tmux set-option -t "${TMUX_PANE}" -w remain-on-exit on 2>/dev/null || true'
  printf '%s\n' 'set +e'
  printf '%s\n' 'set -o pipefail'
  # Build argv: pi -p [PI_ARGS...] -- <prompt>
  # PI_ARGS is intentionally word-split (see env docs).
  printf 'pi_cmd=( %q -p )\n' "$PI_BIN"
  if [[ -n "${PI_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    printf 'pi_cmd+=( %s )\n' "$PI_ARGS"
  fi
  printf 'pi_cmd+=( -- "$(cat %q)" )\n' "$PROMPT_FILE"
  printf '"${pi_cmd[@]}" 2>&1 | tee %q\n' "$LOG_FILE"
  printf '%s\n' 'ec=${PIPESTATUS[0]}'
  printf 'printf "%%s\\n" "$ec" > %q\n' "$STATUS_FILE"
  printf '%s\n' 'set -e'
  # Hold the pane open until the outer script cleans up.
  printf '%s\n' 'exec sleep infinity'
} >"$RUNNER"
chmod +x "$RUNNER"

log "spawning pane…"
PANE_ID=$(tmux split-window -"$PICK_DIR" -t "$PICK_TARGET" -P -F '#{pane_id}' \
  "bash $(printf %q "$RUNNER")")
log "pane id: $PANE_ID"

# Raise scrollback so long runs stay capturable if someone inspects the pane
tmux set-option -t "$PANE_ID" -p history-limit 50000 2>/dev/null || true

# Poll until the runner writes the status file (pi exited) or we time out.
log "waiting for pi to finish (timeout ${TIMEOUT}s)…"
deadline=$((SECONDS + TIMEOUT))
while [[ ! -f "$STATUS_FILE" ]]; do
  if (( SECONDS >= deadline )); then
    printf 'run-pi-agent: timed out after %ss waiting for pi in pane %s\n' \
      "$TIMEOUT" "$PANE_ID" >&2
    # Best-effort partial output on timeout
    if [[ -f "$LOG_FILE" ]]; then
      cat "$LOG_FILE"
    fi
    exit 124
  fi
  # Pane vanished without writing status (e.g. user killed it)
  if ! tmux list-panes -F '#{pane_id}' 2>/dev/null | grep -Fxq "$PANE_ID"; then
    die "pane $PANE_ID disappeared before pi finished"
  fi
  sleep 0.5
done

pi_ec=$(cat "$STATUS_FILE" 2>/dev/null || echo 1)
log "pi exited with code $pi_ec"

if [[ -f "$LOG_FILE" ]]; then
  cat "$LOG_FILE"
else
  # Fallback: scrape the pane if tee never wrote the log
  log "log file missing — falling back to capture-pane"
  tmux capture-pane -t "$PANE_ID" -p -S - 2>/dev/null || true
fi

# Trap handles pane kill + workdir removal; propagate pi's exit code.
exit "$pi_ec"
