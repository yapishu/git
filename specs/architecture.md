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

peer %git
  |
  | Ames coordination + Fine repository reads
  v
%git collaboration protocol
  |- public fork and incremental refresh
  |- ship-authorized fast-forward push
  `- pull-request object transfer

GitHub
  |
  | Git Smart HTTP + REST over Iris
  v
%git GitHub integration
  |- canonical pack ingestion and ref validation
  |- issue and pull-request metadata cache
  `- authenticated fork and pull-request actions
```

Git HTTP is stateless. Discovery and service requests carry everything needed for each exchange, which maps cleanly to Eyre request pokes and Gall responses.

Eyre opens a Gall subscription at `/http-response/<request-id>` before delivering each HTTP poke. `%git` accepts that watch explicitly, sends the response header and binary data as facts, and closes the subscription. The `/git` and `/apps/git/api` bindings are re-established on every load.

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

The inverse path is an explicit `%publish-desk` action. `%git` verifies that the binding still names a live desk, enumerates its files, and reads each stored Clay page through typeless `%q` requests. Source marks are rendered to their canonical mounted bytes; `%hoon` and `%kelvin` have bootstrap renderers so a minimal desk does not need to compile its own complete mark graph before it can be published. Other marks use their normal mark-to-`%mime` conversion.

The resulting path-to-byte map is assembled into canonical blobs and recursively sorted Git trees. A new commit names the ship as author and committer, uses the supplied message, and parents the current linked branch tip. The new objects and ref are installed together only after every Clay page has been read and rendered. A concurrent push to the linked branch is rejected while publication is in progress.

Repository metadata is projected into JSON scries for the web frontend. Separate paths expose the repository list, one repository with its refs and binding, a bounded first-parent history, and the current head tree's file names and sizes. Write credentials and object bytes are not included in this read model.

## Native collaboration

Public repositories can be forked directly from another ship. The receiver sends the OIDs it already has over an Ames coordination poke. The source records a transfer-scoped immutable snapshot containing only the missing objects and announces its symbolic head, refs, and object count. The receiver reads that snapshot through Fine; Vere handles network fragmentation and reassembly instead of Gall sending an application-level chunk sequence. Gall recomputes every Git OID, checks the announced count and complete ref graph, installs the repository atomically, and sends a release poke so the source can discard the transient snapshot. Receiver reads expire after 30 seconds and unreleased source snapshots expire after two minutes. Timer error notifications are consumed without retry. The authenticated API can cancel active transfers and prune consumed results. A self-fork takes the same validation path but bypasses the network read.

A fork records its source ship and repository. Refresh repeats the same incremental exchange. The origin can grant a ship write access in its repository ACL; an authorized fork may then offer its branch back to the origin. The origin requests missing objects from the fork and accepts only a fast-forward of its default branch. A desk-bound destination runs the proposed tree through the same delayed Clay transaction as Smart HTTP and reports the real success or Ford failure back over Ames.

Forks without write access can open native pull requests. The origin verifies and stores the proposed object graph but does not move a branch. A merge rechecks that the current destination is an ancestor of the proposed head, then advances atomically. Desk-bound merges are committed only after Clay accepts the projected desk.

## Web interface

`%git-fileserver` serves the built React application from `/web` at `/apps/git`. It watches Clay for frontend changes, clears Eyre's static-response cache when the tree changes, and unconditionally replaces its binding on load. Extensionless routes fall back to the application shell.

The main `%git` agent owns `/apps/git/api`. Every API request requires an authenticated Urbit web session; Git Basic credentials are deliberately limited to Git and LFS operations. Read routes return the same projections as the public Gall scries. Mutation routes create and delete repositories, change public access, rotate the hashed write token, manage ship writers and desk bindings, publish desks, edit files, browse branches and history, start native forks or updates, and manage pull requests. Mutations reuse the same state transitions as native `%git-action` pokes.

## GitHub integration

GitHub repositories enter through the same Git protocol boundary as any other remote. `%git` requests the upload-pack advertisement through Iris, retains valid refs and the advertised symbolic `HEAD`, asks for the advertised object graph, and decodes the returned pack with the native pack implementation. Every object ID and complete reachable ref graph is verified before the repository is installed. An update is accepted only for a repository linked to the same GitHub origin and not currently bound to Clay. Pack responses are capped at 64 MiB and 25,000 objects.

The optional personal access token remains server-side in Gall state and is never included in the web read model. Git Smart HTTP uses it for private repository access; GitHub REST uses it for private metadata and write operations. Issue and pull-request lists are cached as bounded metadata, excluding issue bodies and comments. Fork creation and pull-request creation are direct REST actions. These operations run asynchronously through Iris and expose transient status to the authenticated web UI.

## Git LFS

The repository URL derives the standard `/<repository>.git/info/lfs` endpoint; `%git` accepts both suffixed and unsuffixed forms. Batch requests use the `basic` transfer adapter and SHA-256 identifiers.

Gall signs direct object-store PUT and GET actions using the endpoint, bucket, region, and credentials published by the ship's `%storage` agent. No provider URL is compiled into the desk. The signed upload binds the expected LFS OID as its payload hash. A successful transfer is still pending until the LFS client invokes its verify action; `%git` then issues a signed HEAD request, checks the stored size, and promotes only the metadata into the repository. Large bytes therefore do not become nouns or persist in the loom.
