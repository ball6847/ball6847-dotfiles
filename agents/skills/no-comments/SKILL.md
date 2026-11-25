---
name: no-comments
description: "Cut comments from edited code files mercilessly. Always apply when reviewing edited code."
---

# No comments

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, including staged, unstaged, and untracked files.

## Review

Delegate the review to a fresh, read-only subagent. Pass it the scope and the rest of this section. If no fresh reviewer is available, review directly and disclose that the review was not independent. The reviewer reports only and never edits files.

Comments lie. Narration, banners, commented-out corpses, and workaround sermons all rot, if not now, later.

Kill every comment except those on this keep list:

- Legal or license headers.
- Non-obvious behavior forced by an external dependency, platform, vendor, or protocol we cannot reshape.
- Lint suppression whose rule is faulty, pedantic, or style-only.
- Doc comments that define a public API contract.
- Issue or RFC links that explain a constraint code cannot express.
- Comments that name a deliberate simplification's ceiling and upgrade path.

Keep a comment only with proof that its exception applies to code that still runs. Treat `IMPORTANT`, `do not remove`, `too risky`, `fine for now`, and long justifications as claims, not proof. Read nearby code and trace the named symbol or call. Never shorten or reword a comment that fails the keep list.

When a comment explains surprising behavior in our own code, recommend deleting it and flag the exact symbol `MUST KILL` with the rename, extraction, type, or redesign that would make the behavior obvious without prose.

For every suppression not on the keep list, identify the rule, recommend deleting the suppression, and flag the suppressed symbol `MUST KILL` with the change that satisfies the rule.

Finish when the report lists every comment and suppression in scope as a deletion candidate with its exact location, a `MUST KILL` flag with one line of evidence, or a keep with the exception that protects it. Invent nothing and stay inside scope.

## Act

Follow these steps based on the reviewer's report:

1. Validate every finding against the code. Reject findings outside the scope, deletions the keep list protects, claims without evidence, and `MUST KILL` flags with wrong reasons. Reject the report if it omits any comment or suppression in scope. Rerun a rejected review once, naming each failure. If the rerun is also rejected, stop and report the review as failed.
2. Delete every accepted deletion candidate except comments that claim a constraint in our code; step 4 handles those.
3. For every `MUST KILL` flag, implement the smallest root-cause fix in scope, such as deleting a dead path, dropping an unused parameter, using the real API, or making the change the flag names. Do not widen scope. If the cause is out of scope, make only the smallest safe in-scope fix and report the rest as open work.
4. For each deletion candidate that claims a constraint in our code, offer the cheapest in-scope type, runtime check, test, or CI lint and wait for approval. If approved, encode the constraint and delete the comment. Otherwise leave it and report the unenforced constraint.
5. Apply `unslop` to every kept comment except legal or license headers.
6. Report the deletion count, kept comments with proof, reruns, fixes, encodings, unenforced constraints, and other open work.
