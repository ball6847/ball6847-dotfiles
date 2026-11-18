---
name: web-testing
description: "Use when testing or verifying a web application or web flow in a real browser: run an end-to-end test, smoke test, or QA pass, check a feature against its spec or requirements, capture screenshots as evidence, or produce an HTML test report. Enforces agent-browser as the only browser tool, one screenshot per step that is read back before continuing, and a hard freeze on database writes and code changes while the test runs."
---

# Web Testing

## Overview

A test run that a reader can trust has three properties:

1. **The browser evidence is real.** Every claim in the report is backed by a screenshot taken from the running application, not by reading the code.
2. **The run was not tampered with.** While the test is running, neither the database nor the code changes. If the test needs one of those to continue, the run stops and says so instead of quietly fixing the problem and reporting a pass.
3. **The result follows the spec.** If a requirement document exists, the requirement decides what "pass" means. Behaviour that differs from the document is a failure, even when the behaviour looks reasonable.

The report at the end is an HTML file with the screenshots as evidence. The template lives in `assets/`, the generator is `scripts/build_report.py`.

## The rules, in order of how often they bite

| Rule | Why |
| --- | --- |
| Use **agent-browser** for every browser action. Never another browser tool. | One browser, one session, one set of screenshots. A second tool means two histories and screenshots that do not match what was tested. |
| Take a **screenshot at every step** and **read it back** before the next step. | A screenshot nobody looked at is not evidence. Reading it is the only way to catch the blank page, the error toast and the layout that collapsed. |
| **No database writes** once the run starts. | A test that seeds its own data proves nothing about the code under test. |
| **No code changes** once the run starts. | Fixing a bug mid-run destroys the before and after comparison. The bug is the finding. |
| If a requirement document exists, **the document decides**. | Working but different from the spec is a failure, not a pass with a note. |
| If the model cannot read images, **stop**. | A run that cannot see the screen cannot verify the screen. |

## Phase 1: Prepare

### 1.1 Confirm the tool exists

Do this before anything else. If the command is missing, the run cannot start.

```bash
scripts/preflight.sh [base-url]
```

The script checks that the command is on PATH, that the browser starts and that the target answers. It also prints the path of the agent-browser skill when there is one.

If the command is missing, stop and report that. Do not install it silently and do not fall back to a different browser tool.

### 1.2 Load the agent-browser skill

If a skill named `agent-browser` is available, read it before the first command. It carries the full command reference, the auth patterns and the pitfalls. This skill covers the workflow, that one covers the tool.

### 1.3 Confirm the model can read images

The model must be able to look at a PNG. Take one throwaway screenshot of any page and read it back with the read tool.

If the image comes back as something the model cannot actually describe (no visual content, an error, a file it refuses to open), **stop immediately** and tell the user the model cannot read images. Every later step depends on this.

### 1.4 Find the spec

Look for a requirements or product spec in the repository. Check the usual places: a `docs/` folder, `requirements.md`, `spec/`, an `AGENTS.md` that points at one, a ticket or issue that describes the behaviour.

Record what the spec says for each behaviour under test. Keep it next to the test plan; it is the yardstick for every verdict.

If there is no spec, say so in the report and judge the behaviour against what the user asked for in the request itself.

### 1.5 Write the test plan

A list of steps, each with:

- **What to do** in the browser
- **What the spec says should happen**
- **What to screenshot**

Put it in the task notes so it survives a long run.

### 1.6 Set up the application

Do all setup **before** the run starts. This is the only window where writing to the database and changing code are allowed.

- Build and start the services
- Seed or clean the test data if the test needs it
- Note the base URL, the credentials and the seeded state

Then state clearly that the run is starting. From this point the freeze applies.

## Phase 2: Run

### 2.1 The loop

For each step in the plan:

1. **Act** in the browser with agent-browser
2. **Wait** for the page to settle (`wait` for a selector or text, not a blind sleep)
3. **Screenshot** to a numbered file
4. **Read the screenshot** and compare it against what the spec says should be on screen
5. **Record** the result: passed, failed, or needs a decision

Step 4 is not optional. A screenshot that has not been read has not been checked. Reading it is where the failures are found.

### 2.2 Commands

```bash
# navigate and settle
agent-browser batch "open <url>" "wait --text <text that must appear>"

# read the page structure, then act on it
agent-browser snapshot -i

# act, settle, capture
agent-browser batch "click @e3" "wait 1500" "screenshot ./shots/03-after-connect.png"

# the annotated screenshot shows the refs on the image itself, useful for
# icon buttons and for anything the text snapshot does not describe
agent-browser screenshot --annotate
```

Use `batch` for two or more commands in a row. Run a single command when the output decides the next one, which is mostly `snapshot -i`.

Refs go stale after anything that navigates or changes the DOM. Re-snapshot after a click that navigates, after a form submit, after a modal opens.

### 2.3 Login

Use a session or a state file so the login runs once.

```bash
agent-browser --session <name> batch \
  "open <url>/login" "snapshot -i" \
  "fill @e1 <user>" "fill @e2 <password>" "click @e3" "wait --url **/dashboard"
```

Never paste a password into a tracked file, a commit or a report.

### 2.4 The freeze

**No database writes.** Not a seed script, not a manual fix, not an admin tool. If the next step needs data that is not there, stop.

**No code changes.** Not a one-line fix, not a comment, not a config tweak. If the next step needs a change, stop.

Both freezes end when the run ends. A run that needs a change is not a failed run, it is a blocked run, and the report says which step blocked and what change would unblock it.

When the run stops, still write the report. A blocked run with evidence for the steps that did run is more useful than nothing, and the report template handles a blocked step through the `blocked` status.

### 2.5 Judging against the spec

For each step, compare the observed screen against the spec:

- **Matches** → passed
- **Does not match** → failed. Even when the observed behaviour is sensible. A reasonable deviation from the spec is still a deviation.
- **The spec is ambiguous or the screen raises a question the spec does not answer** → needs a decision. This is a finding, not a pass.

A step that could not run because the run froze → blocked, with the reason.

### 2.6 Watch for the usual traps

- A toast that says the operation failed while the page looks fine
- A spinner that never resolves
- A modal that hides the thing it is reporting on
- A success message that appears before the data is actually there, so a refresh loses it
- The browser back button breaking a multi step flow
- A page that only works at one viewport width

## Phase 3: Report

### 3.1 Write the manifest

The manifest is JSON. `references/manifest.md` has the full schema and a worked example. The short version:

```json
{
  "title": "Facebook Messenger OAuth",
  "product": "Chatplus",
  "date": "2026-11-18",
  "subtitle": "End to end result with screenshot evidence",
  "verdict": "PASS",
  "summary_headline": "One sentence a reader can act on",
  "summary_body": "What was tested and against what",
  "chips": [{"label": "Branch", "value": "feat/x"}],
  "metadata": [{"label": "Build", "value": "commit abc1234"}],
  "steps": [
    {
      "title": "The Channels page lists the Facebook channel",
      "status": "pass",
      "expected": "A Facebook card with a Connect button",
      "actual": "The card and the button are there",
      "screenshots": [
        {"file": "shots/01-channels.png", "caption": "Facebook channel card", "alt": "..."}
      ]
    }
  ],
  "findings": [
    {"id": "F1", "title": "The page picker hides the result message", "body": "...", "impact": "..."}
  ],
  "notes": ["Anything the reader needs that is not a step"]
}
```

`status` is one of `pass`, `fail`, `blocked`. The generator counts them and picks the verdict.

`file` is a path to the screenshot, relative to `screenshots_dir` or absolute.

### 3.2 Build it

```bash
python3 scripts/build_report.py ./manifest.json ./out
```

That writes `out/report.html`, copies the screenshots into `out/screenshots/` and the font into `out/fonts/`. The report is self contained: open the file from disk, no server and no network.

### 3.3 Check the report before handing it over

Open it in a browser and look at it. Then verify:

- The verdict matches the counts
- Every screenshot in the manifest is in the report
- Clicking a thumbnail opens the full screen image over the whole viewport
- The top bar of the full screen image names the shot, not just the file name
- Esc closes it and the focus returns to the thumbnail
- Printing still produces a readable PDF

## Reporting style

The report is written in **English**.

Prose rules:

- Plain words. Short sentences. No marketing tone.
- Lead with the result, then the evidence, then the detail
- Name the exact thing that failed: the button, the message, the state
- Quote the spec when a step turns on it: "the spec says the page must show X, the page showed Y"
- No emoji, no em dashes, no curly quotes

Colour rules for the report, they are not the same as the product's colours:

- **Red means failed and nothing else.** A product brand red is never used as a structural or accent colour in the report, because a reader has to be able to trust that red always means failed.
- Green means passed, amber means a finding that needs a human decision, and the frame of the report is a deep blue that the manifest can set to the product's own accent.

## Files

| Path | What it is |
| --- | --- |
| `assets/report.css` | The report stylesheet, self contained |
| `assets/inter-latin-var.woff2` | The report font, copied next to the output |
| `scripts/build_report.py` | Manifest to `report.html` |
| `scripts/preflight.sh` | Checks the tool, the browser and the target before the run |
| `references/manifest.md` | The manifest schema, with a full example |
| `references/report-checklist.md` | The checks to run on the finished report |
