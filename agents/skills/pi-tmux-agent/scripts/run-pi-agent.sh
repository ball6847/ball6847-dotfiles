#!/usr/bin/env bash
# run-pi-agent.sh — spawn a pi agent in a tmux pane (full interactive TUI),
# wait for a hard completion contract, return the final answer to the caller,
# and clean up. One call owns the full lifecycle:
#
#   1. pick best split target/direction
#   2. generate --session-id and start pi in visual (interactive) mode
#   3. poll the session JSONL until the completion contract is met
#   4. print the final assistant text (contract tag stripped) on stdout
#   5. kill the pane (unless --keep-pane)
#
# Completion contract (assertable from the final message):
#   The last assistant message must contain EXACTLY this tag (unique per run):
#
#     <done>SESSION_ID</done>
#
#   Example: <done>0696e329-412b-47c4-a091-c7c4c21aabf7</done>
#   stopReason alone is NOT enough — without the tag the turn is incomplete.
#   The script appends this contract to the user prompt automatically.
#
# Usage:
#   run-pi-agent.sh [options] <prompt>
#   run-pi-agent.sh [options] -              # read prompt from stdin
#   echo "prompt" | run-pi-agent.sh [options]
#
# Options:
#   -t, --timeout SECS     Max seconds to wait for completion (default: 3600)
#   -k, --keep-pane        Leave the pane open after completion
#   -C, --cwd DIR          Working directory for pi (default: caller cwd)
#   --session-id ID        Use this session id (default: generated UUID)
#   --pi PATH              pi binary (default: $PI_BIN, else pi on PATH, else ~/.bun/bin/pi)
#   -v, --verbose          Progress messages on stderr
#   -h, --help             Show this help
#
# Environment:
#   MIN_WIDTH / MIN_HEIGHT   Minimum new-pane size for split selection (80 / 20)
#   PI_BIN                   Override pi binary path
#   PI_ARGS                  Extra arguments inserted before the prompt
#                            (e.g. PI_ARGS='--model foo --thinking low')
#   PI_CODING_AGENT_DIR      Pi agent config dir (default: ~/.pi/agent)
#   PI_CODING_AGENT_SESSION_DIR  Override session storage directory
#
# Exit codes:
#   0    contract satisfied, or user confirmed job-done after an interrupt
#   1    setup error, user said job not done, or finished without contract (no interrupt path)
#   124  timed out waiting for the contract
#   125  interrupted — caller MUST ask the human user whether the job is done
#        (non-interactive mode; message includes NEEDS_USER_CONFIRM)
#
# Stdout: final assistant text with the <done>…</done> tag stripped
# Stderr: progress / diagnostics (errors always; progress with -v)
#
# Visibility: runs interactive pi (not -p) so the pane shows the full TUI.
# Result extraction uses ~/.pi/agent/sessions/.../*_<session-id>.jsonl

set -euo pipefail

TIMEOUT="${TIMEOUT:-3600}"
KEEP_PANE=0
VERBOSE=0
CWD="$(pwd)"
PI_BIN="${PI_BIN:-}"
SESSION_ID="${SESSION_ID:-}"
PROMPT=""

# Filled by pick_split
PICK_TARGET=""
PICK_DIR=""

usage() {
  sed -n '2,45p' "$0" | sed 's/^# \?//'
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
# Sets: PICK_TARGET (pane id), PICK_DIR (h|v)
# ---------------------------------------------------------------------------
pick_split() {
  local MIN_WIDTH="${MIN_WIDTH:-80}"
  local MIN_HEIGHT="${MIN_HEIGHT:-20}"

  local best_pane="" best_dir="" best_score=0 best_nw=0 best_nh=0
  local pane_id w h nw nh score

  while read -r pane_id w h; do
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

gen_session_id() {
  if [[ -n "$SESSION_ID" ]]; then
    return
  fi
  if command -v uuidgen >/dev/null 2>&1; then
    SESSION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  elif command -v python3 >/dev/null 2>&1; then
    SESSION_ID=$(python3 -c 'import uuid; print(uuid.uuid4())')
  else
    # Fallback: alphanumeric timestamp + random (valid per pi's session-id rules)
    SESSION_ID="run$(date +%s)$RANDOM"
  fi
}

# Mirror pi's default session directory encoding for a cwd.
session_dir_for_cwd() {
  local cwd_resolved agent_dir stripped
  if [[ -n "${PI_CODING_AGENT_SESSION_DIR:-}" ]]; then
    printf '%s\n' "$PI_CODING_AGENT_SESSION_DIR"
    return
  fi
  cwd_resolved=$(cd "$1" && pwd -P)
  agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
  stripped="${cwd_resolved#/}"
  stripped="${stripped//\//-}"
  stripped="${stripped//\\/-}"
  stripped="${stripped//:/-}"
  printf '%s\n' "${agent_dir}/sessions/--${stripped}--"
}

find_session_file() {
  local dir="$1" sid="$2"
  local f
  # Filename pattern: <timestamp>_<session-id>.jsonl
  shopt -s nullglob
  for f in "$dir"/*_"${sid}".jsonl; do
    printf '%s\n' "$f"
    shopt -u nullglob
    return 0
  done
  shopt -u nullglob
  return 1
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
    --session-id)
      [[ $# -ge 2 ]] || die "$1 requires a value"
      SESSION_ID=$2
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

if [[ $# -gt 0 ]]; then
  die "unexpected arguments after prompt: $* (quote the full prompt as one argument)"
fi

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
command -v python3 >/dev/null 2>&1 || die "python3 is required to read the session log"

[[ "$TIMEOUT" =~ ^[1-9][0-9]*$ ]] || die "timeout must be a positive integer (got: $TIMEOUT)"

# Session ids must be alphanumeric with optional ._- in the middle (pi validates this)
if [[ -n "$SESSION_ID" ]] && [[ ! "$SESSION_ID" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
  die "invalid --session-id (use alphanumeric, '-', '_', '.'; start/end alphanumeric)"
fi

resolve_pi_bin
gen_session_id
SESSION_DIR=$(session_dir_for_cwd "$CWD")

log "using pi binary: $PI_BIN"
log "cwd: $CWD"
log "session-id: $SESSION_ID"
log "session-dir: $SESSION_DIR"
log "timeout: ${TIMEOUT}s"

pick_split || exit 1
log "split target=$PICK_TARGET dir=$PICK_DIR"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/run-pi-agent.XXXXXX")
PROMPT_FILE="$WORK/prompt.txt"
RUNNER="$WORK/runner.sh"
SESSION_HELPER="$WORK/session_helper.py"
PANE_ID=""
SESSION_FILE=""

# Hard completion contract — unique per run via session-id.
DONE_TAG="<done>${SESSION_ID}</done>"
log "done-tag: $DONE_TAG"

# User prompt + mandatory contract appendix (appended by this script, not the caller).
{
  printf '%s\n' "$PROMPT"
  printf '\n'
  printf '%s\n' '---'
  printf '%s\n' 'COMPLETION CONTRACT (mandatory — enforced by the orchestrator):'
  printf '%s\n' 'When you have fully finished the user request WITHOUT any interrupt, your FINAL assistant message MUST contain this exact tag on its own line:'
  printf '\n'
  printf '%s\n' "$DONE_TAG"
  printf '\n'
  printf '%s\n' 'Rules:'
  printf '%s\n' "- Copy the tag EXACTLY (including the session id). Do not invent a different id."
  printf '%s\n' "- Emit the tag only once, only in the final message, only when work is complete."
  printf '%s\n' "- Do not emit the tag mid-task or while you still plan to call tools."
  printf '%s\n' "- Put any summary/answer before the tag; the tag should be the last non-empty line."
  printf '\n'
  printf '%s\n' 'INTERRUPT RULES (mandatory):'
  printf '%s\n' "- If this session was interrupted, aborted, cancelled, or the pane/process was killed mid-work, you MUST NOT simply answer the original question and print the completion tag."
  printf '%s\n' "- After ANY interrupt, always ask the human user to confirm whether the job for this session is done, e.g.:"
  printf '%s\n' '  "This session was interrupted. Is the job done for this session? (yes/no)"'
  printf '%s\n' "- Wait for the user's explicit confirmation in this session."
  printf '%s\n' "- Only if the user clearly confirms YES may you then emit the completion tag."
  printf '%s\n' "- If the user says NO (or is unsure), do NOT emit the tag; summarize remaining work instead."
} >"$PROMPT_FILE"

# Session JSONL helper: status|extract <session.jsonl> <session-id>
cat >"$SESSION_HELPER" <<'PY'
#!/usr/bin/env python3
"""Read pi session JSONL; completion requires <done>{session-id}</done> in the final message."""
from __future__ import annotations

import json
import re
import sys


def load_messages(path: str) -> list[dict]:
    msgs: list[dict] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") != "message":
                continue
            msg = obj.get("message")
            if isinstance(msg, dict):
                msgs.append(msg)
    return msgs


def extract_text(msg: dict) -> str:
    content = msg.get("content")
    if isinstance(content, str):
        text = content
    else:
        parts: list[str] = []
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    parts.append(block.get("text") or "")
        text = "\n".join(parts)
    return text


def done_tag(session_id: str) -> str:
    return f"<done>{session_id}</done>"


def has_done_tag(text: str, session_id: str) -> bool:
    return done_tag(session_id) in text


def strip_done_tag(text: str, session_id: str) -> str:
    tag = done_tag(session_id)
    # Remove the exact tag and tidy surrounding blank lines.
    cleaned = text.replace(tag, "")
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)
    cleaned = cleaned.rstrip() + ("\n" if cleaned.strip() else "")
    return cleaned


def session_was_interrupted(msgs: list[dict]) -> bool:
    """True if any assistant turn was aborted/errored (interrupt in this session)."""
    for msg in msgs:
        if msg.get("role") == "assistant" and msg.get("stopReason") in (
            "error",
            "aborted",
        ):
            return True
    return False


def last_assistant_text(msgs: list[dict]) -> str:
    for msg in reversed(msgs):
        if msg.get("role") == "assistant":
            return extract_text(msg)
    return ""


def status(path: str, session_id: str) -> str:
    """
    pending         — no session / no messages yet
    running         — tools in flight or still generating
    done            — contract tag present AND no interrupt in session history
    needs_confirm   — interrupted (abort/error), or tag present only after interrupt
    incomplete      — model stopped (stop/length) without tag (not an interrupt)
    """
    try:
        msgs = load_messages(path)
    except FileNotFoundError:
        return "pending"
    if not msgs:
        return "pending"

    interrupted = session_was_interrupted(msgs)
    last = msgs[-1]
    role = last.get("role")
    text = extract_text(last) if role == "assistant" else ""
    stop = last.get("stopReason") if role == "assistant" else None

    # After any interrupt in this session, never auto-success — even if the
    # model later prints the done tag. Human must confirm job-done.
    if interrupted:
        if role != "assistant":
            return "running"
        if stop == "toolUse":
            return "running"
        # Idle after interrupt (stop/length/error/aborted) or tag present → confirm
        if stop in ("stop", "length", "error", "aborted") or has_done_tag(
            text, session_id
        ):
            return "needs_confirm"
        return "running"

    # Clean path (never interrupted this session)
    if role != "assistant":
        return "running"
    if has_done_tag(text, session_id):
        return "done"
    if stop in ("error", "aborted"):
        return "needs_confirm"
    if stop in ("stop", "length"):
        return "incomplete"
    return "running"


def extract(path: str, session_id: str, mode: str = "strict") -> tuple[str, int]:
    """
    strict  — only succeed when done tag is present
    last    — last assistant text (for user-confirmed-after-interrupt)
    """
    msgs = load_messages(path)
    if mode == "last":
        text = last_assistant_text(msgs)
        if not text:
            return (
                f"run-pi-agent: no assistant message found (session-id={session_id})\n",
                2,
            )
        return strip_done_tag(text, session_id), 0

    for msg in reversed(msgs):
        if msg.get("role") != "assistant":
            continue
        text = extract_text(msg)
        if has_done_tag(text, session_id):
            return strip_done_tag(text, session_id), 0
        stop = msg.get("stopReason")
        if stop in ("error", "aborted"):
            err = msg.get("errorMessage") or f"turn {stop} (no {done_tag(session_id)})"
            return (err if str(err).endswith("\n") else str(err) + "\n"), 1
        if stop in ("stop", "length"):
            body = text.rstrip() + "\n" if text.strip() else ""
            note = f"run-pi-agent: incomplete — final message missing {done_tag(session_id)}\n"
            return body + note, 1
    return f"run-pi-agent: no assistant message found (expected {done_tag(session_id)})\n", 2


def main() -> int:
    if len(sys.argv) not in (4, 5):
        print(
            "usage: session_helper.py status|extract|extract-last "
            "<session.jsonl> <session-id>",
            file=sys.stderr,
        )
        return 2
    cmd, path, session_id = sys.argv[1], sys.argv[2], sys.argv[3]
    if cmd == "status":
        print(status(path, session_id))
        return 0
    if cmd == "extract":
        text, code = extract(path, session_id, mode="strict")
        sys.stdout.write(text)
        return code
    if cmd == "extract-last":
        text, code = extract(path, session_id, mode="last")
        sys.stdout.write(text)
        return code
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x "$SESSION_HELPER"

cleanup() {
  local ec=$1
  if [[ -n "${PANE_ID:-}" ]] && (( ! KEEP_PANE )); then
    tmux kill-pane -t "$PANE_ID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
  exit "$ec"
}
trap 'cleanup $?' EXIT

# Interactive (visual) pi — no -p. Full TUI in the pane; completion via session log.
{
  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' 'set -euo pipefail'
  printf 'cd %q || exit 1\n' "$CWD"
  printf 'pi_cmd=( %q --session-id %q --name %q )\n' \
    "$PI_BIN" "$SESSION_ID" "run-pi-agent"
  if [[ -n "${PI_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    printf 'pi_cmd+=( %s )\n' "$PI_ARGS"
  fi
  # Initial user message = the prompt; pi processes it immediately in the TUI.
  # Note: pi does not accept a bare "--" argv terminator (it treats it as Unknown option).
  printf 'pi_cmd+=( "$(cat %q)" )\n' "$PROMPT_FILE"
  printf 'exec "${pi_cmd[@]}"\n'
} >"$RUNNER"
chmod +x "$RUNNER"

log "spawning pane (interactive pi)…"
PANE_ID=$(tmux split-window -"$PICK_DIR" -t "$PICK_TARGET" -P -F '#{pane_id}' \
  "bash $(printf %q "$RUNNER")")
log "pane id: $PANE_ID"

tmux set-option -t "$PANE_ID" -p history-limit 50000 2>/dev/null || true

# Ask the human whether the job is done after an interrupt.
# Interactive (TTY): prompt on /dev/tty.
# Non-interactive (agent caller): exit 125 with NEEDS_USER_CONFIRM so the
# caller asks the user and can re-invoke policy accordingly.
ask_user_job_done() {
  local reason=$1
  printf 'run-pi-agent: INTERRUPTED — %s\n' "$reason" >&2
  printf 'run-pi-agent: session-id=%s\n' "$SESSION_ID" >&2
  printf 'run-pi-agent: After an interrupt the job is NOT auto-complete.\n' >&2
  printf 'run-pi-agent: The human user must confirm whether the job for this session is done.\n' >&2

  if [[ -r /dev/tty && -w /dev/tty ]]; then
    local ans
    printf '\n' >/dev/tty
    printf 'Session %s was interrupted (%s).\n' "$SESSION_ID" "$reason" >/dev/tty
    printf 'Is the job DONE for this session? [y/N] ' >/dev/tty
    # Read from the real terminal, not the script's stdin (may be a prompt pipe).
    if ! read -r ans </dev/tty; then
      ans=""
    fi
    case "${ans,,}" in
      y|yes)
        printf 'run-pi-agent: user confirmed job DONE after interrupt\n' >&2
        return 0
        ;;
      *)
        printf 'run-pi-agent: user did NOT confirm job done after interrupt\n' >&2
        return 1
        ;;
    esac
  fi

  # Caller (agent) must ask the human and not treat this as success.
  printf 'run-pi-agent: NEEDS_USER_CONFIRM session-id=%s reason=%s\n' \
    "$SESSION_ID" "$reason" >&2
  printf 'run-pi-agent: Ask the user: "Session %s was interrupted. Is the job done for this session?"\n' \
    "$SESSION_ID" >&2
  printf 'run-pi-agent: Do NOT assume done. Do NOT invent %s. Wait for explicit user yes/no.\n' \
    "$DONE_TAG" >&2
  return 2
}

handle_interrupt_confirm() {
  local reason=$1
  local confirm_ec

  set +e
  ask_user_job_done "$reason"
  confirm_ec=$?
  set -e

  if (( confirm_ec == 0 )); then
    # User said yes — return last assistant text even without the done tag.
    if [[ -n "${SESSION_FILE:-}" && -f "$SESSION_FILE" ]]; then
      log "extracting last assistant message after user-confirmed done…"
      python3 "$SESSION_HELPER" extract-last "$SESSION_FILE" "$SESSION_ID" || true
    fi
    exit 0
  fi
  if (( confirm_ec == 2 )); then
    # Non-interactive: force the calling agent to ask the user.
    if [[ -n "${SESSION_FILE:-}" && -f "$SESSION_FILE" ]]; then
      # Best-effort partial context on stdout for the caller to show the user.
      python3 "$SESSION_HELPER" extract-last "$SESSION_FILE" "$SESSION_ID" 2>/dev/null || true
    fi
    exit 125
  fi
  # User said no
  exit 1
}

# Wait for session file, then for the completion contract tag in the final message.
log "waiting for session file and contract ${DONE_TAG} (timeout ${TIMEOUT}s)…"
deadline=$((SECONDS + TIMEOUT))
turn_status="pending"
prev_status=""
PANE_GONE=0
TIMED_OUT=0

while (( SECONDS < deadline )); do
  if [[ -z "$SESSION_FILE" ]]; then
    if SESSION_FILE=$(find_session_file "$SESSION_DIR" "$SESSION_ID"); then
      log "session file: $SESSION_FILE"
    fi
  fi

  if [[ -n "$SESSION_FILE" && -f "$SESSION_FILE" ]]; then
    turn_status=$(python3 "$SESSION_HELPER" status "$SESSION_FILE" "$SESSION_ID" 2>/dev/null || echo "pending")
    if [[ "$turn_status" != "$prev_status" ]]; then
      log "turn status: $turn_status"
      prev_status=$turn_status
    fi
    # Terminal states for the wait loop.
    if [[ "$turn_status" == "done" || "$turn_status" == "needs_confirm" || "$turn_status" == "incomplete" ]]; then
      break
    fi
  fi

  if ! tmux list-panes -F '#{pane_id}' 2>/dev/null | grep -Fxq "$PANE_ID"; then
    PANE_GONE=1
    # Pane died — try to salvage session status
    if [[ -z "$SESSION_FILE" ]]; then
      SESSION_FILE=$(find_session_file "$SESSION_DIR" "$SESSION_ID" || true)
    fi
    if [[ -n "${SESSION_FILE:-}" && -f "$SESSION_FILE" ]]; then
      turn_status=$(python3 "$SESSION_HELPER" status "$SESSION_FILE" "$SESSION_ID" 2>/dev/null || echo "pending")
      if [[ "$turn_status" == "done" ]]; then
        # Clean contract before pane died — accept success.
        break
      fi
    fi
    # Interrupt path: pane gone without a clean done contract.
    turn_status="needs_confirm"
    break
  fi

  sleep 0.5
done

if [[ "$turn_status" != "done" && "$turn_status" != "needs_confirm" && "$turn_status" != "incomplete" ]]; then
  TIMED_OUT=1
  printf 'run-pi-agent: timed out after %ss (session-id=%s status=%s expected %s)\n' \
    "$TIMEOUT" "$SESSION_ID" "$turn_status" "$DONE_TAG" >&2
  # Timeout is a form of external stop — require user confirmation, not auto-done.
  turn_status="needs_confirm"
fi

if [[ "$turn_status" == "needs_confirm" ]]; then
  reason="session interrupted or aborted"
  if (( PANE_GONE )); then
    reason="pi pane disappeared mid-run"
  elif (( TIMED_OUT )); then
    reason="timed out waiting for ${DONE_TAG}"
  fi
  handle_interrupt_confirm "$reason"
fi

if [[ -z "${SESSION_FILE:-}" || ! -f "$SESSION_FILE" ]]; then
  die "session file not found for session-id=$SESSION_ID under $SESSION_DIR"
fi

if [[ "$turn_status" == "done" ]]; then
  log "extracting final message (contract: $DONE_TAG)…"
  set +e
  python3 "$SESSION_HELPER" extract "$SESSION_FILE" "$SESSION_ID"
  extract_ec=$?
  set -e
  exit "$extract_ec"
fi

# incomplete — model stopped without tag and no interrupt recorded
if [[ "$turn_status" == "incomplete" ]]; then
  printf 'run-pi-agent: incomplete — model stopped without %s\n' "$DONE_TAG" >&2
  set +e
  python3 "$SESSION_HELPER" extract "$SESSION_FILE" "$SESSION_ID"
  set -e
  exit 1
fi

die "unexpected turn status: $turn_status"
