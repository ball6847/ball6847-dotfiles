# Friction catalog (Pi harness)

Read this when `retro-stats.sh` output is ambiguous, or when you need to drill into one turn. The script prints numbers; this file says what each number usually means and what to do about it.

## Reading the digest

| Line | What it tells you | Fix pattern |
|---|---|---|
| `TOOLTIME tool=34s of 114s wall` | Tool share of the wall clock. Low share → the time went to model turns or a human. High share → a slow tool dominates. | Low share: cut turn count (batch edits, stop narrating). High share: attack the specific slow tool. |
| `SLOWEST` | Calls over 5s. | Tests/builds: run once with a wider filter. `webfetch`/`browser_*`: try `browser_http_get` or skip. Repeated 5–20s calls: parallelize. |
| `ERRORS n failed` | Raw failure count. Each failure costs a turn. | Group by message. The same error twice = the classification was wrong once, not the command. |
| `CORRECTIONS n suspected` | User messages that open with "no / stop / wrong / actually / instead". Highest-signal line in the digest. | Read the quoted text. The correction names the real requirement the first prompt did not. Mine it for a rule, not for an apology. |
| `REPEATED 4x <cmd>` | The same command shape re-run with small edits. | Turn it into a script, a `make` target, or one command computed once and reused ($VAR). |
| `REREADS 3x path` | A file read repeatedly with no edit between. | Read once, then edit. Or `grep -n` the section instead of the whole file. |
| `BIGOUT n results >20KB` | Tool output that dominated context for no benefit. | `head`/`tail`/`jq -r '.[] | .x'`/`--limit`. Never `cat` a whole file to find one line. |
| `PARALLEL n turns batching >=2` | Independent calls that were serialized drip by drip. | Batch independent reads/searches in one turn. |

## Signals the script cannot see

Read your own context for these. They are usually worth more than the mechanical counts.

| Signal | Looks like | Route |
|---|---|---|
| Wrong path guess | `ls`/`find` probing after a failed read or edit | One rule: where things actually live |
| Verification skipped | "should work", "tests pass" with no run in the transcript | Rule + check the test command is in AGENTS.md |
| Assumption never stated | Worked 10 turns on the wrong reading of the request | Rule: restate the plan in one line before multi-file edits |
| Tool misuse | `sed`/`cat` where `read` belongs, `grep` on JSON instead of `jq` | Rule naming the right tool for that data |
| Skill that should have fired | The skill existed in the catalog but the session hand-rolled it | Tune that skill's `description`, don't add an AGENTS.md rule |
| Subagent overkill | Spawned a subagent for a 2-minute edit | Rule: delegate only when the subtask needs its own context |
| Wasted re-orientation | Re-derived the same architecture facts twice | Rule pointing at the file that already documents it |

## Drills (one call each, only when needed)

Failures with context:

```bash
jq -r 'select(.type=="message" and .message.role=="toolResult" and .message.isError)
  | "[\(.message.toolName)] \((.message.content | tostring) | .[0:300])"' "$PI_SESSION_FILE" | head -20
```

The user's own words, in order (skips system and tool noise):

```bash
jq -r 'select(.type=="message" and .message.role=="user")
  | (.message.content | if type=="array" then (map(.text? // "") | join(" ")) else tostring end)' "$PI_SESSION_FILE"
```

Turns where the assistant stalled (long gap before the next turn) — find who was slow: the tool, or the model:

```bash
jq -r 'select(.type=="message") | "\(.timestamp) \(.message.role)"' "$PI_SESSION_FILE" | head -40
```

One turn's full tool call, when a specific failure needs the exact arguments:

```bash
jq -r 'select(.type=="message") | (.message.content // [])[] | select(type=="object" and .type=="toolCall") | select(.name=="bash") | .arguments.command' "$PI_SESSION_FILE" | grep -n "<keyword>"
```

## Time budget intuition

- Tool time under ~20% of wall clock: the cost is turn count, not tools. Fix the prompt and the batching, not the commands.
- One tool over 40% of tool time: that tool is the retrospective. Cache it, batch it, or replace it.
- Human idle time is not your cost to fix. Note it and stop.
