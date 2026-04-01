---
name: glab-fetch-discussion
description: Fetch and summarize GitLab merge request discussions/comments. Use when user asks about MR comments, discussions, notes, feedback, or reviews on a merge request. Triggers on phrases like "fetch discussions", "get MR comments", "show merge request feedback", "what are the comments on MR", or when user mentions GitLab MR review feedback.
---

# GitLab Merge Request Discussion Fetcher

Fetches and summarizes merge request discussions using the GitLab CLI (`glab`).

## Prerequisites

- `glab` CLI installed and authenticated
- Running from within a GitLab project repository

## Workflow

### Step 1: Identify the MR

First, determine which MR to fetch:

1. If user provides MR number directly, use it
2. If user is on a feature branch, find the open MR for that branch
3. If unclear, list open MRs and ask user to specify

**Commands:**
```bash
# View current branch
git branch --show-current

# List open MRs (use DEBUG=1 if blank output)
DEBUG=1 glab mr list --state opened

# Find MR for current branch via API
glab api "projects/:id/merge_requests?state=opened" | grep -A5 '"source_branch":"<branch-name>"'
```

### Step 2: Fetch Discussions

**Primary command (works in most cases):**
```bash
glab mr view <MR_NUMBER> --comments
```

**If blank output, try:**
```bash
DEBUG=1 glab mr view <MR_NUMBER> --comments
```

The `--comments` flag is **required**. Without it, only basic MR info is shown.

### Step 3: Alternative Methods (if glab fails)

If `glab mr view` doesn't work, use the GitLab API:

```bash
# Fetch notes (comments)
glab api "projects/:id/merge_requests/<MR_IID>/notes"

# Fetch discussions (threaded comments)
glab api "projects/:id/merge_requests/<MR_IID>/discussions"
```

**Important:** Always quote URLs with `?` to avoid shell globbing issues:
```bash
# Good - quoted
glab api "projects/:id/merge_requests/117/notes"

# Bad - will fail with "no matches found"
glab api projects/:id/merge_requests/117/notes
```

## Output Format

Summarize the discussions in this format:

```
## MR !<NUMBER> Summary

**Title:** <MR title>
**Status:** <state>, <count> comments

### Review Feedback:

1. **<Topic>** - <Summary of comment>
2. **<Topic>** - <Summary of comment>
...
```

Group related comments by topic. Include code suggestions if present.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `glab` not found | Install: `snap install glab` or check `which glab` |
| No output from glab | Add `DEBUG=1` prefix to see what's happening |
| "no matches found" error | Quote the URL (zsh globbing issue) |
| Authentication error | Run `glab auth login` or check with `glab repo view` |
| Can't find MR | Verify MR exists: `glab mr view <NUMBER> --web` |

## Quick Reference

| Task | Command |
|------|---------|
| View MR with comments | `glab mr view <NR> --comments` |
| View with debug | `DEBUG=1 glab mr view <NR> --comments` |
| List open MRs | `glab mr list --state opened` |
| Open in browser | `glab mr view <NR> --web` |
| Check auth | `glab repo view` |
| API: notes | `glab api "projects/:id/merge_requests/<NR>/notes"` |
| API: discussions | `glab api "projects/:id/merge_requests/<NR>/discussions"` |
