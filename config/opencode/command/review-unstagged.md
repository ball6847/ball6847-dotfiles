---
description: Review unstagged changes based on the given criteria
---

please help me review unstaged changes

spot these issues
- common mistakes
- inconsistencies
- race conditions
- concurrency controls
- nil pointers
- misleading comments
- misleading variable names
- misleading error messages
- redundant code
- unused code
- logging (must be structured logs)
- redundant logs
- structured log context size (only add necessary fields useful for filtering at dashboard to log context)

notes, please gather all information first, then analyze based on above criteria in one go

Here are the current changes:
<status-output>
!`git status`
</status-output>

Here are the files with changes:
<files-output>
!`git diff --name-only`
</files-output>

Here are the detailed changes:
<diff-output>
!`git diff`
</diff-output>
