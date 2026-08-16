# Roadmap

`%git` is a native Git object database and Smart HTTP server in Gall. Ordinary Git clients speak to Eyre; no Git executable or sidecar runs beside the ship.

## Working now

- state-0 repositories, ownership, public-read policy, writers, symbolic `HEAD`, refs, and canonical loose objects
- SHA-1 object identity over Git's canonical `<type> <size>\0<content>` representation
- binary-safe pkt-line encoding and decoding, including flush, delimiter, and response-end packets
- protocol v0/v1 Smart HTTP ref discovery for upload-pack
- upload-pack request parsing for wants, haves, flushes, and `done`
- pack v2 generation with full objects, zlib-wrapped stored DEFLATE blocks, Adler-32 checksums, and a trailing pack SHA-1
- commit, tree, and tag graph traversal with packs restricted to the requested reachable closure
- successful stock-client `ls-remote`, fetch, and clone, verified with `git fsck --full`
- authenticated Smart HTTP receive-pack discovery and push
- native zlib/DEFLATE decoding for stored, fixed-Huffman, and dynamic-Huffman streams
- verified full-object, `REF_DELTA`, and `OFS_DELTA` pack ingestion, including chained deltas
- staged pack validation and atomic create, update, force-update, and delete ref transactions
- canonical object hashing for arbitrary binary payloads and undecorated decimal sizes
- unconditional `/git` Eyre rebinding on agent load
- Git LFS Batch and Basic Transfer APIs for SHA-256 objects
- direct signed PUT and GET actions against the endpoint, bucket, and region configured in `%storage`
- post-upload HEAD verification before LFS metadata becomes authoritative
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
- branch-aware file browsing, text and image blob views, authenticated text editing, and per-file history
- mounted-desk discovery and first-class desk-to-repository publication
- Ames-coordinated, Fine-backed repository snapshots with incremental have negotiation, transfer expiry and cancellation, status pruning, object-count checks, and per-object OID verification
- public native forks, explicit refresh, and origin metadata
- ship writer ACLs with fast-forward-only push-back from native forks
- native pull requests whose object graphs are stored at the origin without advancing a branch
- pull-request merges and authorized native updates gated by Clay when the destination branch is desk-bound
- reload-safe, cache-invalidating static fileserver at `/apps/git` and a separately rebound API at `/apps/git/api`
- direct GitHub Smart HTTP import and update with authentic refs, canonical OIDs, delta-pack decoding, reachable-graph validation, and 64 MiB/25,000-object bounds
- optional server-side GitHub token for private repositories and authenticated REST operations
- bounded GitHub issue and pull-request synchronization plus GitHub fork and pull-request creation
- repository navigation and filtering: repository search, code, issues, pull requests, branches, commits, file editing/history, and settings
- conformance vectors for Git object hashing, pkt-line round trips, pack generation, stock Git pack decoding, delta resolution, Clay snapshots, and object-store request signing

## Next

1. Add LFS locking and garbage collection for unreferenced, verified objects.
2. Subtract the client's known reachable closure during upload-pack negotiation and add ACK negotiation.
3. Add protected-branch and fast-forward policy controls on top of compare-and-swap ref updates.
4. Add peeled tag advertisements, shallow fetches, filters, and protocol v2.
5. Add two-ship conformance coverage for Fine-backed repository reads.
6. Add native fork discovery and activity notifications.
7. Add tags, commit detail, textual diffs, review comments, and non-fast-forward pull-request merging.
8. Add richer commit metadata, explicit Clay resync/conflict controls, and paginated GitHub metadata.

## Storage direction

Gall is authoritative for repository metadata, refs, permissions, Git object identity, and verified LFS metadata. Ordinary Git objects remain in state. LFS payloads are transferred directly to the ship-configured object store and never enter Gall state; the object store validates the signed SHA-256 payload hash, and Gall records an object only after a successful size-checked HEAD request.
