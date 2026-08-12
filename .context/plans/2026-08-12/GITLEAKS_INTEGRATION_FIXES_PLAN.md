---
createdAt: "2026-08-12T12:20:00Z"
implementedAt: "2026-08-12T12:29:55Z"
reviewedAt: "2026-08-12T12:40:00Z"
---

# Plan: Gitleaks Integration Fixes (Post-Review Remediation)

## Background & Context

- **Business Driver**: The first implementation pass (per `GITLEAKS_INTEGRATION_PLAN.md`) shipped with two blocking defects found in review (`GITLEAKS_INTEGRATION_REVIEW.md`, verdict FAIL). The most severe is a real security hole: an over-broad `config/` path allowlist in `.gitleaks.toml` causes secrets staged under any `config/**` path to be silently skipped by the pre-commit hook **and** by CI — directly defeating the plan's #1 success criterion.
- **Technical Context**: Root-cause analysis during review established three facts that shape this fix:
  1. **Gitleaks path allowlists are NOT scoped to `dir` scans.** In gitleaks 8.x, `[allowlist] paths` apply to `dir`, `git`, and `git --staged` alike. The committed comment in `.gitleaks.toml` (and a statement in the original plan) claiming "commit-path scans remain fully enforced" is false.
  2. **The broad `config/` allowlist was hiding exactly one real false positive** — a VAPID EC private key in `config/agent-of-empires/push.vapid.json`. That path is **gitignored local runtime data** (its `.gitignore` is `*` except `config.toml`/`.gitignore`), the same class as the already-allowlisted `kimi/`, `qoder/`, `vibe/`, `agent-browser/` runtime dirs. The surgical fix is to allowlist that one runtime subdir, not all of `config/`.
  3. **The plan's own TC-01 test data is broken.** `AKIAIOSFODNN7EXAMPLE` is in gitleaks' default example-key allowlist and is never detected — TC-01 could never have passed as written. Detectable fixtures are required (reviewer confirmed `slack-bot-token` and `stripe-access-token` rules fire on synthetic keys).
- **Related Decisions**: This plan remediates the review's blocking (D1, D3) and concerning/minor items (D2, D4, D5, D6, D7). It does NOT redesign the integration — the four-layer architecture (config + hooks + CI + gitignore) stays. It overrides one prior decision from the original plan: the false assumption that path allowlists only affect `dir`/local scans (corrected in prose and comments).
- **User Impact**: After the fix, committing a secret under `config/**` (or anywhere else tracked) is blocked locally and in CI; the `dir` scan still reports 0 false positives; and an automated behavioral test suite guards against regressions (it would have caught D1).

## Key Information

### Success Criteria

- [ ] `.gitleaks.toml` no longer contains the broad `"config/"` allowlist entry; it is replaced by the narrow `"config/agent-of-empires/"` entry. Secrets staged under any other `config/**` tracked path (e.g. `config/git-commit-ai/`, `config/opencode/`) are **blocked** by `gitleaks git --staged`.
- [ ] `.gitleaks.toml` comment accurately states path allowlists apply to ALL scan modes (`dir`, `git`, `git --staged`), with a warning that any allowlisted tracked path is a blind spot for all scan types.
- [ ] `gitleaks dir . --config .gitleaks.toml` reports **0 leaks** (the VAPID key remains suppressed via the narrow allowlist; the only other finding — an illustrative Slack token in the review report — is redacted).
- [ ] A behavioral test suite exists that stages a detectable secret and asserts the pre-commit hook blocks it (TC-01), including under a `config/**` path (TC-01b regression for D1).
- [ ] Pre-commit and pre-push hooks chain to `*.bak` using file-existence (`[ -f ]`), not executability (`[ -x ]`).
- [ ] CI workflow no longer has a silently-masked SARIF step (`continue-on-error: true` removed); Security-tab code-scanning is explicitly deferred with a documented follow-up, not faked.
- [ ] Illustrative tokens in committed docs (review report, plan) are redacted or `gitleaks:allow`-annotated so the docs can be committed without tripping the scanner.

### Acceptance Criteria

- Given a staged file containing a Slack bot token under `config/git-commit-ai/`, when the pre-commit hook runs, then the commit is aborted (exit 1) and the finding names rule `slack-bot-token`.
- Given the same token staged at the repo root, when the pre-commit hook runs, then the commit is aborted (exit 1).
- Given a clean index, when the pre-commit hook runs, then it exits 0.
- Given `.gitleaks.toml` with the narrow allowlist, when `gitleaks dir . --config .gitleaks.toml` runs, then it reports 0 leaks within ~90s.
- Given a non-gitleaks `pre-commit` hook exists, when the installer runs, then the original is preserved as `pre-commit.bak` and is still executed (via `sh "$bak"`) after gitleaks passes — even if not marked executable.
- Given the behavioral test suite, when invoked, then TC-01, TC-01b, TC-02, TC-04, TC-05 pass; TC-03 passes against a local bare remote; TC-06 is documented as deferred (requires GitHub).

### Assumptions

- gitleaks 8.30.1 (Homebrew) remains the local version; behavior of path allowlists across scan modes is stable in 8.x.
- The synthetic tokens `xoxb-…REDACTED…` (Slack) and `sk_live_…REDACTED…` (Stripe) remain detectable by default rules (verified during review).
- `config/agent-of-empires/` remains local gitignored runtime data; allowlisting it is consistent with how `kimi/` etc. are treated.
- TC-06 (real GitHub Actions run) cannot be verified locally and remains a manual post-merge check.

### Constraints

- Fixes must not weaken staged/history scanning of tracked content — path allowlists may only cover vendored or gitignored local-runtime paths.
- The behavioral tests must run in an **isolated temp git repo** so they never stage leak fixtures in the real dotfiles working tree (which could be accidentally committed or trip the real hooks).
- Test source files that contain synthetic token literals must carry `# gitleaks:allow` trailing comments on those lines so committing the test suite is not blocked by the real pre-commit hook.
- Do NOT commit or push (builder constraint); all verification is local.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| New runtime-data files appear under `config/agent-of-empires/` later and get flagged by `dir` scans | Med | Low | The whole subdir is allowlisted (not just the vapid file), matching `kimi/` pattern; tracked `config.toml` there has no findings |
| Behavioral test leaves a temp repo behind on failure | Low | Low | Trap-based cleanup (`trap 'rm -rf "$TMP"' EXIT`) in the test script |
| Synthetic token literals in the test source are detected and block committing the test | Med | Med | Add `# gitleaks:allow` on every line carrying a full token literal |
| Removing the `upload-sarif` step removes Security-tab surfacing | Med | Med | Document as deferred follow-up; the action's built-in SARIF artifact (`GITLEAKS_ENABLE_UPLOAD_ARTIFACT`, default true) still provides a downloadable report; blocking check is unaffected |
| CI workflow change can't be validated locally | High | Low | TC-06 remains manual; structural YAML validity checked with `actionlint`/yaml parse only |

### Dependencies

- gitleaks 8.30.1 binary (already installed).
- The existing `gitleaks-hooks/`, `scripts/install-gitleaks-hooks.sh`, `.gitleaks.toml`, `.github/workflows/gitleaks.yml` artifacts from the prior implementation.

### Out of Scope

- TC-06 end-to-end CI verification (requires a real GitHub push/PR — manual follow-up).
- Switching the CI scan engine away from `gitleaks/gitleaks-action@v2` (kept per original plan decision).
- Adding `trufflehog`/`detect-secrets` or the `pre-commit` framework (out of scope per original plan).
- Scanning submodule repositories themselves (separate remotes — original plan out of scope).

## Overview

Remediate the two blocking review findings (over-broad allowlist D1; missing behavioral tests D3) and the concerning/minor findings (false comment D2; masked SARIF step D4; report mislabel D5; hook chaining D6; per-path comments D7) with surgical edits to existing artifacts plus one new behavioral test script. The allowlist fix replaces the single broad `"config/"` entry with the narrow `"config/agent-of-empires/"` runtime-data entry; the comment is corrected to reflect gitleaks' real cross-scan allowlist semantics; a new test suite reproduces TC-01..TC-05 in an isolated temp repo using detectable synthetic tokens (including a D1 regression case under `config/**`); hook chaining switches from executability to existence checks; the CI SARIF step is de-masked and Security-tab integration is explicitly deferred; illustrative tokens in docs are redacted/annotated so the repo stays committable.

## Target Structure

```
.dotfiles/
├── .gitleaks.toml                              # MODIFIED: narrow allowlist + corrected comment
├── .github/workflows/gitleaks.yml             # MODIFIED: remove masked upload-sarif; defer code-scanning
├── gitleaks-hooks/
│   ├── pre-commit                             # MODIFIED: [ -x ] -> [ -f ] + sh "$bak"
│   └── pre-push                               # MODIFIED: [ -x ] -> [ -f ] + sh "$bak"
├── .context/
│   ├── plans/2026-08-12/GITLEAKS_INTEGRATION_PLAN.md          # MODIFIED: fix false assumption + TC-01 data
│   ├── implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md  # MODIFIED: remove inaccurate deviation row (D5)
│   └── reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md       # MODIFIED: redact illustrative Slack token
└── tests/
    └── test_gitleaks_hooks_behavior.sh        # NEW: behavioral TC-01..TC-05 in isolated temp repo
```

## Reference Patterns

### Pattern: Isolated hook test in a temp git repo

**Reference**: reviewer's manual verification during review (`.context/reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md`, "Verification Commands" table).

```sh
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q
cp .gitleaks.toml "$TMP/"; cp -R gitleaks-hooks "$TMP/"
( cd "$TMP" && bash "$REPO/scripts/install-gitleaks-hooks.sh" )
printf 'slack=xoxb-...\n' > "$TMP/leak.txt"   # gitleaks:allow
git -C "$TMP" add leak.txt
( cd "$TMP" && .git/hooks/pre-commit >/dev/null 2>&1 ) ; rc=$?
test "$rc" -eq 1   # expect blocked
```

**Notes**: Running in `mktemp -d` guarantees leak fixtures never touch the real working tree. The installer resolves `REPO_ROOT` via `git rev-parse --show-toplevel`, so copying `gitleaks-hooks/` into `$TMP` makes it self-contained. Token-bearing lines in the test source must end with `# gitleaks:allow`.

### Pattern: gitleaks:allow inline suppression

**Reference**: gitleaks default config docs.

```
secret-like-content-here   gitleaks:allow
```

**Notes**: gitleaks looks for the literal `gitleaks:allow` on the same line as a finding and suppresses it. Use only for intentional fixtures/docs, never for real secrets. In shell, place after a `#` comment so it is also valid syntax.

## Files to Create

### `tests/test_gitleaks_hooks_behavior.sh`

**Purpose**: Automated behavioral tests mapping to the original plan's TC-01..TC-05 (and a D1 regression case TC-01b), run in an isolated temp git repo so no leak fixtures touch the real working tree.

**Responsibilities**:
- `set -euo pipefail`; create `mktemp -d` and `trap 'rm -rf "$TMP"' EXIT`.
- Copy real `.gitleaks.toml` and `gitleaks-hooks/` into `$TMP`; `git init`; run `scripts/install-gitleaks-hooks.sh` from within `$TMP`.
- Define a `detectable_secret` fixture using a Slack bot token literal (`xoxb-…REDACTED…`) and a Stripe key (`sk_live_…REDACTED…`); every source line containing a full token literal ends with `# gitleaks:allow`.
- Helper `expect_block <path>`: writes the secret to `<path>` under `$TMP`, `git add`, runs `.git/hooks/pre-commit`, asserts exit code 1.
- Helper `expect_pass`: with clean index, runs `.git/hooks/pre-commit`, asserts exit 0.
- TC-01: `expect_block leak.txt` (repo root).
- TC-01b (D1 regression): `expect_block config/git-commit-ai/leak.txt` — must block after the allowlist fix.
- TC-02: clean-index commit allowed (exit 0).
- TC-03: `git commit --no-verify` a secret, create a local bare remote (`git init --bare "$TMP/remote.git"`), `git push origin master`, assert pre-push blocks (exit 1).
- TC-04: `gitleaks dir . --config .gitleaks.toml` in `$TMP` → 0 leaks; `gitleaks git --staged` clean → 0; `gitleaks git` → 0.
- TC-05: run installer twice → second run prints "already installed"; seed a dummy `pre-commit` (`echo old`), run installer, assert `pre-commit.bak` exists, content preserved, and `echo old` runs after gitleaks passes.
- Print `PASS/FAIL` counts; exit non-zero if any fail.

**Interface**:
```sh
# Run: bash tests/test_gitleaks_hooks_behavior.sh
# Exit 0 = all behavioral tests pass; non-zero = at least one failed.
```

**See Also**: Reference pattern "Isolated hook test in a temp git repo".

## Files to Modify

### `.gitleaks.toml`

**Changes Required**:

1. **Replace** the broad allowlist entry
   - From: `"config/"` (with comment "Config directory with vendored themes")
   - To: `"config/agent-of-empires/"` (local runtime data; gitignored except `config.toml`)
   - Reason: the broad entry hid secrets in tracked AI-agent configs; the only real false positive it suppressed was the VAPID key in `config/agent-of-empires/push.vapid.json`, which the narrow entry still covers.

2. **Rewrite** the header comment block (D2)
   - From: "This allowlist applies to working-tree scans only. Commit-path scans (`git --staged`, `git`) of tracked content remain fully enforced."
   - To: an accurate statement that `[allowlist] paths` apply to **all** scan modes (`dir`, `git`, `git --staged`); that allowlisted paths are blind spots for every scan type; and that entries are therefore limited to vendored / gitignored local-runtime paths only.

3. **Add** per-path rationale comments (D7) — one short `#` comment per entry explaining why it is safe (e.g. `# kimi: gitignored local runtime data (credentials/sessions/telemetry)`).

### `gitleaks-hooks/pre-commit` and `gitleaks-hooks/pre-push`

**Changes Required**:

1. **Modify** the `.bak` chaining check (D6)
   - From: `if [ -x "$bak" ]; then exec "$bak"; fi`
   - To: `if [ -f "$bak" ]; then exec sh "$bak"; fi`
   - Reason: match the plan's "if it exists" semantics; a non-executable pre-existing hook should still run (via `sh`), not be silently skipped.
   - Backward Compatible: Yes (executed hooks still run; now also runs non-executable ones).

### `.github/workflows/gitleaks.yml`

**Changes Required**:

1. **Remove** the speculative `upload-sarif` step (D4)
   - Remove the `Upload SARIF report` step (which pointed at an undocumented `results.sarif` path and used `continue-on-error: true` to mask failure).
   - Reason: `gitleaks/gitleaks-action@v2` uploads a SARIF **artifact** by default (`GITLEAKS_ENABLE_UPLOAD_ARTIFACT`, default true); the manual step's path was unverifiable and its `continue-on-error` silently masked a missing-file failure.
2. **Keep** `permissions: security-events: write` (harmless; enables a future code-scanning upload without another edit).
3. **Add** a comment documenting that GitHub Security-tab **code scanning** integration is a deferred follow-up (TC-06), and that the blocking check + downloadable SARIF artifact remain in effect.

### `.context/plans/2026-08-12/GITLEAKS_INTEGRATION_PLAN.md`

**Changes Required**:

1. **Correct** the false assumption (D2 root cause)
   - In the "Related Decisions" / "Files to Create → .gitleaks.toml" prose, replace statements implying path allowlists only affect `dir`/local scans with the accurate cross-scan semantics.
2. **Fix** TC-01 test data
   - From: `AKIAIOSFODNN7EXAMPLE` (AWS example key, in gitleaks' default allowlist — never detected)
   - To: a Slack bot token `xoxb-…REDACTED…` (detectable by the `slack-bot-token` rule).
3. **Add** `config/agent-of-empires/` to the allowlist spec list (was missing; it is local runtime data in the same class as `kimi/`).

### `.context/implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md`

**Changes Required**:

1. **Remove** the inaccurate "Installer backup error handling" row from the Deviations table (D5) — refusing to overwrite an existing `.bak` matches the plan exactly; it is not a deviation.

### `.context/reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md`

**Changes Required**:

1. **Redact** the illustrative Slack token (D-fix, discovered during remediation)
   - From: full token literal `xoxb-…REDACTED…` on the token-bearing line(s)
   - To: a redacted form `xoxb-…REDACTED…` (or append `gitleaks:allow` if the full token must remain as evidence).
   - Reason: otherwise committing the review report is blocked by the very scanner this integration installs. (The Stripe token, if present in full, gets the same treatment.)

## Files to Delete

None.

## Diagrams

### Sequence Diagram: D1 regression test (the case that would have caught the hole)

```
Test runner        temp repo .git/hooks/pre-commit     gitleaks git --staged     .gitleaks.toml
   |                        |                                |                         |
   |-- stage slack token -->|                                |                         |
   |   under config/...     |                                |                         |
   |-- run pre-commit ----->|                                |                         |
   |                        |-- gitleaks git --staged ------->|                         |
   |                        |                                 |--- read allowlist ---->|
   |                        |                                 | (config/ NOT listed)   |
   |                        |<-- finding: slack-bot-token ----|                         |
   |<-- exit 1 (blocked) ---|                                 |                         |
   |   PASS: D1 fixed       |                                 |                         |
```

## Test Cases

### TC-01: Pre-commit blocks a staged detectable secret (P0, Security)

**Priority:** P0
**Type:** Security

#### Objective

Verify the pre-commit hook aborts a commit when a staged file contains a recognizable secret — using a token gitleaks actually detects (not the allowlisted AWS example key).

#### Preconditions

- Hooks installed in an isolated temp repo via `scripts/install-gitleaks-hooks.sh`.
- Fixture: a Slack bot token `xoxb-…REDACTED…` (line ends `# gitleaks:allow` in test source).

#### Test Steps

1. Write the token to `$TMP/leak.txt` and `git add`.
   **Expected:** staged.
2. Run `.git/hooks/pre-commit`.
   **Expected:** exit 1; output references rule `slack-bot-token`.

#### Post-conditions

- Temp repo is torn down by the EXIT trap; real working tree untouched.

### TC-01b: D1 regression — secret under `config/**` is blocked (P0, Security)

**Priority:** P0
**Type:** Regression

#### Objective

Verify the over-broad `config/` allowlist is gone: a secret staged under a tracked `config/**` path is blocked.

#### Preconditions

- Same as TC-01, plus the narrow `config/agent-of-empires/` allowlist in place.

#### Test Steps

1. Write the token to `$TMP/config/git-commit-ai/leak.txt` and `git add`.
2. Run `.git/hooks/pre-commit`.
   **Expected:** exit 1 (blocked). (Under the bug, this returned 0.)

#### Post-conditions

- Temp repo torn down.

### TC-02: Pre-commit allows a clean commit (P0, Functional)

**Priority:** P0
**Type:** Functional

#### Objective

Verify the hook does not block legitimate commits.

#### Preconditions

- Hooks installed; clean index in temp repo.

#### Test Steps

1. Run `.git/hooks/pre-commit`.
   **Expected:** exit 0; no "leaks found" message.

#### Post-conditions

- Hook passes silently.

### TC-03: Pre-push blocks a leak in history (P1, Security)

**Priority:** P1
**Type:** Security

#### Objective

Verify push is blocked if history contains a leak.

#### Preconditions

- Hooks installed in temp repo; a local bare remote at `$TMP/remote.git`.

#### Test Steps

1. Create secret file, `git add`, `git commit --no-verify` (bypass pre-commit).
2. `git push origin master`.
   **Expected:** pre-push scans history, finds the leak, exits 1; push refused.

#### Post-conditions

- Local branch ahead of remote by the test commit; temp repo torn down.

### TC-04: dir/staged/history scans with config report 0 leaks (P1, Regression)

**Priority:** P1
**Type:** Regression

#### Objective

Verify the narrow allowlist removes known false positives without hiding tracked content.

#### Preconditions

- `.gitleaks.toml` with `config/agent-of-empires/` (not `config/`).

#### Test Steps

1. `gitleaks dir . --config .gitleaks.toml` in temp repo.
   **Expected:** 0 leaks.
2. `gitleaks git --staged --config .gitleaks.toml` (clean index).
   **Expected:** 0 leaks.
3. `gitleaks git --config .gitleaks.toml`.
   **Expected:** 0 leaks in history.

#### Post-conditions

- Baseline remains clean.

### TC-05: Installer idempotency and hook preservation (P2, Functional)

**Priority:** P2
**Type:** Functional

#### Objective

Verify installer is safe to re-run and preserves pre-existing hooks (now via existence check, not executability).

#### Preconditions

- A dummy `pre-commit` containing `echo old` (not marked executable) in the temp repo.

#### Test Steps

1. Run `scripts/install-gitleaks-hooks.sh`.
   **Expected:** original renamed to `pre-commit.bak`; gitleaks hook installed.
2. Run installer again.
   **Expected:** "already installed"; no duplicate `.bak`.
3. Make a clean commit.
   **Expected:** `echo old` output appears after gitleaks passes (chaining via `sh "$bak"` works for non-executable backups).

#### Post-conditions

- `.git/hooks/` contains gitleaks hooks + `.bak` files; temp repo torn down.

### TC-06: CI workflow fails on leak (P1, Integration) — DEFERRED

**Priority:** P1
**Type:** Integration

#### Objective

Verify GitHub Actions workflow fails the check when a leak is pushed.

#### Preconditions

- Workflow committed and pushed; GitHub Actions enabled.

#### Test Steps

1. Push a commit containing a synthetic secret to a PR branch.
   **Expected:** `gitleaks` job fails; SARIF artifact present; PR check red.
2. Remove the secret, force-push.
   **Expected:** job passes; check green.

#### Post-conditions

- No secret lands on `master`.

**Note**: Cannot be verified locally; remains a manual post-merge check. Structural YAML validity only is checked here.

## Verification Commands

```bash
# 1. Behavioral suite (TC-01, TC-01b, TC-02, TC-03, TC-04, TC-05)
bash tests/test_gitleaks_hooks_behavior.sh

# 2. Existing content/exists checks still pass
bash tests/test_gitleaks_integration.sh

# 3. dir scan clean with narrow allowlist
gitleaks dir . --config .gitleaks.toml --no-banner   # expect: no leaks found

# 4. full history clean
gitleaks git --config .gitleaks.toml --no-banner      # expect: no leaks found

# 5. D1 proof: stage a Slack token under config/ and confirm the hook blocks
#    (run in a scratch worktree, NOT master; the behavioral suite covers this)

# 6. YAML structural validity of the workflow (ruby ships a YAML lib on this machine)
ruby -ryaml -e "YAML.load_file('.github/workflows/gitleaks.yml'); puts 'yaml ok'"
```

## Expected Outcome

- **User perspective**: Committing a secret anywhere in the repo — including under `config/**` — is blocked locally within milliseconds; CI remains a second line of defense; `dir` scans stay quiet (0 false positives); a behavioral test suite prevents the D1 regression from recurring.
- **System perspective**: `.gitleaks.toml` allowlist is narrow and accurately documented; hooks chain correctly to non-executable backups; CI no longer carries a silently-masked step; all committed docs are scanner-clean.

## Rollback Plan

1. **Revert allowlist**: restore `"config/"` in `.gitleaks.toml` (re-introduces the D1 hole — only as a last resort).
2. **Revert hook chaining**: `sh "$bak"` → `exec "$bak"` with `[ -x ]`.
3. **Revert CI**: re-add the `upload-sarif` step (re-introduces the masked failure).
4. **Remove tests**: delete `tests/test_gitleaks_hooks_behavior.sh`.
5. Full rollback to the pre-fix state is available via the original `GITLEAKS_INTEGRATION_PLAN.md` implementation.

## Related Links

- Original plan: [GITLEAKS_INTEGRATION_PLAN.md](./GITLEAKS_INTEGRATION_PLAN.md)
- Implementation report: [../../implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md](../../implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md)
- Review report (FAIL): [../../reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md](../../reviews/2026-08-12/GITLEAKS_INTEGRATION_REVIEW.md)
- Gitleaks config docs: `gitleaks --help`, `gitleaks git --help` (v8.30.1)
