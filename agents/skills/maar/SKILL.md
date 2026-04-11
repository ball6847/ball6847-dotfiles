---
name: maar
description: |
  Mermaid ASCII Auto-Renderer — render Mermaid .mmd diagram files into ASCII art
  and inject them into Markdown documents automatically.

  Use this skill when:
  1. User asks to "add a diagram" or "create a diagram" in Markdown docs
  2. User wants to render .mmd files into ASCII in their README or docs
  3. User needs architecture, flowchart, sequence, state, class, or ER diagrams
  4. User mentions "mermaid" or ".mmd" files
  5. User wants to update existing MAAR-injected diagrams
  6. Agent needs to document system architecture visually
  7. User says "generate a flowchart", "create a sequence diagram", etc.
---

# MAAR — Mermaid ASCII Auto-Renderer

Render Mermaid diagrams as ASCII art and inject them into Markdown files automatically. Keep
diagrams as code (`.mmd` files) in version control, with rendered ASCII output in your docs.

## Quick Start

```bash
# Install Deno (if not installed)
curl -fsSL https://deno.land/install.sh | sh

# Run MAAR on a Markdown file
deno run --allow-read --allow-write jsr:@ball6847/maar docs/README.md
```

---

## Workflow

### Step 1: Identify the Need

Determine what the user wants:

- **New diagram**: Create a `.mmd` file and link it from Markdown
- **Update diagram**: Edit the `.mmd` file, then re-run MAAR

### Step 2: Create/Edit Mermaid File

Create a `.mmd` file with valid Mermaid syntax:

```bash
mkdir -p docs/diagrams
cat > docs/diagrams/flow.mmd << 'EOF'
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[End]
EOF
```

Place diagrams in a logical location relative to the Markdown file (e.g., `docs/diagrams/`).

### Step 3: Link in Markdown

Add a link in the target `.md` file:

```markdown
[View Flow](diagrams/flow.mmd)
```

Or as an image-style link:

```markdown
![Flow Diagram](diagrams/flow.mmd)
```

The path must be **relative to the Markdown file's location**.

### Step 4: Run MAAR

```bash
deno run --allow-read --allow-write jsr:@ball6847/maar <markdown-file.md>
```

MAAR will:

- Detect all `.mmd` links in the file
- Render each diagram as ASCII
- Inject ASCII blocks above each link
- Write changes atomically

### Step 5: Verify Output

After running MAAR:

1. Read the modified Markdown file to confirm ASCII was injected
2. If MAAR exited with code 1, read the error and fix the `.mmd` file
3. If successful, the file now contains the rendered diagram

### Step 6: Commit (if requested)

Commit both files together:

```bash
git add docs/diagrams/flow.mmd docs/README.md
git commit -m "docs: add flow diagram"
```

---

## Output Format

MAAR injects ASCII in this structure:

````
<!-- MAAR: diagrams/flow.mmd -->
```
┌─────┐
│Start│
└─────┘
  │
  ▼
┌──────┐
│Action│
└──────┘
```

[View Flow](diagrams/flow.mmd)
````

- `<!-- MAAR: ... -->` marker identifies existing blocks
- Plain triple backticks (no language identifier)
- Original `.mmd` link preserved for re-rendering

---

## Re-rendering

MAAR is idempotent — running it again produces identical output:

```bash
# First run
deno run --allow-read --allow-write jsr:@ball6847/maar README.md

# Second run — same result
deno run --allow-read --allow-write jsr:@ball6847/maar README.md
```

When a `<!-- MAAR: ... -->` marker exists, MAAR replaces the ASCII block. This makes updating
diagrams easy:

1. Edit the `.mmd` file
2. Re-run MAAR
3. Commit both changes

---

## Error Handling

MAAR fails fast with specific errors:

| Error            | Cause                        | Fix                   |
| ---------------- | ---------------------------- | --------------------- |
| `file not found` | `.md` or `.mmd` file missing | Check file paths      |
| `syntax error`   | Invalid Mermaid syntax       | Fix `.mmd` content    |
| `0 diagrams`     | No `.mmd` links found        | Add links to Markdown |

When MAAR fails:

1. Read the error output carefully
2. Fix the source `.mmd` file (for syntax errors) or link path (for missing files)
3. Re-run MAAR

---

## Diagram Types

| Type      | Keyword           | Use For                                    |
| --------- | ----------------- | ------------------------------------------ |
| Flowchart | `flowchart`       | Processes, workflows, decision trees       |
| Sequence  | `sequenceDiagram` | API calls, interactions, message flows     |
| State     | `stateDiagram-v2` | Application states, lifecycle, FSM         |
| Class     | `classDiagram`    | Object models, architecture, relationships |
| ER        | `erDiagram`       | Database schema, data models               |

See [mermaid-syntax.md](references/mermaid-syntax.md) for detailed syntax examples.

---

## Best Practices

1. **Keep `.mmd` files in version control** — diagrams are code
2. **Commit both source and rendered output together** — stay in sync
3. **Never manually edit the ASCII block** — let MAAR manage it
4. **Use descriptive link text** — `[System Architecture](arch.mmd)`
5. **Place diagrams near related docs** — `docs/diagrams/` for `docs/README.md`

---

## Troubleshooting

### Deno Not Installed

```bash
curl -fsSL https://deno.land/install.sh | sh
# Restart shell after install
```

### Mermaid Syntax Error

Validate at https://mermaid.live/ before running MAAR.

Common issues:

- Missing spaces in `A --> B` (use `A --> B`)
- Incorrect node shape syntax
- Unclosed brackets

### Path Resolution

The `.mmd` path is relative to the Markdown file:

- Markdown: `docs/README.md`
- Link: `[Flow](diagrams/flow.mmd)`
- MAAR looks for: `docs/diagrams/flow.mmd`

---

## Resources

- **Repository**: https://github.com/ball6847/maar
- **Issues**: https://github.com/ball6847/maar/issues
- **Mermaid Docs**: https://mermaid.js.org/
