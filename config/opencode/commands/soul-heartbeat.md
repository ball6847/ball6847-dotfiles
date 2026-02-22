---
description: Soul Mode heartbeat (non-interactive)
agent: soul
---

You are running Soul Mode heartbeat.

Constraints:
- Non-interactive: do not ask questions.
- Safe: no destructive actions.

Steps:
1) Read `.opencode/soul.md`.
2) Read `AGENTS.md` (and `_repos/openwork/AGENTS.md` if present).
3) Get workspace path via `pwd`.
4) Query OpenCode sqlite db for this workspace directory (if available):
   - Recent sessions:
     `SELECT id, title, time_updated FROM session WHERE directory = '<pwd>' ORDER BY time_updated DESC LIMIT 8;`
   - Open todos:
     `SELECT s.title, t.content, t.status, t.priority, t.time_updated FROM todo t JOIN session s ON s.id = t.session_id WHERE s.directory = '<pwd>' AND t.status != 'completed' ORDER BY t.time_updated DESC LIMIT 20;`
   - Recent transcript text:
     `SELECT s.title, p.time_updated, json_extract(p.data, '$.text') AS text FROM part p JOIN message m ON m.id = p.message_id JOIN session s ON s.id = m.session_id WHERE s.directory = '<pwd>' AND json_extract(p.data, '$.type') = 'text' ORDER BY p.time_updated DESC LIMIT 60;`
   - If db lookup fails, continue in degraded mode.
5) Optionally refresh `.opencode/soul.md` with small, deduped updates to Loose ends / Recurring chores when justified by evidence.
6) Output concise check-in:
   - Summary (1 sentence)
   - Loose ends (1-3 bullets)
   - Next action (1 bullet)
   - Improvements (2-3 bullets)
7) Append one JSON line with keys: `ts`, `workspace`, `summary`, `loose_ends`, `next_action` (and optional observability keys).

Append using one heredoc command:

    cat <<'EOF' >> .opencode/soul/heartbeat.jsonl
    {"ts":"...","workspace":"...","summary":"...","loose_ends":["..."],"next_action":"..."}
    EOF
