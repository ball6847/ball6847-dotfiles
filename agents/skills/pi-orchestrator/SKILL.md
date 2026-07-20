---
name: pi-orchestrator
description: Orchestrates build-review cycles by delegating tasks to builder and reviewer pi instances using the pi-tmux-agent skill. Implements a plan with automated quality gates, looping until reviewer passes or maximum 3 rounds reached. Use whenever you need end-to-end plan execution with quality assurance — especially when the user mentions orchestrating, delegating to builder/reviewer, running a plan through build and review, or wants agents working side by side.
user-invocable: true
---

# Pi Orchestrator Skill

## Instructions

Coordinate build-review cycles to implement a plan by delegating to builder and reviewer pi instances. This skill ensures implementations pass review before completion. It uses the **pi-tmux-agent** skill to spawn each agent in its own tmux pane with smart layout decisions.

### Prerequisites

- A plan file must exist at `.context/plans/YYYY-MM-DD/FEATURE_PLAN.md`
- The **pi-tmux-agent** skill is available (used for spawning and managing panes)

### Workflow

Execute the following loop, up to 3 rounds:

```
Round 1:
  1. Spawn builder agent (via pi-tmux-agent) -> Implement the plan
  2. Capture builder result -> Check for completion
  3. Spawn reviewer agent (via pi-tmux-agent) -> Verify implementation
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Continue to Round 2

Round 2 (if needed):
  1. Spawn builder agent (via pi-tmux-agent) -> Fix issues from review
  2. Capture builder result -> Check for completion
  3. Spawn reviewer agent (via pi-tmux-agent) -> Verify fixes
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Continue to Round 3

Round 3 (if needed):
  1. Spawn builder agent (via pi-tmux-agent) -> Final attempt to fix issues
  2. Capture builder result -> Check for completion
  3. Spawn reviewer agent (via pi-tmux-agent) -> Verify fixes
  4. Capture reviewer result -> Check verdict
  5. Check verdict:
     - If PASS -> Close panes, report success
     - If PARTIAL/FAIL -> Close panes, summarize issues
```

### Maximum Rounds

- **Maximum**: 3 rounds
- After 3 rounds without reviewer returning PASS, stop and provide issue summary

### Spawning Agents

Use the **pi-tmux-agent** skill to spawn both builder and reviewer panes. For each spawn:

1. The pi-tmux-agent skill decides the optimal split target and direction automatically
2. It captures the new pane's stable id (`%N`) directly from tmux
3. You send the prompt template (see below) to the new pane

Keep track of the pane ids in variables — `BUILDER_PANE`, `REVIEWER_PANE` — so they can be polled and closed reliably.

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

After the round completes (success or failure), close both worker panes by id using the pi-tmux-agent cleanup procedure. Tolerate panes that already exited:

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
- The pi-tmux-agent skill handles split decisions — trust its `pick-split.sh` helper
