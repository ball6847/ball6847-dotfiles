---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane with smart layout decisions, wait for a hard completion contract, and clean up — in a single script call. Use when you need to run a pi agent in a tmux pane — whether for orchestration, parallel tasks, or any scenario requiring a pi session in a specific pane. Handles automatic split direction, pane lifecycle, session-based result capture, interrupt confirmation, and cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Run a pi agent in a tmux pane via **one script call**. The script owns the full lifecycle (layout → spawn → wait → capture → cleanup) so you do not drive tmux or poll panes yourself.

### Prerequisites

- Must be inside an active tmux session (`$TMUX` set)
- `pi` CLI available in PATH (or `~/.bun/bin/pi`, or pass `--pi`)
- `python3` available (used to read the session log)

### Run an agent

Resolve the path relative to the skill directory (e.g. `~/.agents/skills/pi-tmux-agent/scripts/run-pi-agent.sh`):

```bash
bash <skill-dir>/scripts/run-pi-agent.sh "Your prompt here"
```

Stdout is the **final assistant text** with the completion tag stripped. Exit `0` only on a clean contract **or** after the human confirms job-done following an interrupt.

### Completion contract (assertable)

Done is **not** inferred from “model stopped talking” alone. On a clean (never interrupted) run, the final assistant message must contain this **exact** tag:

```text
<done>SESSION_ID</done>
```

The script appends contract instructions (including the exact tag) to the prompt automatically.

| Session state                                                  | Status          | Exit          |
| -------------------------------------------------------------- | --------------- | ------------- |
| Tag present, **no** interrupt in session                       | `done`          | `0`           |
| Any abort/error in session history (even if tag appears later) | `needs_confirm` | see interrupt |
| Pane killed / timeout mid-run without clean `done`             | `needs_confirm` | see interrupt |
| Model `stop` without tag, never interrupted                    | `incomplete`    | `1`           |
| Still tool-calling                                             | `running`       | (wait)        |

### Interrupt → always ask the user

If the session is **interrupted** (abort, error, pane gone, timeout), the job is **never** auto-complete.

Rules enforced by the script **and** the prompt appendix:

1. The pi agent must **not** only answer the original question and print `<done>…</done>` after an interrupt.
2. After an interrupt it must **ask the human** whether the job for this session is done.
3. The orchestrator/`run-pi-agent` path also requires human confirmation before success.

| Environment                    | Behavior                                                  |
| ------------------------------ | --------------------------------------------------------- |
| Interactive TTY                | Script prompts: `Is the job DONE for this session? [y/N]` |
| Non-interactive (agent caller) | Exit **`125`** + stderr `NEEDS_USER_CONFIRM`              |

**When you see exit 125 / `NEEDS_USER_CONFIRM`:**

1. Tell the user the session was interrupted (`session-id=…`).
2. Ask explicitly: _“Is the job done for this session?”_
3. **Do not** invent the done tag or assume success.
4. If user says **yes** — treat the job as done (use any partial stdout the script printed as context).
5. If user says **no** — treat as not done; resume, re-run, or stop per user guidance.

Stdout on `125` may include the last assistant text as **context for the user**, not as a successful contract result.

### Options

| Flag                 | Meaning                                    |
| -------------------- | ------------------------------------------ |
| `-t, --timeout SECS` | Max wait for the contract (default `3600`) |
| `-k, --keep-pane`    | Leave the pane open after completion       |
| `-C, --cwd DIR`      | Working directory for pi                   |
| `--session-id ID`    | Pin session id (default: generated UUID)   |
| `--pi PATH`          | Path to the pi binary                      |
| `-v, --verbose`      | Progress on stderr                         |

### Exit codes

| Code  | Meaning                                                                 |
| ----- | ----------------------------------------------------------------------- |
| `0`   | Clean contract, or user confirmed job-done after interrupt              |
| `1`   | Incomplete / user said not done / setup error                           |
| `124` | (reserved historically; timeout now goes through confirm → often `125`) |
| `125` | Interrupted — **caller must ask the human** whether the job is done     |

### Important notes

- Do **not** manage tmux yourself — only call `run-pi-agent.sh`
- Clean success = exit `0` **and** (normally) a satisfied contract; after interrupt, success only via **user confirmation**
- Parallel runs need distinct `--session-id` values
