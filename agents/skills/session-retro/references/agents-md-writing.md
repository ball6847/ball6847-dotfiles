# Writing rules into AGENTS.md

AGENTS.md loads on **every** turn of **every** session in that directory tree. Every line costs context and competes for attention. A 400-line AGENTS.md makes an agent skip all of it. Write like the file is a budget, not a diary.

## Placement

| Lesson | File |
|---|---|
| Repo/package specific (paths, commands, gotchas, domain naming) | `<repo>/AGENTS.md` |
| Cross-project personal habit or tooling preference | `~/.pi/agent/AGENTS.md` |
| Subtree only (e.g. `apps/web`) | `AGENTS.md` inside that subtree, not the root |
| Enforceable by machine | A check, not a file — see step 5 of the skill |

Never create a parallel file (`CLAUDE.md`, `NOTES.md`, `LESSONS.md`) next to an existing `AGENTS.md`. One always-loaded file per scope.

## Section

One dedicated section per file, appended once:

```markdown
## Session lessons

- **<trigger>**: <action>. Why: <reason>.
```

If the file uses frontmatter or has a "Project rules" section, add the bullets there instead of creating a second section. If the repo's AGENTS.md already has themed sections (`## Testing`, `## Database`), put the bullet in the matching section — placement is how the rule gets read at the moment it matters.

## Anatomy of a good bullet

```markdown
- **Editing `packages/db`**: run `pnpm db:generate` after touching schema files; CI fails on a stale snapshot. Why: the snapshot is committed.
- **Debugging the webhook flow**: replay with `pnpm dev:replay fixtures/<id>.json` instead of re-triggering Stripe. Why: re-triggers mutate real state.
- **Naming**: `tenant`, not `org`, in api-gateway. Why: `org` is the CRM's word for something else.
```

Three properties:

1. **Trigger first** — the moment the agent will be in when the rule matters ("Editing…", "Debugging…", "When the user says…"). A rule with no trigger is read at the wrong time, if ever.
2. **Imperative and checkable** — "run X", "read Y", "use Z". Never "be careful", "prefer", "consider".
3. **Why in one clause** — enough for a future agent to tell whether the rule still applies. No story, no date.

## Dedupe and merge (mandatory)

1. Read the whole file first.
2. Grep 2–3 keywords from the new rule (e.g. `grep -ni "migration\|drizzle\|snapshot" AGENTS.md`).
3. Match found:
   - Same meaning, weaker wording → rewrite that bullet, don't add another.
   - Same topic, different rule → merge into one bullet if they fit in 25 words; otherwise put them adjacent.
   - Contradiction → the newer evidence wins. Replace the old bullet; never leave both, or the agent will pick at random.
4. No match → add one bullet at the right place.

## Cap and pruning

- ≤15 bullets in `## Session lessons`, ≤25 words each.
- Whole file stays under ~150 lines.
- At the cap: delete the bullet whose subject no longer exists in the codebase, then the vaguest one. Delete first, add second — never grow past the cap.

## Never write

- Dates, ticket IDs, commit SHAs, PR numbers, "we discussed".
- Narrative ("on Tuesday the build failed because…").
- Secrets, tokens, customer data, internal URLs with credentials.
- Anything the harness already enforces (read-before-edit, tool argument shapes, how skills load). Duplicating platform behaviour trains agents to skim the file.
- Instructions aimed at a human reviewer.
- Speculation. If the session did not prove it, it goes in the ledger, not here.

## Retired rules

A rule whose failure mode disappeared is worse than no rule: it costs context and teaches a stale pattern. When you notice one (the subject file is gone, the command no longer exists, the flow was rewritten), delete it in the same edit and count it as a win in the report (`-1 stale`).

## Edit mechanics

- Read the file, then apply one `edit` call with all changes for that file.
- Preserve the file's existing bullet style and section order.
- Show the user the added/rewritten/removed lines in the report — never silently grow a file that loads on every turn.
