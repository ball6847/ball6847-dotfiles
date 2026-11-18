---
name: dont-make-me-think
description: Use when designing, reviewing, or writing copy for any app screen, flow, form, navigation, empty state, or error message; when auditing usability from code, a screenshot, or a running app; when planning or debriefing a usability test; or when the user mentions Don't Make Me Think, Steve Krug, usability, UX heuristics, "is this confusing", or "will users get this".
---

# Don't Make Me Think

## Overview

Usability lens for app work, built on Steve Krug's *Don't Make Me Think, Revisited* and *Rocket Surgery Made Easy*, reinforced by the core canon (Nielsen's 10 heuristics, Laws of UX, NN/g forms/errors/mobile research, WCAG 2.2).

**Core principle:** every moment a user stops to wonder — *what is this? where am I? is that clickable? what happens if I tap this?* — is a cost. Remove the question, don't explain the answer.

Pairs with `frontend-design-plus` (aesthetics, visual identity). This skill owns *whether people can use it*.

## Pick the mode

| Request | Mode | Read |
|---|---|---|
| "Review / audit this screen", screenshot, component | **Review** | `references/krug.md`, `references/canon.md` |
| "Design / build a screen or flow" | **Design** | `references/krug.md`, `references/canon.md`, `references/copy.md` |
| Button labels, errors, empty states, instructions, any UI text | **Copy** | `references/copy.md` |
| "How do we test this", test debrief | **Test** | `references/testing.md` |

Several modes can apply in one task (designing a screen includes its copy). Run each mode's recipe.

## The five Krug moves (every mode)

1. **Delete before you fix.** For each piece of text, control, and step, first ask whether it should exist. Welcome blurbs, instructions, and "happy talk" usually go. Then halve the remaining words.
2. **Scan test.** Users scan, satisfice, and muddle through. Ask what a hurried user sees in the first 5 seconds and what they'd tap first. Is that the right thing?
3. **Trunk test.** On any screen, can the user tell: what app/area this is, what this page is called, what the main options are, and how to go back? Page name must match the thing they tapped to get here.
4. **Mindless clicks.** Count clicks/taps that require thought, not clicks. Each step must be an obvious, unambiguous choice. Conventions beat cleverness.
5. **Goodwill ledger.** Note what drains the user's reservoir of goodwill (hiding what they need, demanding data in your format, asking for unneeded info, losing their input, fluff in the way) and what refills it (sensible defaults, saved steps, clear recovery, apologizing when it's your fault).

The moves feed the output below. They are not separate write-ups unless a contract names them.

**Smallest change** = the least that removes the problem: deleting, relabeling, resizing, moving, or swapping one control (dropdown → segmented buttons) all count. Rebuilding the flow does not.

## Output contracts

**Review** — pick the template by length asked. Severity = frequency × impact × persistence (scale in `canon.md`). Fill every slot; write "none found" rather than dropping a slot.

Full review:
```
| Sev 0–4 | Where | Problem as the user experiences it | Principle (Krug: happy talk; Nielsen #9…) | Fix (smallest change) |
  …rows, most severe first…
Markup that breaks behavior:  (code/HTML input only; else "n/a — screenshot")
  e.g. <button> without type inside <form> = submit; input without <label for>; wrong input type
Missing states:  loading · offline/retry · double submit · success · empty
Delete list:
Trunk test:  identity · page name · sections · options · you-are-here · back/search
RTL / target language:  (when mock language/direction ≠ shipped app: checks from canon.md)
Top 3 to fix first:
Validate:  the one task to watch 3 users attempt
```

Brief review (user says brief / quick / short on time): same table with Sev ≥ 2 rows only, then **Markup that breaks behavior**, **Top 3**, **Validate**. Nothing else.

**Design** — in order: (1) the user's *one job* on this screen and the top task in their words; (2) what you deliberately left off; (3) layout in visual-hierarchy order with page name, primary action, and defaults; (4) copy for all labels/buttons/errors (Copy mode rules); (5) states: empty, loading, error, success; (6) five-move self-check, one line each; (7) **Validate**: the task to put in front of 3 users with a paper sketch or prototype before building.

**Copy** — for each string: the final text, then one line *why* (what question it answers for the user). If the right answer is "no text", say so and say what replaces it (a page title, a default, a better label). If the true text depends on app behavior you can't see (does it auto-retry? is input kept?), give one version per behavior, labeled with the condition.

**Test** — a filled-in plan from `references/testing.md`: date, 3 participants and how to recruit loosely, 2–4 tasks written as scenarios, the session script adapted to this product, observer setup, and the debrief agenda. If the feature already shipped, round 1 is this week; then the monthly cadence.

## Common mistakes

| Mistake | Instead |
|---|---|
| Writing the requested intro/instruction line | Ask whether the screen needs it; usually give the page a clear name and better labels |
| Generic findings ("improve clarity") | Name the exact element, the user's confusion, and the principle |
| Equal-weight list of 25 issues | Severity-ranked; top 3 first; cosmetic issues batched at the end |
| Redesign as the fix | Krug: smallest tweak that removes the problem |
| Settling an argument by opinion ("users prefer…") | No average user exists; resolve by watching 3 users |
| Plan to test after launch with 5×2 users | Test early, monthly, 3 users, team watches live |
| RTL/Hebrew screen judged by LTR habits | Apply RTL checks in `canon.md` |
