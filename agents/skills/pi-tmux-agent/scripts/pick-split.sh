#!/usr/bin/env bash
# pick-split.sh — choose the best tmux pane to split and the direction,
# maximizing the new pane's usable space.
#
# A new tmux pane is always created by splitting an existing one, so the
# decision has two parts: which pane to split, and whether to split it
# horizontally (-h, side-by-side) or vertically (-v, stacked). This script
# evaluates every pane in the current window for both directions and picks
# the combination that yields the largest *usable* new pane.
#
# "Usable" accounts for two things:
#   1. Minimums — a pi pane needs ~MIN_WIDTH columns / ~MIN_HEIGHT rows to
#      render its TUI readably. Candidate splits below these are rejected.
#   2. Aspect ratio — terminal character cells are ~2x taller than wide, so
#      a pane is visually balanced when width ≈ 2 × height (in cells). The
#      quality score of a candidate is min(width, 2*height): the limiting
#      visual dimension. Maximizing it favors balanced panes over skinny
#      ones with misleadingly large area.
#
# Usage: pick-split.sh
# Stdout: "<target_pane_id> <h|v>"   (parse with: read TARGET DIR < <(pick-split.sh))
# Stderr: human-readable rationale
# Exit 1: no pane can be split without violating the minimums

set -euo pipefail

MIN_WIDTH="${MIN_WIDTH:-80}"    # columns the new pane needs to be usable
MIN_HEIGHT="${MIN_HEIGHT:-20}"  # rows the new pane needs to be usable

best_pane=""
best_dir=""
best_score=0
best_nw=0
best_nh=0

while read -r pane_id w h; do
  # Candidate: horizontal split (side-by-side). New pane ~ (w/2) x h.
  nw=$((w / 2))
  if (( nw >= MIN_WIDTH )); then
    score=$(( nw < 2 * h ? nw : 2 * h ))
    if (( score > best_score )); then
      best_score=$score; best_pane=$pane_id; best_dir="h"
      best_nw=$nw; best_nh=$h
    fi
  fi

  # Candidate: vertical split (stacked). New pane ~ w x (h/2).
  nh=$((h / 2))
  if (( nh >= MIN_HEIGHT )); then
    score=$(( w < 2 * nh ? w : 2 * nh ))
    if (( score > best_score )); then
      best_score=$score; best_pane=$pane_id; best_dir="v"
      best_nw=$w; best_nh=$nh
    fi
  fi
done < <(tmux list-panes -F "#{pane_id} #{pane_width} #{pane_height}")

if [[ -z "$best_pane" ]]; then
  echo "pick-split: terminal too small — no pane can be split while keeping" >&2
  echo "the new pane at least ${MIN_WIDTH} cols or ${MIN_HEIGHT} rows." >&2
  echo "Maximize the terminal window, or override MIN_WIDTH/MIN_HEIGHT." >&2
  exit 1
fi

# Splitting a zoomed window force-unzooms it; surface that so the
# orchestrator can mention it to the user before their view changes.
if [[ "$(tmux display-message -p '#{window_zoomed_flag}')" == "1" ]]; then
  echo "pick-split: note — the window is currently zoomed; splitting will unzoom it" >&2
fi

kind=$([[ "$best_dir" == "h" ]] && echo "horizontally (side-by-side)" || echo "vertically (stacked)")
echo "pick-split: splitting $best_pane $kind -> new pane ~${best_nw}x${best_nh}" >&2
echo "$best_pane $best_dir"
