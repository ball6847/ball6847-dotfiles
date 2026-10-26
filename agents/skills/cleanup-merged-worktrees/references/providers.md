# Provider routing and merge proof

## Establish identity before API calls

For each repository, record its Git common directory, candidate local ref, fetch remote, intended integration repository/branch, and remote ref owner. Submodules are independent repositories.

Useful discovery commands (read-only):

```bash
git -C "$repo_path" remote -v
git -C "$repo_path" remote get-url --all "$remote"
git -C "$repo_path" remote get-url --push --all "$remote"
git -C "$repo_path" config --get "remote.$remote.mirror"
git -C "$repo_path" for-each-ref --format='%(refname) %(objectname) %(upstream)'
```

Parse HTTPS, `ssh://`, and SCP-style SSH URLs without dropping nested GitLab namespaces. Strip only a terminal `.git`. Redact URL credentials from logs. Respect `url.*.insteadOf`/`pushInsteadOf`; validate effective endpoints, not just raw config. For SSH aliases, `ssh -G alias` can identify HostName without opening a connection. An SSH HostName may still differ from the API hostname, so confirm using CLI host configuration and repository metadata.

Do not infer provider from the executable installed or a hostname containing “git”. For github.com/gitlab.com the public provider is known; for enterprise/custom hosts use existing configuration and a successful read-only repository lookup. If ambiguous, ask once. Unknown providers get an inventory-only report, not a guessed API.

Use `gh api --hostname "$api_host" ...` for GitHub and `glab api --hostname "$api_host" ...` for GitLab. Explicit paths prevent current-directory remote selection surprises. Follow any repository-specific CLI environment rules, but do not embed this session’s hosts/aliases into the global skill. Do not change authentication or dump tokens/config files to solve routing.

Confirm returned repository ID/path and default branch. Resolve source and target repository identities separately, especially with forks. A PR in upstream can use a branch owned by a fork; deleting `upstream:feature` would delete a different ref.

## Normalize evidence

Use one internal shape for either adapter:

```text
provider, api_host
source_repo_id/path, target_repo_id/path
change_number, url, state, merged_at
source_branch, historical_source_sha
target_branch, merge_commit_sha, squash_commit_sha
local_tip_sha, live_remote_tip_sha, live_target_tip_sha
protected/default/ruleset status
open_source_dependencies[], open_target_dependencies[]
proof_kind, proof_details, checked_at
```

A check is verified only when every required request succeeds and all result pages are processed. Check process return codes before parsing output. Do not turn a 401, 403, network failure, rate limit, timeout, or generic 404 into “no PR”/“already deleted.” Verify repository visibility first and corroborate branch absence with successful `git ls-remote --refs` on the exact endpoint. If API and Git disagree, keep the branch pending resolution.

## Fresh Git evidence

`git ls-remote --refs` gives current IDs but does not download objects. Fetch only required branches/objects with `--no-tags --no-recurse-submodules`, without checkout, pull, or prune. Record any temporary refs and remove only those created by this run after evidence is saved. A shallow clone or missing object can make ancestry fail; distinguish “not ancestor” from command/object errors. Deepen only with appropriate scope, or report unknown.

Treat `git merge-base --is-ancestor A B` exit 0 as true, 1 as false, and other exits as failure. For exceptional tree equivalence, both `git rev-parse --verify '<sha>^{tree}'` calls must succeed before comparing nonempty outputs. Empty/error strings are never equal-tree proof.

The accepted target comes from the PR/MR and project branch policy, not a universal main/develop preference. For a feature-branch target, trace the chain to the actual integration branch. Store the live integration tip and verify that the PR/MR merge or squash commit remains reachable from it.

## Safe deletion identity

A remote branch key is `(provider host, source repository ID/path, full refs/heads/name)`—not just a branch name. Local branches are additionally keyed by Git common directory. Deduplicate actions by these identities.

Before push deletion, resolve exactly one authorized destination and independently validate its live SHA. Avoid configured mirror/multiple push destinations. Never construct an authenticated URL for logging. Compare the exact ref returned by `ls-remote`; exit 0 with empty output is absence, while nonzero exit is a failure.

Scan open source and target dependencies in repositories relevant to that branch, not just the merged change’s repository. In fork workflows, include known upstreams and other repositories where this fork is a PR/MR source. If that dependency scope cannot be established reliably, retain the remote branch rather than claim exhaustive safety. A server-side search can help discover dependencies but is not exhaustive if pagination, permissions, or search limits truncate results.
