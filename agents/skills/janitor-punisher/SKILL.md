---
name: janitor-punisher
description: Bulk-resolve AI review discussions on GitLab merge requests. Use this skill when the user wants to mass-resolve discussions, clean up AI bot comments, remove spam reviews, or batch resolve merge request threads. Also trigger when user mentions "resolve discussions", "bulk resolve", "mass resolve", "clean up AI reviews", "remove bot comments", "gitlab MR cleanup", or similar phrases related to managing GitLab merge request discussions.
---

# Janitor Punisher

Bulk-resolve AI review discussions on GitLab merge requests. This skill helps you clean up merge requests by automatically resolving all discussions from specified authors (e.g., AI review bots like 7Sol_Janitor, GitLabDuo).

## When to Use This Skill

- You have dozens or hundreds of AI-generated review discussions to resolve
- A bot has spammed your merge request with excessive comments
- You want to clean up outdated or irrelevant AI review threads
- You need to batch-resolve discussions from a specific reviewer
- Your merge request is cluttered with low-quality automated reviews

## Prerequisites

### 1. GitLab CLI (glab) Installed and Authenticated

**Check if glab is installed:**
```bash
glab --version
```

**If not installed, install it:**

**macOS:**
```bash
brew install glab
```

**Linux:**
```bash
curl -sL https://j.mp/glab-cli | sudo bash
```

**Or download from:** https://gitlab.com/gitlab-org/cli/-/releases

**Authenticate glab:**
```bash
glab auth login
```

Follow the prompts to authenticate with your GitLab account.

### 2. Merge Request URL

You need the full GitLab merge request URL. It should look like:
```
https://gitlab.com/owner/project/-/merge_requests/123
```

**How to get your MR URL:**

1. Open your merge request in GitLab web interface
2. Copy the full URL from your browser address bar
3. The URL format must be: `https://gitlab.com/<project-path>/-/merge_requests/<number>`

**Examples of valid MR URLs:**
- `https://gitlab.com/seven-solutions/checkinplus/availability-rates-inventory-api/-/merge_requests/56`
- `https://gitlab.com/my-team/backend-service/-/merge_requests/42`
- `https://gitlab.com/company/project/subproject/-/merge_requests/100`

## Usage Instructions

### Step 1: Ask User for Required Information

Before running the script, you must collect:

1. **Merge Request URL** (REQUIRED)
   - Ask: "Please provide the GitLab merge request URL you want to clean up"
   - Wait for the user to provide the URL
   - Validate it matches the format: `https://gitlab.com/<project>/-/merge_requests/<number>`

2. **Author Filter** (OPTIONAL)
   - Default author: `7Sol_Janitor`
   - Ask: "Which author's discussions should I resolve? (default: 7Sol_Janitor, or specify another like 'GitLabDuo')"
   - If user doesn't specify, use the default

### Step 2: Verify Prerequisites

**Check glab is installed:**
```bash
which glab || echo "glab not found"
```

If glab is not installed, provide installation instructions (see Prerequisites section above) and **STOP** - do not proceed until glab is installed.

**Check glab is authenticated:**
```bash
glab auth status
```

If not authenticated, instruct the user to run `glab auth login` and **STOP**.

### Step 3: Confirm with User

Show a summary of what will happen:

```
I will resolve all unresolved discussions from [AUTHOR] on:
  MR: [MR_URL]
  
This will mark all discussions from this author as "resolved" in GitLab.
The discussions will still be visible but marked as resolved.

Do you want to proceed? (yes/no)
```

Wait for explicit user confirmation before proceeding.

### Step 4: Execute the Script

The bundled script is located at: `scripts/resolve_discussions.sh`

Run it with:
```bash
./scripts/resolve_discussions.sh "<MR_URL>" "<AUTHOR>"
```

**Example:**
```bash
./scripts/resolve_discussions.sh "https://gitlab.com/seven-solutions/checkinplus/availability-rates-inventory-api/-/merge_requests/56" "7Sol_Janitor"
```

### Step 5: Interpret Results

The script will output:
- Number of pages fetched
- Number of discussions found per page
- Total discussions to resolve
- Progress as each discussion is resolved
- Final summary (Resolved: X, Failed: Y)

**If successful:**
```
==========================================
Done! Resolved: 73, Failed: 0
==========================================
```

**If some failed:**
```
==========================================
Done! Resolved: 70, Failed: 3
==========================================
```

Report the results to the user and explain any failures.

## What the Script Does

1. **Parses the MR URL** to extract project path and MR ID
2. **Fetches all discussions** from the merge request (handles pagination automatically)
3. **Filters discussions** by author (default: 7Sol_Janitor)
4. **Filters for unresolved** discussions only
5. **Resolves each discussion** using `glab mr note --resolve`
6. **Reports results** showing how many were resolved vs failed

## Safety Notes

- The script only resolves discussions, it doesn't delete them
- Resolved discussions remain visible in GitLab's "Show resolved" view
- You can unresolve discussions later if needed via GitLab web UI
- The script is idempotent - running it multiple times is safe

## Troubleshooting

### "glab: command not found"
Install glab CLI (see Prerequisites).

### "glab: HTTP 401" or authentication errors
Run `glab auth login` to authenticate.

### "Invalid GitLab MR URL format"
Ensure the URL matches exactly: `https://gitlab.com/<project>/-/merge_requests/<number>`

### No discussions found
- Check that the MR has discussions from the specified author
- Verify the author username is correct (case-sensitive)
- Check that discussions are not already resolved

### Some discussions failed to resolve
- The discussion may have been deleted or modified during script execution
- You may not have permission to resolve that discussion
- The note ID may have changed

## Alternative: Manual Resolution

If you prefer not to use the script, you can resolve discussions manually:

1. Use glab to list discussions:
   ```bash
   glab mr view <MR_ID> --comments
   ```

2. Resolve individual discussions:
   ```bash
   glab mr note <MR_ID> --resolve <NOTE_ID>
   ```

However, for bulk operations with many discussions, the script is strongly recommended.

## Script Location

The resolution script is bundled with this skill at:
```
scripts/resolve_discussions.sh
```

You can copy this script to your project or run it directly from the skill bundle.
