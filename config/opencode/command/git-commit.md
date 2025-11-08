---
description: Review unstagged changes and commit them
---

Here are the current changes:
!`git status`

Here are the detailed changes:
!`git diff`

Recent commit history:
!`git log --oneline -5`

Based on the above information, analyze the changes and create an appropriate commit message following these guidelines:

1. **Analyze Changes**: Understand what changes will be committed from the git status and diff output
2. **Review Context**: Examine recent commit history to understand commit message style
3. **Stage Appropriately**: Only stage relevant files for this commit using `git add`
4. **Craft Commit Message**:
   - Use present tense ("add feature" not "added feature")
   - Keep first line under 50 characters
   - Separate subject from body with blank line
   - Explain what and why, not how
   - Reference issue numbers if applicable
5. **Create Commit**: Use `git commit -m` with the crafted message
6. **Verify**: Run `git status` to confirm commit succeeded

Focus on creating atomic, well-described commits that follow conventional commit standards when appropriate.
