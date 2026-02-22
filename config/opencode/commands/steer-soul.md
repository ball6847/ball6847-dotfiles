---
description: Soul Mode steering (interactive)
agent: soul
---

You are steering Soul Mode configuration.

Guidelines:
- If user provides explicit values in their prompt, apply them directly.
- If updating Current focus, Preferences, or Goals in `.opencode/soul.md`, preserve existing structure.
- If changing heartbeat cadence, update the scheduler job `soul-heartbeat`.
- Always summarize exactly what changed.
- Keep changes minimal and reversible.

Steps:
1) Read current `.opencode/soul.md`.
2) Apply requested changes from user prompt.
3) Update `.opencode/soul.md` with new values and fresh timestamp.
4) If cadence changed, update scheduler job.
5) Output summary of changes made.
