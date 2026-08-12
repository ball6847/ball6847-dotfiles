---
createdAt: "2026-08-12T12:10:00Z"
planPath: "../plans/2026-08-12/GITLEAKS_INTEGRATION_PLAN.md"
implementationReportPaths:
  - "../implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md"
---

# Review Report: Gitleaks Secret-Scanning Integration

## Verdict

**FAIL**

The implementation is structurally complete (all planned files created, installer idempotent, history/dir scans clean) and most verification commands pass. However, one deviation from the plan's allowlist scope creates a **real security hole** that defeats the plan's #1 success criterion, and the TDD test suite does not cover any of the plan's six behavioral test cases. Both are blocking. Fixes are required before this can be considered complete.

## Summary

The builder created every planned artifact and a 20-check "content/exists" test script. Functional verification (performed by the reviewer, since the builder listed these as "Next Steps") confirms: full-history scan passes (781ms, 0 leaks), `dir` scan with the config reports 0 leaks, staged scan on a clean index passes, the installer is idempotent, the pre-commit hook blocks a staged secret under a non-allowlisted path, and allows a clean commit. So the mechanism is sound in principle.

The blocker is the allowlist scope: the builder added `config/` (entire tracked directory) to `.gitleaks.toml` in addition to the plan's narrower `config/rio/themes`. Gitleaks path allowlists apply to **all** scan types (`dir`, `git`, `git --staged`) — contrary to a comment in the committed config — and because the config auto-loads, this means **a secret staged under any `config/**` path is not blocked by the pre-commit hook and is not caught by CI**. `config/` holds tracked AI-agent config files (e.g. `config/git-commit-ai/config.json`, `config/opencode/opencode.jsonc`), which the plan explicitly identifies as a prime leak vector. This is the exact risk the plan's risk table warned against ("Over-broad path allowlist hides a real secret … Mitigation: Allowlist only concrete top-level dirs").

## Items Verified

### Files Created

| File | Status | Notes |
| ---- | ------ | ----- |
| `.gitleaks.toml` | ⚠️ Created, but deviates from spec | Adds over-broad `config/` allowlist; comment is factually false (see Discrepancy D1, D2) |
| `.gitleaksignore` | ✅ Created as planned | Comment-only placeholder with format docs |
| `.github/workflows/gitleaks.yml` | ⚠️ Created, one concern | SARIF upload path unverified (see D4) |
| `scripts/install-gitleaks-hooks.sh` | ✅ Created as planned | Idempotent; marker detection works; backup logic matches plan |
| `gitleaks-hooks/pre-commit` | ✅ Created as planned | Runs `gitleaks git --staged --no-banner --config … --redact`; chains `.bak` on pass; remediation hint present |
| `gitleaks-hooks/pre-push` | ✅ Created as planned | Runs `gitleaks git --no-banner --config … --redact`; chains `.bak` on pass |

### Files Modified

| File | Status | Notes |
| ---- | ------ | ----- |
| `.gitignore` | ✅ Modified as planned | `gitleaks-report.*` added at end |
| `README.md` | ✅ Skipped (acceptable) | Plan marked it optional; no existing tools/security section |

### Diagrams Conformance

| Diagram Type | Status | Notes |
| ------------- | ------ | ----- |
| Sequence: Commit-time | ✅ Conforms (structurally) | commit → pre-commit runs `gitleaks git --staged` → reads `.gitleaks.toml` → leak=exit 1 / clean=exec `pre-commit.bak`. Matches implementation. |
| Sequence: Push-time | ✅ Conforms (structurally) | push → pre-push scans full history → block/allow → CI backstop. Matches implementation. |

Caveat: the diagrams depict "on leak → exit 1". That holds only for non-allowlisted paths; the `config/` allowlist (D1) breaks this guarantee for `config/**`.

### Test Cases Coverage

The builder's `tests/test_gitleaks_integration.sh` contains 20 **content/exists** assertions (file exists, file contains string X). It contains **zero** behavioral tests mapped to the plan's test cases. Per reviewer TDD-compliance rules, missing behavioral coverage for testable logic is blocking.

| TC-ID | Priority | Type | Status | Notes |
| ----- | -------- | ---- | ------ | ----- |
| TC-01 | P0 | Security | ❌ Not covered | No test stages a recognizable secret and asserts the commit is aborted. Reviewer ran it manually: **PASS for non-allowlisted path** (exit 1), **FAIL under `config/`** (exit 0 — the D1 hole). Also note the plan's chosen key `AKIAIOSFODNN7EXAMPLE` is in gitleaks' own default example-key allowlist and is never detected — the plan's TC-01 test data is itself flawed. |
| TC-02 | P0 | Functional | ❌ Not covered | No automated test. Reviewer ran manually: clean commit allowed (exit 0) ✅. |
| TC-03 | P1 | Security | ❌ Not covered | No test for `git commit --no-verify` + push block. Not run. |
| TC-04 | P1 | Regression | ❌ Not covered | No automated test. Reviewer ran manually: `gitleaks dir . --config .gitleaks.toml` → 0 leaks ✅ (scanned 1.01 MB in 80ms). |
| TC-05 | P2 | Functional | ❌ Not covered | No automated test. Reviewer ran manually: installer idempotent (run #2 skips both hooks) ✅; hook preservation not exercised (no pre-existing hook in repo). |
| TC-06 | P1 | Integration | ❌ Not covered | Requires GitHub; cannot verify locally. Acceptable to defer, but should be noted as unverified. |

## Discrepancies

### D1 — Over-broad `config/` allowlist defeats the primary success criterion [BLOCKING]

**Plan Specification**: Allowlist only `config/rio/themes` (concrete vendored path) plus the listed top-level vendored/ignored dirs. Risk table mitigation explicitly says: "Allowlist only concrete top-level dirs."

**Actual Implementation**: `.gitleaks.toml` adds `"config/"` to the allowlist, which allowlists the **entire** tracked `config/` tree. The builder's implementation report lists this as a "deviation" and calls it "still narrowly scoped" — it is not. 44 tracked files live under `config/`, including `config/git-commit-ai/config.json` and `config/opencode/opencode.jsonc` (AI-agent configs the plan flags as prime leak vectors).

**Impact (proven by reviewer)**: Staging a real Slack bot token (`xoxb-…REDACTED…`, detectable by default rules) under `config/git-commit-ai/REVIEW_TEST_LEAK.txt` and running the pre-commit hook's exact command yields **exit 0 / no leaks**. The same token staged at the repo root is blocked (exit 1). This directly violates the plan's #1 success criterion ("Committing a file containing a recognizable secret … is blocked locally by the pre-commit hook"). Because the same `.gitleaks.toml` is auto-detected by `gitleaks-action@v2` in CI, the server-side backstop is equally weakened for `config/**` paths.

**Recommendation**: Remove `"config/"` from the allowlist. Keep only `"config/rio/themes"` as the plan specified. If `config/rio/themes` needs broader coverage, enumerate concrete vendored subpaths instead of allowlisting the whole tree.

### D2 — Config comment is factually false [BLOCKING / CONCERNING]

**Plan Specification**: Plan states "Commit-path scans (`git --staged`, `git`) of tracked content remain fully enforced" and "rely on `.gitignore` + git-level scans for the commit path."

**Actual Implementation**: `.gitleaks.toml` carries the comment: *"This allowlist applies to working-tree scans only. Commit-path scans (`git --staged`, `git`) of tracked content remain fully enforced."*

**Impact**: This is **false**. Gitleaks path allowlists apply to **all** scan modes, including `git --staged` and `git` (history) — proven by D1's test (staged secret under `config/` was skipped). The comment will mislead future maintainers into adding more paths believing the commit path stays strict, compounding the hole. This also means the plan's own assumption ("path allowlists … only what dir/local scans need") is incorrect for gitleaks 8.x.

**Recommendation**: Either (a) remove path allowlists that touch tracked paths entirely (the only truly safe option for staged/history enforcement), or (b) keep them strictly limited to vendored/untracked dirs AND rewrite the comment to accurately state that path allowlists apply to `dir`, `git`, and `git --staged` alike. Document that any allowlisted tracked path is a blind spot for all scan types.

### D3 — Test suite does not cover TC-01..TC-06 [BLOCKING — TDD compliance]

**Plan Specification**: Six test cases (TC-01 through TC-06) define expected behavior with steps and expected results.

**Actual Implementation**: `tests/test_gitleaks_integration.sh` is a static content/exists checker (file present, file contains string). None of the six behavioral scenarios are implemented as executable tests. The builder's report lists the verification commands as "Next Steps" rather than having run them.

**Impact**: The plan's acceptance criteria are not demonstrably satisfied by an automated suite. The most important test (TC-01, the negative/block test) would have **caught D1** had it been run with a secret staged under `config/` — its absence is why the hole shipped.

**Recommendation**: Replace/augment the content checks with behavioral tests that map to each TC-ID, e.g. a script that stages a detectable secret (Slack/Stripe token, NOT `AKIAIOSFODNN7EXAMPLE`) and asserts non-zero exit; stages it under an allowlisted path to assert the documented blind spot is intentional; runs the installer twice and asserts idempotency; runs `gitleaks dir . --config .gitleaks.toml` and asserts 0 leaks. TC-06 (CI) may remain manual but should be documented as deferred.

### D4 — CI SARIF upload path unverified [CONCERNING]

**Plan Specification**: "Upload SARIF report as an artifact (`github/codeql-action/upload-sarif@v3`) so findings surface in GitHub Security tab" (an acceptance criterion).

**Actual Implementation**: Workflow runs `gitleaks/gitleaks-action@v2` then `github/codeql-action/upload-sarif@v3` with `sarif_file: results.sarif`, guarded by `if: always()` and `continue-on-error: true`.

**Impact**: The actual SARIF output path produced by `gitleaks-action@v2` is not confirmed to be `results.sarif`. If the path is wrong, the `continue-on-error: true` silently masks the upload failure, the job still passes, but findings never reach the Security tab — quietly failing an acceptance criterion. Cannot verify locally.

**Recommendation**: Confirm the action's SARIF output path against `gitleaks/gitleaks-action` docs, or rely on the action's built-in upload (it uploads SARIF to the Security tab itself when `security-events: write` is granted). Add a step that fails loudly if the SARIF file is missing rather than `continue-on-error`.

### D5 — Implementation report mislabels a non-deviation [MINOR]

**Plan Specification**: Installer: "refuse to clobber an existing `.bak`, print error."

**Actual Implementation**: Installer refuses to overwrite an existing `.bak` and exits 1. The implementation report lists this as a deviation ("Safety improvement … Refused to overwrite existing `.bak`").

**Impact**: None functionally — the behavior **matches** the plan exactly. The report's "Deviation" table entry is inaccurate and could confuse a reviewer.

**Recommendation**: Remove that row from the report's Deviations table; it is not a deviation.

### D6 — Hook chaining requires `.bak` to be executable [MINOR]

**Plan Specification**: "On pass: if `pre-commit.bak` exists, exec it."

**Actual Implementation**: `if [ -x "$bak" ]; then exec "$bak"; fi` (checks executability, not just existence).

**Impact**: If a pre-existing hook was not executable, chaining silently no-ops. Git hooks are normally executable, so practical impact is low, but it diverges from the spec's "if it exists".

**Recommendation**: Use `[ -f "$bak" ]` and `sh "$bak"` (or `exec sh "$bak"`) to match the "exists" semantics and avoid skipping non-executable backups.

### D7 — Allowlist comments not per-path [MINOR]

**Plan Specification**: `.gitleaks.toml` should "Include a comment block documenting WHY each path is allowed."

**Actual Implementation**: Comments group paths by category ("local runtime data / credentials, gitignored" and "Vendored submodule / third-party content") but do not document WHY each individual path is allowed.

**Impact**: Low. A future maintainer adding a path has a rough guide but not per-path rationale.

**Recommendation**: Add a one-line `#` rationale per allowlisted path (e.g. `# kimi: gitignored local runtime data (credentials/sessions/telemetry)`).

## Obstacles Resolution

| Obstacle | Status | Resolution |
| -------- | ------- | ---------- |
| (none reported by builder) | ✅ N/A | Builder reported no obstacles. Review confirms no environmental obstacles, but found two blocking implementation issues (D1, D3). |

## Verification Commands (run by reviewer)

| # | Command | Result |
| - | ------- | ------ |
| 1 | `gitleaks dir . --config .gitleaks.toml --no-banner` | ✅ 0 leaks, 1.01 MB in 80ms |
| 2 | `gitleaks git --staged --config .gitleaks.toml --no-banner` (clean index) | ✅ 0 leaks |
| 3 | `gitleaks git --config .gitleaks.toml --no-banner` (full history) | ✅ 0 leaks, 1801 commits in 781ms |
| 4 | `scripts/install-gitleaks-hooks.sh` ×2 | ✅ Idempotent (2nd run skips) |
| 5 | `.git/hooks/pre-commit` with staged Slack token at repo root | ✅ Exit 1 (blocked) |
| 6 | `.git/hooks/pre-commit` with staged Slack token under `config/` | ❌ Exit 0 (NOT blocked — D1) |
| 7 | `.git/hooks/pre-commit` clean index | ✅ Exit 0 |

Test artifacts (staged leak files, installed test hooks) were cleaned up; `.git/hooks` restored to original state (no pre-commit/pre-push).

## Related Links

- Original Plan: [Plan](../plans/2026-08-12/GITLEAKS_INTEGRATION_PLAN.md)
- Implementation Reports:
  - [Implementation Report](../implementation-reports/2026-08-12/GITLEAKS_INTEGRATION_REPORT.md)

## Reviewer Notes

- The plan's TC-01 test data (`AKIAIOSFODNN7EXAMPLE`) is itself flawed: gitleaks' default config allowlists that exact AWS example key, so it is never detected even with a perfectly correct implementation. TC-01 should be rewritten to use a detectable token (the reviewer used a Slack bot token and a Stripe key, both detected).
- The plan's assumption that gitleaks path allowlists are scoped to `dir`/local scans only is **incorrect** for gitleaks 8.x — they apply to `git` and `git --staged` as well. This assumption underpins the "commit path remains fully enforced" claim and should be corrected in the plan when D1/D2 are addressed.
- Overall code quality of the hook scripts and installer is good: clean POSIX sh, graceful missing-binary handling, `--redact` used, idempotent installer with marker detection. The blocking issues are scoped to config scope (D1) and test coverage (D3), not to script craftsmanship.
- Recommended fix order: D1 (remove `config/` from allowlist) → D2 (fix comment) → D3 (add behavioral tests, which would have caught D1) → D4 (verify SARIF) → D5/D6/D7 (minor). After D1+D2, re-run verification commands #1–#7 (expect #6 to flip to ❌→✅ blocked once `config/` is removed).
