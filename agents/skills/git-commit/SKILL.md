---
name: git-commit
_description: Create well-formed git commits following conventional commit standards. Use this skill whenever the user asks to commit changes, create a commit, make a git commit, or needs help crafting commit messages. This skill provides git status/diff context and guides users through creating atomic, descriptive commits.
---

# Git Commit Skill

## Overview

This skill helps users create well-formed git commits by providing context about current changes and guiding them through the commit message creation process following conventional commit standards.

## When to Use

- User asks to commit changes
- User needs help creating a git commit
- User wants guidance on commit message format
- User mentions "git commit" or related phrases

## Workflow

### 1. Gather Context

First, gather information about the current repository state:

```bash
# Get current git status
git status --porcelain

# Get detailed changes
git diff

# Get recent commit history
git log --oneline -5
```

### 2. Analyze Changes

Review the output to understand:

- What files have been modified
- What changes were made (from diff)
- Recent commit patterns and style

### 3. Craft Commit Message

Create a commit message following these guidelines:

**Format:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Rules:**

- Use present tense ("add feature" not "added feature")
- Keep subject line under 50 characters
- Separate subject from body with blank line
- Explain what and why, not how
- Reference issue numbers if applicable

**Common Types:**

- feat: A new feature
- fix: A bug fix
- docs: Documentation changes
- style: Code style changes (formatting, missing semicolons)
- refactor: Code refactoring
- perf: Performance improvements
- test: Adding or updating tests
- chore: Maintenance tasks

### 4. Execute Commit

```bash
# Stage appropriate files
git add <files>

# Create commit with crafted message
git commit -m "<commit_message>"
```

## Output Format

**Silent Mode:** Only output the git commands and their results. Do NOT provide explanations, documentation, or commentary.

Example output:

```
$ git add src/main.py tests/test_main.py
$ git commit -m "feat(auth): implement JWT-based authentication

- Add JWT token generation and validation
- Include comprehensive test coverage
- Fixes #123"
```

## Important Constraints

1. **Do NOT run** `git status`, `git diff`, or `git log` commands manually - use the context provided
2. **Only use** `git add` and `git commit` commands
3. **Follow silent mode** - no explanations or commentary
4. **Create atomic commits** - only stage relevant files for this specific change

## Examples

**Example 1: Feature Addition**

```
$ git add src/api.py src/models.py
$ git commit -m "feat(api): add user profile endpoint

- Implement GET /api/users/{id}/profile
- Add UserProfile model and serializer
- Include request validation"
```

**Example 2: Bug Fix**

```
$ git add src/utils.py tests/test_utils.py
$ git commit -m "fix(utils): handle null values in string parser

- Add null check before string parsing
- Update tests to cover edge cases
- Fixes #456"
```

## Best Practices

1. **Atomic Commits:** Each commit should represent a single logical change
2. **Descriptive Messages:** Explain the purpose and impact of changes
3. **Consistent Style:** Follow the repository's existing commit message patterns
4. **Reference Issues:** Include issue/ticket numbers when applicable

