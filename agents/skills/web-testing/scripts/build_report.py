#!/usr/bin/env python3
"""Build a self-contained HTML test report from a JSON manifest.

The manifest describes the run: the verdict, the metadata, the steps, the
findings and the notes. Every step may carry screenshots. The script embeds
every screenshot and the font in the HTML, so one file opens from disk with
no network access and no folder beside it.

Usage:
    python3 build_report.py <manifest.json> [output-path]

The output path may be a directory, which gets report.html, or a path ending
in .html. The manifest schema is documented in references/manifest.md.
"""

from __future__ import annotations

import base64
import html
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent / "assets"


def esc(value: object) -> str:
    """Escape text for HTML, keeping the markup of inline code spans intact.

    A manifest may write a product name as `**facebookConnect=connected**` to
    mean inline code. Everything else is escaped.
    """
    text = html.escape(str(value), quote=False)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<code>\1</code>", text)
    return text


def slug(text: str) -> str:
    out = re.sub(r"[^a-z0-9]+", "-", str(text).lower()).strip("-")
    return out or "item"


def mix(first: str, second: str, weight: float) -> str:
    """Mix two hex colours. Weight is how much of the second one ends up in the result."""

    def parts(value: str) -> tuple[int, int, int]:
        value = value.lstrip("#")
        return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]

    a, b = parts(first), parts(second)
    mixed = [round(a[i] + (b[i] - a[i]) * weight) for i in range(3)]
    return "#" + "".join(f"{value:02x}" for value in mixed)


def shift(color: str, amount: float) -> str:
    """Darken a hex colour. Amount is between -1 and 1."""
    value = color.lstrip("#")
    channels = [int(value[i : i + 2], 16) for i in (0, 2, 4)]
    shifted = [max(0, min(255, round(channel * (1 + amount)))) for channel in channels]
    return "#" + "".join(f"{channel:02x}" for channel in shifted)


def image_size(path: Path) -> tuple[int, int]:
    """Read the pixel size of a PNG without any third party library."""
    try:
        with path.open("rb") as handle:
            head = handle.read(26)
        if head[:8] != b"\x89PNG\r\n\x1a\n":
            return 3024, 1602
        width = int.from_bytes(head[16:20], "big")
        height = int.from_bytes(head[20:24], "big")
        if width <= 0 or height <= 0:
            return 3024, 1602
        return width, height
    except Exception:
        return 3024, 1602


class ShotIndex:
    """One counter for every screenshot in the report.

    The overlay and the figure in the body have to agree on the numbering,
    so both read it from here. The figure gets ev-NN, the overlay gets
    view-NN, and the overlay links back to its own figure.
    """

    def __init__(self) -> None:
        self.entries: list[dict] = []

    def add(self, shot: dict) -> int:
        src = shot["src"]
        width, height = image_size(Path(shot.get("path", src)))
        self.entries.append(
            {
                "src": src,
                "width": width,
                "height": height,
                "caption": shot.get("caption", ""),
                "alt": shot.get("alt", shot.get("caption", "")),
                "file": Path(shot.get("path", src)).name,
            }
        )
        return len(self.entries)

    def __len__(self) -> int:
        return len(self.entries)


def figure_html(index: ShotIndex, shot: dict, indent: str) -> str:
    """Render one evidence figure, numbered from the shared index."""
    number = index.add(shot)
    src = shot["src"]
    caption = shot.get("caption", "")
    alt = shot.get("alt", caption)
    size_width = index.entries[number - 1]["width"]
    size_height = index.entries[number - 1]["height"]
    return (
        f'{indent}<figure class="evidence" id="ev-{number:02d}">\n'
        f'{indent}  <a class="preview" href="#view-{number:02d}" '
        f'aria-label="Expand to full screen: {esc(caption)}">\n'
        f'{indent}    <img src="{esc(src)}" width="{size_width}" '
        f'height="{size_height}" alt="{esc(alt)}" loading="lazy">\n'
        f"{indent}  </a>\n"
        f'{indent}  <figcaption><span>{esc(caption)}</span>'
        f'<a href="{esc(src)}" aria-label="Open full size: {esc(caption)}">'
        f'<code translate="no">{esc(Path(shot.get("path", src)).name)}</code></a></figcaption>\n'
        f"{indent}</figure>"
    )


def build_steps(steps: list[dict], index: ShotIndex) -> str:
    blocks = []
    total = len(steps)

    for position, step in enumerate(steps, start=1):
        number = step.get("number", position)
        status = step.get("status", "pass")
        badge = {
            "pass": "PASS",
            "fail": "FAIL",
            "blocked": "BLOCKED",
        }.get(status, "PASS")
        badge_class = {"pass": "", "fail": " fail", "blocked": " blocked"}.get(status, "")

        parts = [
            f'          <li class="step" id="step-{number}">',
            f'            <span class="step-number" aria-hidden="true">{esc(number)}</span>',
            '            <div class="step-heading">',
            f'              <h3>{esc(step["title"])}</h3>',
            f'              <span class="step-count" aria-hidden="true">{number} / {total}</span>',
            f'              <span class="pass{badge_class}" translate="no">{badge}</span>',
            '            </div>',
        ]
        if step.get("expected"):
            parts.append(
                f'            <p class="step-note"><span class="step-note-label">Expected</span>'
                f' {esc(step["expected"])}</p>'
            )
        if step.get("actual"):
            parts.append(
                f'            <p class="step-note"><span class="step-note-label">Observed</span>'
                f' {esc(step["actual"])}</p>'
            )
        if step.get("notes"):
            parts.append(f'            <p class="step-note">{esc(step["notes"])}</p>')

        for shot in step.get("screenshots", []):
            parts.append(figure_html(index, shot, "            "))

        parts.append("          </li>")
        blocks.append("\n".join(parts))

    return "\n".join(blocks)


def build_findings(findings: list[dict], index: ShotIndex) -> tuple[str, str]:
    index_rows = []
    cards = []
    for position, finding in enumerate(findings, start=1):
        fid = finding.get("id", f"F{position}")
        index_rows.append(
            f'          <li><a href="#f-{slug(fid)}"><span>{esc(fid)}</span>'
            f'<span>{esc(finding["title"])}</span></a></li>'
        )
        body = [f'      <article class="finding" id="f-{slug(fid)}">']
        body.append(
            f'        <h3><span class="finding-id" translate="no">{esc(fid)}</span>'
            f'{esc(finding["title"])}</h3>'
        )
        body.append(f'        <div class="finding-copy"><p>{esc(finding.get("body", ""))}</p>')
        if finding.get("impact"):
            body.append(
                f'          <p class="impact"><strong>Impact</strong> {esc(finding["impact"])}</p>'
            )
        body.append("        </div>")
        for shot in finding.get("screenshots", []):
            body.append(figure_html(index, shot, "        "))
        body.append("      </article>")
        cards.append("\n".join(body))
    return "\n".join(index_rows), "\n".join(cards)


def build_overlays(index: ShotIndex) -> str:
    blocks = []
    total = len(index)
    for number, shot in enumerate(index.entries, start=1):
        previous = (
            f'<a class="overlay-step" href="#view-{number - 1:02d}" data-step="prev" '
            f'aria-label="Previous image" rel="prev">&#8249;</a>'
            if number > 1
            else '<span class="overlay-step is-disabled" aria-hidden="true">&#8249;</span>'
        )
        following = (
            f'<a class="overlay-step" href="#view-{number + 1:02d}" data-step="next" '
            f'aria-label="Next image" rel="next">&#8250;</a>'
            if number < total
            else '<span class="overlay-step is-disabled" aria-hidden="true">&#8250;</span>'
        )
        blocks.append(
            f"""      <div class="overlay" id="view-{number:02d}" role="dialog" aria-modal="true" aria-label="{esc(shot['caption'])}">
        <a class="overlay-backdrop" href="#ev-{number:02d}" tabindex="-1" aria-hidden="true"></a>
        <div class="overlay-bar">
          <div class="overlay-heading">
            <span class="overlay-title">{esc(shot['caption'])}</span>
            <code class="overlay-file" translate="no">{esc(shot['file'])}</code>
          </div>
          <div class="overlay-tools">
            <span class="overlay-count" aria-label="Image {number} of {total}">{number} / {total}</span>
            {previous}
            {following}
            <a class="overlay-close" href="#ev-{number:02d}">Close image</a>
          </div>
        </div>
        <img class="overlay-img" src="{esc(shot['src'])}" width="{shot['width']}" height="{shot['height']}" alt="{esc(shot['alt'])}">
      </div>"""
        )
    return "\n".join(blocks)


def embed_screenshots(manifest: dict, manifest_path: Path) -> None:
    """Replace every screenshot file with an inline PNG data URI.

    The report must open from file:// with no broken image links. A relative
    link would resolve against wherever the HTML file is saved, which is not
    the evidence folder. Keeping the bytes in the HTML makes the report a
    single portable file.
    """
    shots_dir = manifest.get("screenshots_dir")
    shots_root = Path(shots_dir).expanduser() if shots_dir else None
    if shots_root is not None and not shots_root.is_absolute():
        shots_root = manifest_path.parent / shots_root
    embedded: dict[str, str] = {}

    def resolve(name: str) -> Path:
        candidate = Path(name).expanduser()
        if not candidate.is_absolute():
            candidate = manifest_path.parent / candidate
        if candidate.exists():
            return candidate
        if shots_root and (shots_root / name).exists():
            return shots_root / name
        return candidate if not shots_root else shots_root / name

    def store(name: str) -> str:
        if name in embedded:
            return embedded[name]
        source = resolve(name)
        if not source.exists():
            raise SystemExit(f"screenshot not found: {source}")
        encoded = base64.b64encode(source.read_bytes()).decode("ascii")
        embedded[name] = f"data:image/png;base64,{encoded}"
        return embedded[name]

    for group in (manifest.get("steps", []), manifest.get("findings", [])):
        for item in group:
            for shot in item.get("screenshots", []):
                source = resolve(shot["file"])
                shot["src"] = store(shot["file"])
                shot["path"] = str(source.resolve())


def build_step_index(steps: list[dict]) -> str:
    rows = []
    for position, step in enumerate(steps, start=1):
        number = step.get("number", position)
        rows.append(
            f'          <li><a href="#step-{number}"><span class="step-n">{esc(number)}</span>'
            f'<span>{esc(step["title"])}</span></a></li>'
        )
    return "\n".join(rows)


def build_metadata(rows: list[dict]) -> str:
    blocks = []
    for row in rows:
        blocks.append(
            f'          <div>\n            <dt>{esc(row["label"])}</dt>\n'
            f'            <dd>{esc(row["value"])}</dd>\n          </div>'
        )
    return "\n".join(blocks)


def build_paths(paths: list[dict]) -> str:
    blocks = []
    for path in paths:
        blocks.append(
            f'          <article class="path">\n            <h3>{esc(path["title"])}</h3>\n'
            f'            <p>{esc(path.get("body", ""))}</p>\n          </article>'
        )
    return "\n".join(blocks)


def build_notes(notes: list[str]) -> str:
    items = "\n".join(f"        <li>{esc(note)}</li>" for note in notes)
    return f"      <ul>\n{items}\n      </ul>"


def apply_accent(css: str, accent: str) -> str:
    """Recolour the frame of the report with the product's own accent."""
    replacements = [
        (r"(--chrome:\s*)#[0-9a-fA-F]{6}", accent),
        (r"(--chrome-deep:\s*)#[0-9a-fA-F]{6}", shift(accent, -0.45)),
        (r"(--chrome-soft:\s*)#[0-9a-fA-F]{6}", mix(accent, "#ffffff", 0.92)),
        (r"(--chrome-line:\s*)#[0-9a-fA-F]{6}", mix(accent, "#ffffff", 0.72)),
        (r"(--ring:\s*)#[0-9a-fA-F]{6}", accent),
    ]
    for pattern, value in replacements:
        css = re.sub(pattern, lambda m, v=value: m.group(1) + v, css, count=1)
    return css


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    manifest_path = Path(sys.argv[1]).expanduser().resolve()
    if len(sys.argv) > 2:
        output = Path(sys.argv[2]).expanduser().resolve()
    else:
        output = manifest_path.parent / "report.html"
    if output.suffix.lower() != ".html":
        output = output / "report.html"
    out_dir = output.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    with manifest_path.open(encoding="utf-8") as handle:
        manifest = json.load(handle)

    embed_screenshots(manifest, manifest_path)

    steps = manifest.get("steps", [])
    findings = manifest.get("findings", [])

    index = ShotIndex()
    steps_html = build_steps(steps, index)
    finding_index, finding_cards = build_findings(findings, index)
    overlays_html = build_overlays(index)

    passed = sum(1 for step in steps if step.get("status", "pass") == "pass")
    blocked = sum(1 for step in steps if step.get("status") == "blocked")
    hard_failed = sum(1 for step in steps if step.get("status") == "fail")
    failed = hard_failed + blocked
    decided = len(findings)
    total = len(steps)

    verdict = "PASS" if not failed else "FAIL"

    parts = []
    if hard_failed:
        parts.append(f"{hard_failed} failed")
    if blocked:
        parts.append(f"{blocked} blocked")
    failed_note = "" if not parts else ", " + " and ".join(parts)

    segments = "".join(
        f'<span class="seg-{ {"pass": "pass", "fail": "fail", "blocked": "blocked"}.get(step.get("status", "pass"), "pass") }"></span>'
        for step in steps
    )

    verdict_panel_class = "result-panel" if verdict == "PASS" else "result-panel is-fail"

    chips = "".join(
        f'\n          <span class="chip">{esc(chip["label"])} <code translate="no">'
        f'{esc(chip["value"])}</code></span>'
        for chip in manifest.get("chips", [])
    )

    nav_items = []
    if manifest.get("paths"):
        nav_items.append('<a href="#paths">Paths under test</a>')
    nav_items.append(f'<a href="#steps">All {total} steps</a>')
    if findings:
        word = "finding" if decided == 1 else "findings"
        nav_items.append(f'<a href="#findings">{decided} {word}</a>')
    if manifest.get("notes"):
        nav_items.append('<a href="#notes">Notes for the reader</a>')

    pill_class = "pass-pill" if verdict == "PASS" else "pass-pill is-fail"
    pass_pill = f'<a class="{pill_class}" href="#summary" translate="no">{verdict} {passed}/{total}</a>'

    decision_block = ""
    if findings:
        rows = "\n".join(
            f'            <li><a href="#f-{slug(f.get("id", ""))}">'
            f'<span class="finding-id" translate="no">{esc(f.get("id", ""))}</span>'
            f'{esc(f["title"])}</a></li>'
            for f in findings
        )
        decision_block = (
            '        <div class="decision-summary">\n'
            '          <p class="eyebrow">Needs a decision</p>\n'
            f"          <ol>\n{rows}\n          </ol>\n"
            "        </div>"
        )

    paths_block = ""
    if manifest.get("paths"):
        paths_block = (
            '      <section class="section" id="paths" aria-labelledby="paths-title">\n'
            '        <p class="eyebrow">What was tested</p>\n'
            '        <h2 id="paths-title">Paths under test</h2>\n'
            f'        <div class="paths">\n{build_paths(manifest["paths"])}\n        </div>\n'
            "      </section>\n"
        )

    findings_block = ""
    if findings:
        findings_block = (
            '      <section class="section" id="findings" aria-labelledby="findings-title">\n'
            '        <div class="findings-header">\n'
            '          <p class="eyebrow">Findings</p>\n'
            '          <h2 id="findings-title">What needs a decision</h2>\n'
            f'          <ul class="finding-index">\n{finding_index}\n          </ul>\n'
            "        </div>\n"
            f"{finding_cards}\n"
            "      </section>\n"
        )

    notes_block = ""
    if manifest.get("notes"):
        notes_block = (
            '      <section class="section" id="notes" aria-labelledby="notes-title">\n'
            '        <p class="eyebrow">For the reader</p>\n'
            '        <h2 id="notes-title">Notes</h2>\n'
            f'        <div class="notes">\n{build_notes(manifest["notes"])}\n        </div>\n'
            "      </section>\n"
        )

    css = (ASSETS / "report.css").read_text(encoding="utf-8")
    if manifest.get("accent"):
        css = apply_accent(css, manifest["accent"])

    # A report must be one portable file, so the font travels inside the CSS.
    font_data = base64.b64encode((ASSETS / "inter-latin-var.woff2").read_bytes()).decode("ascii")
    css = css.replace(
        'url("fonts/inter-latin-var.woff2")',
        f'url("data:font/woff2;base64,{font_data}")',
        1,
    )

    title = manifest.get("title", "Test report")
    subtitle = manifest.get("subtitle", "")
    product = manifest.get("product", "")
    date = manifest.get("date", "")
    headline = manifest.get("summary_headline", "")
    summary_body = manifest.get("summary_body", "")
    footer = manifest.get("footer", "")

    document = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <meta name="description" content="{esc(title)}. {esc(subtitle)}">
  <title>{esc(title)} | Test execution report</title>
  <style>
{css}  </style>
</head>
<body>
  <a class="skip-link" href="#main">Skip to the report body</a>
  <div class="document">
    <header class="masthead">
      <div class="header-line eyebrow">
        <p>Test execution report{(" &middot; " + esc(product)) if product else ""}</p>
        <p><time datetime="{esc(date)}" translate="no">{esc(date)}</time></p>
      </div>
      <p class="overline" translate="no">Test execution report</p>
      <div class="title-block">
        <h1>{esc(title)}</h1>
        <p>{esc(subtitle)}</p>
      </div>
      <p class="masthead-meta">{chips}
      </p>
    </header>

    <div class="contents-wrap">
    <nav class="contents" aria-label="Contents">
      <span class="contents-title">{esc(title)}</span>
      {pass_pill}
      {"".join(nav_items)}
    </nav>
    <div class="progress" aria-hidden="true"></div>
    </div>

    <main id="main">
      <section id="summary" aria-labelledby="summary-title">
        <div class="{verdict_panel_class}">
          <div class="verdict-block">
            <p class="verdict" translate="no">{verdict}</p>
            <p class="result-count">{passed} of {total} steps passed{failed_note}</p>
            <div class="segments" aria-hidden="true">
              {segments}
            </div>
          </div>
          <div class="result-copy">
            <h2 id="summary-title">{esc(headline)}</h2>
            <p>{esc(summary_body)}</p>
            <ul class="legend">
              <li><span class="legend-swatch swatch-pass" aria-hidden="true"></span>Passed {passed}</li>
              <li><span class="legend-swatch swatch-fail" aria-hidden="true"></span>Failed {failed}</li>
              <li><span class="legend-swatch swatch-decision" aria-hidden="true"></span>Needs a decision {decided}</li>
            </ul>
          </div>
        </div>
{decision_block}        <dl class="metadata">
{build_metadata(manifest.get("metadata", []))}
        </dl>
      </section>

{paths_block}      <section class="section" id="steps" aria-labelledby="steps-title">
        <p class="eyebrow">Evidence from the run</p>
        <h2 id="steps-title">All {total} steps</h2>
        <p class="section-intro">Every step states its result and shows the screenshots taken at that point. Click a file name under an image to open it full size.</p>

        <nav class="step-map" aria-label="Step index">
          <ol>
{build_step_index(steps)}
          </ol>
        </nav>

        <ol class="steps" role="list">
{steps_html}
        </ol>
      </section>

{findings_block}{notes_block}    </main>

    <footer>
      {esc(footer)}
    </footer>
  </div>

  <!-- Full screen images live at the end of the document, not inside a card.
       A card has an animation that touches transform, which makes it the
       containing block for a position fixed overlay, so an overlay placed
       inside a card would be clipped to the card instead of the viewport. -->
  <div class="overlay-host">
{overlays_html}
  </div>

  <script>
    /* The full screen image opens with CSS :target, so the report works with
       no JavaScript at all. This script only adds three things:
       1. Esc closes the image
       2. focus moves into the image when it opens and back to the thumbnail
          when it closes
       3. Tab stays inside the image, it never falls through to the page
          underneath */
    (function () {{
      function overlayNow() {{
        return document.querySelector('.overlay:target');
      }}

      function thumbnailFor(id) {{
        return document.querySelector('a.preview[href="#' + id + '"]');
      }}

      function closeButtonOf(overlay) {{
        return overlay.querySelector('.overlay-close');
      }}

      window.addEventListener('hashchange', function () {{
        var overlay = overlayNow();
        if (overlay) {{
          var close = closeButtonOf(overlay);
          if (close) close.focus({{ preventScroll: true }});
        }}
      }});

      /* The step buttons and the close button use location.replace so the
         browser history does not grow one entry per image. The Back button
         then always returns to the position before the image was opened. */
      document.addEventListener('click', function (event) {{
        var link = event.target && event.target.closest
          ? event.target.closest('.overlay-step, .overlay-close, .overlay-backdrop')
          : null;
        if (!link || link.tagName !== 'A') return;
        event.preventDefault();
        location.replace(link.getAttribute('href'));
      }});

      document.addEventListener('keydown', function (event) {{
        var overlay = overlayNow();
        if (!overlay) return;

        if (event.key === 'Escape') {{
          event.preventDefault();
          var close = closeButtonOf(overlay);
          if (close) {{
            location.replace(close.getAttribute('href'));
          }} else {{
            location.replace('#summary');
          }}
          var thumbnail = thumbnailFor(overlay.id);
          if (thumbnail) {{
            setTimeout(function () {{
              thumbnail.focus({{ preventScroll: true }});
            }}, 0);
          }}
          return;
        }}

        if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {{
          var step = overlay.querySelector(
            event.key === 'ArrowLeft'
              ? '.overlay-step[data-step="prev"]'
              : '.overlay-step[data-step="next"]'
          );
          if (step && step.tagName === 'A') {{
            event.preventDefault();
            step.click();
          }}
          return;
        }}

        if (event.key === 'Tab') {{
          /* Keep focus inside the image, cycle through the buttons that can
             actually be pressed: the step buttons and the close button. */
          var focusable = Array.prototype.filter.call(
            overlay.querySelectorAll('a[href]'),
            function (item) {{
              return item.getAttribute('tabindex') !== '-1'
                && item.getAttribute('aria-hidden') !== 'true';
            }}
          );
          if (!focusable.length) return;
          var position = focusable.indexOf(document.activeElement);
          var next = focusable[(position + (event.shiftKey ? -1 : 1) + focusable.length) % focusable.length];
          event.preventDefault();
          next.focus();
        }}
      }});

      /* When the report is opened straight on an image link the browser moves
         focus to the document after the script ends, so wait for the load
         event before moving the focus ourselves. */
      window.addEventListener('load', function () {{
        var overlay = overlayNow();
        var close = overlay && closeButtonOf(overlay);
        if (close) close.focus({{ preventScroll: true }});
      }});
    }})();
  </script>
</body>
</html>
"""

    output.write_text(document, encoding="utf-8")
    print(f"wrote {output}")
    print(f"  steps: {total}, passed: {passed}, failed: {failed}, findings: {decided}")
    print(f"  images: {len(index)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
