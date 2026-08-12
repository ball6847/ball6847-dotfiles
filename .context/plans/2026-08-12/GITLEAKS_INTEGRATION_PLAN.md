---
createdAt: "2026-08-12T11:44:03Z"
implementedAt: "2026-08-12T12:00:00Z"
reviewedAt: "2026-08-12T12:10:00Z"
---

# Plan: Gitleaks Secret-Scanning Integration

## Background & Context

- **Business Driver**: The user wants to guarantee the dotfiles repo (`ball6847-dotfiles`, remote: `git@github.com:ball6847/ball6847-dotfiles.git`) never leaks secrets. This is a personal repo synced to a public GitHub remote; config files for AI agents (kimi, qwen, gemini, vibe), editors, and shell tooling are prime candidates for accidentally committing API keys, tokens, and credentials.
- **Technical Context**: Baseline scan completed with `gitleaks 8.30.1` (installed via Homebrew):
  - `gitleaks git` (full history, 1801 commits, ~2.37 MB): **0 leaks** — history is clean.
  - `gitleaks dir .` (working tree, 1.79 GB, 90s): **393 findings, ALL in untracked/vendored paths** — 0 findings in tracked files.
  - The 393 untracked findings break down: kimi (256), qoder (97), vibe (21), agent-browser (16), cc-skills-golang (2), config (1). Rules: generic-api-key (259), jwt (88), curl-auth-header (41), aws-access-token (4), private-key (1). These live in: local gitignored runtime data (`kimi/credentials/`, `kimi/sessions/`, `kimi/telemetry/` — confirmed gitignored via `kimi/.gitignore` `/*` pattern), vendored submodule working trees (`cc-skills-golang`), and vendored extension code with `node_modules` (`qoder/extensions/...`).
  - Repo has 7 submodules (zsh plugins, alacritty-theme, cc-skills-golang, etc.). Submodule content is NOT scanned by `gitleaks git` (only gitlink entries), but IS scanned by `gitleaks dir`.
  - No top-level `.github/` directory exists yet. No tracked pre-commit/pre-push hooks (only `.git/hooks/post-commit` installed by Qoder, not tracked).
- **Related Decisions**: Use official `gitleaks/gitleaks-action@v2` for CI (standard, SARIF-capable). Use git hooks for local protection. Keep default rules via `[extend] useDefault = true` rather than redefining the rule set. Do NOT blanket-allowlist the vendored dirs in the committed config used for `git` scans (history is clean anyway); instead scope path allowlists to what `dir`/local scans need, and rely on `.gitignore` + `git`-level scans for the commit path.
- **User Impact**: Every commit and push is checked locally and in CI before anything reaches GitHub. A leaked secret becomes a blocked commit/push instead of a cleanup incident.

## Key Information

### Success Criteria

- [ ] Committing a file containing a recognizable secret (AWS key, GitHub PAT, generic API key) is **blocked locally** by the pre-commit hook.
- [ ] Pushing to `origin` runs a full-history scan via pre-push hook and **blocks the push** if a leak is detected.
- [ ] CI workflow runs `gitleaks` on push/PR to GitHub and fails the check on findings.
- [ ] `gitleaks git --staged` and `gitleaks git` pass cleanly on the current repo (no allowlist needed to make them pass).
- [ ] A repo-local `.gitleaks.toml` exists with default rules extended plus a narrowly-scoped allowlist so `gitleaks dir .` no longer reports the 393 known false positives (vendored/submodule/ignored paths).
- [ ] Hook installer is idempotent and preserves any pre-existing hooks (chaining, not clobbering).

### Acceptance Criteria

- Given a staged file containing a fake-but-recognizable secret, when the pre-commit hook runs, then commit is aborted with a gitleaks finding listing file/rule/line, and exit code is non-zero.
- Given a clean staging area, when the pre-commit hook runs, then commit proceeds unchanged (fast, no banner noise).
- Given `.gitleaks.toml` with the vendored-path allowlist, when `gitleaks dir . --config .gitleaks.toml` runs, then it reports **0 leaks** and completes within ~90s.
- Given the CI workflow, when a PR/push lands on GitHub, then the `gitleaks` job shows a pass/fail badge-able check.
- Given an existing non-gitleaks `pre-commit` hook (e.g. Qoder's `post-commit`), when the installer runs, then the existing hook logic still executes.

### Assumptions

- Homebrew is the package manager on this macOS machine; gitleaks 8.30.1 is already installed.
- The repo is hosted on GitHub (`github.com/ball6847/ball6847-dotfiles`) — GitHub Actions is the CI platform.
- Submodule and vendored directories (`qoder/extensions/...node_modules`, `cc-skills-golang`, etc.) are third-party content and are not the user's secrets; findings there are false positives for this repo's purposes.
- The 393 `dir`-scan findings are all in untracked/gitignored/vendored files (verified: 0 tracked findings), so no real user secret is currently at risk of commit.

### Constraints

- `.git/hooks/` is not tracked by git; hooks must be installed by a script and re-installed on each clone/machine.
- The `install.sh` script symlinks dotfiles but does not currently manage git hooks; the hook installer should be separate and additive (surgical change).
- Windows PowerShell scripts exist in the repo; local hook protection only applies on machines that run the installer (primary dev machine is macOS).
- Gitleaks is heuristic — generic secrets (e.g., high-entropy custom tokens with no known prefix) may go undetected; this is accepted tooling limitation.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Over-broad path allowlist hides a real secret committed under a vendored path | Med | High | Allowlist only concrete top-level dirs; CI `git`-scan doesn't use path allowlist for vendored content (only local `dir` scans do); add comment in config warning about scope |
| Hook blocks legitimate commits on false positives | Med | Med | `.gitleaksignore` file tracked in repo; `gitleaks:allow` inline comments; documented escape hatch in hook output |
| Hook not installed on other machines / fresh clones | High | Med | Installer script tracked in repo + documented in README; CI provides server-side backstop |
| Existing hooks clobbered by installer | Low | Med | Installer renames existing `.git/hooks/pre-commit` → `.git/hooks/pre-commit.bak` and chains execution |
| CI fails on submodule gitlink content or vendored files | Low | Low | `gitleaks-action` runs `gitleaks git` (history of main repo only, no submodule content); checkout uses `fetch-depth: 0` |

### Dependencies

- Homebrew (gitleaks binary) — already satisfied.
- GitHub Actions runner network access to `gitleaks/gitleaks-action@v2`.
- Git 2.x (2.50.1 present) — hooks and `git diff --staged`-based scanning.

### Out of Scope

- Retroactive secret rotation/cleanup for any secret found in history (none found — not needed).
- Scanning submodule repositories themselves (they are separate remotes; could be added later as a follow-up).
- Windows/Git-for-Windows hook installation (PowerShell hooks for `install.ps1` — possible follow-up).
- Adding other secret scanners (trufflehog, detect-secrets, pre-commit framework) — gitleaks only, per request.

## Overview

Add Gitleaks as a four-layer defense for the dotfiles repo: (1) a tracked `.gitleaks.toml` config extending default rules with a narrowly-scoped path allowlist so local `dir` scans stop flagging vendored/ignored content; (2) local `pre-commit` (staged-diff scan) and `pre-push` (full-history scan) hooks installed by a tracked, idempotent installer script; (3) a GitHub Actions workflow running `gitleaks/gitleaks-action@v2` on push and PR; (4) `.gitignore` entries for local scan report artifacts. The end-to-end behavior: any attempt to commit or push a secret is blocked with actionable output; CI independently enforces it on GitHub.

## Target Structure

```
.dotfiles/
├── .gitleaks.toml              # NEW: config (extend defaults + vendored-path allowlist)
├── .gitleaksignore             # NEW: empty (or comment-only) placeholder for future false positives
├── .github/
│   └── workflows/
│       └── gitleaks.yml        # NEW: CI scan on push/PR
├── scripts/
│   └── install-gitleaks-hooks.sh  # NEW: installs pre-commit/pre-push hooks (idempotent)
├── gitleaks-hooks/
│   ├── pre-commit              # NEW: runs `gitleaks git --staged`
│   └── pre-push                # NEW: runs `gitleaks git`
└── .gitignore                  # MODIFIED: add gitleaks report artifacts
```

## Reference Patterns [Optional]

### Pattern: Hook execution semantics

**Reference**: existing `.git/hooks/post-commit` (Qoder tracker, untracked)

```sh
#!/bin/sh
# existing hook pattern: run tool, never break the git operation on tool failure
qodercli commit --hook --workspace "$repo_root" 2>/dev/null || true
```

**Notes**: Pre-existing hooks are chained, not replaced: installer renames `pre-commit` → `pre-commit.bak` and the installed hook execs the `.bak` (if present) *after* gitleaks passes, or *before* — decision: run gitleaks first; on pass, exec previous hook if it exists. Pre-push hooks are only invoked by `git push` and their non-zero exit blocks the push.

### Pattern: Gitleaks staged scan (v8.30)

```sh
# pre-commit: scan only staged diff
gitleaks git --staged --no-banner --config "$(git rev-parse --show-toplevel)/.gitleaks.toml"
```

**Notes**: `gitleaks git --staged` scans the staged changes (equivalent of legacy `gitleaks protect`). Exit code 1 on findings; findings printed to stdout with file/rule/line. Run from repo root; hooks get repo root via `git rev-parse --show-toplevel`.

## Files to Create

### `.gitleaks.toml`

**Purpose**: Repo-scoped gitleaks configuration. Keeps all default rules and adds a path allowlist for the vendored/ignored working-tree content that produces the 393 known false positives in `dir` scans.

**Responsibilities**:
- `[extend] useDefault = true` so all built-in rules remain active (must be first table).
- `[allowlist] paths = [...]` listing top-level dirs whose *working-tree content* should be skipped: `kimi`, `qoder`, `vibe`, `agent-browser`, `cc-skills-golang`, and submodule dirs (`zsh_custom/plugins/`, `alacritty-theme`, `config/rio/themes`, `xclip-win32yank-wrapper`, `config/agent-of-empires/`).
- Include a comment block documenting WHY each path is allowed (local runtime data / vendored third-party) and warning that `[allowlist] paths` apply to ALL scan modes (`dir`, `git`, `git --staged`). Any allowlisted path is a blind spot for every scan type.
- Do NOT add per-rule secret regex allowlists at this time (no tracked findings to suppress).

**See Also**: Gitleaks config schema: `[extend]`, `[allowlist]` with `paths` and `regexes` (official docs).

### `.gitleaksignore`

**Purpose**: Explicit list of future findings the repo owner has reviewed and accepted (line format: `commit:file:rule`). Currently empty/comment-only because the baseline is clean.

**Responsibilities**:
- Comment header explaining format and that entries must be reviewed secrets, not bulk additions.

### `.github/workflows/gitleaks.yml`

**Purpose**: Server-side enforcement on GitHub.

**Responsibilities**:
- Trigger: `push` (all branches) and `pull_request`.
- Job `scan` on `ubuntu-latest`.
- Checkout with `fetch-depth: 0` (full history required for accurate scan).
- Run `gitleaks/gitleaks-action@v2` with default config (auto-detects `.gitleaks.toml`).
- Upload SARIF report as an artifact (`github/codeql-action/upload-sarif@v3`) so findings surface in GitHub Security tab.
- Job must fail when leaks are found (action default).

### `scripts/install-gitleaks-hooks.sh`

**Purpose**: Idempotent installer that wires the tracked hook scripts into `.git/hooks/`.

**Responsibilities**:
- Determine repo root via `git rev-parse --show-toplevel`; operate only inside that `.git/hooks/`.
- For each of `pre-commit` and `pre-push`:
  - If a hook already exists and is NOT already a gitleaks hook (detect by marker comment), rename it to `<name>.bak` (overwrite `.bak` only if identical source? No — refuse to clobber an existing `.bak`, print error).
  - Copy the tracked `gitleaks-hooks/<name>` script into `.git/hooks/<name>` with `chmod +x`.
  - Idempotency: re-running must not create duplicate `.bak` chains; detect installed state by a unique marker line (`# gitleaks-hook`) in the target hook.
- Print a summary of actions taken; exit non-zero on hard failures (e.g., cannot write hooks dir).
- If `gitleaks` binary is missing, print a warning but still install hooks (hooks themselves print a skip message when gitleaks is absent — see hook spec).

### `gitleaks-hooks/pre-commit`

**Purpose**: Local gate on staged content.

**Responsibilities**:
- POSIX `sh` script; run from any cwd (resolve repo root first).
- If `gitleaks` not on PATH: print warning, exit 0 (never break dev workflow silently — but CI still protects).
- Run `gitleaks git --staged --no-banner --config <root>/.gitleaks.toml --redact`.
- On findings (exit != 0): print human-readable hint (file/rule/line already printed by gitleaks) + remediation note (`.gitleaksignore` / `gitleaks:allow`), exit 1.
- On pass: if `pre-commit.bak` exists, exec it; exit with its status.

### `gitleaks-hooks/pre-push`

**Purpose**: Local gate on full history before push.

**Responsibilities**:
- Same conventions as pre-commit (missing binary → warn + exit 0).
- Run `gitleaks git --no-banner --config <root>/.gitleaks.toml --redact` (full history, up to ~1s on this repo).
- On findings: exit 1 (blocks push). On pass: chain `pre-push.bak` if present.

## Files to Modify

### `.gitignore`

**Changes Required**:

1. **Add** local gitleaks report artifacts
   - Location: end of file (after existing entries)
   - Details:
     ```
     # Gitleaks local scan reports
     gitleaks-report.*
     ```

### `README.md` [optional]

**Changes Required**:

1. **Add** a short "Secret scanning" section (only if README has a tools/security area; otherwise skip to stay surgical)
   - Details: one paragraph on gitleaks + link to `scripts/install-gitleaks-hooks.sh` and CI workflow. **Builder decision**: add only if there's an existing obvious section; otherwise defer to a follow-up.

## Diagrams [Optional]

### Sequence Diagram: Commit-time protection

```
Developer          pre-commit hook         gitleaks            .gitleaks.toml       pre-commit.bak
   |                     |                    |                     |                    |
   |-- git commit ------>|                    |                     |                    |
   |                     |-- gitleaks git --staged ->|              |                    |
   |                     |                    |--- read config --->|                    |
   |                     |<-- findings | clean -------------------|                    |
   |                     |-- [clean?] exec pre-commit.bak ------->|                    |
   |                     |-- [leak?] exit 1 --------------------->|                    |
   |<-- commit aborted --|                    |                     |                    |
   |    (or committed)   |                    |                     |                    |
```

### Sequence Diagram: Push-time protection (CI backstop)

```
Developer   pre-push hook        gitleaks git (full history)      GitHub Actions
   |             |                        |                            |
   |-- push ---->|                        |                            |
   |             |-- scan history ------->|                            |
   |             |<-- clean? ------------|                            |
   |             |-- allow push -------->|                            |
   |             |                        |-- push arrives ---------->|
   |             |                        |      gitleaks-action runs |
   |             |                        |      fails on leak ------>|
   |             |                        |      PR/push check: fail  |
```

## Test Cases

### TC-01: Pre-commit blocks a staged secret (P0, Security)

**Priority:** P0
**Type:** Security

#### Objective

Verify the pre-commit hook aborts a commit when a staged file contains a recognizable secret.

#### Preconditions

- gitleaks installed, hooks installed via `scripts/install-gitleaks-hooks.sh`.
- Temporary file in repo with a fake Slack bot token, e.g. `xoxb-…REDACTED…` (detectable by default rules, safe to use).

#### Test Steps

1. `echo "slack_token = xoxb-…REDACTED…" > /tmp/gitleaks-test.txt && cp /tmp/gitleaks-test.txt <repo>/test-leak.txt
   **Expected:** file created in working tree
2. `git add test-leak.txt`
   **Expected:** staged
3. `git commit -m "test gitleaks"`
   **Expected:** commit is aborted; output contains `gitleaks` finding with rule `slack-bot-token` and file `test-leak.txt`; exit code non-zero.

#### Post-conditions

- `test-leak.txt` removed and not committed (`git status` clean after `git restore --staged` + delete).

### TC-02: Pre-commit allows a clean commit (P0, Functional)

**Priority:** P0
**Type:** Functional

#### Objective

Verify the hook does not block legitimate commits.

#### Preconditions

- Hooks installed; working tree contains only an innocuous change (e.g., edit to a comment).

#### Test Steps

1. Make a trivial change (e.g., append comment line to a config file).
2. `git add . && git commit -m "clean commit test"`
   **Expected:** commit succeeds; gitleaks output shows scan ran with no leaks (or hook is quiet on pass).

#### Post-conditions

- Commit exists in log.

### TC-03: Pre-push blocks a leak in history (P1, Security)

**Priority:** P1
**Type:** Security

#### Objective

Verify push is blocked if history contains a leak (simulate by committing the leak without pre-commit, then pushing).

#### Preconditions

- Hooks installed; a local-only commit containing a secret exists (create via `git commit --no-verify` to bypass pre-commit).

#### Test Steps

1. Create secret file, `git add`, commit with `--no-verify`.
2. `git push origin <branch>`
   **Expected:** pre-push hook scans full history, finds leak, exits 1; push refused.

#### Post-conditions

- Local branch ahead of remote by exactly the test commit; test commit cleaned up (reset + `git reflog` note).

### TC-04: dir scan with allowlist config reports 0 leaks (P1, Regression)

**Priority:** P1
**Type:** Regression

#### Objective

Verify the allowlist removes the 393 known false positives without hiding tracked content.

#### Preconditions

- `.gitleaks.toml` committed.

#### Test Steps

1. `gitleaks dir . --config .gitleaks.toml --no-banner --timeout 90 -r /tmp/report.json`
   **Expected:** `no leaks found`; report has 0 entries; completes < 90s.
2. `gitleaks git --staged --config .gitleaks.toml` (clean index)
   **Expected:** no leaks (tracked scan still enforced with same config).
3. `gitleaks git --config .gitleaks.toml`
   **Expected:** no leaks in full history (config does not weaken history scan).

#### Post-conditions

- Baseline remains clean.

### TC-05: Installer idempotency and hook preservation (P2, Functional)

**Priority:** P2
**Type:** Functional

#### Objective

Verify installer is safe to re-run and preserves pre-existing hooks.

#### Preconditions

- A dummy pre-existing `pre-commit` hook content (e.g., `echo old`) in place.

#### Test Steps

1. Run `scripts/install-gitleaks-hooks.sh`.
   **Expected:** original hook renamed to `pre-commit.bak`; new gitleaks hook installed; `pre-commit.bak` content preserved.
2. Run `scripts/install-gitleaks-hooks.sh` again.
   **Expected:** no duplicate `.bak`; hooks still installed; exit 0.
3. Make a clean commit; verify `echo old` output appears after gitleaks passes (chaining works).
4. `git push` to a test remote; verify pre-push runs.
   **Expected:** both hooks chain correctly.

#### Post-conditions

- `.git/hooks/` contains gitleaks `pre-commit`/`pre-push` + original `.bak` files.

### TC-06: CI workflow fails on leak (P1, Integration)

**Priority:** P1
**Type:** Integration

#### Objective

Verify GitHub Actions workflow fails the check when a leak is pushed.

#### Preconditions

- Workflow committed and pushed; GitHub Actions enabled on repo.

#### Test Steps

1. Push a commit containing a fake secret to a PR branch.
   **Expected:** `gitleaks` job fails; SARIF artifact uploaded; PR check red.
2. Remove the secret, force-push.
   **Expected:** job passes; check green.

#### Post-conditions

- No secret ever lands on `master` (verified via remote state).

## Verification Commands

```bash
# 1. Config correctness: default rules still active, allowlist applied
gitleaks dir . --config .gitleaks.toml --no-banner --timeout 90 -r /tmp/report.json && echo "dir scan clean"

# 2. Staged scan (post-hook smoke test)
gitleaks git --staged --config .gitleaks.toml --no-banner

# 3. Full history remains clean
gitleaks git --config .gitleaks.toml --no-banner

# 4. Hooks installed and executable
ls -la .git/hooks/pre-commit .git/hooks/pre-push
.git/hooks/pre-commit   # must exit 0 on clean index
.git/hooks/pre-push     # must exit 0 (or warn if no remote refs)

# 5. Installer idempotent
scripts/install-gitleaks-hooks.sh && scripts/install-gitleaks-hooks.sh

# 6. Hook actually blocks (negative test, run in a scratch worktree, NOT master)
git commit -m "leak test"   # with staged fake AWS key -> must fail
```

## Expected Outcome

- **User perspective**: `git commit` and `git push` are self-checking; any secret-shaped content is caught within milliseconds locally, and GitHub CI is the second line of defense. No repo config change is needed per machine beyond running the installer once.
- **System perspective**: `.gitleaks.toml` + hooks + CI form a complete loop; working-tree `dir` scans stop producing noise (393 → 0); history and staged scans remain strict.

## Rollback Plan

1. **Remove hooks**: `rm .git/hooks/pre-commit .git/hooks/pre-push` (restore `.bak` files if desired: `mv .git/hooks/pre-commit.bak .git/hooks/pre-commit`).
2. **Remove config**: delete `.gitleaks.toml` and `.gitleaksignore`; revert `.gitignore` line.
3. **Remove CI**: delete `.github/workflows/gitleaks.yml`; workflow stops running on next push (no secret data retained; SARIF artifacts auto-expire).
4. **Uninstall tool**: `brew uninstall gitleaks` (hooks degrade gracefully — they warn and exit 0 when the binary is absent).

## Related Links [Optional]

- Gitleaks docs: `gitleaks --help`, `gitleaks git --help` (v8.30.1 installed)
- Official action: `gitleaks/gitleaks-action@v2` (GitHub Marketplace)
- Repo remote: `git@github.com:ball6847/ball6847-dotfiles.git`

## Implementation

- **Status**: Completed
- **Reports**:
  - [Implementation Report](../implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md) (if applicable)

## Review

- **Status**: FAIL
- **Reviews**:
  - [Review Report](../reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md)
