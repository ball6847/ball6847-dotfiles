---
name: pi-orchestrator
description: Orchestrates build-review cycles by delegating tasks to builder and reviewer pi instances using the pi-tmux-agent skill. Implements a plan with automated quality gates, looping until reviewer passes or maximum 3 rounds reached. Use whenever you need end-to-end plan execution with quality assurance — especially when the user mentions orchestrating, delegating to builder/reviewer, running a plan through build and review, or wants agents working side by side.
user-invocable: true
---

# Pi Orchestrator Skill

## Instructions

Coordinate build-review cycles to implement a plan by delegating to builder and reviewer pi instances. This skill ensures implementations pass review before completion.

**Do not manage tmux yourself.** For every agent run (builder or reviewer), use the **pi-tmux-agent** skill only. That skill owns pane layout, spawning pi, waiting until the agent finishes, capturing output, and cleanup. Never call `tmux split-window`, `send-keys`, `capture-pane`, or `kill-pane` from this skill.

### Prerequisites

- A plan file must exist at `.context/plans/YYYY-MM-DD/FEATURE_PLAN.md`
- The **pi-tmux-agent** skill is available

### Workflow

Execute the following loop, up to 3 rounds. Each agent step is a single **pi-tmux-agent** invocation that blocks until that agent is done, then returns its output.

```
Round 1:
  1. Run builder via pi-tmux-agent (implement the plan)
  2. Read builder output -> check for completion
  3. Run reviewer via pi-tmux-agent (verify implementation)
  4. Read reviewer output -> check verdict
  5. Check verdict:
     - If PASS -> report success
     - If PARTIAL/FAIL -> Continue to Round 2

Round 2 (if needed):
  1. Run builder via pi-tmux-agent (fix issues from review)
  2. Read builder output -> check for completion
  3. Run reviewer via pi-tmux-agent (verify fixes)
  4. Read reviewer output -> check verdict
  5. Check verdict:
     - If PASS -> report success
     - If PARTIAL/FAIL -> Continue to Round 3

Round 3 (if needed):
  1. Run builder via pi-tmux-agent (final attempt to fix issues)
  2. Read builder output -> check for completion
  3. Run reviewer via pi-tmux-agent (verify fixes)
  4. Read reviewer output -> check verdict
  5. Check verdict:
     - If PASS -> report success
     - If PARTIAL/FAIL -> summarize issues
```

Run builder and reviewer **sequentially** (builder fully finishes before reviewer starts). Do not parallelize them within a round unless the user explicitly asks.

### Maximum Rounds

- **Maximum**: 3 rounds
- After 3 rounds without reviewer returning PASS, stop and provide issue summary

### Running Agents (via pi-tmux-agent)

Follow the **pi-tmux-agent** skill for how to invoke the agent. Pass the builder or reviewer prompt (templates below) as the prompt. Use the skill's returned stdout as that agent's result — do not poll panes or scrape tmux yourself.

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

### Checking Review Verdict

After the reviewer finishes, inspect the **pi-tmux-agent** output for the verdict:

- **PASS**: "Review complete. Verdict: PASS" or "Verdict: PASS"
- **PARTIAL/FAIL**: "Verdict: PARTIAL" or "Verdict: FAIL" or missing PASS

**The round is PASSED only when the reviewer returns PASS.**

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
- **Never manage tmux directly** — always use the **pi-tmux-agent** skill for agent runs (spawn, wait, output, cleanup)
- **No subagents inside a tmux-agent session.** Once a pi-tmux-agent session has started, do **not** spawn another subagent (builder, reviewer, or any other pi instance) from within that session. The session is a single-agent boundary — nested agent runs corrupt output capture and break the completion contract.
