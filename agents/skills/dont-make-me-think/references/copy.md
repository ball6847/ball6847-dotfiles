# UI copy — microcopy recipe

Krug's third law applies hardest here: get rid of half the words, then half of what's left. Users scan for words that match their goal.

## Step 0 — should this text exist?

Before writing, check:
- **Intro / welcome / instructions at top of a screen?** Usually replace with a clear page title plus labels that make instructions unnecessary. If a hint is truly needed, put one short line *at the field* where it's needed.
- **Tooltip explaining a control?** Fix the control's label instead.
- **Confirmation dialog?** Only for destructive or irreversible actions. Otherwise do it and offer undo.

If the answer is "no text", say so and name what replaces it.

## Recipes by string type

| String | Shape | Example (EN / HE) |
|---|---|---|
| **Page title** | Noun phrase naming the thing the user tapped to get here | "Report task" / "דיווח משימה" |
| **Primary button** | Verb + object, says what happens | "Send report" / "שליחת דיווח" — not "Submit", "Proceed", "אישור" |
| **Destructive button** | Verb + object, names the loss | "Delete patrol" / "מחיקת סבב" |
| **Field label** | 1–3 words, noun, matches the user's term | "Site" / "אתר" |
| **Inline hint** | Only format or constraint the user can't guess | "Up to 3 photos" |
| **Error** | What happened + how to fix, in user terms; say whether input is kept | "No signal. Your photo is saved and will send when you're back online." |
| **Empty state** | Why it's empty + what will appear / what to do next (+ action if one exists) | "No tasks for today. New tasks assigned to you will appear here." |
| **Success** | Confirm the outcome concretely, then the next step | "Report sent" + return to task list |
| **Loading** | Say what's happening if > 1 s | "Uploading photo…" |

## Rules that apply to all

- **User's words, not the system's.** No codes, field names, or internal jargon. Match the names on the physical world (site names, task types) the user already knows.
- **Front-load the key word.** Scanners read the first 2 words.
- **Be honest.** Only say "saved", "automatic", "less than a minute" if true. Lying spends goodwill.
- **Apologize when it's our fault** (server, network on our side), never blame the user.
- **Consistent terms.** One name per concept across the whole app (don't mix "patrol"/"round"/"tour").
- **No happy talk:** "Welcome!", "Thank you for your cooperation!", "innovative", "seamlessly", "empowers".

## Hebrew specifics

- Avoid gendered imperatives in shared UI: use infinitive (לשלוח), noun form (שליחת דיווח), or plural (שלחו).
- Keep numbers, phone numbers, and codes as LTR runs (`<bdi>`).
- Have a native speaker read strings on a real device before shipping.

## Output per string

```
<final text>
  why: <the question it answers for the user, or why no text>
```
