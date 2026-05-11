---
name: orchestrator
description: Orchestrates build-review cycles to implement a plan with automated quality gates. Delegates to builder for implementation and TWO concurrent reviewers for verification. Loops until BOTH reviewers pass or maximum rounds reached. Use when you need end-to-end plan execution with quality assurance.
user-invocable: true
---

# Orchestrator Skill

## Instructions

Coordinate build-review cycles to implement a plan with automated dual quality gates.
This skill ensures implementations pass review by TWO independent reviewers before completion.

### Workflow

Execute the following loop:

```
Round 1:
  1. Delegate to builder -> Implement the plan
  2. Delegate to reviewer #1 AND reviewer #2 concurrently -> Verify implementation
  3. Wait for BOTH reviews to complete
  4. Check combined verdict:
     - If BOTH PASS -> Done, report success
     - If ANY PARTIAL/FAIL -> Continue to Round 2

Round 2 (if needed):
  1. Delegate to builder -> Fix issues from reviews
  2. Delegate to reviewer #1 AND reviewer #2 concurrently -> Verify fixes
  3. Wait for BOTH reviews to complete
  4. Check combined verdict:
     - If BOTH PASS -> Done, report success
     - If ANY PARTIAL/FAIL -> Continue to Round 3

Round 3 (if needed):
  1. Delegate to builder -> Final attempt to fix issues
  2. Delegate to reviewer #1 AND reviewer #2 concurrently -> Verify fixes
  3. Wait for BOTH reviews to complete
  4. Check combined verdict:
     - If BOTH PASS -> Done, report success
     - If ANY PARTIAL/FAIL -> Stop, summarize issues
```

### Maximum Rounds

- **Maximum**: 3 rounds
- After 3 rounds without BOTH reviewers returning PASS, stop and provide issue summary

### Delegation Commands

**To builder:**

```
Use the Task tool with subagent_type: "builder"
Provide the plan path and any specific issues to address from previous reviews.
```

**To reviewers (concurrent):**

```
Use the Task tool TWICE with subagent_type: "reviewer"
Provide the SAME plan path to both reviewers to verify implementation against.
Both reviewers must receive identical prompts simultaneously.
```

### Checking Review Verdict

After BOTH reviewers complete, check both review reports' verdicts:

- **PASS + PASS**: Implementation matches plan, stop loop with success
- **PASS + PARTIAL/FAIL**: Some issues remain, continue to next round
- **PARTIAL + PASS/PARTIAL/FAIL**: Issues found, continue to next round
- **FAIL + ANY**: Significant issues found, continue to next round

**The round is PASSED only when BOTH reviewers return PASS.**

### Round Tracking

Track rounds explicitly in your response:

```
## Orchestrator Progress

**Current Round**: 1/3
**Status**: [Building / Reviewing (0/2) / Reviewing (1/2) / Complete]

### Round History

| Round | Build Status | Reviewer #1 | Reviewer #2 | Combined Verdict | Notes |
|-------|--------------|-------------|-------------|------------------|-------|
| 1 | Completed | PARTIAL | PASS | PARTIAL | Missing error handling in #1 |
```

### Final Reporting

**On Success (BOTH reviewers PASS):**

```markdown
## Orchestrator Complete

**Rounds Used**: X/3 **Final Status**: SUCCESS **Plan**: [link to plan]

All implementations verified against plan by both reviewers.

### Review Summary
- Reviewer #1: PASS
- Reviewer #2: PASS
```

**On Failure (3 rounds without BOTH PASS):**

```markdown
## Orchestrator Stopped

**Rounds Used**: 3/3 **Final Status**: FAILED **Plan**: [link to plan]

### Final Review Results
- Reviewer #1: [verdict]
- Reviewer #2: [verdict]

### Summary of Issues

[List all unresolved issues from both reviewers across all rounds]

### Recommendations

[Suggestions for how to proceed - manual intervention, plan revision, etc.]
```

## Important Notes

- Always start with Round 1, do not skip ahead
- Pass context from previous rounds to help agents focus on specific issues
- Do not modify the plan during orchestration
- If builder reports blocking obstacles, still proceed to dual review for visibility
- Keep detailed notes of each reviewer's findings separately
- **CRITICAL**: Both reviewers must receive the exact same prompt simultaneously
- **CRITICAL**: Wait for BOTH reviews to complete before checking verdict and proceeding
