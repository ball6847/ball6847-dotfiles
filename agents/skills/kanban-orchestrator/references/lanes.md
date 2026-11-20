# Lane Protocols

Each lane names: owner agent, required protocol (tools + steps, in order), required artifact, exit condition, forbidden actions.

A lane result is accepted only when the required artifact exists **and** the protocol was followed. Missing step -> re-delegate once naming the step.

---

## Backlog — owner: orchestrator (no subagent)

Protocol (orchestrator work only, no code reading):

1. Read the card's `title` and `description` only.
2. Write the goal block into the card notes:
   - **Outcome** — one sentence, what is true when this card is done.
   - **Done criteria** — numbered, each one checkable by an artifact.
   - **Non-goals** — what is explicitly out of scope.
3. If the card description has no measurable outcome, ask the user one question. Do not guess scope.

Required artifact: the goal note on the card.
Exit condition: outcome + at least two numbered, checkable done criteria + non-goals recorded.
Forbidden: exploring the repo, guessing the implementation, delegating work.

---

## Todo — owner: scout (`explore-codebase`)

Protocol:

1. Read the card goal note.
2. Locate every file, module and test that the work touches. Use the repo's own search tools.
3. Report the current state of each touched area, the existing conventions to follow, and the risk areas.
4. Name the tests that exist today and the ones that would have to be written.

Required artifact: scope report (markdown) with file paths and the conventions/risk list.
Exit condition: report exists and every file it names exists on disk.
Forbidden: editing any file, writing tests, proposing the plan (that is the Plan lane).

---

## Plan — owner: `planner`

Protocol:

1. Read the card goal note and the scope report.
2. Write a plan file to `.context/plans/YYYY-MM-DD/<SLUG>_PLAN.md` (repo convention wins if the repo already uses a different path).
3. Structure the plan as ordered tasks. Each task states: files to change, the behaviour it adds, the test that proves it.
4. Map every numbered done criterion to at least one task. A criterion with no task is a gap — fix the plan, not the criterion.
5. List the risks and the rollback path.

Required artifact: the plan file, plus a one-line summary naming the plan path.
Exit condition: plan file exists and every done criterion maps to a task.
Forbidden: implementation, test writing, changing the goal without orchestrator approval.

---

## Implement — owner: `builder`, gated by `reviewer`

Protocol (builder):

1. Read the plan file.
2. Work task by task, test first for each behaviour the task adds (the repo's `builder` skill defines the TDD cycle).
3. Run the test suite the repo uses. A failing suite is the builder's problem to fix, not a report to hand over.
4. Write an implementation report: `.context/implementation-reports/YYYY-MM-DD/<SLUG>_REPORT.md`, listing changed files, tests added, test run output, and anything left open.
5. Do not touch the card or the board.

Protocol (reviewer, delegated by the orchestrator after the builder returns):

1. Verify the implementation against the plan file and the card's done criteria.
2. Verify each changed file is covered by a test.
3. Return exactly one verdict: `PASS`, `PARTIAL`, or `FAIL`, with a numbered list of findings for anything other than PASS.

Required artifacts: implementation report + reviewer verdict.
Exit condition: report exists, suite green, reviewer verdict `PASS`.
Forbidden: orchestrator-side editing, moving the card, accepting a report without a verdict.

Re-delegation: `PARTIAL`/`FAIL` -> builder gets the finding list verbatim. Maximum 3 rounds, then escalate to the user.

---

## Deploy — owner: deploy agent

Protocol:

1. Read the plan and the implementation report.
2. Ship the change through the repo's own path: merge to the trunk branch, open the PR, or run the deployment command the repo documents. Never invent a deploy procedure.
3. Wait for CI. A red CI run is a deploy failure.
4. Verify the deployed system from the outside: the endpoint answers, the new behaviour is observable, logs show no new errors.

Required artifact: deploy record (target, commit or PR url, CI run id, verification output).
Exit condition: shipped, CI green, external verification recorded.
Forbidden: shipping with red CI, deploying without reading the repo's deploy docs, moving the card.

---

## Done — owner: orchestrator

Protocol:

1. Confirm the Deploy lane's artifacts: shipped, CI green, external verification recorded.
2. Re-check every done criterion against the evidence table. Any criterion without evidence -> card goes back to the lane that owns that criterion.
3. Move the card to `lane-done`.
4. Write the summary note: goal, what shipped, evidence per criterion, files touched, remaining risks.

Forbidden: closing a card with an unproven criterion.
