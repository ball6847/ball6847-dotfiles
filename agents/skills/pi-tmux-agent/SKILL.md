---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane with smart layout decisions, wait for a hard completion contract, and clean up — in a single script call. Use when you need to run a pi agent in a tmux pane — whether for orchestration, parallel tasks, or any scenario requiring a pi session in a specific pane. Handles automatic split direction, pane lifecycle, session-based result capture, continued chat after interrupt, and cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Run a pi agent via **`run-pi-agent.sh`**. That **script** owns the lifecycle and **blocks until the completion contract** (or timeout). You (the calling agent) must **not** freeze the conversation waiting on it.

### Separation of concerns

| Layer | Role |
|-------|------|
| **`run-pi-agent.sh`** | Blocks in its **own process** until `<done>SESSION_ID</done>` (or timeout). Handles pane, pi, session poll, cleanup. |
| **Calling agent / skill** | **Starts** the script (prefer background), stays free to talk to the user, later **collects** exit code + stdout. Never treat “agent tool blocked for minutes” as the wait mechanism. |

Wrong: call the script in a long foreground tool and sit on it for the whole pi job.  
Right: start the script in the background; the **script** keeps blocking; you only re-check when needed.

### Prerequisites

- Active tmux session (`$TMUX` set)
- `pi` on PATH (or `~/.bun/bin/pi`, or `--pi`)
- `python3` (reads the session log)

### How the calling agent should invoke it

**Preferred — background the script process:**

```bash
SKILL_DIR=…/pi-tmux-agent   # resolve skill path
OUT=/tmp/pi-agent-$$.out
ERR=/tmp/pi-agent-$$.err

bash "$SKILL_DIR/scripts/run-pi-agent.sh" -v -t 3600 "Your prompt" \
  >"$OUT" 2>"$ERR" &
echo $! > /tmp/pi-agent-$$.pid
```

Then:

- Tell the user the pane is up / session-id (from `ERR` once available)
- Keep chatting with the user while the **script** waits
- When appropriate, check: `kill -0 $(cat pidfile)` or wait on that pid in a **short** poll — do not monopolize the turn for the full duration
- On completion: read `$OUT` (result), `$ERR` (diagnostics), and the process exit code

**Foreground is OK only** when the caller is already a dedicated worker process whose only job is that one agent (e.g. a shell job the user started). Orchestrating agents in a chat UI should background.

### Completion contract

The **script** unblocks only when some assistant message contains exactly:

```text
<done>SESSION_ID</done>
```

(The script appends this contract + exact tag to the prompt automatically.)

| Event | Script behavior |
|-------|-----------------|
| Tools running | Keep blocking |
| Idle without tag | Keep blocking |
| Interrupt / abort | Keep blocking — user continues in the **pi pane** |
| Pi process exits | Reopen same `--session-id` for more chat |
| Tag appears | Write result to stdout, exit `0` |
| Timeout | Exit `124`, leave pane open |
| User closes pane | Exit `1` |

Human “is the job done?” after interrupt happens **inside the pi chat**. The script does not return early for that — it waits for the tag.

### Options

| Flag | Meaning |
|------|---------|
| `-t, --timeout SECS` | Max wait for the contract (default `3600`) |
| `-k, --keep-pane` | Leave pane open after success |
| `-C, --cwd DIR` | Working directory |
| `--session-id ID` | Pin session id |
| `--pi PATH` | pi binary |
| `-v, --verbose` | Progress on stderr (session-id, done-tag, status) |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Contract satisfied — stdout is final answer (tag stripped) |
| `1` | Setup error / pane closed early |
| `124` | Timed out waiting for the tag |

### Important notes

- **Script blocks. Agent does not.**  
- Do not manage tmux yourself — only start `run-pi-agent.sh`  
- Parallel agents: distinct `--session-id`, each script process in the background  
