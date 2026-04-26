---
name: dev-story-orchestrator
_description: Orchestrate batch implementation of multiple user stories by delegating /dev-story workflows to a general subagent. Use when the user wants to "start implementation for all user stories", "implement all stories", "batch dev-story", "run dev-story on multiple stories", or "implement stories one-by-one". This skill is the orchestrator that delegates actual implementation work to subagents.
allowed-tools: Read, Glob, Bash, Task, TodoWrite
---

# Dev Story Orchestrator

**Purpose:** Batch orchestrator for implementing multiple user stories through BMAD's `/dev-story` workflow, delegating actual implementation to a `general` subagent while the main agent coordinates.

## When to Use This Skill

Use this skill when:
- User says "start implementation for all user stories"
- User wants to "implement all stories" or "batch dev-story"
- User asks to "run dev-story on multiple stories" or "implement stories one-by-one"
- Multiple story files exist in `docs/stories/` and need implementation
- User wants to delegate dev-story workflows to subagents

## Core Principle: Orchestrator, Not Implementer

**You are the orchestrator, NOT the implementer.** Your job is to:
1. Discover all user stories that need implementation
2. Delegate each story's `/dev-story` workflow to a `general` subagent
3. Coordinate and track progress
4. Report status and results

**You do NOT implement the stories yourself.** Always delegate to the `general` subagent.

## Workflow

### Step 1: Discover User Stories

Find all story files in the project:

```bash
# Find all story files in docs/stories/ directory
glob "docs/stories/*.md"
glob "docs/stories/**/*.md"
```

Common story file patterns:
- `docs/stories/STORY-*.md`
- `docs/stories/*.md`
- `docs/stories/**/*.md`

### Step 2: Prioritize Stories

Read each story file and extract:
- Story ID (e.g., STORY-123, US-456)
- Title
- Priority/severity (if specified)
- Dependencies

**Prioritization order:**
1. Priority: High → Medium → Low
2. Dependencies: Stories with no dependencies first
3. Creation order (if no other indicators)

### Step 3: Create Execution Plan

Use `TodoWrite` to track all stories:

```yaml
Stories to implement:
  - [ ] STORY-001: [Title]
  - [ ] STORY-002: [Title]
  - [ ] STORY-003: [Title] (depends on STORY-001)
  ...
```

### Step 4: Delegate to Subagent (One-by-One)

For each story, delegate to a `general` subagent:

**Subagent Task:**
```
Task: Implement user story using BMAD /dev-story workflow
Story: STORY-XXXX - [Story Title]
Story file: [path/to/STORY-XXXX.md]

Instructions:
1. Read the story file at [path/to/STORY-XXXX.md]
2. Load the bmad-orchestrator skill
3. Execute /dev-story for STORY-XXXX
4. Follow the full dev-story workflow to implement this story
5. Report completion status and any issues

IMPORTANT: Complete the full implementation of this story.
Do not return until dev-story workflow is finished.
```

**Launch one subagent per story sequentially** (not in parallel), as dev-story workflows may have dependencies and conflicts.

### Step 5: Track Progress

Update TodoWrite as each story completes:
- Mark stories as complete
- Note any blockers or issues
- Track partial completions

### Step 6: Report Results

After all stories complete, report:
- Total stories processed
- Successfully implemented
- Blocked/failed
- Any issues encountered
- Next steps

## Subagent Delegation Template

```
Task: Run /dev-story for [STORY-ID]

Story file: [full path to story file]
Story ID: [STORY-ID]
Story title: [title from file]

Steps:
1. Read the story file to understand requirements
2. Load the bmad-orchestrator skill
3. Run `/dev-story STORY-ID` (or `/dev-story` and provide STORY-ID when prompted)
4. Follow the complete dev-story workflow
5. Implement all acceptance criteria
6. Report status when complete

Remember: You are the implementer. Complete the full dev-story workflow.
```

## Error Handling

**Story file not found:**
- Report missing story
- Skip and continue with next

**Subagent fails:**
- Log the failure reason
- Mark story as blocked
- Continue with independent stories
- Report dependency issues

**BMAD not initialized:**
- Check for `bmad/config.yaml`
- If missing, suggest running `/workflow-init` first
- Do NOT initialize BMAD yourself

## Integration Notes

This skill works with:
- `bmad-orchestrator` - The target skill loaded by subagents
- `/dev-story` command - The workflow executed by subagents
- `general` subagent - The agent type that performs actual implementation

## Example Interaction

```
User: implement all stories

Orchestrator:
  I'll help you implement all user stories. Let me first discover what stories exist...

  [Discovers 5 stories: STORY-001 through STORY-005]

  Found 5 stories to implement:
  1. STORY-001: User login (High priority)
  2. STORY-002: Dashboard view (Medium priority, depends on STORY-001)
  3. STORY-003: Profile settings (Medium priority)
  4. STORY-004: Logout (Low priority, depends on STORY-001)
  5. STORY-005: Password reset (High priority)

  Processing order: STORY-001 → STORY-005 → STORY-003 → STORY-002 → STORY-004

  Starting implementation...

  [Delegates each story to general subagent one-by-one]

  ✅ All stories completed:
  - STORY-001: ✓ Implemented
  - STORY-005: ✓ Implemented
  - STORY-003: ✓ Implemented
  - STORY-002: ✓ Implemented
  - STORY-004: ✓ Implemented
```

## Quick Reference

- **Discover:** `glob "docs/stories/**/*.md"`
- **Delegate:** Use `Task` tool with `subagent_type: "general"`
- **Command:** `/dev-story STORY-ID`
- **Skill:** `bmad-orchestrator`
- **Mode:** Sequential (one story at a time)

## Notes for Claude

- Always be the orchestrator, never the implementer
- Delegate actual work to `general` subagent
- Process stories sequentially, not in parallel
- Update progress tracking after each story
- Report clear completion status
