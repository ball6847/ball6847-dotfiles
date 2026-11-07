#!/usr/bin/env bash
# Mechanical pre-pass for the session-retro skill.
# Reads a Pi session transcript (JSONL) and prints a compact evidence digest.
# Usage: retro-stats.sh [path-to-session.jsonl]   (default: $PI_SESSION_FILE)
set -euo pipefail

file="${1:-${PI_SESSION_FILE:-}}"
if [ -z "$file" ] || [ ! -f "$file" ]; then
  echo "retro-stats: no transcript. Pass a path or run inside a Pi session (\$PI_SESSION_FILE)." >&2
  exit 1
fi

jq -s -r '
def msgs: map(select(.type == "message"));
def calls:
  [ msgs[] | (.message.content // []) | .[]?
    | select(type == "object" and .type == "toolCall") ];
def results:
  [ msgs[] | select(.message.role == "toolResult") | .message ];
def txt: (if type == "array" then (map(select(type == "object") | (.text // "")) | join(" ")) elif type == "string" then . else "" end);
def short: (txt | gsub("\\s+"; " ") | .[0:110]);
def epoch: (if type == "string" then (gsub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) else 0 end);
def span($a; $b): (if ($a | type) == "string" and ($b | type) == "string" then (((($b | epoch) - ($a | epoch)) / 60) | floor | tostring) + "m" else "?" end);
def wall($a; $b): (if ($a | type) == "string" and ($b | type) == "string" then ((($b | epoch) - ($a | epoch)) | floor | tostring) + "s" else "?" end);
def norm: (gsub("^[[:space:]]*(cd [^&;|]+ [&;]+[[:space:]]*)+"; "") | gsub("[\\n\\t]+"; " ") | gsub("[[:space:]]+"; " "));
def corr: test("(?i)(^|[.!?\\n] *|\\b)(no[,.]|nope|stop|wrong|incorrect|not what|that.s not|i said|i meant|actually|instead|wait[,.]|hold on|still (broken|failing|not)|same error|didn.t|don.t|why did|revert|undo)");

($ARGS.named // {}) as $_ignored
| (msgs) as $m
| (map(select(.type == "session")) | first) as $s
| (calls) as $c
| (results) as $r
| ($m | first | .timestamp) as $t0
| ($m | last | .timestamp) as $t1
| "SESSION   id=\($s.id // "?") start=\($t0) end=\($t1)",
  "          cwd=\($s.cwd // "?")  span=\(span($t0; $t1))",
  "VOLUME    user=\([$m[] | select(.message.role == "user")] | length) assistant=\([$m[] | select(.message.role == "assistant")] | length) toolCalls=\($c | length) toolResults=\($r | length)",
  "TOOLS     \([ $c[].name ] | group_by(.) | map({n: .[0], c: length}) | sort_by(-.c) | map("\(.n)x\(.c)") | join(" "))",
  "TOOLTIME  tool=\(((([ $r[] | .durationMs // 0 ] | add) // 0) / 1000 | floor))s of \(wall($t0; $t1)) wall",
  "SLOWEST   \([ $r[] | select((.durationMs // 0) > 5000) | {n: .toolName, ms: .durationMs} ] | sort_by(-.ms) | .[0:5] | map("\(.n)=\((.ms / 1000) | floor)s") | join(" ") | if . == "" then "none>5s" else . end)",
  "ERRORS    \([$r[] | select(.isError == true)] | length) failed",
  ([ $r[] | select(.isError == true) | "\(.toolName): \(.content | short)" ] | group_by(.) | map({m: .[0], c: length}) | sort_by(-.c) | .[0:5] | map("          \(.c)x \(.m)") | if length > 0 then join("\n") else empty end),
  "CORRECTIONS \([ $m[] | select(.message.role == "user") | (.message.content | if type == "array" then (map(select(.type == "text") | .text) | join(" ")) else tostring end) ] | map(select(corr)) | length) suspected",
  ([ $m[] | select(.message.role == "user") | (.message.content | if type == "array" then (map(select(.type == "text") | .text) | join(" ")) else tostring end) | select(corr) | "          - \(short)" ] | .[0:6] | if length > 0 then join("\n") else empty end),
  "REPEATED  \([ $c[] | select(.name == "bash") | .arguments.command // "" | norm | .[0:70] ] | group_by(.) | map(select(length >= 3) | "\(length)x \(.[0])") | .[0:5] | join("\n          ") | if . == "" then "none" else . end)",
  "REREADS   \([ $c[] | select(.name == "read") | .arguments.path // empty ] | group_by(.) | map(select(length >= 2) | "\(length)x \(.[0])") | .[0:6] | join("\n          ") | if . == "" then "none" else . end)",
  "BIGOUT    \([ $r[] | select((.content | tostring | length) > 20000) ] | length) results >20KB",
  ([ $r[] | select((.content | tostring | length) > 20000) | "          \(.toolName) \((.content | tostring | length) / 1024 | floor)KB" ] | .[0:5] | if length > 0 then join("\n") else empty end),
  "PARALLEL  \([$m[] | select(.message.role == "assistant") | [(.message.content // [])[] | select(type == "object" and .type == "toolCall")] | length | select(. >= 2)] | length) assistant turns batching >=2 calls"
' "$file"
