---
name: review
description: Reviews build agent's implementation against predefined plans, creating review reports with timestamps and bidirectional links. Updates plan's reviewedAt field and generates reports in `.context/reviews/YYYY-MM-DD/FEATURE_NAME_REVIEW.md` format.
user-invocable: true
---

# Review Skill

## Instructions

Review the build agent's implementation against the predefined plan to ensure correctness and completeness. Create a review report documenting findings and update the plan with review timestamp.

### Workflow

1. **Load Inputs**
   - Read the plan file
   - Read any related implementation reports (if available)

2. **Verify Implementation**
   - Explore the codebase to check each planned change
   - Verify implementation details against plan specifications
   - Identify deviations from the planned approach

3. **Create Review Report** (if discrepancies found or review needed)
   - Document findings in a review report
   - Link to plan and implementation reports

4. **Update Plan**
   - Set the plan's `reviewedAt` timestamp
   - Add "Review" section linking to the review report

### Review Focus

- Verify all planned files were modified as specified
- Check that implementation follows the architectural approach in the plan
- Ensure no unintended changes were made
- Confirm the solution addresses the original requirements
- Check that obstacles from implementation reports were resolved

**DO NOT FIX** - Only report discrepancies between the plan and implementation.

### Critical Feedback Standards

When reviewing implementations, be direct and thorough:

- **Point out all deviations** - No matter how small, document every discrepancy from the plan
- **Question design decisions** - If implementation choices differ from the planned approach, question whether the change was justified
- **Highlight incomplete work** - Clearly mark any planned items that were skipped or partially implemented
- **Assess quality gaps** - Note missing tests, documentation, error handling, or edge cases
- **Be specific** - Provide concrete examples of what was expected vs. what was delivered
- **Rate severity** - Classify issues as blocking (must fix), concerning (should fix), or minor (nice to have)

The goal is honest, constructive criticism that improves code quality and maintains architectural integrity.

### Review Reports

Create a review report to document findings, especially when:
- Discrepancies are found between plan and implementation
- Implementation reports indicate unresolved obstacles
- Formal review documentation is needed

#### Report File Path

Reports must be saved to:
```
.context/reviews/YYYY-MM-DD/FEATURE_NAME_REVIEW.md
```

Where:
- `YYYY-MM-DD` is the current date with leading zeros (e.g., `2026-04-03`)
- `FEATURE_NAME_REVIEW.md` is the review name in UPPER_SNAKE_CASE followed by `_REVIEW.md`

#### Required Frontmatter

Every review report must include:

```yaml
---
createdAt: "YYYY-MM-DDTHH:mm:ssZ"
planPath: "../plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md"
implementationReportPaths:
  - "../implementation-reports/YYYY-MM-DD/FEATURE_NAME_REPORT.md"
---
```

- `createdAt`: ISO 8601 timestamp when the review was completed
- `planPath`: Relative path to the original plan file
- `implementationReportPaths`: List of related implementation reports (supports multiple iterations)

#### Report Structure

```markdown
---
createdAt: "2026-04-03T16:00:00Z"
planPath: "../plans/2026-04-03/FEATURE_NAME_PLAN.md"
implementationReportPaths:
  - "../implementation-reports/2026-04-03/FEATURE_NAME_REPORT.md"
---

# Review Report: [Feature Name]

## Verdict

**[PASS / PARTIAL / FAIL]**

## Summary

[Brief summary of the review findings]

## Items Verified

### Files Created

| File | Status | Notes |
|------|--------|-------|
| `path/to/file.go` | ✅ Created as planned | Matches specification |

### Files Modified

| File | Status | Notes |
|------|--------|-------|
| `path/to/file.go` | ✅ Modified as planned | Changes match specification |

### Files Deleted

| File | Status | Notes |
|------|--------|-------|
| `path/to/file.go` | ✅ Deleted as planned | N/A |

## Discrepancies

### [Discrepancy Title]

**Plan Specification**: What the plan specified

**Actual Implementation**: What was actually done

**Impact**: How this affects the implementation

**Recommendation**: Suggested fix or justification

## Obstacles Resolution

| Obstacle | Status | Resolution |
|----------|--------|------------|
| Obstacle from implementation report | ✅ Resolved | How it was resolved |

## Related Links

- Original Plan: [Plan](../plans/YYYY-MM-DD/FEATURE_NAME_PLAN.md)
- Implementation Reports:
  - [Report 1](../implementation-reports/YYYY-MM-DD/FEATURE_NAME_REPORT.md)

## Reviewer Notes

[Any additional observations or context]
```

### Plan Linking

After completing the review:

1. Update the plan file's frontmatter to set `reviewedAt`:
```yaml
---
createdAt: "2026-04-03T10:30:00Z"
implementedAt: "2026-04-03T14:45:00Z"
reviewedAt: "2026-04-03T16:00:00Z"
---
```

2. Add a "Review" section at the end of the plan linking to the review report:
```markdown
## Review

- **Status**: [PASS / PARTIAL / FAIL]
- **Reviews**:
  - [Review Report](../reviews/YYYY-MM-DD/FEATURE_NAME_REVIEW.md) (if applicable)
```

### Example

See existing review reports in `.context/reviews/` for reference examples.
