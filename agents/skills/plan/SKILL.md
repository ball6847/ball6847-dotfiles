---
name: plan
description: Creates detailed implementation plans with timestamps and proper file naming. Use when breaking down complex tasks into actionable steps before coding. Generates plans in `.context/plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md` format with createdAt, implementedAt, and reviewedAt timestamps.
user-invocable: true
---

# Plan Skill

## Instructions

Create comprehensive implementation plans as new markdown files. Plans must be explicit and detailed enough for less capable models to work with them without requiring further technical decisions.

### File Path Format

Plans must be saved to:
```
.context/plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md
```

Where:
- `YYYY-MM-DD` is the current date with leading zeros (e.g., `2026-04-03`)
- `FEATURE_NAME_PLAN.md` is the plan name in UPPER_SNAKE_CASE followed by `_PLAN.md`

### Required Frontmatter

Every plan must include these timestamp fields in the YAML frontmatter:

```yaml
---
createdAt: "YYYY-MM-DDTHH:mm:ssZ"
implementedAt: null
reviewedAt: null
---
```

- `createdAt`: ISO 8601 timestamp when the plan is created (use current time)
- `implementedAt`: Set to `null` initially, updated when implementation is complete
- `reviewedAt`: Set to `null` initially, updated when the plan is reviewed

### Plan Structure

Follow this structure for all plans:

```markdown
---
createdAt: "2026-04-03T10:30:00Z"
implementedAt: null
reviewedAt: null
---

# Plan: [Brief Description]

## Overview

[One paragraph describing what this plan accomplishes]

## Target Structure

[If applicable, show the expected directory/file structure]

## Files to Create

[List each file with detailed specifications]

## Files to Modify

[List each file with specific changes needed]

## Files to Delete

[List files to remove after migration]

## Verification Commands

[Commands to run after implementation]

## Expected Outcome

[What success looks like]

## Rollback Plan

[How to revert if issues arise]
```

### Example

See existing plans in `.context/plans/` for reference examples.
