# Backup, deletion gate, and recovery

## Choose a durable private location

Use an explicitly writable path **outside all removal targets**, not an OS temporary directory. Prefer a user-approved archival directory; a Git common-directory backup is optional only when permitted by the harness and local policy. Never route around protected-path denials using shell, Python, or another tool. Choose another permitted location or ask.

Check free space and permissions. On Unix create a private directory with `umask 077`; use restrictive ACLs elsewhere. Backups can include `.env` files, credentials, remote URLs, and reflogs. Do not upload them or print their contents. Reject a backup path that resolves inside a deletion target through symlinks.

## Inventory everything that will disappear

Snapshot tracked, staged, unstaged, untracked, and ignored files. Save paths, file types, sizes, modes, regular-file SHA-256 hashes, and symlink targets. Include hidden files, local reports, issue notes, environment files, nested repositories, and module metadata.

Use `lstat`/equivalent and archive symlinks as links; never follow an external target. Detect unexpected sockets, devices, mounts, and other special files and resolve them before deletion. A known disposable process socket can be removed by stopping its owner; unknown special files block the cleanup.

Exclude only individually identified regenerable directories approved for this run, with exact relative paths in the manifest. Do not use blanket name-based exclusion of `build`, `dist`, `vendor`, or `node_modules`: projects can keep real authored changes there. Prove excluded content is regenerable, or archive it. Avoid filesystem traversal into excluded directories only after that decision is recorded.

## Preserve history separately from files

A working-files archive is not a Git backup. A patch is also not a complete backup: it can miss untracked files, index state, binary data, submodule commits, refs, and reflogs.

Record each repository’s actual Git directory and Git common directory using Git, not assumptions about `.git` being a directory. Account for:

- Linked worktrees whose `.git` is a pointer file and whose objects/refs live elsewhere.
- Submodule repositories under worktree-owned metadata, including uninitialized modules with remaining local refs.
- External/shared submodule common directories and their other registered worktrees.
- Object alternates, shallow/promisor/partial clones, Git LFS objects, and local stashes.
- Ref metadata, indexes, config, reflogs, detached HEADs, and local branches beyond the currently checked-out branch.

For the workspace/root, make a self-contained `git bundle` of every approved branch/HEAD whose history may otherwise become unreachable; include other relevant local-only refs/stashes. Verify the bundle and its advertised heads. For each submodule whose Git storage will be deleted, preserve **all** local history, not just its current tip: archive complete owned Git metadata/object storage or create verified self-contained bundles plus the metadata needed for recovery.

A metadata archive that still relies on an unarchived alternate/object store is not self-contained. Bundles do not include LFS payloads or arbitrary unreachable reflog objects. Preserve required stores/payloads and local-only reflog history, or block removal if recovery cannot be guaranteed. Do not delete external/shared object stores. Uncertain ownership or additional worktrees under a proposed deletion path blocks removal until resolved.

For verified merged history that remains on a retained repository/remote, record the recovery source explicitly; still preserve unmerged/unpushed/stashed/untracked material before deletion. Deleted remote tips must have recorded recoverability, including rebased source history not reachable from the target.

## Verify before removal

Create an archive member manifest and verify it against the source inventory. Reopen archives and hash regular-file contents, validate symlink targets/types/modes, and compare the complete member set. Reject incomplete, truncated, or unreadable archives. Verify bundle integrity and dependencies; archive-level hashes alone only detect later corruption, not an incomplete backup.

Record before/after repository HEADs, refs, status, and filesystem inventory while making the backup. Any change during capture invalidates it. Immediately before deletion, rescan the **full inventory**, not only previously known paths: newly created ignored files must be detected. Check that retained baselines remain stable, locks are absent, and no active process is using the target.

No check eliminates all concurrent-writer races. Stop approved obsolete writers, leave active development alone, and defer when a stable snapshot cannot be established. Do not forcibly unlock a worktree or bypass a lock file.

## Suggested artifacts

```text
cleanup-<timestamp>/
  inventory.json
  approvals.json
  provider-evidence.json
  retained-before.json
  workspace-history.bundle
  <worktree-id>/
    working-files.tar.gz
    git-metadata.tar.gz       # where owned metadata will be deleted
    manifest.json
    workspace.patch          # convenience, not the backup of record
  actions.jsonl
  final-verification.json
  SHA256SUMS
  RECOVERY.md
```

Schema may vary; include exact repository/path/ref identities, deleted SHAs, timestamps, command outcomes, exemptions, exclusions, and backup checksums. Write action results incrementally so a partial cleanup can resume without redoing successful deletions. Store logs privately and redact credentials.

## Recovery instructions

Write specific recovery instructions for the actual archive format and Git layout used. Start by extracting selected files into a new private directory, never directly over a live repository. Validate checksums first.

`git bundle list-heads <bundle>` lists recoverable refs; fetching a bundle into a recovery repository can restore their history. A copied linked-worktree metadata tree may contain absolute/relative `gitdir`, `commondir`, and submodule `core.worktree` paths; restoring at a different location requires Git-aware repair, not a blind tar extraction. Document original paths and any external retained dependencies. Restore LFS payloads separately when needed. Reinstall only the explicitly excluded regenerable dependencies/caches.

Do not delete the backup after successful cleanup without a separate retention decision. Report its path, size if measured, and privacy warning.
