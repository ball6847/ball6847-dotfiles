---
name: pi-tmux-agent
description: Spawn a pi agent instance in a tmux pane with smart layout decisions, wait for completion, and clean up — in a single script call. Use when you need to run a pi agent in a tmux pane — whether for orchestration, parallel tasks, or any scenario requiring a pi session in a specific pane. Handles automatic split direction, pane lifecycle, output capture, and cleanup.
user-invocable: true
---

# Pi Tmux Agent Skill

## Instructions

Run a pi agent in a tmux pane via **one script call**. The script owns the full lifecycle (layout → spawn → wait → capture → cleanup) so you do not drive tmux or poll panes yourself.

### Prerequisites

- Must be inside an active tmux session (`$TMUX` set)
- `pi` CLI available in PATH (or `~/.bun/bin/pi`, or pass `--pi`)

### Run an agent

Resolve the path relative to the skill directory (e.g. `~/.agents/skills/pi-tmux-agent/scripts/run-pi-agent.sh`):

```bash
bash <skill-dir>/scripts/run-pi-agent.sh "Your prompt here"
```

Stdout is pi's full output. The exit code is pi's exit code (`124` on timeout, `1` on setup errors).

**Multiline / large prompts** — use stdin:

```bash
bash <skill-dir>/scripts/run-pi-agent.sh <<'EOF'
Implement the plan at .context/plans/...
When done, summarize what changed.
EOF
```

### Options

| Flag                 | Meaning                                        |
| -------------------- | ---------------------------------------------- |
| `-t, --timeout SECS` | Max wait for completion (default `3600`)       |
| `-k, --keep-pane`    | Leave the pane open after completion           |
| `-C, --cwd DIR`      | Working directory for pi (default: caller cwd) |
| `--pi PATH`          | Path to the pi binary                          |
| `-v, --verbose`      | Progress messages on stderr                    |

Environment:

| Var                        | Meaning                                                                        |
| -------------------------- | ------------------------------------------------------------------------------ |
| `MIN_WIDTH` / `MIN_HEIGHT` | Minimum new-pane size for split selection (default `80` / `20`)                |
| `PI_BIN`                   | Override pi binary                                                             |
| `PI_ARGS`                  | Extra pi flags before the prompt (e.g. `PI_ARGS='--model foo --thinking low'`) |

### What the script does

1. **pick_split** — chooses the largest usable pane and split direction (`h` or `v`) so the new pane stays readable
2. **spawn** — `tmux split-window` running `pi -p` (print / non-interactive) with your prompt
3. **wait** — blocks until pi exits (or `--timeout`)
4. **output** — prints the captured log on stdout
5. **cleanup** — kills the pane unless `--keep-pane`

`pi -p` is intentional: completion is process-exit based, not TUI scraping or `send-keys` races. Output still streams live in the pane via `tee`.

### Layout rules (handled for you)

- Split the largest existing pane (orchestrator pane is a valid target)
- Prefer the longer visual dimension (`width ≈ 2 × height` cells)
- Enforce minimum usable size (~80 cols × 20 rows); override with `MIN_WIDTH` / `MIN_HEIGHT`
- If no split fits, the script exits non-zero — tell the user to maximize the window
- If the window is zoomed, splitting will unzoom it (script notes this on stderr)

### Parallel agents

Each invocation creates its own pane and blocks until that agent finishes. For parallel work, run multiple script invocations in the background (separate shell jobs) and `wait` on them — do not reimplement pane polling yourself.

### Important notes

- Do **not** call `tmux split-window` / `send-keys` / `capture-pane` for pi agents when this skill is in use — call `run-pi-agent.sh` only
- Prefer several sequential script calls over one giant prompt when tasks are independent stages
- After many panes close, you may rebalance with `tmux select-layout tiled` if the layout feels lopsided (only if the user isn't focused on reading a pane)
