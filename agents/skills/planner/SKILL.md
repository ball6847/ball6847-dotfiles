---
name: planner
description: Creates detailed implementation plans with test cases, ASCII diagrams, timestamps, and proper file naming. Use when breaking down complex tasks into actionable steps before coding. Generates plans in `.context/plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md` format with createdAt, implementedAt, and reviewedAt timestamps. Includes test cases following qa-test-planner format and ASCII sequence, state transition, and ER diagrams when relevant.
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
- Complete file contents or large code blocks (>30 lines)
- Step-by-step coding instructions that micromanage the builder

Instead, specify:

- Interfaces: function signatures, input/output types, error cases
- Behavior: what the code should do, constraints, edge cases
- References: "Follow the pattern in `src/auth/handler.go`" or
  "Use the same style as `UserRepository`"
- Snippets: short fragments for non-obvious logic like complex SQL, regex,
  or algorithm formulas. Use the **Reference Patterns** section for these.

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

Follow this structure for all plans. Sections marked [Optional] can be omitted
if not applicable.

````markdown
---
createdAt: "2026-04-03T10:30:00Z"
implementedAt: null
reviewedAt: null
---

# Plan: [Brief Description]

## Background & Context

[Why this change is needed. Include:]

- **Business Driver**: What problem or opportunity prompted this?
- **Technical Context**: Current architecture, related systems, technical debt
- **Related Decisions**: ADRs, previous discussions, rejected approaches
- **User Impact**: Who benefits and how

## Key Information

### Success Criteria

[Measurable criteria that determine when this plan is complete]

- [ ] Criterion 1
- [ ] Criterion 2

### Acceptance Criteria

[Specific conditions the implementation must satisfy]

- Given [context], when [action], then [expected result]
- Given [context], when [action], then [expected result]

### Assumptions

[Things assumed to be true but not verified]

- Assumption 1
- Assumption 2

### Constraints

[Technical or business limitations]

- Constraint 1
- Constraint 2

### Risks

[Potential issues and mitigation]

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [High/Med/Low] | [High/Med/Low] | [How to handle] |

### Dependencies

[External systems, libraries, or other work]

- Dependency 1
- Dependency 2

### Out of Scope

[Explicitly what this plan does NOT cover]

- Item 1
- Item 2

## Overview

[One concise paragraph describing: what this plan builds, which components it
modifies, and what the end-to-end behavior should be.]

## Target Structure

[If applicable, show the expected directory/file structure]

```
src/
  new_feature/
    mod.rs
    handler.rs
    types.rs
```

## Reference Patterns [Optional]

[Code examples, patterns, or snippets to guide implementation. Use only when
existing code references aren't sufficient or when demonstrating non-obvious
patterns. Keep snippets short (<30 lines).]

### Pattern: [Name]

**Reference**: `path/to/existing/file.rs`

```rust
// Brief example showing expected pattern
pub trait Validator {
    fn validate(&self) -> Result<(), ValidationError>;
}

#[derive(Debug, thiserror::Error)]
pub enum ValidationError {
    #[error("field {0} is required")]
    MissingField(String),
}
```

**Notes**: [Any context about this pattern]

## Files to Create

[List each file with detailed specifications]

### `path/to/new/file.rs`

**Purpose**: [What this file does]

**Responsibilities**:
- Responsibility 1
- Responsibility 2

**Interface**:
```rust
// Key types/functions this file must expose
pub fn process(input: Input) -> Result<Output, Error>;
```

**See Also**: Reference pattern "[Name]" in this plan, or `existing/file.rs`

## Files to Modify

[List each file with specific changes needed]

### `path/to/existing/file.rs`

**Changes Required**:

1. **Add** [what to add]
   - Location: After line X, or inside function Y
   - Details: [specification]

2. **Modify** [what to change]
   - From: [current behavior/signature]
   - To: [new behavior/signature]
   - Backward Compatible: Yes/No. If No, explain migration path.

3. **Remove** [what to remove]
   - Reason: [why it's safe to remove]

## Files to Delete [Optional]

[List files to remove after migration]

| File | Reason | Migration Notes |
|------|--------|-----------------|
| `path/to/file.rs` | [Why] | [Any required cleanup] |

## Diagrams [Optional]

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

```bash
# Run tests
cargo test

# Run linter
cargo clippy
```

## Expected Outcome

[What success looks like from user and system perspectives]

## Rollback Plan

[How to revert if issues arise]

1. [Step 1]
2. [Step 2]

## Related Links [Optional]

- [ADR-005: Use this pattern for X](./docs/adrs/005-pattern.md)
- [Design Doc](https://...)
- [Related Issue](https://...)
````

### Example

See existing plans in `.context/plans/` for reference examples.
