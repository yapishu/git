# Roadmap

`%urgit` is a native Git object database and Smart HTTP server in Gall. Ordinary Git clients speak to Eyre; no Git executable or sidecar runs beside the ship.

## Working now

- state-1 repositories, ownership, public-read policy, writers, symbolic `HEAD`, refs, and canonical loose objects; state-0 upgrades in place
- SHA-1 object identity over Git's canonical `<type> <size>\0<content>` representation
- binary-safe pkt-line encoding and decoding, including flush, delimiter, and response-end packets
- protocol v0/v1 Smart HTTP ref discovery for upload-pack
- protocol v2 capability discovery, `ls-refs`, and section-framed sideband `fetch`
- upload-pack request parsing for wants, haves, flushes, and `done`
- pack v2 generation with full objects, zlib-wrapped stored DEFLATE blocks, Adler-32 checksums, and a trailing pack SHA-1
- commit, tree, and tag graph traversal with wants restricted to advertised refs and packs restricted to the requested reachable closure
- stateless upload-pack negotiation that ACKs advertised common objects and subtracts the client's known reachable closure from incremental fetch packs
- shallow clone and fetch with boundary reporting, relative deepening, and unshallow support
- partial clone with `blob:none` and `blob:limit` filters plus on-demand promisor blob retrieval
- successful stock-client `ls-remote`, fetch, and clone, verified with `git fsck --full`
- authenticated Smart HTTP receive-pack discovery and push
- native zlib/DEFLATE decoding for stored, fixed-Huffman, and dynamic-Huffman streams
- verified full-object, `REF_DELTA`, and `OFS_DELTA` pack ingestion, including chained deltas
- staged pack validation and atomic create, update, force-update, and delete ref transactions
- per-branch protection that permits creation and fast-forward updates while rejecting force-pushes and deletion with Git report-status errors
- canonical object hashing for arbitrary binary payloads and undecorated decimal sizes
- unconditional `/git` Eyre rebinding on agent load
- Git LFS Batch and Basic Transfer APIs for SHA-256 objects
- direct signed PUT and GET actions against the endpoint, bucket, and region configured in `%storage`
- post-upload HEAD verification before LFS metadata becomes authoritative
- Git LFS file locking with exclusive paths, owner-aware create/list/verify/unlock, bounded cursor pagination, and stock-client interoperability
- explicit LFS garbage collection that scans every advertised ref closure, previews unreachable verified payloads, and deletes at most 100 objects per confirmed run
- Basic write tokens stored only as hashes, with authenticated ship sessions accepted for administration
- optional branch-to-Clay-desk bindings with canonical Git-tree-to-desk path conversion
- two-phase linked pushes that advance the Git ref only after Clay accepts the complete delta
- Git-compatible rejection messages containing the Clay/Ford trace when a linked desk does not validate
- non-reentrant timer error handling that cannot retry a failed Clay mutation or jam Behn
- Clay-to-Git publication of a bound desk as canonical blobs, recursively sorted trees, and a parented commit
- typeless Clay page reads for publishing minimal desks without requiring every mark core to build first
- binding and publication guards that reject nonexistent desks
- JSON read models for repository metadata, refs, first-parent history, and head-tree file listings
- authenticated web API for repository lifecycle, access policy, write tokens, Clay bindings, and publication
- componentized React interface with repository navigation, clone URLs, file trees, commit history, and settings
- GitHub-style repository summaries with file, commit, branch, tag, and LFS counts rather than internal object counts
- branch-aware file browsing, text and image blob views, authenticated text editing, per-file history, commit identities, and commit detail
- bounded occurrence-aware line blame across Git first-parent commits and native Clay revisions, with attributed source gutters in authenticated and public file views
- mounted-desk discovery and first-class desk-to-repository publication
- Ames-coordinated, Fine-backed repository snapshots with incremental have negotiation, a bounded initial-response deadline, byte-bounded checksummed Git-pack pages, one verified sequential Fine read in flight, exact-path `%yawn` cancellation, Dojo transfer diagnostics, status pruning, pack checksum and object-count checks, and per-object OID verification
- two-ship Fine conformance: bidirectional native forks reconstructed complete repositories and passed stock Git clone and `git fsck --full`
- on-demand Ames peer discovery with bounded public-repository catalogs, writer hints, expiry, cancellation, and status pruning
- persistent peer bookmarks with expandable public repositories in the sidebar
- bounded remote repository overviews over Ames, with request-scoped Fine overview reads accepted and every unanswered browse terminated explicitly
- remote forge summaries expose native and cached GitHub issues and pull requests alongside code, branches, and history
- request-scoped Fine detail reads expose native issue bodies and comments plus pull-request diffs and review discussion; authenticated Ames requests create native issues and append origin-authoritative ship-authored comments to both native issues and pull requests
- bounded peer activity notifications for incoming and outgoing forks, snapshot reads, native updates, and pull requests
- public native forks, explicit pull-from-origin refresh, and origin metadata
- ship writer ACLs with fast-forward-only push-back from native forks
- native pull requests whose object graphs are stored at the origin without advancing a branch
- pull-request creation in the fork UI with source/target context, live transfer status, origin navigation, remote PR listings, review diffs, and merge controls
- native pull-request detail with bounded per-file red/green textual diffs
- native issues with ship authors, open/close lifecycle, comments, deduplicated labels, ship assignees, and bounded repository summaries
- unauthenticated native issue reads for public repositories and linked `~ship/repository#number` references in issue discussion
- same-repository branch pull requests plus close/reopen lifecycle and native review discussion with general comments, base/head line anchors, and resolve/reopen state
- pull-request integration by fast-forward, already-contained detection, or canonical two-parent three-way merge with content and file-mode conflict detection
- pull-request merges and authorized native updates gated by Clay when the destination branch is desk-bound
- explicit Clay revision-to-Git commit mappings in both publication directions
- canonical native Clay history for bound branches, with exact revision numbers, timestamps, takos, mapped Git commits, bounded revision diffs, historical file reads, and per-file revision history
- live Clay/Git drift classification and explicit synchronization controls in both directions
- reload-safe, cache-invalidating static fileserver at `/apps/urgit` and a separately rebound API at `/apps/urgit/api`
- unauthenticated, sanitized read-only pages and APIs for public repositories, with branch/file browsing, history, and commit diffs
- direct GitHub Smart HTTP import and update with authentic refs, canonical OIDs, delta-pack decoding, reachable-graph validation, and 64 MiB/25,000-object bounds
- fast-forward-only GitHub pulls that preserve local-only refs and authenticated branch-selectable receive-pack pushes with report-status validation
- optional server-side GitHub token for private repositories and authenticated REST operations
- bounded five-page GitHub issue and pull-request synchronization with refresh, conditional load-more, and number deduplication; request-scoped null-safe detail and unified-diff reads; and GitHub fork and pull-request creation
- request-scoped, size-checked upstream GitHub file views for linked repositories without persisting response bodies
- consolidated new-repository flow for blank repositories, Clay desks, peer forks, and GitHub imports; peer forks accept an explicit local name, distinguish safe same-origin refreshes from collisions, and use in-app confirmation dialogs for destructive actions
- repository navigation and filtering: repository search, code, issues, pull requests, branches, 50-item commit or Clay-revision history pages, expandable file trees, deep-linked line ranges, syntax-highlighted file editing/history, and settings
- web branch management with source-tip creation, default-branch selection, guarded deletion, and create/edit/delete commits on any selected branch
- authenticated and public branch comparison with bounded tree diffs and downloadable unified patches for text-only changes
- bounded branch-aware code search with line-level deep links for authenticated and public repository views
- structural web editing that creates the first commit in a blank repository, creates nested files, preserves existing modes, removes empty directories, and deletes files through Clay-gated commits
- web creation and deletion of lightweight and annotated tags from contextual history actions or compact revision/ref/unique-short-hash targets, with canonical tag objects and peeled tag advertisements for stock Git clients
- on-demand materialization of selected native Clay revisions as canonical Git commits for tags, archives, diffs, and revision-to-commit mapping
- tag-rooted releases with immutable backing tags, bounded notes, public detail reads, and deterministic mode-preserving ustar source archives limited to 10,000 files and 64 MiB
- HMAC-SHA256 outgoing repository webhooks with event filters, pending/success/failure delivery history, and Smart HTTP plus Clay-gated push integration
- HMAC-SHA256 incoming GitHub ping, push, and pull-request endpoints; pushes record bounded, ref-coalesced upstream notices with explicit pull-or-dismiss actions, while pull-request events asynchronously refresh page-one GitHub PR metadata
- per-repository Hark notifications for incoming native issues, pull requests, and comments, with event filters, repository muting, and `%urgit`-scoped Landscape history
- conformance vectors for Git object hashing, pkt-line round trips, pack generation, stock Git pack decoding, delta resolution, GitHub receive-pack requests/results, Clay snapshots, object-store request signing, and webhook signing/parsing

## Next

1. Add origin-authoritative cross-ship pull-request line-comment and resolution operations.
2. Map native issue, pull-request, and comment mutations onto linked GitHub repositories.
3. Add cross-ship close, reopen, label, assignment, review resolution, and merge operations.
4. Add webhook delivery redelivery and editable webhook configuration.
5. Emit issue and pull-request events for every lifecycle mutation, including comments, review resolution, close, reopen, and merge.
6. Add release assets as LFS-backed objects alongside the deterministic source archive.

## Storage direction

Gall is authoritative for repository metadata, refs, permissions, Git object identity, and verified LFS metadata. Ordinary Git objects remain in state. LFS payloads are transferred directly to the ship-configured object store and never enter Gall state; the object store validates the signed SHA-256 payload hash, and Gall records an object only after a successful size-checked HEAD request.
