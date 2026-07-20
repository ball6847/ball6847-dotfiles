---
name: pi-orchestrator
description: Orchestrates build-review cycles by delegating tasks to builder and reviewer pi instances running in tmux panes, with automatic pane layout decisions (horizontal vs vertical split) based on available terminal space to maximize visibility. Implements a plan with automated quality gates, looping until reviewer passes or maximum 3 rounds reached. Use whenever you need end-to-end plan execution with quality assurance in a tmux environment — especially when the user mentions orchestrating, delegating to builder/reviewer in tmux panes, running a plan through build and review, or wants agents working side by side in their terminal.
user-invocable: true
---

# Pi Orchestrator Skill

## Instructions

Coordinate build-review cycles to implement a plan by delegating to builder and reviewer pi instances running in tmux panes. This skill ensures implementations pass review before completion. Pane placement is decided automatically so that every spawned pane gets the most usable space possible.

### Prerequisites

- tmux session must be active
- `pi` CLI must be available in PATH (if `pi` is not found in new panes, use its absolute path, e.g. `~/.bun/bin/pi`)
- A plan file must exist at `.context/plans/YYYY-MM-DD/FEATURE_PLAN.md`

### Workflow

Execute the following loop, up to 3 rounds:

```
Round 1:
  1. Spawn builder pane (auto-layout) -> Implement the plan
  2. Capture builder result -> Check for completion
  3. Spawn reviewer pane (auto-layout) -> Verify implementation
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Continue to Round 2

Round 2 (if needed):
  1. Spawn builder pane (auto-layout) -> Fix issues from review
  2. Capture builder result -> Check for completion
  3. Spawn reviewer pane (auto-layout) -> Verify fixes
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Continue to Round 3

Round 3 (if needed):
  1. Spawn builder pane (auto-layout) -> Final attempt to fix issues
  2. Capture builder result -> Check for completion
  3. Spawn reviewer pane (auto-layout) -> Verify fixes
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Close panes, summarize issues
```

### Maximum Rounds

- **Maximum**: 3 rounds
- After 3 rounds without reviewer returning PASS, stop and provide issue summary

### Pane Layout — Automatic Split Decisions

Do NOT hardcode a split direction. The right direction depends on the current terminal layout, which changes as panes are spawned and closed. Decide per spawn using these principles:

- **Split the largest existing pane.** A new pane is created by splitting an existing one, so splitting the biggest pane gives the newcomer the most space. The orchestrator pane is a valid split target — minimum-size guards (below) prevent it from ever becoming cramped.
- **Split along the longer visual dimension.** Terminal character cells are roughly twice as tall as they are wide, so a pane looks balanced when `width ≈ 2 × height` (in character cells). A horizontal split (`-h`, side-by-side) is right for wide panes; a vertical split (`-v`, stacked) is right for tall panes.
- **Enforce minimum usable sizes.** A pi pane needs roughly 80 columns to render its TUI readably and 20 lines to show progress. Never create a pane smaller than that.

Use the bundled helper script to make this decision deterministically. Resolve the path relative to the skill directory (e.g. `~/.agents/skills/pi-orchestrator/scripts/pick-split.sh`):

```bash
read TARGET DIRECTION < <(bash <skill-dir>/scripts/pick-split.sh)
```

The script prints the target pane id and direction (`h` or `v`), plus a human-readable rationale on stderr. It exits non-zero if no pane can be split without violating the minimums — in that case, warn the user that the terminal is too small and ask them to maximize the window before continuing.

Minimums can be tuned via environment variables if a user has unusual needs:

```bash
MIN_WIDTH=100 MIN_HEIGHT=24 bash <skill-dir>/scripts/pick-split.sh
```

### Spawning a Worker Pane (Builder or Reviewer)

Use this procedure for both builder and reviewer spawns. It captures the new pane's stable id (`%N`) directly from tmux, so there is no guessing of pane indices:

```bash
# 1. Decide where and how to split
read TARGET DIRECTION < <(bash <skill-dir>/scripts/pick-split.sh)

# 2. Split and capture the new pane id
PANE_ID=$(tmux split-window -"$DIRECTION" -t "$TARGET" -P -F '#{pane_id}' 'pi')

# 3. Send the prompt (see templates below)
tmux send-keys -t "$PANE_ID" "<prompt>" C-m
```

Keep track of the ids in variables — `BUILDER_PANE`, `REVIEWER_PANE` — so they can be polled and killed reliably.

### Builder Prompt Template

For Round 1:
```
Please use the builder skill to implement the plan at <plan_path>.
```

For Rounds 2-3 (include issues from previous review):
```
Please use the builder skill to implement the plan at <plan_path>. The previous review found these issues that need fixing: <list_of_issues>
```

### Reviewer Prompt Template

```
Please use the reviewer skill to review the implementation of the plan at <plan_path> against the implementation report at <report_path>. Verify that all changes match the plan and that the codebase is correct.
```

### Waiting and Capturing Results

Poll the pane output until the agent's completion summary appears (look for the final summary text and the return of the empty input prompt):

```bash
sleep 5 && tmux capture-pane -t "$PANE_ID" -p -S -500 | tail -80
```

Repeat with longer sleeps for long-running tasks. Prefer several polls over one long sleep so you can report progress to the user.

### Checking Review Verdict

After the reviewer completes, capture the pane output and look for the verdict in the final summary:

- **PASS**: "Review complete. Verdict: PASS" or "Verdict: PASS"
- **PARTIAL/FAIL**: "Verdict: PARTIAL" or "Verdict: FAIL" or missing PASS

**The round is PASSED only when the reviewer returns PASS.**

### Closing Panes

After the round completes (success or failure), close both worker panes by id. Tolerate panes that already exited:

```bash
tmux kill-pane -t "$REVIEWER_PANE" 2>/dev/null || true
tmux kill-pane -t "$BUILDER_PANE" 2>/dev/null || true
```

If the remaining layout feels lopsided after closing panes, you may rebalance with `tmux select-layout tiled` — but do this only if the user isn't actively reading the orchestrator pane, since it resizes their view.

### Round Tracking

Track rounds explicitly in your response:

```
## Orchestrator Progress

**Current Round**: 1/3
**Status**: [Building / Reviewing / Complete]

### Round History

| Round | Build Status | Reviewer | Verdict | Notes |
|-------|--------------|----------|---------|-------|
| 1 | Completed | PASS | PASS | All checks passed |
| 2 | Completed | PARTIAL | PARTIAL | Missing error handling |
```

### Final Reporting

**On Success (reviewer PASSES):**

```markdown
## Orchestrator Complete

**Rounds Used**: X/3
**Final Status**: SUCCESS
**Plan**: [link to plan]

All implementations verified against plan by reviewer.

### Review Summary

- Reviewer: PASS
```

**On Failure (3 rounds without PASS):**

```markdown
## Orchestrator Stopped

**Rounds Used**: 3/3
**Final Status**: FAILED
**Plan**: [link to plan]

### Final Review Results

- Reviewer: [verdict]

### Summary of Issues

[List all unresolved issues from reviewer across all rounds]

### Recommendations

[Suggestions for how to proceed - manual intervention, plan revision, etc.]
```

## Important Notes

- Always start with Round 1, do not skip ahead
- Pass context from previous rounds to help agents focus on specific issues
- Do not modify the plan during orchestration
- If builder reports blocking obstacles, still proceed to review for visibility
- Keep detailed notes of reviewer's findings
- Always close tmux panes after each round to keep the workspace clean
- Decide split direction fresh at every spawn — a direction that was right for the builder may be wrong for the reviewer once the layout has changed
- If `pick-split.sh` reports the terminal is too small, tell the user rather than forcing a cramped split
- If `pick-split.sh` notes the window is zoomed, tell the user their view will unzoom before spawning
