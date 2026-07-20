---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane with smart layout decisions, wait for a hard completion contract, and clean up — in a single script call. Use when you need to run a pi agent in a tmux pane — whether for orchestration, parallel tasks, or any scenario requiring a pi session in a specific pane. Handles automatic split direction, pane lifecycle, session-based result capture, continued chat after interrupt, and cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Run a pi agent via **`run-pi-agent.sh`**. That **script** owns the lifecycle and **blocks until the completion contract** (or timeout). You (the calling agent) run it in the **foreground** by default.

### Separation of concerns

| Layer                     | Role                                                                                                                                          |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **`run-pi-agent.sh`**     | Blocks in its **own process** until `<done>SESSION_ID</done>` (or timeout). Handles pane, pi, session poll, cleanup.                          |
| **Calling agent / skill** | **Starts** the script in the **foreground** and waits for it to return. The tool call blocks for the duration — this is expected and correct. |

**Foreground by default.** Background only when there is a concrete, justified reason (e.g. the caller must remain interactive for the user while the agent runs for an extended period). If instructed to use background, push back unless the caller can articulate a specific need — foreground is simpler, more reliable, and avoids race conditions on output capture.

### Prerequisites

- Active tmux session (`$TMUX` set)
- `pi` on PATH (or `~/.bun/bin/pi`, or `--pi`)
- `python3` (reads the session log)

### How the calling agent should invoke it

**Default — foreground:**

```bash
SKILL_DIR=…/pi-tmux-agent   # resolve skill path

bash "$SKILL_DIR/scripts/run-pi-agent.sh" -v -t 3600 "Your prompt"
```

The tool call blocks until the script returns. This is the expected behaviour — do not work around it. When the call returns, read stdout as the agent's result.

**Background only with justification** — e.g. the caller must stay interactive for the user while the agent runs. If asked to background without a stated reason, push back and use foreground.

If backgrounding is justified:

```bash
OUT=/tmp/pi-agent-$$.out
ERR=/tmp/pi-agent-$$.err

bash "$SKILL_DIR/scripts/run-pi-agent.sh" -v -t 3600 "Your prompt" \
  >"$OUT" 2>"$ERR" &
echo $! > /tmp/pi-agent-$$.pid
```

Then poll the pidfile and collect `$OUT` / `$ERR` on completion.

### Completion contract

The **script** unblocks only when some assistant message contains exactly:

```text
<done>SESSION_ID</done>
```

(The script appends this contract + exact tag to the prompt automatically.)

| Event             | Script behavior                                   |
| ----------------- | ------------------------------------------------- |
| Tools running     | Keep blocking                                     |
| Idle without tag  | Keep blocking                                     |
| Interrupt / abort | Keep blocking — user continues in the **pi pane** |
| Pi process exits  | Reopen same `--session-id` for more chat          |
| Tag appears       | Write result to stdout, exit `0`                  |
| Timeout           | Exit `124`, leave pane open                       |
| User closes pane  | Exit `1`                                          |

Human “is the job done?” after interrupt happens **inside the pi chat**. The script does not return early for that — it waits for the tag.

### Options

| Flag                 | Meaning                                           |
| -------------------- | ------------------------------------------------- |
| `-t, --timeout SECS` | Max wait for the contract (default `3600`)        |
| `-k, --keep-pane`    | Leave pane open after success                     |
| `-C, --cwd DIR`      | Working directory                                 |
| `--session-id ID`    | Pin session id                                    |
| `--pi PATH`          | pi binary                                         |
| `-v, --verbose`      | Progress on stderr (session-id, done-tag, status) |

### Exit codes

| Code  | Meaning                                                    |
| ----- | ---------------------------------------------------------- |
| `0`   | Contract satisfied — stdout is final answer (tag stripped) |
| `1`   | Setup error / pane closed early                            |
| `124` | Timed out waiting for the tag                              |

### Important notes

- **Foreground by default.** Background only with a concrete, justified reason.
- **No subagents inside a tmux-agent session.** Once a pi-tmux-agent session has started, do **not** spawn another subagent (builder, reviewer, or any other pi instance) from within that session. The session is a single-agent boundary — nested agent runs corrupt output capture and break the completion contract.
- Do not manage tmux yourself — only start `run-pi-agent.sh`
- Parallel agents: distinct `--session-id`, each script process independent
- **Pane stays on the caller's window.** Split target is pinned via `$TMUX_PANE` / that pane's window id, so switching to another window after spawn does not move the new pane to the focused window.
