---
name: glab-resolve-discussion
description: Resolve GitLab merge request discussions using the glab CLI. Use this skill when the user wants to resolve, mark as resolved, close, or dismiss one or more discussions/comments/threads on a GitLab MR. Trigger on phrases like "resolve discussion", "mark as resolved", "resolve this comment", "close thread", "resolve MR feedback", or "resolve all discussions". Also trigger when the user asks to resolve discussions after fixing review comments, even if they don't use the word "resolve".
---

# GitLab Resolve Discussion Skill

Helps resolve one or more discussions on a GitLab merge request.

## Workflow

### Step 1: Identify the MR

Get the MR number for the current branch:

```bash
glab mr list
```

Look for the MR associated with the current branch in the output. Extract the MR number (e.g. `!117` → `117`).

### Step 2: Fetch Unresolved Discussions

Fetch all resolvable, unresolved discussions:

```bash
glab api "projects/:id/merge_requests/<MR_NUMBER>/discussions" | jq -r '
  .[] | select(.resolvable == true and .resolved == false) |
  "\(.notes[0].id)\t\(.notes[0].body | .[0:120] | gsub("\n";" "))"
'
```

This outputs lines in the format:

```
<NOTE_ID>   <first 120 chars of discussion body>
```

**Important:** The `NOTE_ID` here is the **numeric** note ID (e.g. `3211546987`), NOT the discussion string ID. Only the numeric note ID works with the resolve command.

### Step 3: Present to User (if no specific discussion given)

Display the list in human-readable format, numbered for easy selection:

```
Unresolved discussions in MR !<NUMBER>:

1. [3211546987] Remove this commented-out debug code before merging.
2. [3211546996] Missing error handling for fetch failures and invalid JSON responses...
3. [3211547010] `Number(ServerEnv.STRAPI_CACHE_TTL)` will return `NaN` if the environment...
4. [3211547029] The `path` parameter is user-controlled and directly concatenated into...
5. [3211547039] String comparison for boolean values is fragile. If the environment...
6. [3211547049] The Redis connection is initiated at module load time, which may cause...
```

Then ask the user which discussions to resolve:

- "all" → resolve all
- numbers like "1, 3, 5" → resolve those specific ones
- a description/keyword → match and resolve the closest one

### Step 4: Resolve

For each selected discussion, run:

```bash
glab mr note <MR_NUMBER> --resolve <NOTE_ID>
```

Confirm each one as it resolves:

```
✓ Resolved: Remove this commented-out debug code before merging.
✓ Resolved: Missing error handling for fetch failures...
```

## Key Technical Notes

- **`--resolve` takes numeric note ID** — use `notes[0].id` (integer like `3211546987`), not the discussion string ID (hex like `4f3f266fb8...`)
- The `--resolve` flag is deprecated but still works; the newer syntax is `glab mr note resolve <discussion-id> <MR_NUMBER>` but it uses the string discussion ID which is less reliable
- If `jq` is not available, use Python: `python3 -c "import json,sys; [print(n['notes'][0]['id'], n['notes'][0]['body'][:120]) for n in json.load(sys.stdin) if n.get('resolvable') and not n.get('resolved')]"`
- System notes (commit notifications, etc.) have `resolvable: false` — they are automatically excluded

## Handling Edge Cases

**No unresolved discussions:**

```
✓ No unresolved discussions found in MR !<NUMBER>.
```

**Can't find MR for current branch:**
Ask the user to provide the MR number directly.

**Resolve fails:**
Show the error and suggest checking authentication with `glab auth status`.
