---
description: Full Soul Mode revert
agent: soul
---

You are reverting Soul Mode completely.

Steps:
1) Delete scheduler job `soul-heartbeat` if it exists.
2) Remove Soul Mode files:
   - `.opencode/soul.md`
   - `.opencode/soul/` (entire directory)
   - `.opencode/agents/soul.md`
   - `.opencode/commands/soul-heartbeat.md`
   - `.opencode/commands/soul-status.md`
   - `.opencode/commands/steer-soul.md`
   - `.opencode/commands/take-my-soul-back.md`
3) Revert `opencode.jsonc` changes:
   - Remove `.opencode/soul.md` from `instructions` array
   - Remove `opencode-scheduler` from `plugins` only if it was added solely for Soul Mode
4) Confirm what was removed and what remains.

Safety: This is designed to be fully reversible. No other files are touched.
