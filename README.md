# %urgit

## `|install ~matwet %urgit`

<img width="947" height="585" alt="image" src="https://github.com/user-attachments/assets/b13cdad5-ab95-4e9a-95af-e3fc81fbdd18" />

`%urgit` makes an Urbit ship a native Git remote. Standard Git clients use Smart HTTP through Eyre while Gall owns the object database, refs, and repository policy. No Git executable or server-side sidecar is involved.

## Features

- clone, fetch, push, force-update, and delete refs with ordinary Git clients
- canonical SHA-1 object storage for blobs, trees, commits, and tags
- native pkt-line parsing and pack v2 encoding/decoding in Hoon
- Git wire protocols v0/v1 and v2, including command-based `ls-refs` and `fetch`
- native zlib/DEFLATE plus `REF_DELTA` and `OFS_DELTA` pack ingestion
- reachability-limited packs with native ACK negotiation and incremental closure subtraction
- shallow clone, relative deepening, and unshallow fetches with stock Git clients
- partial clone filters for `blob:none` and `blob:limit`, including on-demand promisor blob fetches
- atomic ref transactions protected by per-repository write credentials
- per-branch protection with Git-native force-push and deletion rejections
- authenticated and public branch comparison with complete tree diffs and downloadable `git apply` patches for bounded text changes
- optional branch-to-desk bindings that apply pushed commits directly to Clay
- Clay-gated pushes: invalid desks are rejected by Git with the complete Ford stack trace
- Clay-to-Git publishing that snapshots a bound desk as canonical blobs, trees, and commits
- native Clay revision history for bound branches, including revision numbers, canonical timestamps, takos, mapped Git commits, per-file history, and revision diffs
- bridge status and explicit synchronization controls that compare the live desk with the linked branch and can safely apply either side
- GitHub-style web interface for repositories, rendered Markdown READMEs, branch creation/defaults/deletion, expandable file trees, deep-linked source lines, branch-aware file creation/editing/deletion, history, line blame, authorship, diffs, and repository settings
- branch-aware repository code search with line-level results that open directly in the highlighted source view
- lightweight and annotated tag management with contextual commit/revision actions, unique abbreviated commit IDs, and standards-compliant peeled advertisements
- tags can target native Clay revisions; the selected revision is materialized as a canonical Git commit and recorded in the revision-to-commit map without moving the bound branch
- releases rooted at existing tags, with notes and deterministic source tar archives for authenticated and public repository pages
- signed outgoing webhooks for pushes, tags, pull requests, issues, releases, and successful Clay synchronization, with a bounded delivery ledger
- signed incoming GitHub webhooks: pushes create explicit upstream-update prompts, while pull-request events refresh linked PR metadata in the background
- unauthenticated read-only repository pages for public projects, including branches, files, history, and commit diffs
- repository summaries report files, commits, branches, tags, and LFS files instead of internal object counts
- one-click publication of any mounted Clay desk as a Git repository
- verified, incremental native forks with explicit pull-from-origin refresh: Ames coordinates access and refs while bounded sequential Fine pages carry checksummed Git pack bytes for only the missing immutable objects; duplicate requests coalesce and active transfers can be cancelled
- persistent ship peers in the sidebar, with on-demand public repository discovery; bounded remote browsing of code, branches, history, rendered READMEs, and individual file previews; and full native issue and pull-request discussions read through request-scoped Fine
- ship write ACLs with fast-forward-only native push-back from authorized forks
- native pull requests between ships or local branches, with close/reopen lifecycle, per-file red/green diffs, resolvable general and line-anchored review comments, cross-ship discussion at the origin, fast-forward or conflict-checked three-way merges, and Clay gating
- native issues authored by ship identity, with remote creation, open/close lifecycle, origin-authoritative cross-ship comments, labels, assignees, public read-only views, and linked `~ship/repository#number` references
- per-repository Landscape notifications for incoming native issues, pull requests, and comments, with event-level muting, Hark-owned `%urgit` history, and an Urgit-only top-bar feed
- explicit Clay revision-to-commit history for both pushed Git trees and published desk snapshots
- bidirectional GitHub synchronization through Git Smart HTTP: safe fast-forward pulls and branch-selectable pushes preserving canonical object IDs
- optional GitHub token support for private imports, GitHub forks, and opening pull requests
- paginated, deduplicated GitHub issue and pull-request lists with conditional load-more controls, request-scoped full bodies and unified pull-request diffs, and upstream file contents fetched on demand
- Git and Clay histories loaded in pages of 50, with commit and revision detail available from every displayed identifier
- browser-local draft recovery for file creation and editing, issue composition, pull-request titles, and local or remote discussion comments
- JSON scries and HTTP APIs for repository summaries, refs, first-parent history, and file trees
- Git LFS batch uploads and downloads backed by the ship's configured object storage
- Git LFS file locking compatible with stock `git lfs lock`, `locks`, and `unlock`
- explicit reachability-based cleanup of verified LFS payloads no longer referenced by any repository ref
- direct, short-lived Signature V4 transfer actions so large LFS payloads bypass the loom
- stable Smart HTTP remotes at:

```text
https://ship.example/git/<repository>
```

Further protocol work is tracked in [`specs/roadmap.md`](specs/roadmap.md). Protocol boundaries are documented in [`specs/architecture.md`](specs/architecture.md).

## Development

Build directly into a mounted desk:

```sh
zig build -Ddesk=/path/to/pier/urgit
```

The build requires Git, Zig, and Node.js 22 (or Node.js 20.19 or newer). It installs frontend dependencies with `npm` when needed.

Then commit the `%urgit` desk and run the protocol vectors:

```hoon
+urgit!git-codec-vector
+urgit!git-pack-vector
+urgit!git-pack-decode-vector
+urgit!git-stock-pack-vector
+urgit!git-delta-pack-vector
+urgit!git-ofs-delta-pack-vector
+urgit!git-storage-vector
+urgit!git-clay-vector
+urgit!git-tree-vector
+urgit!git-archive-vector
+urgit!git-shallow-vector
+urgit!git-blame-vector
+urgit!git-github-vector
+urgit!git-webhook-vector
```

The codec vector's blob OID must be `3b18e512dba79e4c8300dd08aeb37f8e728b8dad`, matching `git hash-object` for `hello world\n`. The pack vectors cover local round trips and stock Git packs containing binary tree data, `REF_DELTA`, and `OFS_DELTA` entries. The storage vector checks that object-store transfers contain authorization, date, and payload-hash headers. The archive vector checks executable and symbolic-link tar entries. The webhook vector checks a standard HMAC-SHA256 value and GitHub push parsing.

Each repository can be assigned a write token with the `%set-write-token` action. Git and Git LFS clients use any Basic-auth username and that token as the password. The token authorizes fetch and push for private repositories. Public repositories permit unauthenticated fetches and LFS downloads; uploads require the write token or an authenticated ship session.

A repository branch can be linked to a Clay desk with `%bind-desk`. A push to that branch is accepted only after Clay applies and validates the projected desk. Ford failures are returned as ordinary Git `ng` report-status messages, so command-line clients, CI, and coding agents receive the compiler trace while the Git ref remains unchanged.

`%publish-desk` snapshots the current bound desk into the linked branch. Clay pages are rendered to their canonical source representation, assembled into ordinary Git blobs and recursively sorted trees, and committed with the ship as author and committer. The existing branch tip becomes the parent.

The web read model is available through `%urgit` scries at `/repositories/json`, `/repository/<name>/json`, `/repository/<name>/commits/json`, and `/repository/<name>/files/json`. A desk-bound branch reports Clay's native revision sequence through the history endpoint; ordinary branches report Git commits.

The repository settings page compares the current branch tree with the live bound desk and reports whether they are synchronized, ahead on either side, divergent, or not yet mapped. “Apply branch to desk” uses the same Clay-gated transaction as a linked Git push; “Publish desk to branch” snapshots Clay in the other direction.

The authenticated web app is served at `/apps/urgit`. Public repositories also have a read-only page at `/apps/urgit/public/<repository>` that requires no Urbit login. Its new-repository dialog creates a blank repository, publishes a mounted desk, forks from a ship, or imports from GitHub. The API manages repository policy and Clay bindings, browses, searches, compares, and edits local files, keeps peer bookmarks, remotely browses bounded public-repository overviews, forks and refreshes repositories, manages native issues and releases, opens or merges native pull requests, and configures incoming and outgoing webhooks. GitHub pull and push packs are limited to 64 MiB and 25,000 objects to protect the loom; large file payloads belong in LFS. The static frontend is built from `fe/` into `desk/web/` by the normal Zig build.
