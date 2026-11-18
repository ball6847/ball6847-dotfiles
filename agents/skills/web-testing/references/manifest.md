# Manifest schema

The manifest is a JSON file. `scripts/build_report.py` reads it and writes `report.html`.

```bash
python3 scripts/build_report.py ./manifest.json ./out
```

## Top level

| Key | Type | Required | Meaning |
| --- | --- | --- | --- |
| `title` | string | yes | The subject of the test, shown as the h1 and in the nav |
| `product` | string | no | The product name, shown next to "Test execution report" |
| `date` | string | no | ISO date, `2026-11-18`. Rendered as a `<time>` element |
| `subtitle` | string | no | One line under the title |
| `accent` | string | no | Hex colour for the frame of the report, `#16408f` by default. Set it to the product's own accent |
| `chips` | array | no | Small labels in the masthead, `{"label": "Branch", "value": "feat/x"}` |
| `summary_headline` | string | yes | The one sentence a reader acts on |
| `summary_body` | string | yes | What was tested and against what |
| `metadata` | array | no | Definition rows under the summary, `{"label": "Build", "value": "commit abc1234"}` |
| `paths` | array | no | The paths under test, side by side. `{"title": "...", "body": "..."}` |
| `steps` | array | yes | The steps, in the order they ran |
| `findings` | array | no | What needs a human decision |
| `notes` | array of strings | no | Anything else the reader needs |
| `footer` | string | no | One line at the bottom |
| `screenshots_dir` | string | no | Folder the `file` paths in the shots are relative to |

## Steps

| Key | Type | Meaning |
| --- | --- | --- |
| `title` | string | What this step proves |
| `status` | string | `pass`, `fail` or `blocked`. Defaults to `pass` |
| `expected` | string | What the spec says should happen |
| `actual` | string | What the screen actually showed |
| `notes` | string | Anything else about this step |
| `number` | number | Optional, overrides the position in the list |
| `screenshots` | array | The shots taken at this step |

A step with `status` `fail` or `blocked` is counted in the failed total and the verdict becomes `FAIL`.

## Screenshots

```json
{"file": "shots/03-after-connect.png", "caption": "Facebook card after Connect", "alt": "Description of the image for a reader who cannot see it"}
```

- `file` is a path relative to `screenshots_dir`, or an absolute path
- `caption` is the label under the image and the title in the full screen bar. Write it so a reader knows what they are looking at without opening it
- `alt` describes the image itself. It is read aloud by a screen reader and used when the image cannot be shown

The generator copies every file into `out/screenshots/` and rewrites the path.

## Findings

```json
{
  "id": "F1",
  "title": "The page picker hides the result message",
  "body": "What happens, in what order, and how to reproduce it",
  "impact": "What it costs the user",
  "screenshots": []
}
```

`id` is a short label such as `F1`. `body` and `impact` may use `**text**` to mark inline code.

Findings drive the "Needs a decision" block in the summary and the findings section. A finding that carries screenshots gets its own entry in the full screen overlay.

## Inline code

Any string may wrap a fragment in `**double asterisks**` to render it as inline code:

```json
{"body": "The callback answers with **facebookConnect=connected**"}
```

Everything else is escaped, so a value containing `<` or `&` is safe.

## Full example

```json
{
  "title": "Facebook Messenger OAuth",
  "product": "Chatplus",
  "date": "2026-11-18",
  "subtitle": "End to end result with screenshot evidence",
  "accent": "#16408f",
  "chips": [
    {"label": "Branch", "value": "feat/messenger-oauth"},
    {"label": "Commit", "value": "66b5782b"}
  ],
  "summary_headline": "Connect, receive a message and reply all the way through",
  "summary_body": "Ran against the real Meta consent screen, a real webhook delivery and the real send API. Checked against the requirements document.",
  "metadata": [
    {"label": "Build", "value": "platform feat/messenger-oauth at 66b5782b"},
    {"label": "System", "value": "API on :18880, worker from the same build, Mongo replica set, Temporal"}
  ],
  "paths": [
    {"title": "One page", "body": "The callback connects that page and answers **facebookConnect=connected**."},
    {"title": "Several pages", "body": "The callback stores the grant and answers **facebookConnect=choose**."}
  ],
  "steps": [
    {
      "title": "The Channels page lists the Facebook channel",
      "status": "pass",
      "expected": "A Facebook card with a Connect button",
      "actual": "The card and the button are there",
      "screenshots": [
        {"file": "shots/01-channels.png", "caption": "Facebook channel card", "alt": "The Settings Channels page with a Facebook card and a Connect button"}
      ]
    },
    {
      "title": "The reply deadline expires before a human answers",
      "status": "blocked",
      "expected": "The composer stays usable until a person replies",
      "actual": "The run stopped here, the seed data for this case was missing",
      "notes": "Seeding this case needs a database write, which is not allowed during a run."
    }
  ],
  "findings": [
    {
      "id": "F1",
      "title": "The page picker hides the result message",
      "body": "The success message renders behind the modal, so a reader cannot see it while the modal is open.",
      "impact": "A user cannot tell whether the page connected.",
      "screenshots": [
        {"file": "shots/20-picker.png", "caption": "Result message behind the page picker", "alt": "A modal with a page list on top of a success message"}
      ]
    }
  ],
  "notes": [
    "The reply deadline finding is not a verdict, it is a gap in the run."
  ],
  "footer": "Generated from a test run on 2026-11-18.",
  "screenshots_dir": "."
}
```
