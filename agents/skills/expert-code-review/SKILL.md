---
name: expert-code-review
description: Perform an expert-level code review of a diff, PR, branch, or set of files and produce a structured JSON review report written to a file. Use whenever the user asks for a code review, PR review, diff review, or review report — especially when they want scored assessment (severity, verdict, overall score), structured/machine-readable output, or a review artifact saved to disk. Covers scoring rules, verdict gating, and the review JSON schema.
---

# Expert Code Review

Produce a structured JSON review report and write it to a file. Do not print the full report in chat — summarize verdict, score, and top findings, and point to the file.

## Workflow

1. Gather the review target: diff, PR, commit range, or file list. If ambiguous, ask.
2. Review every changed file against the focus areas (default: correctness, concurrency, security, error-handling, performance, maintainability).
3. Classify each finding with severity and category per the rules below.
4. Compute scores per the scoring rules below — follow them exactly; do not invent scores ad hoc.
5. Validate the report against the TypeScript contract in [references/review-report.ts](references/review-report.ts) (read it before writing output — it is the single source of truth for field names and enums).
6. Write the report as pretty-printed JSON (2-space indent) to the output file:
   - Default path: `./code-review-<yyyymmdd>-<short-target>.json` in the working directory (e.g. `code-review-20260731-quota-consume.json`).
   - If the user specifies a path, use it.
   - Ensure `metadata.schema_version` matches the version in the reference file.
7. Reply with a 3–6 line chat summary: verdict, overall score, finding counts by severity, and the file path. Never paste the whole JSON into chat.

## Severity rules

| Severity | Definition | Merge impact |
|---|---|---|
| `blocker` | Data loss, security hole, race/ correctness bug that will fire in production, broken build | Must fix before merge |
| `major` | Real bug or design flaw with meaningful blast radius, missing critical validation/error handling | Should fix before merge |
| `minor` | Code smell, weak test, suboptimal pattern; works but degrades quality | Fix in this PR or follow-up |
| `nit` | Style, naming, comment, preference | Optional |

Rules:
- Severity is assigned by *impact if merged*, not by effort to fix.
- Never downgrade a security or data-integrity issue below `major`.
- Every `blocker`/`major` finding must include `evidence` and `suggestion`; `suggested_patch` when a concrete fix is short.
- Set per-finding `confidence` honestly; findings below 0.6 confidence go in `open_questions` instead.

## Verdict rules (deterministic)

- `reject`: any `blocker` finding that is architectural (cannot be fixed within the PR's scope).
- `request_changes`: ≥1 `blocker`, or ≥2 `major`.
- `approve_with_comments`: exactly 1 `major`, or ≥1 `minor`/`nit` with no major+.
- `approve`: zero findings, or only `nit`.
- If overall confidence < 0.7 (e.g. missing context), downgrade one level and explain in `summary.one_liner`.

## Scoring rules

`summary.overall_score` starts at **10.0** and deducts:

| Deduction | Amount |
|---|---|
| Per `blocker` | −3.0 |
| Per `major` | −1.5 |
| Per `minor` | −0.5 |
| Per `nit` | −0.1 |
| Tests removed or coverage drops | −1.0 (once) |
| No tests for new logic | −1.0 (once) |

- Clamp to [0, 10], round to 1 decimal.
- Add up to +0.5 back (once) for exceptional quality (great tests, docs, migration safety); note it in a `positives` entry.

`metrics` sub-scores (0–10 integers) are judged independently:
- `maintainability`: coupling, duplication, naming, module boundaries
- `readability`: clarity of control flow, comments where non-obvious
- `security`: input validation, authn/authz, injection, secret handling (start at 10, −2 per security finding, min 0)
- `performance`: N+1 queries, unbounded loops/allocations, missing indexes, blocking I/O on hot paths

## Action items

- Derive `action_items` from findings, priority 1 = blockers first.
- `blocks_merge: true` for items resolving `blocker`/`major` findings.
- Every action item must reference its source findings via `finding_refs`.

## Output contract

Field names, enums, and required fields are defined in [references/review-report.ts](references/review-report.ts). Read it before writing the file. Keep the JSON strictly conformant — no extra top-level keys, no comments in JSON.
