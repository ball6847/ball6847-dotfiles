---
name: builder
description: Implements features or fixes according to a predefined plan, creating implementation reports with timestamps and bidirectional links to plans. Updates plan's implementedAt field upon completion. Generates reports in `.context/implementation-reports/YYYY-MM-DD/FEATURE_NAME_REPORT.md` format.
user-invocable: true
---

# Build Skill

## Instructions

Implement features or fixes according to a predefined plan, **using a Test-Driven Development (TDD) workflow**. Focus on writing clean, maintainable code that follows the project's architecture and coding standards.

### Workflow

Follow this TDD cycle for every testable package:

1. **Read the Plan** - Start by reading the plan file specified by the user
2. **Write Tests First** — For each testable unit, write tests that define expected behavior, edge cases, and error paths. Tests MUST be written before implementation.
   - Follow the project's standard test conventions (table-driven, arrange-act-assert, etc.)
   - Tests should FAIL at this point (since implementation doesn't exist yet) — this is expected
3. **Write Implementation** — Implement the code to make all tests pass
   - Write the minimum code needed to pass tests
4. **Run Tests** — Execute the project's standard test runner to verify everything passes
   - If tests fail, fix implementation until green
5. **Refactor** — Clean up code while keeping tests green
6. **Update Plan** — Upon successful completion, update the plan's `implementedAt` timestamp
7. **Create Report** — If obstacles are encountered, create an implementation report

### Test Requirements

- **Tests are mandatory** for all testable logic units (functions, methods, pure logic packages, etc.)
- **UI/GUI code** (interactive prompts, visual components) may be harder to unit test; skip if mocking the framework is impractical, but document why
- **Never skip tests** for pure logic just to save time — tests are a deliverable
- **Do NOT commit or push** — the builder does not run git operations
- Consult `AGENTS.md` for language-specific test conventions and frameworks

### Plan Linking

After successful implementation:

1. Update the plan file's frontmatter to set `implementedAt`:

```yaml
---
createdAt: "2026-04-03T10:30:00Z"
implementedAt: "2026-04-03T14:45:00Z"
reviewedAt: null
---
```

2. Add an "Implementation" section at the end of the plan linking to the report (if created):

```markdown
## Implementation

- **Status**: Completed
- **Reports**:
  - [Implementation Report](../implementation-reports/YYYY-MM-DD/FEATURE_NAME_REPORT.md) (if applicable)
```

### Implementation Reports

Create an implementation report **only if**:

- Obstacles blocked completion of planned tasks
- Deviations from the plan were required
- Further decisions from the manager are needed

#### Report File Path

Reports must be saved to:

```
.context/implementation-reports/YYYY-MM-DD/FEATURE_NAME_REPORT.md
```

Where:

- `YYYY-MM-DD` is the current date with leading zeros (e.g., `2026-04-03`)
- `FEATURE_NAME_REPORT.md` is the report name in UPPER_SNAKE_CASE followed by `_REPORT.md`

#### Required Frontmatter

Every report must include:

```yaml
---
createdAt: "YYYY-MM-DDTHH:mm:ssZ"
planPath: "../plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md"
---
```

- `createdAt`: ISO 8601 timestamp when the report is created (also marks when implementation was completed)
- `planPath`: Relative path back to the original plan file

#### Report Structure

```markdown
---
createdAt: "2026-04-03T14:45:00Z"
planPath: "../plans/2026-04-03/FEATURE_NAME_PLAN.md"
---

# Implementation Report: [Feature Name]

## Summary

[Brief summary of what was implemented and what was blocked]

## Completed Items

- [x] Item 1 from plan
- [x] Item 2 from plan

## Obstacles

### [Obstacle Title]

**Expected**: What the plan specified

**Actual**: What happened during implementation

**Impact**: How this affects the implementation

**Decision Needed**: What needs manager input

## Deviations from Plan

| Plan Item | Deviation        | Reason            |
| --------- | ---------------- | ----------------- |
| Item 1    | Changed approach | Reason for change |

## Next Steps

1. [Step needed to resolve obstacles]
2. [Step needed to complete remaining work]

## Related Links

- Original Plan: [Plan](../plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md)
```

### Example

See existing reports in `.context/implementation-reports/` for reference examples.
