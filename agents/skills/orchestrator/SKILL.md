---
name: orchestrator
_description: Orchestrates build-review cycles to implement a plan with automated quality gates. Delegates to builder for implementation and reviewer for verification. Loops until review passes or maximum rounds reached. Use when you need end-to-end plan execution with quality assurance.
user-invocable: true
---

# Orchestrator Skill

## Instructions

Coordinate build-review cycles to implement a plan with automated quality gates.
This skill ensures implementations pass review before completion.

### Workflow

Execute the following loop:

```
Round 1:
  1. Delegate to builder -> Implement the plan
  2. Delegate to reviewer -> Verify implementation
  3. Check verdict:
     - If PASS -> Done, report success
     - If PARTIAL/FAIL -> Continue to Round 2

Round 2 (if needed):
  1. Delegate to builder -> Fix issues from review
  2. Delegate to reviewer -> Verify fixes
  3. Check verdict:
     - If PASS -> Done, report success
     - If PARTIAL/FAIL -> Continue to Round 3

Round 3 (if needed):
  1. Delegate to builder -> Final attempt to fix issues
  2. Delegate to reviewer -> Verify fixes
  3. Check verdict:
     - If PASS -> Done, report success
     - If PARTIAL/FAIL -> Stop, summarize issues
```

### Maximum Rounds

- **Maximum**: 3 rounds
- After 3 rounds without PASS, stop and provide issue summary

### Delegation Commands

**To builder:**

```
Use the Task tool with subagent_type: "builder"
Provide the plan path and any specific issues to address from previous review.
```

**To reviewer:**

```
Use the Task tool with subagent_type: "reviewer"
Provide the plan path to verify implementation against.
```

### Checking Review Verdict

After reviewer completes, check the review report's verdict:

- **PASS**: Implementation matches plan, stop loop with success
- **PARTIAL**: Some issues remain, continue to next round
- **FAIL**: Significant issues found, continue to next round

### Round Tracking

Track rounds explicitly in your response:

```
## Orchestrator Progress

**Current Round**: 1/3
**Status**: [Building / Reviewing / Complete]

### Round History

| Round | Build Status | Review Verdict | Notes |
|-------|--------------|----------------|-------|
| 1 | Completed | PARTIAL | Missing error handling |
```

### Final Reporting

**On Success (PASS verdict):**

```markdown
## Orchestrator Complete

**Rounds Used**: X/3 **Final Status**: SUCCESS **Plan**: [link to plan]

All implementations verified against plan.
```

**On Failure (3 rounds without PASS):**

```markdown
## Orchestrator Stopped

**Rounds Used**: 3/3 **Final Status**: FAILED **Plan**: [link to plan]

### Summary of Issues

[List all unresolved issues from reviews]

### Recommendations

[Suggestions for how to proceed - manual intervention, plan revision, etc.]
```

## Important Notes

- Always start with Round 1, do not skip ahead
- Pass context from previous rounds to help agents focus on specific issues
- Do not modify the plan during orchestration
- If builder reports blocking obstacles, still proceed to review for visibility
- Keep detailed notes of each round's findings
