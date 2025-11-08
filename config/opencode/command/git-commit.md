---
description: Review unstagged changes and commit them
agent: flash
---

Follow these steps to create high-quality commits:

1. **Analyze Changes**: Run `git status` and `git diff` to understand what changes will be committed
2. **Review Context**: Examine recent commit history with `git log --oneline -5` to understand commit message style
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
