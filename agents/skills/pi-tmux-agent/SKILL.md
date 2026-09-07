---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane, wait for a hard completion contract, and clean up — in a single foreground script call. Use when you need to run a pi agent in a tmux pane for orchestration or any scenario requiring a pi session in a specific pane. Handles automatic split direction, pane lifecycle, session-based result capture, continued chat after interrupt, and cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Run a pi agent via **`run-pi-agent.sh`**. That **script** owns the lifecycle and **blocks until the completion contract** (or timeout). You (the calling agent) run it in the **foreground**.

### Separation of concerns

| Layer                     | Role                                                                                                                                          |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **`run-pi-agent.sh`**     | Blocks in its **own process** until `<done>SESSION_ID</done>` (or timeout). Handles pane, pi, session poll, cleanup.                          |
| **Calling agent / skill** | **Starts** the script in the **foreground** and waits for it to return. The tool call blocks for the duration — this is expected and correct. |

### Prerequisites

- Active tmux session (`$TMUX` set)
- `pi` on PATH (or `~/.bun/bin/pi`, or `--pi`)
- `python3` (reads the session log)

### How the calling agent should invoke it

```bash
SKILL_DIR=…/pi-tmux-agent   # resolve skill path

bash "$SKILL_DIR/scripts/run-pi-agent.sh" -v -t 3600 "Your prompt"
```

The tool call blocks until the script returns. This is the expected behaviour — do not work around it. When the call returns, read stdout as the agent's result.

Calling-agent rule: break the delegated work into small pieces and track them as todo items — even if there is only one. Prefer several sequential small runs over one large run: a task that fits inside its timeout never needs timeout recovery. (Inside the session, the pi agent should work the same way using its own native todo list — but nested runs and subagents are forbidden, see below.)

### Completion contract

The **script** unblocks only when some assistant message contains exactly:

```text
<done>SESSION_ID</done>
```

(The script appends this contract + exact tag to the prompt automatically.)

| Event             | Script behavior                                                         |
| ----------------- | ----------------------------------------------------------------------- |
| Tools running     | Keep blocking                                                           |
| Idle without tag  | Keep blocking                                                           |
| Interrupt / abort | Keep blocking — user continues in the **pi pane**                       |
| Pi process exits  | Reopen same `--session-id` for more chat                                |
| Tag appears       | Write result to stdout, exit `0`                                        |
| Timeout           | Exit `124`, pane killed by default (`--on-timeout keep` leaves it open) |
| User closes pane  | Exit `1`                                                                |

Human “is the job done?” after interrupt happens **inside the pi chat**. The script does not return early for that — it waits for the tag. That gate applies to in-run interrupts only; an automated resume (new invocation with an existing `--session-id`) gets resume-rules instead — continue the remaining work directly, no confirmation question — because no human is watching the pane.

### Options

| Flag                      | Meaning                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `-t, --timeout SECS`      | Max wait for the contract (default `3600`)                                         |
| `--on-timeout kill\|keep` | Pane policy on timeout (default `kill`; `keep` leaves pane open)                   |
| `-k, --keep-pane`         | Leave pane open after success (success path only)                                  |
| `-C, --cwd DIR`           | Working directory                                                                  |
| `--session-id ID`         | Pin session id                                                                     |
| `--pi PATH`               | pi binary                                                                          |
| `-m, --model MODEL`       | Model pattern passed as `--model` to pi (e.g. `zenmux/deepseek/deepseek-v4-flash`) |
| `-v, --verbose`           | Progress on stderr (session-id, done-tag, status)                                  |

### Exit codes

| Code  | Meaning                                                                                 |
| ----- | --------------------------------------------------------------------------------------- |
| `0`   | Contract satisfied — stdout is final answer (tag stripped)                              |
| `1`   | Setup error / pane closed early                                                         |
| `124` | Timed out waiting for the tag — stdout is empty; pane killed unless `--on-timeout keep` |

### On timeout (exit `124`)

Exit `124` means the agent did **not** finish. Stdout is empty (a partial tail is printed to stderr only — never treat it as the final answer). Single-writer rule to avoid racing the timed-out agent:

1. Do **not** do the delegated work yourself and do **not** spawn a new agent for it yet.
2. Recover the incomplete task — first break what remains into small todo items (even if there is only one: track them on your side and include the list in the resume/retry prompt), then pick exactly one owner:
   - **Resume** (preferred when the partial work looks right): re-invoke with the same session id from stderr — `run-pi-agent.sh --session-id <id> "<what remains, plus any correction>"`. Session history survives the killed pane, so the new run continues where the old one stopped. Give it a generous `-t`: a task that timed out once usually needs more time, not a new worker. Use the same `-C`: with a different cwd pi silently creates an EMPTY session with the same id (history lost, duplicate id). State the remaining work as direct instructions; the script detects the existing session and swaps the interrupt gate for resume-rules.
   - **Fork** (old session file itself seems wedged but its history is valuable): fork full history into a new id, then resume that — from the same cwd run `pi --fork <session-file> --session-id "$NEW_ID" -p "Summarize where the previous session stopped in 3 bullets"` (use the `partial work preserved in:` path from stderr and a fresh uuid for `$NEW_ID`), then `run-pi-agent.sh --session-id "$NEW_ID" "<what remains>"`. Forking also drops malformed lines, so it sanitizes a corrupt tail.
   - **Retry fresh** (partial work is wrong or the approach was bad): start a new run without `--session-id`, pasting only the still-valid bits of the partial tail into the new prompt. Allowed immediately under the default kill policy (the script already killed the pane); with `--on-timeout keep`, `tmux kill-pane -t <pane>` first.
   - **Take over yourself**: same precondition as retry fresh — old pane dead — then you own the files. Use the partial tail plus the session file (`partial work preserved in: …` on stderr) as starting context instead of redoing completed steps.
3. One owner at a time — never resume AND retry/take-over concurrently for the same task.
4. With `--on-timeout keep` the pane is still alive and the agent may still be working — killing it before any competing work is mandatory, not optional.

### Important notes

- **No subagents inside a tmux-agent session.** Once a pi-tmux-agent session has started, do **not** spawn another subagent (builder, reviewer, or any other pi instance) from within that session. The session is a single-agent boundary — nested agent runs corrupt output capture and break the completion contract.
- Do not manage tmux yourself — only start `run-pi-agent.sh`
- **Pane stays on the caller's window.** Split target is pinned via `$TMUX_PANE` / that pane's window id, so switching to another window after spawn does not move the new pane to the focused window.
