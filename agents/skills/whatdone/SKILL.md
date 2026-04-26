---
name: whatdone
_description: Retrieve GitLab activity (commits/MRs) from yesterday/last week. Triggers on questions like "What have I done yesterday?" or slash commands "/whatdone", "/wd". Requires confirmation for conversational triggers, but slash commands proceed directly to time selection.
---

# WhatDone Skill

This skill helps users retrieve their GitLab activity (commits and merge requests) from yesterday or last week using the glab CLI tool.

## When to Use

Use this skill when the user asks questions about their recent GitLab activity:

- "What have I done yesterday?"
- "What did I accomplish last week?"
- "Show me my recent work"
- "What were my contributions yesterday?"
- "What did I work on last week?"
- "Show me my GitLab activity from yesterday"
- "/whatdone"
- "/wd"

## Confirmation Rules

### Confirmation Rules

#### Conversational Triggers
For questions about recent work (e.g., "What have I done yesterday?", "Show me my recent work"), ALWAYS ask for user confirmation before proceeding. The confirmation should:
- Explain what will be retrieved (GitLab activity)
- Offer time range options (yesterday/last week)
- Include a cancel option

#### Slash Command Triggers
For explicit commands ("/whatdone", "/wd"), skip confirmation and proceed directly to retrieve activity from yesterday (default) or ask for time range if needed.

#### Cancellation
If user cancels or doesn't respond, DO NOT proceed with retrieval.

### Cancellation Rule

If user selects "Cancel" or doesn't respond to confirmation, DO NOT proceed with this skill.

## Prerequisites

1. User must be authenticated with glab CLI
2. glab CLI must be installed and configured  
3. User must have appropriate permissions to access the repositories

## Workflow

### Step 0: Load glab Skill (MANDATORY)

ALWAYS load the glab skill first for accurate glab command building:

```bash
skill(name="glab")
```

This ensures all glab commands are constructed correctly and have access to proper authentication.

### Step 1: Determine Time Range

Ask the user:
"What time range would you like to see?"

Options:
- Yesterday (show activity from yesterday)
- Last week (show activity from last week)
- Other (specify custom time range)

For conversational triggers, include a cancel option:
- Cancel (don't retrieve activity)

Based on user selection:
- **Yesterday**: Proceed with yesterday's date range
- **Last week**: Proceed with last week's date range
- **Cancel**: Stop execution immediately (conversational triggers only)
- **Other**: Ask user to specify custom date range (e.g., "last 3 days", "specific date"), then calculate appropriate START_DATE and END_DATE

### Step 2: Load glab Skill

Always load the glab skill first for accurate glab command building:

```bash
skill(name="glab")
```

### Step 3: Determine Time Range

Based on user selection:

- **Yesterday**: Use date range from yesterday 00:00:00 to yesterday 23:59:59
- **Last week**: Use date range from Monday 00:00:00 to Sunday 23:59:59 of last week

Format dates in ISO 8601 format with timezone:

```bash
# For yesterday
START_DATE=$(date -d 'yesterday' +%Y-%m-%dT00:00:00Z)
END_DATE=$(date -d 'yesterday' +%Y-%m-%dT23:59:59Z)

# For last week
START_DATE=$(date -d 'last monday' +%Y-%m-%dT00:00:00Z)
END_DATE=$(date -d 'last sunday' +%Y-%m-%dT23:59:59Z)
```

### Step 4: Retrieve Merge Requests

First, detect current project path and username:

```bash
# Get current project path
CURRENT_PROJECT=$(basename $(pwd))

# Get current username from glab config
USERNAME=$(glab api /user | jq -r '.username')
AUTHOR_ID=$(glab api /user | jq -r '.id')

# Get project full path
PROJECT_PATH=$(glab api /projects/$CURRENT_PROJECT | jq -r '.path_with_namespace' 2>/dev/null || echo "$CURRENT_PROJECT")
```

Then try to find merge requests in the current project:

```bash
cd /path/to/current/project
glab mr list --author=@me --created-after="$START_DATE" --created-before="$END_DATE" --all
```

If no merge requests found, search in the seven-solutions/checkinplus group:

```bash
glab api "/groups/seven-solutions%2Fcheckinplus/merge_requests?author_id=$AUTHOR_ID&created_after=$START_DATE&created_before=$END_DATE"
```

### Step 5: Retrieve Commits

If no merge requests found, or if user wants to see commits regardless, retrieve commits:

```bash
cd /path/to/current/project
glab api "/projects/$PROJECT_PATH/repository/commits?author=$USERNAME&since=$START_DATE&until=$END_DATE"
```

### Step 6: Format Output

Present the results in a clear format:

#### For Merge Requests:

```markdown
## Merge Requests from [Yesterday/Last Week]

### Open Merge Requests

1. **Title**: [MR Title]
   - Project: [Project Name]
   - MR ID: ![MR_ID]
   - State: Opened
   - Created: [Created Date]
   - Web URL: [Web URL]

### Merged Merge Requests

1. **Title**: [MR Title]
   - Project: [Project Name]
   - MR ID: ![MR_ID]
   - State: Merged
   - Created: [Created Date]
   - Merged: [Merged Date]
   - Web URL: [Web URL]
```

#### For Commits:

```markdown
## Commits from [Yesterday/Last Week]

1. **Title**: [Commit Title]
   - Commit: [Short ID]
   - Time: [Commit Time]
   - Web URL: [Web URL]
```

### Step 7: Handle No Results

If no merge requests or commits found:

```markdown
No GitLab activity found for the specified time period.

Would you like to:

1. Try a different time range?
2. Check a specific project?
3. Cancel?
```

## Error Handling

If glab commands fail:

1. Check if user is authenticated: `glab auth status`
2. Verify glab CLI is installed and configured
3. Check network connectivity
4. Provide clear error messages to the user

## Examples

### Example 1: Yesterday's Activity

User: "What I have done yesterday?"

Agent:

1. Confirms intent
2. Loads glab skill
3. Retrieves merge requests from yesterday
4. If none found, retrieves commits from yesterday
5. Presents formatted results

### Example 2: Last Week's Activity

User: "/wd last week"

Agent:

1. Confirms intent for last week
2. Loads glab skill
3. Retrieves merge requests from last week
4. If none found, retrieves commits from last week
5. Presents formatted results

## Notes

- Always prioritize merge requests over commits when both exist
- Format dates in ISO 8601 format with timezone (YYYY-MM-DDTHH:MM:SSZ)
- Use UTC timezone for all API calls to ensure consistency
- Convert display times to local timezone for user-friendly output
- Respect user privacy - only show their own activity
- Provide web URLs for easy access to full details
- Handle pagination for large result sets (use --page and --per-page flags)
- Cache glab API responses to avoid redundant calls
