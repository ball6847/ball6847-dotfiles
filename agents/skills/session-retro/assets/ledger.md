# Retro ledger — `~/.pi/agent/retro/ledger.md`

Copy this file's header to `~/.pi/agent/retro/ledger.md` on first use. Cheap lessons live here; they never load into a session.

- Re-read the file immediately before editing it. Other sessions append to it.
- Same root cause, different symptom → increment `Count`, refresh `Last seen`, append the new evidence.
- `Count` ≥ 2, user stated it as a standing rule, or the cost exceeded 20 minutes → promote to an AGENTS.md bullet and set `Status`.
- A row that stops recurring and matters to nobody gets deleted after a few months. The ledger is not an archive.

| Project | Root cause (≤8 words) | Count | Last seen | Evidence | Status |
|---|---|---|---|---|---|
| /home/me/code/api | Guessed file paths instead of reading tree once | 2 | 2026-11-06 | turn 12: 4 `find` calls before the first `ls` | promoted → AGENTS.md#session-lessons |
| /home/me/code/api | Re-ran full test suite for a one-file change | 1 | 2026-11-06 | `pnpm test` x3, 4m each | open |
