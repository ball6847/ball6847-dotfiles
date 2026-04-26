---
name: planner
_description: Creates detailed implementation plans with test cases, ASCII diagrams, timestamps, and proper file naming. Use when breaking down complex tasks into actionable steps before coding. Generates plans in `.context/plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md` format with createdAt, implementedAt, and reviewedAt timestamps. Includes test cases following qa-test-planner format and ASCII sequence, state transition, and ER diagrams when relevant.
user-invocable: true
---

# Plan Skill

## Instructions

Create comprehensive implementation plans as new markdown files. Plans must be
explicit and detailed enough for less capable models to work with them without
requiring further technical decisions.

### Brevity Rules

Plans describe **what** to build, not **how** to code it. Do NOT include:

- Full function/method implementations
- Complete file contents or large code blocks
- Step-by-step coding instructions

Instead, specify:

- Interfaces: function signatures, input/output types, error cases
- Behavior: what the code should do, constraints, edge cases
- References: "Follow the pattern in `src/auth/handler.go`" or
  "Use the same style as `UserRepository`"
- Snippets: only short fragments (≤10 lines) for non-obvious logic like
  complex SQL, regex, or algorithm formulas

### File Path Format

Plans must be saved to:

```
.context/plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md
```

Where:

- `YYYY-MM-DD` is the current date with leading zeros (e.g., `2026-04-03`)
- `FEATURE_NAME_PLAN.md` is the plan name in UPPER_SNAKE_CASE followed by
  `_PLAN.md`

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
- `implementedAt`: Set to `null` initially, updated when implementation is
  complete
- `reviewedAt`: Set to `null` initially, updated when the plan is reviewed

### Plan Structure

Follow this structure for all plans:

````markdown
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

## Diagrams

[Include ASCII diagrams when the plan involves multi-component interactions,
state changes, or data relationships. Use only the diagram types relevant to
the plan — omit sections that add no value.]

### Sequence Diagram

[Use when: multiple services/components interact in a defined order]

```
ParticipantA    ParticipantB    ParticipantC
   |                |              |
   |--- request --->|              |
   |                |--- call ---->|
   |                |<-- result ---|
   |<-- response ---|              |
   |                |              |
```

### State Transition Diagram

[Use when: entities have discrete states with defined transitions]

```
   [Idle] --submit--> [Processing] --approve--> [Approved]
     ^                   |                         |
     |                   |fail                     |revoke
     |                   v                         v
     +-------------- [Rejected]              [Revoked]
```

### ER Diagram

[Use when: plan involves database schema, data models, or relationships]

```
User            Post            Comment
====            ====            =======
id (PK)    1--* id (PK)    1--* id (PK)
email           author_id (FK)  post_id (FK)
name            title           body
                body            created_at
                created_at
```

## Test Cases

[Generate test cases following the qa-test-planner skill format. For each
feature or change in the plan, include test cases with this structure:]

### TC-[ID]: [Test Case Title]

**Priority:** P0 | P1 | P2 | P3
**Type:** Functional | UI | Integration | Regression | Security

#### Objective

[What this test verifies and why]

#### Preconditions

- [Setup requirements]
- [Test data needed]

#### Test Steps

1. [Action to perform]
   **Expected:** [What should happen]
2. [Action to perform]
   **Expected:** [What should happen]

#### Post-conditions

- [System state after test]

[Include at minimum:

- One P0 test per critical path
- Edge case and boundary value tests
- Negative/error scenario tests
- Integration tests for cross-component changes]

## Verification Commands

[Commands to run after implementation]

## Expected Outcome

[What success looks like]

## Rollback Plan

[How to revert if issues arise]
````

### Example

See existing plans in `.context/plans/` for reference examples.
