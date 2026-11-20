# Delegation Contract

Every lane step is a subagent run. The orchestrator never does the work; it writes the prompt and judges the result.

## How to delegate

Use whichever the session exposes:

- pi Task tool: `subagent_type` = the owner agent name.
- pstack `subagent` tool: `agent` = the owner agent name, `task` = the prompt below.

Available agents (see `~/.pi/agent/agents/`): `explore-codebase` (scout), `general`, `builder`, `reviewer`. Skills that back them: `planner`, `builder`, `reviewer` (repo skills under `agents/skills/`).

Agent availability differs per session. If the owner agent for a lane is missing, fall back to `general` and paste the lane protocol from `references/lanes.md` into the prompt verbatim — the protocol travels in the prompt, not in the agent's head.

## Background by default

Subagents run in the background unless the user says otherwise:

- Launch the run, then keep working on supervision: check the run's state, read the artifact when it lands.
- Never advance the card while the lane's run is still alive.
- Never launch a second agent for the same lane while the first is alive — two writers on one lane corrupt the artifact.
- If the harness gives no background switch, treat "launch" as "start and return control", and poll the run before judging the lane.

## Prompt template

Fill every field. A subagent that lacks the card context cannot meet the goal.

```
You are the <OWNER> agent for lane <LANE> of a Kanban card.

Card
  id: <CARD_ID>
  title: <CARD_TITLE>
  description: <CARD_DESCRIPTION>

Goal (fixed by the orchestrator — do not renegotiate it)
  outcome: <OUTCOME>
  done criteria:
    1. <CRITERION>
    2. <CRITERION>
  non-goals: <NON_GOALS>

Lane protocol (follow in order)
  <paste the matching section of references/lanes.md>

Context
  scope report: <PATH or "none">
  plan file: <PATH or "none">

Your deliverable
  artifact path: <PATH>
  artifact must contain: <list>

Definition of done for you
  - <protocol step 1 satisfied>
  - <protocol step 2 satisfied>
  - report the artifact path and the exact test/run output that proves it

Rules
  - Do NOT move the card, edit the board file, or change any lane state.
  - Do NOT start work outside the done criteria.
  - If a done criterion is unreachable, stop and report exactly why, with the file/command that proves it.
  - Do NOT mark the work done without the artifact path and the run output.
```

## Re-delegation with a gap

Same template plus a `Gap` block, one attempt only:

```
Gap to close (from the previous attempt)
  <numbered finding, verbatim>
Evidence for the gap: <file:line, command output, or "artifact missing">
```

Rules for re-delegation:

- Name the gap. "It still fails" is not a gap.
- Include the evidence that shows the gap.
- Change something in the prompt when you re-delegate (context, scope, or instruction). An identical re-run wastes a round.

## Reviewer gate prompt

```
You are the reviewer agent for a Kanban card.

Card id: <CARD_ID>
Goal outcome: <OUTCOME>
Done criteria:
  1. <CRITERION>
  ...
Plan file: <PATH>
Implementation report: <PATH>
Changed files (from the report): <LIST>

Verify
  1. Every done criterion has evidence in the report or in the diff.
  2. Every changed file has a test that covers it.
  3. The implementation matches the plan; no scope creep, no missing task.
  4. The repo's test suite passes as reported.

Return exactly one verdict line: "Verdict: PASS" | "Verdict: PARTIAL" | "Verdict: FAIL"
Then, for anything other than PASS, a numbered list of findings:
  1. <finding> — <file:line> — <what to change>
```

A verdict without findings for `PARTIAL`/`FAIL` is invalid. A report without a verdict is invalid. Both mean: re-delegate with the gap named.

## Notes on the card

Notes are written by the orchestrator only, after a lane verdict:

```
[Todo] scope report: <PATH> — exit: MET
[Plan] goal: <one line>
[Plan] done criteria: 1) ... 2) ...
[Plan] exit: MET — plan at <PATH>
[Implement] round 1: PARTIAL — <finding count> findings, re-delegated to builder
[Implement] round 2: PASS — report <PATH>, suite green
[Deploy] shipped <PR/commit> — CI <run id> green — verified <probe>
[Done] goal met: 1) <evidence> 2) <evidence>
```

## Escalation text

When a lane stalls twice, ask the user one question with the gap and the options:

```
Card <CARD_ID> is stuck in lane <LANE>.

Gap: <what is missing>
Attempt 1: <verdict + finding>
Attempt 2: <verdict + finding>

Options
  a) <narrow the goal / split the card>
  b) <change the plan, then re-run the lane>
  c) <stop the card here>
```
