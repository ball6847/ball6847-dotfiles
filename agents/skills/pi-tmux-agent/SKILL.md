---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane with smart layout decisions, poll for completion, and clean up. Use when you need to run a pi agent in a tmux pane — whether for orchestration, parallel tasks, or any scenario requiring a pi TUI session in a specific pane. Handles automatic split direction, pane id capture, output polling, and pane cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Spawn a pi agent in a tmux pane, wait for it to complete, and clean up. This is a reusable building block — it handles the tmux mechanics so callers can focus on what to ask the agent.

### Prerequisites

- tmux session must be active
- `pi` CLI must be available in PATH (if `pi` is not found in new panes, use its absolute path, e.g. `~/.bun/bin/pi`)

### Pane Layout — Automatic Split Decisions

Do NOT hardcode a split direction. The right direction depends on the current terminal layout, which changes as panes are spawned and closed. Decide per spawn using these principles:

- **Split the largest existing pane.** A new pane is created by splitting an existing one, so splitting the biggest pane gives the newcomer the most space. The orchestrator pane is a valid split target — minimum-size guards (below) prevent it from ever becoming cramped.
- **Split along the longer visual dimension.** Terminal character cells are roughly twice as tall as they are wide, so a pane looks balanced when `width ≈ 2 × height` (in character cells). A horizontal split (`-h`, side-by-side) is right for wide panes; a vertical split (`-v`, stacked) is right for tall panes.
- **Enforce minimum usable sizes.** A pi pane needs roughly 80 columns to render its TUI readably and 20 lines to show progress. Never create a pane smaller than that.

Use the bundled helper script to make this decision deterministically. Resolve the path relative to the skill directory (e.g. `~/.agents/skills/pi-tmux-agent/scripts/pick-split.sh`):

```bash
read TARGET DIRECTION < <(bash <skill-dir>/scripts/pick-split.sh)
```

The script prints the target pane id and direction (`h` or `v`), plus a human-readable rationale on stderr. It exits non-zero if no pane can be split without violating the minimums — in that case, warn the user that the terminal is too small and ask them to maximize the window before continuing.

Minimums can be tuned via environment variables if a user has unusual needs:

```bash
MIN_WIDTH=100 MIN_HEIGHT=24 bash <skill-dir>/scripts/pick-split.sh
```

### Spawning a Pane

Use this procedure to spawn a pi agent in a new pane. It captures the new pane's stable id (`%N`) directly from tmux, so there is no guessing of pane indices:

```bash
# 1. Decide where and how to split
read TARGET DIRECTION < <(bash <skill-dir>/scripts/pick-split.sh)

# 2. Split and capture the new pane id
PANE_ID=$(tmux split-window -"$DIRECTION" -t "$TARGET" -P -F '#{pane_id}' 'pi')

# 3. Send the prompt
tmux send-keys -t "$PANE_ID" "<prompt>" C-m
```

Keep track of the pane id in a variable so it can be polled and killed reliably.

### Waiting and Capturing Results

Poll the pane output until the agent's completion summary appears (look for the final summary text and the return of the empty input prompt):

```bash
sleep 5 && tmux capture-pane -t "$PANE_ID" -p -S -500 | tail -80
```

Repeat with longer sleeps for long-running tasks. Prefer several polls over one long sleep so you can report progress to the user.

### Closing a Pane

After the agent completes, close the pane by id. Tolerate panes that already exited:

```bash
tmux kill-pane -t "$PANE_ID" 2>/dev/null || true
```

If the remaining layout feels lopsided after closing panes, you may rebalance with `tmux select-layout tiled` — but do this only if the user isn't actively reading the pane, since it resizes their view.

## Important Notes

- Decide split direction fresh at every spawn — a direction that was right for one agent may be wrong for the next once the layout has changed
- If `pick-split.sh` reports the terminal is too small, tell the user rather than forcing a cramped split
- If `pick-split.sh` notes the window is zoomed, tell the user their view will unzoom before spawning
- The pane id (`%N`) is stable across polls — use it rather than pane indices which can shift
