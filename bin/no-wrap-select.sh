#!/bin/bash
# Non-wrapping pane selection for tmux
# Usage: no-wrap-select.sh [left|right|up|down]

SESSION=$(tmux display-message -p '#S')
WINDOW=$(tmux display-message -p '#I')
DIRECTION="$1"

# Get all pane indices sorted
TARGET="$SESSION:$WINDOW"

# Use a temporary file to preserve newlines
tmpfile=$(mktemp)
tmux list-panes -t "$TARGET" -F "#{pane_index}" | sort -n > "$tmpfile"

# Get the active pane (not the current pane where the script is running)
CURRENT=$(tmux list-panes -t "$TARGET" -F "#{pane_index}#{?pane_active,ACTIVE,}" | grep "ACTIVE" | sed 's/ACTIVE//')

# Read panes into an array using read
PANE_ARRAY=()
while read -r line; do
    PANE_ARRAY+=("$line")
done < "$tmpfile"

case "$DIRECTION" in
    "left"|"up")
        # Find previous pane (don't wrap)
        for i in "${!PANE_ARRAY[@]}"; do
            if [ "${PANE_ARRAY[i]}" -eq "$CURRENT" ] && [ "$i" -gt 0 ]; then
                PREV="${PANE_ARRAY[$((i-1))]}"
                tmux select-pane -t "$TARGET.$PREV"
                rm -f "$tmpfile"
                exit 0
            fi
        done
        ;;
    "right"|"down")
        # Find next pane (don't wrap)
        for i in "${!PANE_ARRAY[@]}"; do
            if [ "${PANE_ARRAY[i]}" -eq "$CURRENT" ] && [ "$i" -lt "$((${#PANE_ARRAY[@]}-1))" ]; then
                NEXT="${PANE_ARRAY[$((i+1))]}"
                tmux select-pane -t "$TARGET.$NEXT"
                rm -f "$tmpfile"
                exit 0
            fi
        done
        ;;
esac

# Exit successfully even if no pane was selected (at edge)
rm -f "$tmpfile"
exit 0
