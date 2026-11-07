---
name: session-retro
description: End-of-session retrospective / post-mortem. Audits this session's transcript for what went wrong and what was slow, finds the root cause, and writes the durable fix into AGENTS.md (plus an optional ledger). Use when the user says "retro", "retrospective", "post-mortem", "what went wrong", "why was that slow", "let's wrap up", "before we finish", or at the end of any multi-step task that hit errors, retries, slow stretches, or user corrections.
---

# Session retro

Goal: **each mistake happens at most twice.** The first time it goes in the ledger; the second time it becomes an AGENTS.md rule that every future session loads. The same gate applies to speed: a slow pattern seen twice becomes a rule or a script.

Budget: **≤2 minutes, ≤10 tool calls.** A script does the counting. A retro longer than the work it reviews is waste.

## 1. Measure — one call

```bash
bash ~/.agents/skills/session-retro/scripts/retro-stats.sh
```

Reads `$PI_SESSION_FILE`. Prints: span, tool mix, tool time vs wall clock, slowest calls, failures grouped by message, suspected user corrections, repeated commands, re-reads, oversized outputs, parallel batching.

Older session: `pstack_sessions` (action `list`) → pass the returned path. Never glob `~/.pi/agent/sessions` yourself.

## 2. Judge — no tools

Two passes, **at most 3 findings total**, ranked by cost. Cost = wall-clock minutes lost, failed attempts, or a user correction. Everything cheaper is noise.

**Pass A — what was slow.** Take the top time sinks and attribute them:

| Digest line | Verdict | Fix shape |
|---|---|---|
| Tool time ≥40% of wall clock, one tool dominant | A tool is the cost | Cache it, batch it, or replace it |
| Tool time low, many turns | Turn count is the cost | Fewer turns: batch independent calls, stop narrating, read once instead of three times |
| Repeat command shape ≥3× | Recomputed the same answer | Script, `make` target, or compute once into a variable |
| Slowest calls are 20s+ individually | Wrong tool or wrong scope | `browser_http_get` over `browser_navigate`; `grep -n` over full reads; one test file over the suite |

**Pass B — what went wrong.** For every failure cluster and every user correction, state a root cause a rule, test, or tool could have prevented:

| Symptom | Not a root cause | Root cause |
|---|---|---|
| Edited the wrong file | "was careless" | "Edited from memory; never read the file first" |
| 6 min of path guessing | "search was slow" | "Guessed paths instead of reading the layout once" |
| "no, the *other* service" | "misunderstood" | "Two services share a name; the right one is the one under `api/`" |
| Same test failed twice | "flaky" | "Ran the suite instead of the failing file, so the second failure had no new signal" |

Read `references/friction-catalog.md` when the numbers are ambiguous or a signal needs drilling with `jq`.

Zero findings is valid: report the numbers, one line, done.

## 3. Route

Ledger: `~/.pi/agent/retro/ledger.md` — copy the header from `assets/ledger.md` on first use. One row per root cause, keyed by project path.

| Situation | Destination |
|---|---|
| One-off, cheap, no recurrence | Ledger only |
| User stated it as a standing rule ("always…", "never…") | **AGENTS.md now** |
| Recurred: ledger `Count` ≥ 2 | **AGENTS.md now** |
| Cost >20 min, or it reached a commit / PR / production | **AGENTS.md now** |
| Fix is a project fact (path, command, gotcha, naming) | **AGENTS.md now** |
| Cross-project habit, not repo-specific | `~/.pi/agent/AGENTS.md` |
| A machine could check it | Propose the check, not the text — step 5 |

Row shape: `| <project path> | <root cause, ≤8 words> | <count> | <date> | <evidence: turn or command> | <open|promoted → AGENTS.md#section> |`. Re-read the ledger immediately before writing — other sessions append to it. Same root cause, different symptom → increment the count; do not add a row.

## 4. Write AGENTS.md

Target: the `AGENTS.md` of the project the session worked in. **Read it first** — mandatory, both to dedupe and because you are editing it.

One line per rule:

```markdown
- **<trigger condition>**: <imperative action>. Why: <reason, ≤8 words>.
```

Good: `- **Touching the DB schema**: read the latest drizzle migration before editing. Why: the snapshot drifts from the code.`
Bad: `- Be careful with the database.` / `- 2026-11-06: long debug session about schema drift.`

Hard limits:

- ≤15 bullets in `## Session lessons`, ≤25 words each; whole file under ~150 lines.
- **Merge before adding.** Grep 2–3 keywords. Near-duplicate → rewrite the existing bullet, never add a second.
- **Delete before adding** at the cap: the rule whose subject is gone, then the vaguest one.
- No dates, ticket IDs, SHAs, narrative, secrets. Only rules that survive a refactor.
- A rule that already existed but did not prevent the mistake is too vague or misplaced: rewrite it with the concrete trigger, or move it to the section covering where the mistake happens.

Full spec with worked examples: `references/agents-md-writing.md`.

## 5. Escalate to structure

If a rule gets violated twice, or a machine can check it, text is the wrong fix. Pick the strongest rung:

1. Lint rule / test / type constraint.
2. Script or `make` target the agent can run.
3. Hook or extension that blocks the bad action.
4. AGENTS.md bullet — judgment calls only.

When you escalate, delete the bullet and mention the check inside the rule in one clause. If the mechanism needs real work, file it on the kanban board (Backlog lane) instead of writing a rule that will be ignored.

## 6. Report

≤5 lines, no preamble:

```
Retro: 38m, 84 tool calls, 7% failed, 3 corrections.
Slow: full test suite re-run 3× (12m) — cause: no `--filter` habit. Fix: AGENTS.md rule added.
Wrong: edited generated files twice — cause: generator output not marked. Fix: ledger (count 2 → promoted).
AGENTS.md: +2 rules, 1 rewritten, 1 stale removed. Ledger: +1.
Next: run `pnpm test --filter api` once to confirm the rule works.
```

Clean session still reports its numbers: `Retro: clean — 38m, 84 calls, 0 failed, 0 corrections.`

If a kanban card is linked, comment those lines on it and move it to Done. If the retro changed no files, skip the board.

## Do not

- Do not re-read the transcript. The script plus your own context is the evidence; drill with `jq` into one turn only.
- Do not re-run the task's commands to "verify" the retro.
- Do not record secrets, customer data, or API keys anywhere.
- Do not write a repo rule for a personal habit — that goes in `~/.pi/agent/AGENTS.md`.
- Do not write a post-mortem file for a slip caught before it shipped — ledger row, done.
- Do not let the retro block delivery. Ship first, retro after, or while CI runs.
