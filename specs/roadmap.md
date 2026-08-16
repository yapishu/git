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
- conformance vectors for Git object hashing, pkt-line round trips, pack generation, stock Git pack decoding, delta resolution, and object-store request signing

## Next

1. Add LFS locking and garbage collection for unreferenced, verified objects.
2. Subtract the client's known reachable closure during upload-pack negotiation and add ACK negotiation.
3. Add protected-branch and fast-forward policy controls on top of compare-and-swap ref updates.
4. Add peeled tag advertisements, shallow fetches, filters, and protocol v2.
5. Add Ames discovery, ACL exchange, notifications, and repository replication.
6. Add explicit Clay import/export as a projection layer rather than conflating Clay revisions with Git commits.

## Storage direction

Gall is authoritative for repository metadata, refs, permissions, Git object identity, and verified LFS metadata. Ordinary Git objects remain in state. LFS payloads are transferred directly to the ship-configured object store and never enter Gall state; the object store validates the signed SHA-256 payload hash, and Gall records an object only after a successful size-checked HEAD request.
