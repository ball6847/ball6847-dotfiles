# Core canon — beyond Krug

Use to name the principle behind a finding and to supply hard numbers.

## Nielsen's 10 usability heuristics (NN/g, 1994, updated 2020)

| # | Heuristic | Typical app violation |
|---|---|---|
| 1 | Visibility of system status | No spinner/progress; no "saved"/"sent" confirmation; unclear offline state |
| 2 | Match between system and real world | Internal codes, DB field names, jargon ("Error 422 field_3") |
| 3 | User control and freedom | No undo/cancel/back; destructive action without escape |
| 4 | Consistency and standards | Same action labeled differently across screens; nonstandard icons |
| 5 | Error prevention | Reset next to Submit; free text where a picker fits; no constraints on dates |
| 6 | Recognition rather than recall | User must remember IDs/codes from another screen; unlabeled icons |
| 7 | Flexibility and efficiency of use | No defaults, no shortcuts, power users forced through wizards |
| 8 | Aesthetic and minimalist design | Happy talk, clutter, competing emphasis (= Krug's noise) |
| 9 | Help users recognize, diagnose, recover from errors | Vague errors, errors far from field, input wiped |
| 10 | Help and documentation | Help missing at point of need, or used to excuse bad design |

## Severity scale (Nielsen)

`0` not a usability problem · `1` cosmetic, fix if time · `2` minor, low priority · `3` major, high priority · `4` catastrophe, fix before release.

Rate on three factors together: **frequency** (how many users hit it), **impact** (easy to overcome, or blocks/loses work?), **persistence** (one-time, or bites every time?). Data loss or task failure on the main path = 4.

## Laws of UX (lawsofux.com, Jon Yablonski) — the ones that matter most

| Law | Use it to |
|---|---|
| **Jakob's law** — users spend most time in *other* apps and expect yours to work the same | Justify following platform conventions |
| **Fitts's law** — time to hit a target depends on its size and distance | Make primary actions big and in reach; separate destructive actions from primary ones |
| **Hick's law** — decision time grows with number and complexity of choices | Cut options, use progressive disclosure, highlight the recommended choice |
| **Doherty threshold** — productivity soars when response < ~400 ms | Optimistic UI, skeletons, instant feedback |
| **Tesler's law** — complexity can't vanish, only move | Move complexity from user to system (defaults, inference, prefill) |
| **Postel's law** — liberal in what you accept | Accept "050-1234567", "0501234567", "+972…"; normalize yourself |
| **Peak-end rule** — experiences judged by peak and end | Nail the success state and the worst moment (errors) |
| **Aesthetic-usability effect** — pretty feels easier | Don't let polish hide problems in tests |
| **Von Restorff (isolation)** — the different item is remembered | Exactly one visually distinct primary action per screen |
| **Serial position** — first and last items best remembered | Key nav items at the ends |
| **Goal-gradient** — effort rises near the goal | Show progress in multistep flows |
| **Miller's law** — working memory is limited | Chunk info; *not* a license for "max 7 menu items" |
| **Gestalt: proximity, common region, similarity** | Group related fields; space separates groups |

## Response-time limits (Nielsen)

0.1 s feels instant · 1 s keeps flow (no indicator needed) · 10 s attention limit — beyond 1 s show progress; beyond 10 s show % or let the user do something else.

## Forms (NN/g + Baymard research)

- Labels **above** fields, visible always. **Never placeholder-as-label** (disappears, low contrast, hurts recall).
- Single column. Group related fields with headings/spacing. Field width hints expected length.
- Mark **required** (or optional — whichever is the minority) explicitly.
- Validate **inline on blur**, not on every keystroke. Error text next to the field, plus a summary at top for long forms; move focus to the first error.
- Keep everything the user entered on error. Never clear the form.
- Ask only what you need. Prefill what you know. Smart defaults.
- Right input for the data: picker/segmented control for ≤5 options; `type`, `inputmode`, `autocomplete` set correctly.
- Button = specific verb + object ("Send report"), never "Submit"/"Proceed"/"OK". No Reset button.
- Prevent double submit: disable + show progress after first tap.

## Error messages (NN/g)

Visible and near the problem · human-readable (no codes) · precise about what went wrong · constructive (how to fix) · polite, no blame · preserve input · offer a recovery action.

## Mobile / touch

- Targets: Apple HIG 44×44 pt, Material 48×48 dp, NN/g ≈ 1×1 cm; ≥ 8 px between targets. Bigger for gloves, motion, poor light.
- Primary action in the thumb zone (bottom of screen), full width when it's the screen's main job.
- Inputs ≥ 16 px font (prevents iOS zoom on focus). Allow pinch zoom.
- Design for interruption: save drafts, survive backgrounding, handle offline and retry.
- Don't rely on hover, long-press, or undiscoverable gestures for core actions.

## WCAG 2.2 AA — numbers to check

| Criterion | Requirement |
|---|---|
| 1.4.3 Contrast | Text 4.5:1; large text (≥ 24 px, or ≥ 18.66 px bold) 3:1 |
| 1.4.11 Non-text contrast | UI component boundaries, icons, focus rings 3:1 |
| 1.4.10 Reflow | Usable at 320 CSS px width without 2-D scrolling |
| 1.4.4 Resize text | Works at 200% text size |
| 2.4.7 / 2.4.11 Focus | Focus visible; not hidden behind sticky headers/footers |
| 2.5.7 Dragging | Every drag action has a single-pointer alternative (buttons/menu) |
| 2.5.8 Target size (min) | ≥ 24×24 CSS px (AAA 2.5.5: 44×44) |
| 3.3.1 / 3.3.2 | Errors identified in text; inputs have labels/instructions |
| 3.3.7 Redundant entry | Don't make users re-enter info already given in the same process |
| 1.4.1 Use of color | Color never the only signal (add icon/text) |

## RTL (Hebrew/Arabic) checks

- Whole layout mirrors: reading starts top-right, primary action on the right in button pairs, back arrow points right, progress flows right→left. Use logical CSS (`margin-inline-start`, `inset-inline-end`).
- **Don't mirror:** clocks, media play icons, checkmarks, logos, charts' numeric axes when convention is LTR, phone numbers, codes, numbers.
- Wrap LTR runs (phone numbers, IDs, emails, mixed Latin) in `<bdi>` or `dir="ltr"` so punctuation doesn't jump.
- Hebrew imperatives are gendered: prefer infinitive ("לשלוח דיווח"), noun form ("שליחת דיווח"), or plural ("שלחו") for neutral copy.
- Test with real Hebrew strings, not lorem or English: Hebrew is often shorter, but mixed bidi lines break layouts.
