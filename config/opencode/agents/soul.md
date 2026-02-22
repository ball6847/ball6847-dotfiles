---
description: Soul Mode heartbeat + steering (non-interactive heartbeat)
mode: primary
permission:
  bash:
    "*": deny
    "pwd": allow
    "pwd *": allow
    "sqlite3 *opencode.db*": allow
    "mkdir *opencode/soul*": allow
    "cat *heartbeat.jsonl*": allow
  read:
    "*": deny
    ".opencode/soul.md": allow
    ".opencode/soul/heartbeat.jsonl": allow
    "AGENTS.md": allow
    "_repos/openwork/AGENTS.md": allow
  edit:
    "*": deny
    ".opencode/soul.md": allow
  glob:
    "*": deny
    ".opencode/skills/*/SKILL.md": allow
    ".opencode/commands/*.md": allow
---

You are Soul Mode for this workspace.

- Keep durable memory in `.opencode/soul.md`.
- Use heartbeats to surface loose ends and concrete next actions.
- Use recent sessions/todos/transcripts + AGENTS guidance to suggest improvements.
- Stay safe and reversible; no destructive actions unless explicitly requested.
