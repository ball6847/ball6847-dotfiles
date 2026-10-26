# GitLab adapter (`glab`)

Use explicit API hostname and URL-encoded project path, including on self-managed hosts. Nested group paths must be fully encoded, or use the verified numeric project ID returned by GitLab. Do not assume the workspace root’s project/host applies to submodules.

Respect repository-specific environment instructions. For example, if local instructions require a fixed `GLAB_HOST` to avoid an SSH alias, retain that environment rule and pass the actual API host through `--hostname`. Do not modify global auth/config or encode any particular organization’s alias as a universal rule.

## Project and candidate MRs

```bash
glab api --hostname "$api_host" "projects/$encoded_project"
glab api --hostname "$api_host" --method GET --paginate \
  "projects/$target_project_id/merge_requests" \
  -f state=all -f "source_branch=$source_branch" -f per_page=100
```

Query MRs in the **target project**, including for forks. `--method GET` is intentional: adding fields otherwise changes the HTTP method. Read each matching MR individually:

```bash
glab api --hostname "$api_host" \
  "projects/$target_project_id/merge_requests/$iid"
```

Record `state`, `merged_at`, `sha`, `source_branch`, `target_branch`, `source_project_id`, `target_project_id`, `merge_commit_sha`, `squash_commit_sha`, `diff_refs`, and `web_url`. Require `state == merged`; closed is not merged. Validate source project identity as well as the branch name.

For reused/advanced branches or conflicting current versus historical SHA fields, inspect MR diff versions and commits, without treating the latest source branch tip as necessarily the merged tip:

```bash
glab api --hostname "$api_host" --paginate \
  "projects/$target_project_id/merge_requests/$iid/versions?per_page=100"
glab api --hostname "$api_host" --paginate \
  "projects/$target_project_id/merge_requests/$iid/commits?per_page=100"
```

For squash merges, compare candidates to the verified historical source SHA and independently verify the merge/squash integration commit remains reachable from the fresh accepted target. In fast-forward workflows where integration fields are unavailable, require direct ancestry into the live target or other complete historical proof; null integration fields are not permission to skip verification.

## Live source ref and protection

Encode branch names as one path component:

```bash
glab api --hostname "$api_host" \
  "projects/$source_project_id/repository/branches/$encoded_branch"
glab api --hostname "$api_host" --paginate \
  "projects/$source_project_id/protected_branches?per_page=100"
```

Check the branch’s `protected` and `default` flags, the source project’s default branch, applicable wildcard/inherited protections, and project integration/release policy. Never unprotect a branch or use elevated privileges just to delete it. Permission failures or incomplete inherited-protection information are blockers when needed to establish safety.

## Open dependencies and forks

Enumerate open MRs in the source project and known target/upstream projects:

```bash
glab api --hostname "$api_host" --method GET --paginate \
  "projects/$check_project_id/merge_requests" -f state=opened -f per_page=100
```

Compare `(source_project_id, source_branch)` and `(target_project_id, target_branch)`. Include stacked MRs and cross-project sources, not only MRs into the default branch. If a source project can feed an unknown set of target projects, use available instance-wide authorized discovery to resolve that scope or retain the branch. Missing access to a relevant project prevents an exhaustive claim.

Handle paginated CLI output according to the installed version. Some versions emit successive JSON arrays; do not parse only page one or ignore a decode error. Prefer supported ndjson output or explicitly collect each page and verify completeness.

A branch-specific 404 counts as absent only after source-project visibility is verified and successful `git ls-remote` on the exact destination confirms no ref. A commit 404 can mean an unpushed local tip; preserve it until integration evidence resolves it.

Return normalized evidence to the main workflow. Delete with its exact-SHA leased Git refspec, not `glab mr close`, a merge command, bulk merged-branch deletion, or an unconditional branch DELETE API.
