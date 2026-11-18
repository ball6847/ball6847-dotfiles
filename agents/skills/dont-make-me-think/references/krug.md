# Krug — principles as checks

Source: Steve Krug, *Don't Make Me Think, Revisited* (3rd ed., 2014). Each principle is phrased as a check you can run against a screen.

## Three laws

| Law | Check |
|---|---|
| **1. Don't make me think.** A page should be self-evident; failing that, self-explanatory. | Would a first-time user know what this is and how to use it without reading? Any "question mark" moment (cute names, marketing-ese, unclear clickables) is a defect. |
| **2. Clicks don't matter; thinking does.** "It doesn't matter how many times I have to click, as long as each click is a mindless, unambiguous choice." | Count the decisions, not the taps. Three obvious taps beat one confusing screen. |
| **3. Omit needless words.** "Get rid of half the words on each page, then get rid of half of what's left." | Can this text be cut by half without losing meaning? Then cut it. |

## How users really behave

- **They scan, they don't read.** Look for words matching their goal; ignore the rest.
- **They satisfice.** Pick the first reasonable option, not the best one. If the first plausible tap is wrong, that's your bug.
- **They muddle through.** They don't figure out how things work; they find something that works and keep using it, even if it's the slow way.

Design implication: the *first plausible* thing must be the *right* thing.

## Billboard design (designing for scanning)

| Check | What good looks like |
|---|---|
| **Conventions** | Use the patterns people already know (logo top, back arrow, cart icon, tab bar, search magnifier). Innovate only when clearly better *and* still self-evident. Consistency is good, clarity beats it. |
| **Visual hierarchy** | More important = more prominent. Related things are grouped visually. Nesting shows what's part of what. |
| **Clearly defined areas** | User can point at "the nav", "the content", "the actions" within seconds. |
| **Obvious clickables** | Tappable things look tappable (shape, color, label). Flat design that hides affordances fails here. |
| **Noise** | Kill three kinds: *shouting* (everything bold/red/urgent), *disorganization* (no grid), *clutter* (too much stuff). |
| **Formatted for scanning** | Headings, short paragraphs, bulleted lists, key terms highlighted. |

## Omit needless words

- **Happy talk must die.** Welcome blurbs, "This innovative module empowers you…", self-congratulation. Zero information, pushes content down.
- **Instructions must die.** Make it obvious instead. Where instructions are unavoidable, make them minimal and place them at the point of need, not at the top.

## Navigation and the trunk test

Navigation tells people what's here, where they are, and how to get around. Every page needs a **name**, in the right place, prominent, matching what they clicked to get there. Show **"you are here"** indicators clearly (not subtly).

**Trunk test** — drop a user on any screen cold. They should immediately identify:
1. What app/site is this? (identity)
2. What page/screen am I on? (page name)
3. What are the major sections?
4. What are my options at this level?
5. Where am I in the scheme of things? (you-are-here)
6. How can I search / go back?

## Home / entry screens

Within seconds, the entry screen must answer: what is this, what can I do here, why here. Use a **tagline** (clear, informative, 6–8 words) not a slogan. Don't let every stakeholder add "just one more thing".

## Religious debates

Teams argue from personal preference ("I hate dropdowns"). There is **no average user**; all web use is idiosyncratic. Settle "does X work?" by watching people use it, not by debate.

## Reservoir of goodwill

Each user arrives with some goodwill; every annoyance drains it, and when empty they leave.

**Drains:** hiding info users want (prices, contact, status); punishing them for not doing it your way (formatting phone numbers, dates); asking for info you don't need; fake sincerity / "your call is important"; sizzle in the way (splash screens, long intros, autoplay); looking amateurish.

**Refills:** know the main things people want and make them obvious; tell them what they want to know up front; save steps wherever you can; put effort into it; anticipate questions and answer them; creature comforts; make it easy to recover from errors; *when in doubt, apologize.*

## Mobile

- Tradeoffs are real, but managing small screens must not come at the cost of usability.
- Affordances matter more: no hover on touch, so tappability must be visible.
- Allow zoom. Don't hide key features behind gestures nobody discovers.
- Make it memorable: users return after weeks and should not have to relearn.
- Speed is usability; perceived slowness kills goodwill.

## Accessibility

Fixing confusing UI is the biggest accessibility win, since it helps everyone. Then cover the basics: alt text, real labels on inputs, keyboard access, visible focus, skip links, semantic headings. (Numbers in `canon.md`.)

## Usability as common courtesy

Every principle above reduces to respect: don't waste the user's time, don't make them do your work, tell them the truth.
