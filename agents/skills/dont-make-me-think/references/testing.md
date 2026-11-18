# Do-it-yourself usability testing (Krug)

Source: Steve Krug, *Rocket Surgery Made Easy* (2010) and *Don't Make Me Think, Revisited* ch. 9. Lean loop for small teams with no researcher.

## Core beliefs

- Testing one user is 100% better than testing none.
- Testing one user early beats testing 50 near the end. Test sketches, prototypes, and competitors' apps, not only finished builds.
- Purpose is to find problems and fix them, not to prove anything. No statistics needed.

## The loop

| Element | Krug's default | Adapt for field/mobile apps |
|---|---|---|
| **Cadence** | One morning a month, on a fixed day | Same; put it on the calendar so it happens regardless of release state |
| **Participants** | 3 per round | 3; then fix and run again next month |
| **Recruiting** | Recruit loosely, grade on a curve. Anyone who's used similar apps works for most problems | For domain tasks, include at least 1 real user (worker, manager). Pay or thank them |
| **Location** | Quiet room, one facilitator + participant | On site where possible: real phone, real light, real gloves, real signal |
| **Observers** | As many team members as possible watch live (other room/screen share) | At minimum the dev who built it watches |
| **Method** | Think aloud: participant says what they're looking at, thinking, and doing | If thinking aloud is awkward, ask "what did you expect?" right after each task |
| **Debrief** | Same day, over lunch, observers + team, ~1 hour | Same |
| **Fixing** | Fix the most serious problems first, with the smallest change that works | Same; re-test next round |

## Writing tasks

- 2–4 tasks per session, written as **scenarios** with a goal, not instructions. Bad: "Click the report button." Good: "You just finished cleaning the 2nd floor bathroom. Let the office know."
- Never use the words on the UI in the task (it gives away the answer).
- Include the main job of the screen first; save edge cases (offline, partial, mistake correction) for later tasks.
- Before tasks, optional **get-it test**: show the screen 5 seconds, then ask "What is this? What would you do here?"

## Session script (~20–45 min, adapt wording)

1. **Welcome (2 min).** "Thanks for helping. We're testing the app, not you; you can't do anything wrong here. Please think out loud: tell me what you're looking at, what you're trying to do, and what you're thinking. If you get stuck I may not help, because we want to see what happens without us there. Ask questions anyway; I'll answer at the end."
2. **Background (2 min).** What they do, which phone, which apps they use daily.
3. **Get-it test (2 min)** if testing a new screen.
4. **Tasks (main block).** Read each scenario aloud, hand it on a card. Stay neutral. Prompts allowed: "What are you thinking?" "What would you do now?" "What did you expect to happen?" Don't lead, don't explain, don't defend.
5. **Probe (5 min).** Return to moments of hesitation: "Back there you paused, what were you looking for?"
6. **Wrap up.** Answer their questions, thank, pay.

## Debrief agenda (same day, ~1 hour)

1. Each observer lists the **3 most serious problems** they saw (not all of them).
2. Merge into one list; rank by severity (scale in `canon.md`).
3. Pick the **top ~10**; commit to fix the top few before the next round.
4. For each, choose the **smallest tweak** that could fix it. Resist: redesigns, adding explanations, adding features. Removing things is often the fix.
5. Ignore "kayak" problems (user goes slightly off, recovers on their own without trouble) unless frequent.
6. Write the list down; it's the agenda for next month's check.

## Common traps

- Waiting for the product to be "ready" before testing.
- Recruiting perfectly representative users, so testing never happens.
- Asking opinions ("Do you like it?") instead of watching behavior.
- Fixing the long tail of small issues while the big one stays.
- Adding instructions/tooltips to fix a confusing design: change the design.

## Plan template

```
Round: <date, time>          Facilitator: <name>   Observers: <names>
Participants (3): <who / how recruited / thank-you>
Device & place: <real phone, on site / room>
Get-it test: <screen>        Tasks:
  1. <scenario>
  2. <scenario>
  3. <scenario>
Debrief: <time, place>  Output: top-3 per observer → ranked list → fixes for next round
```
