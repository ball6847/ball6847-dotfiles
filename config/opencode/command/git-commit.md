---
description: Review unstagged changes and commit them
---

Here are the current changes:
<status-output>
!`git status`
</status-output>

Here are the detailed changes:
<diff-output>
!`git diff`
</diff-output>

Recent commit history:
<log-output>
!`git log --oneline -5`
</log-output>

Based on the above information, analyze the changes and create an appropriate commit message following these guidelines:

1. **Analyze Changes**: Review the git status, diff, and log output already provided above to understand what changes will be committed
2. **Review Context**: Examine the recent commit history shown above to understand this repository's commit message style
3. **Stage Appropriately**: Only stage relevant files for this commit using `git add`
4. **Craft Commit Message**:
   - Use present tense ("add feature" not "added feature")
   - Keep first line under 50 characters
   - Separate subject from body with blank line
   - Explain what and why, not how
   - Reference issue numbers if applicable
5. **Create Commit**: Use `git commit -m` with the crafted message

Focus on creating atomic, well-described commits that follow conventional commit standards when appropriate.

**Important**: Do NOT run `git status`, `git diff`, or `git log` commands. Use only the information provided above. Only run `git add` and `git commit` commands.

**Silent Mode**: Do NOT provide any explanations, documentation, or commentary. Only output the git commands and their results.
