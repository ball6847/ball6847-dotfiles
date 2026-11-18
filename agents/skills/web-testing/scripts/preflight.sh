#!/usr/bin/env bash
# Preflight for a web test run.
#
# Checks the things that have to be true before the run starts. A failure here
# means the run cannot start, so stop and report rather than working around it.
#
# Usage: preflight.sh [base-url]

set -uo pipefail

BASE_URL="${1:-}"
FAILED=0

say() { printf '%s\n' "$*"; }
ok() { printf '  ok    %s\n' "$*"; }
bad() { printf '  FAIL  %s\n' "$*"; FAILED=1; }

say "agent-browser"

if command -v agent-browser >/dev/null 2>&1; then
  ok "found at $(command -v agent-browser)"
  version="$(agent-browser --version 2>/dev/null | head -1)"
  ok "version ${version:-unknown}"
else
  bad "the agent-browser command is not on PATH"
  say "         install it with: npm i -g agent-browser"
  say "         do not fall back to another browser tool"
fi

say ""
say "agent-browser skill"

SKILL_FOUND=""
for candidate in \
  "$HOME/.agents/skills/agent-browser/SKILL.md" \
  "$HOME/.claude/skills/agent-browser/SKILL.md" \
  "$HOME/.pi/agent/skills/agent-browser/SKILL.md" \
  ".agents/skills/agent-browser/SKILL.md" \
  ".claude/skills/agent-browser/SKILL.md"; do
  if [ -f "$candidate" ]; then
    SKILL_FOUND="$candidate"
    break
  fi
done

if [ -n "$SKILL_FOUND" ]; then
  ok "found at $SKILL_FOUND"
  say "         read it before the first browser command"
else
  say "  note  not found, carry on with the commands in SKILL.md"
fi

say ""
say "browser"

if command -v agent-browser >/dev/null 2>&1; then
  if agent-browser --session preflight open "about:blank" >/dev/null 2>&1; then
    ok "the browser starts"
    agent-browser --session preflight close >/dev/null 2>&1
  else
    bad "the browser does not start, run: agent-browser install"
  fi
fi

if [ -n "$BASE_URL" ]; then
  say ""
  say "target"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$BASE_URL" 2>/dev/null || echo 000)"
  if [ "$code" = "000" ]; then
    bad "no answer from $BASE_URL"
  else
    ok "$BASE_URL answered $code"
    if [ "$code" -ge 500 ]; then
      bad "the target is returning a server error"
    fi
  fi
fi

say ""
if [ "$FAILED" -ne 0 ]; then
  say "preflight failed, do not start the run"
  exit 1
fi
say "preflight passed"
