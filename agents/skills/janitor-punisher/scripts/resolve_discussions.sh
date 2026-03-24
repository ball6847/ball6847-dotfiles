#!/bin/bash

# Check if MR URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <merge-request-url> [author]"
  echo "Example: $0 https://gitlab.com/owner/project/-/merge_requests/123"
  echo "Example: $0 https://gitlab.com/owner/project/-/merge_requests/123 GitLabDuo"
  exit 1
fi

MR_URL="$1"
AUTHOR="${2:-7Sol_Janitor}"  # Default to 7Sol_Janitor if not provided

# Parse MR URL to extract project path and MR IID
# URL format: https://gitlab.com/<project-path>/-/merge_requests/<iid>
if [[ "$MR_URL" =~ ^https?://[^/]+/(.+)/-/merge_requests/([0-9]+) ]]; then
  PROJECT_PATH="${BASH_REMATCH[1]}"
  MR_ID="${BASH_REMATCH[2]}"
else
  echo "Error: Invalid GitLab MR URL format"
  echo "Expected: https://gitlab.com/owner/project/-/merge_requests/123"
  exit 1
fi

# URL encode project path (replace / with %2F)
ENCODED_PROJECT_PATH=$(echo "$PROJECT_PATH" | sed 's/\//%2F/g')

PER_PAGE=100

echo "Resolving discussions from:"
echo "  Project: $PROJECT_PATH"
echo "  MR ID: $MR_ID"
echo "  Author Filter: $AUTHOR"
echo ""
echo "Fetching all unresolved discussion notes..."

# Fetch all pages automatically
ALL_NOTES=""
PAGE=1

while true; do
  echo "Fetching page ${PAGE}..."
  
  # Fetch current page
  PAGE_DATA=$(glab api "projects/${ENCODED_PROJECT_PATH}/merge_requests/${MR_ID}/discussions?per_page=${PER_PAGE}&page=${PAGE}" 2>&1)
  
  # Check if page has any discussions at all
  DISCUSSION_COUNT=$(echo "$PAGE_DATA" | jq 'length')
  
  if [ "$DISCUSSION_COUNT" -eq 0 ]; then
    echo "No more pages (empty response)"
    break
  fi
  
  # Extract note IDs matching criteria
  PAGE_NOTES=$(echo "$PAGE_DATA" | jq -r "[.[] | .notes[] | select(.resolvable and (.resolved | not) and .author.username == \"${AUTHOR}\") | .id] | .[]")
  
  if [ -n "$PAGE_NOTES" ]; then
    ALL_NOTES="${ALL_NOTES}${PAGE_NOTES}
"
    echo "Found $(echo "$PAGE_NOTES" | grep -v '^$' | wc -l) notes on page ${PAGE}"
  else
    echo "No matching notes on page ${PAGE}"
  fi
  
  # If we got less than PER_PAGE discussions, this is the last page
  if [ "$DISCUSSION_COUNT" -lt "$PER_PAGE" ]; then
    echo "Reached last page"
    break
  fi
  
  ((PAGE++))
done

# Count total
TOTAL=$(echo "$ALL_NOTES" | grep -v '^$' | wc -l)

echo ""
echo "=========================================="
echo "Found $TOTAL unresolved discussions from ${AUTHOR}"
echo "=========================================="
echo ""

if [ "$TOTAL" -eq 0 ]; then
  echo "No discussions to resolve. Exiting."
  exit 0
fi

echo "Resolving discussions..."
echo ""

RESOLVED=0
FAILED=0

while IFS= read -r note_id; do
  if [ -n "$note_id" ] && [ "$note_id" != "null" ]; then
    result=$(glab mr note "$MR_ID" --resolve "$note_id" 2>&1)
    if echo "$result" | grep -q "✓"; then
      echo "✓ Resolved note $note_id"
      ((RESOLVED++))
    else
      echo "✗ Failed to resolve note $note_id"
      ((FAILED++))
    fi
  fi
done <<< "$ALL_NOTES"

echo ""
echo "=========================================="
echo "Done! Resolved: $RESOLVED, Failed: $FAILED"
echo "=========================================="
