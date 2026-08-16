# Architecture

## Boundary

```text
git CLI
  |
  | Smart HTTP
  v
Eyre /git/<repository>
  |
  v
%git
  |- refs and atomic updates
  |- canonical object verification
  |- repository policy
  |- pack and pkt-line codecs
  `- LFS metadata and signed transfer actions

Git LFS client
  |
  | batch + verify (small JSON)
  v
%git
  |
  | signed basic-transfer action
  v
ship-configured object storage
```

Git HTTP is stateless. Discovery and service requests carry everything needed for each exchange, which maps cleanly to Eyre request pokes and Gall responses.

Eyre opens a Gall subscription at `/http-response/<request-id>` before delivering each HTTP poke. `%git` accepts that watch explicitly, sends the response header and binary data as facts, and closes the subscription. The `/git` binding is re-established on every load.

## Object model

An object is stored as its Git type plus its exact content bytes. Its OID is derived from the canonical loose-object byte sequence and is never accepted on trust. Commit, tree, and tag parsing produces views for traversal and UI; the canonical byte representation remains authoritative.

## Protocol strategy

Protocol v0/v1 comes first because it shares one advertisement model across `ls-remote`, fetch, and push. Capability advertisements remain deliberately small. Protocol v2 will reuse the same pkt-line, ref, object, and pack layers after clone and push work end to end.

Fetch packs contain full objects without deltas. Commit headers, raw tree entries, and annotated-tag targets are traversed from the requested wants; unrelated objects are excluded. The current negotiation may resend objects the client already has. ACK negotiation and subtraction of known reachable closures are the next efficiency step.

Pack output is pack version 2. Each object is encoded in a standards-compliant zlib stream using stored DEFLATE blocks, followed by the required pack SHA-1. This deliberately favors a small auditable encoder over compression ratio; compressed DEFLATE blocks can replace it without changing the pack layer.

Incoming pushes are staged: parse commands, verify the pack checksum, decode zlib/DEFLATE streams, resolve full objects and chained `REF_DELTA`/`OFS_DELTA` representations, reconstruct canonical object IDs, validate authorization and compare-and-swap old ref values, validate that every new ref resolves, and update objects plus refs in one Gall transition. A malformed pack or invalid command leaves repository state unchanged.

## Clay projection

A repository may bind one branch to one Clay desk. The Git tree is flattened into desk paths, with the final filename suffix interpreted as its Clay mark (`app/foo.hoon` becomes `/app/foo/hoon`). Symlinks, submodules, unsafe path segments, and path collisions are rejected before Clay is touched.

Linked pushes use a two-phase Gall transaction. `%git` stages the objects and proposed ref in memory, computes a Clay delta against the current desk, and starts the Clay mutation from a later Behn event. The Git ref is not advanced until Clay succeeds. This event boundary lets Behn return a failed Clay/Ford computation as a structured `tang` instead of aborting the original Eyre request.

The result is recorded before a separate one-shot report event answers the Git client. A failure becomes a receive-pack `ng <ref> <reason>` result containing the rendered Ford trace; success commits the staged repository and returns `ok <ref>`. An error notification on either timer wire is consumed rather than replayed, so a failed response to a disconnected HTTP client cannot re-enter Clay or block Behn's global timer queue.

## Git LFS

The repository URL derives the standard `/<repository>.git/info/lfs` endpoint; `%git` accepts both suffixed and unsuffixed forms. Batch requests use the `basic` transfer adapter and SHA-256 identifiers.

Gall signs direct object-store PUT and GET actions using the endpoint, bucket, region, and credentials published by the ship's `%storage` agent. No provider URL is compiled into the desk. The signed upload binds the expected LFS OID as its payload hash. A successful transfer is still pending until the LFS client invokes its verify action; `%git` then issues a signed HEAD request, checks the stored size, and promotes only the metadata into the repository. Large bytes therefore do not become nouns or persist in the loom.
