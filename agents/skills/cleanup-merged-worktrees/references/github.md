# GitHub adapter (`gh`)

Use explicit API hostname and owner/repository, including on GitHub Enterprise. Commands below are GET-only evidence collection; interpolate validated, URL-encoded values. With `gh api`, query fields require `--method GET` because adding fields otherwise selects POST.

## Repository and candidate PRs

```bash
gh auth status --hostname "$api_host"
gh api --hostname "$api_host" "repos/$owner/$repo"
gh api --hostname "$api_host" --method GET --paginate \
  "repos/$owner/$repo/pulls" \
  -f state=all -f "head=$source_owner:$source_branch" -f per_page=100
```

Query the **base repository** for PRs, which may differ from the source fork. Read every matching PR individually:

```bash
gh api --hostname "$api_host" "repos/$base_owner/$base_repo/pulls/$number"
```

Record `merged`, `merged_at`, `head.sha`, `head.ref`, `head.repo.id/full_name`, `base.ref`, `base.repo.id/full_name`, `merge_commit_sha`, and `html_url`. REST `state: closed` alone does not mean merged. Validate both repository IDs, not just branch labels. If source repository data is null/deleted or otherwise ambiguous, keep local work pending historical verification.

`merge_commit_sha` semantics depend on merge strategy. For a merged PR, verify the recorded integration commit is reachable from the fresh accepted target. Verify the candidate local and remote tips are covered by the **merged version** of the PR. For ambiguous source SHA history (reused branch, API head moved after merging), inspect the merged commit/parents, PR commit list, and timeline or retained historical evidence. Do not assume any PR sharing the branch name covers today's tip.

```bash
gh api --hostname "$api_host" --paginate \
  "repos/$base_owner/$base_repo/pulls/$number/commits?per_page=100"
```

The PR commits API has a maximum of 250 commits; that list alone is not exhaustive for larger PRs. Use Git history or mark the result unknown. Exact recorded source-tip proof does not require enumerating every commit.

## Live branch and protections

Encode the branch as one URL path component (`/` becomes `%2F`):

```bash
gh api --hostname "$api_host" "repos/$source_owner/$source_repo/branches/$encoded_branch"
gh api --hostname "$api_host" --paginate \
  "repos/$source_owner/$source_repo/rules/branches/$encoded_branch?per_page=100"
```

Check repository `default_branch`, branch `protected`, applicable repository/organization rulesets, and local branch policy. Ruleset bypass permission is not cleanup authorization. A rules endpoint unavailable on a particular Enterprise version or inaccessible to your token is **unknown**, not proof of no restrictions; use supported read-only equivalents or keep the ref.

## Open dependencies and forks

Enumerate all open PRs in the source repository and each known upstream/base repository that can reference the candidate:

```bash
gh api --hostname "$api_host" --method GET --paginate \
  "repos/$check_owner/$check_repo/pulls" -f state=open -f per_page=100
```

Compare `(head.repo.id, head.ref)` for source use and `(base.repo.id, base.ref)` for target use. A same-named branch in a different fork is a different ref. Include stacked PRs targeting the candidate and PRs from the candidate into another known upstream, not only PRs into the repository’s default branch. GitHub search can discover additional PRs but has result limits and should not silently replace exhaustive known-repository enumeration.

If the remote ref is missing, confirm the source repository lookup succeeded and `git ls-remote` to its exact push endpoint succeeds with no matching ref. Report “already absent,” not “deleted by this run.” Provider/auth errors remain blockers.

Return normalized evidence to the main workflow. Use its lease-protected Git deletion; do not use `gh pr close --delete-branch`, unconditional `gh api -X DELETE`, or `gh pr merge` for housekeeping.
