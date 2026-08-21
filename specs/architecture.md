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
%urgit
  |- refs and atomic updates
  |- canonical object verification
  |- repository policy
  |- pack and pkt-line codecs
  `- LFS metadata and signed transfer actions

Git LFS client
  |
  | batch + verify (small JSON)
  v
%urgit
  |
  | signed basic-transfer action
  v
ship-configured object storage

peer %urgit
  |
  | Ames coordination + Mesa archive delivery
  v
%urgit collaboration protocol
  |- on-demand public repository catalogs
  |- public fork and incremental refresh
  |- ship-authorized fast-forward push
  |- pull-request object transfer
  `- bounded Fine fallback

GitHub
  |
  | Git Smart HTTP + REST over Iris
  v
%urgit GitHub integration
  |- canonical pack ingestion and ref validation
  |- fast-forward pull and receive-pack push
  |- issue and pull-request metadata cache
  `- authenticated fork and pull-request actions

external automation
  |
  | signed HTTPS JSON
  v
%urgit webhooks
  |- outgoing repository events + delivery history
  `- incoming GitHub push notices + explicit pull prompts
```

Git HTTP is stateless. Discovery and service requests carry everything needed for each exchange, which maps cleanly to Eyre request pokes and Gall responses.

Eyre opens a Gall subscription at `/http-response/<request-id>` before delivering each HTTP poke. `%urgit` accepts that watch explicitly, sends the response header and binary data as facts, and closes the subscription. The `/git` and `/apps/urgit/api` bindings are re-established on every load.

## Object model

An object is stored as its Git type plus its exact content bytes. Its OID is derived from the canonical loose-object byte sequence and is never accepted on trust. Commit, tree, and tag parsing produces views for traversal and UI; the canonical byte representation remains authoritative.

## Protocol strategy

Protocol v0/v1 shares one advertisement model across `ls-remote`, fetch, and push. Protocol v2 is selected by the standard `Git-Protocol: version=2` header and advertises command-based `ls-refs` and `fetch`. Its ref responses carry symbolic-head and peeled-tag attributes, while fetch uses section headers, delimiter packets, and mandatory sideband pack framing. Both generations reuse the same pkt-line, ref, object, reachability, and pack layers; receive-pack remains v0/v1 because protocol v2 does not define a push command.

Annotated tags are stored as canonical Git tag objects and advertised with the immediately following peeled `^{}` ref required by protocol v0/v1. Lightweight tags point directly at their target. Both forms use ordinary `refs/tags/*` refs, so tags created in the web interface and tags pushed by Git clients are interchangeable.

A tag on a bound repository may name `r<number>`. `%urgit` reads that historical Clay yaki, renders its files, and materializes only that revision as a canonical Git commit. The commit is added to the repository object database and revision-to-commit map without rewriting the bound branch. This keeps Clay history native and cheap to list while making selected revisions usable by tags, archives, Git clients, and commit diffs.

Fetch packs contain full objects without deltas. Wants must be reachable from advertised refs, which permits a partial-clone client to retrieve a promised object while preventing arbitrary unreachable-object reads. Commit headers, raw tree entries, and annotated-tag targets are traversed from those wants; unrelated objects are excluded. During incremental fetch, only `have` objects reachable from advertised refs are accepted as common, the server ACKs a common object, and their complete reachable closure is subtracted before the pack is encoded. Requests ending in a flush receive negotiation status only; a pack begins after `done`.

Depth requests cut only commit ancestry: every selected commit still receives its complete tree and blobs. The response reports shallow boundaries, relative deepening extends from the client's existing boundaries, and the Git unshallow sentinel restores the full advertised history. Partial-clone filters omit traversed blobs for `blob:none` or blobs at and above a `blob:limit` threshold. An object named directly by a promisor fetch is always returned even when the client repeats its filter. Trees and commits remain complete, so stock Git can discover and lazily request the omitted blob OIDs.

Pack output is pack version 2. Each object is encoded in a standards-compliant zlib stream using stored DEFLATE blocks, followed by the required pack SHA-1. This deliberately favors a small auditable encoder over compression ratio; compressed DEFLATE blocks can replace it without changing the pack layer.

Incoming pushes are staged: parse commands, verify the pack checksum, decode zlib/DEFLATE streams, resolve full objects and chained `REF_DELTA`/`OFS_DELTA` representations, reconstruct canonical object IDs, validate authorization and compare-and-swap old ref values, validate that every new ref resolves, and update objects plus refs in one Gall transition. A malformed pack or invalid command leaves repository state unchanged.

Each branch can be protected independently. Creation of a protected branch is allowed, while later updates must contain the current tip in the new reachable graph; deletion is rejected. Policy runs against the staged and existing object maps before the atomic ref transaction, and failures are returned as ordinary receive-pack report-status messages. Unprotected branches retain Git's normal force-update and deletion behavior.

## Clay projection

A repository may bind one branch to one Clay desk. The Git tree is flattened into desk paths, with the final filename suffix interpreted as its Clay mark (`app/foo.hoon` becomes `/app/foo/hoon`). Symlinks, submodules, unsafe path segments, and path collisions are rejected before Clay is touched.

Linked pushes use a two-phase Gall transaction. `%urgit` stages the objects and proposed ref in memory, computes a Clay delta against the current desk, and starts the Clay mutation from a later Behn event. The Git ref is not advanced until Clay succeeds. This event boundary lets Behn return a failed Clay/Ford computation as a structured `tang` instead of aborting the original Eyre request.

The result is recorded before a separate one-shot report event answers the Git client. A failure becomes a receive-pack `ng <ref> <reason>` result containing the rendered Ford trace; success commits the staged repository and returns `ok <ref>`. An error notification on either timer wire is consumed rather than replayed, so a failed response to a disconnected HTTP client cannot re-enter Clay or block Behn's global timer queue.

The inverse path is an explicit `%publish-desk` action. `%urgit` verifies that the binding still names a live desk, enumerates its files, and reads each stored Clay page through typeless `%q` requests. Source marks are rendered to their canonical mounted bytes; `%hoon` and `%kelvin` have bootstrap renderers so a minimal desk does not need to compile its own complete mark graph before it can be published. Other marks use their normal mark-to-`%mime` conversion.

The resulting path-to-byte map is assembled into canonical blobs and recursively sorted Git trees. A new commit names the ship as author and committer, uses the supplied message, and parents the current linked branch tip. The new objects and ref are installed together only after every Clay page has been read and rendered. A concurrent push to the linked branch is rejected while publication is in progress.

Every successful crossing records an explicit link between the Clay revision and Git commit. Git-to-Clay links are written only after Clay accepts the projected desk; Clay-to-Git links are written with the published commit. The bound branch's canonical web history comes directly from Clay's revision map and `%w` timestamp resolution, so it remains complete even when a revision has no projected Git commit. Each entry exposes its native revision number, timestamp, tako, and any crossing recorded for it. Other branches retain ordinary Git first-parent history.

The bridge-status API reads the live Clay revision metadata, resolves the linked Git branch, and compares their complete path-to-byte projections. It reports exact content equality separately from the stored crossing map, which distinguishes in-sync, Git-ahead, Clay-ahead, diverged, and not-yet-mapped bindings. A crossing whose exact revision and commit still match is synchronized even when a Clay mark canonicalizes its mounted representation, such as `%txt` dropping a trailing newline. An explicit branch-to-desk resync enters the existing delayed Clay transaction and does not report success until Clay acknowledges the mutation; a Ford failure returns its rendered trace and leaves the branch and crossing map unchanged.

Revision detail compares the native path-to-lobe maps of adjacent Clay yakis. Changed blobs are read directly by lobe, preserving historical content without rebuilding an old desk's mark graph. The response lists up to 1,000 changed paths and bounds rendered bodies independently, so large desk imports remain inspectable without constructing an unbounded HTTP noun. File history follows the same native sequence, and a file selected at `r<number>` is read from that exact Clay revision.

Line blame uses the same first-parent boundary for ordinary Git branches and the canonical Clay revision sequence for bound branches. Each line is keyed by its bytes and duplicate ordinal within the file, then carried backward while that occurrence remains present in the parent snapshot. This tracks inserted blocks, moved lines, and repeated text without allocating an edit-distance matrix in the loom. Blame is limited to text files of 256 KiB and 10,000 lines, walks at most 200 snapshots, and returns only commit or revision metadata referenced by the final attribution. The public repository API exposes the same bounded read.

Repository metadata is projected into JSON scries for the web frontend. Separate paths expose the repository list, one repository with its refs and binding, canonical Clay revisions or bounded Git first-parent history as appropriate, and the current head tree's file names and sizes. Write credentials and object bytes are not included in this read model.

Persisted state is `%1`. Loading `%0` preserves every repository and global setting while adding the default repository notification event set.

## Native collaboration

The authenticated frontend discovers a peer explicitly rather than maintaining a background network index. An Ames catalog request returns at most 200 public repositories with their symbolic head, ref and object counts, and whether the requesting ship is in that repository's writer ACL. Discovery results are transient, expire after thirty seconds, and can be cancelled or pruned through the authenticated API. Private repositories are never advertised.

Peer identities themselves are persisted as bookmarks and expanded on demand in the sidebar. Repository browsing requests a bounded JSON overview through the same Ames coordination channel as catalog discovery. A capable source immediately acknowledges the request, prepares the overview on a deferred event, and delivers the completed JSON in one Gall packet when the ships have a directed Mesa route. Request-scoped Fine pages remain the compatibility path and are released through the same identity-checked operation. The 45-second unanswered-request timeout applies only before acknowledgement; acknowledged overview preparation has a separate ten-minute ceiling, while Fine reads stop only after two minutes without page progress. The source responds only when the requesting ship may read the repository.

The overview contains repository metadata, branch refs, the current file tree, up to 50 first-parent commits, per-file latest-commit attribution within that same bounded history, native issue and pull-request summaries, and cached GitHub issue and pull-request summaries; it contains no Git object bodies, issue bodies, discussion bodies, or credentials. Repository and history counts use bounded or structural operations; a history longer than the overview window is reported as `50+` rather than traversed in full. File listing flattens only path, mode, and object ID metadata, consulting each blob solely for its byte count. Per-file attribution compares Git tree OIDs structurally, skipping unchanged subtrees instead of flattening both complete trees for every commit, and serializes each distinct latest-commit summary once even when many files share it. The browser keeps complete remote overviews in IndexedDB without automatic expiry. Reopening a cached repository renders it immediately and requests only a compact repository revision stamp; a changed stamp marks the view as having an update, while a failed check leaves the cached view available and reports that updates could not be checked. Refresh is always explicit and replaces the cached overview only after a complete successful read. Opening a native issue, pull request, commit, or file uses the same acknowledged browse transport for the full issue thread, bounded pull-request or commit diff, review discussion, or exact head-branch file bytes. Peer file previews are limited to 4 MiB. The requester verifies that the responding ship, requested repository, and embedded repository identity all match its pending request before exposing the result. Concurrent identical requests are coalesced by the receiving agent. The frontend renders the peer-reported stage while active and replaces the loader with the terminal error and an explicit retry action.

Public repositories can be forked directly from another ship. The receiver sends the OIDs it already has in an authenticated Ames request whose transfer ID advertises the current object-transfer capability. The source validates and acknowledges the request before preparing data; an unanswered request ends explicitly, while an accepted request receives a separate preparation window. Concurrent identical requests coalesce, and a newer request for the same peer and repository supersedes any unreleased source snapshot.

When the capability is present and Ames reports the destination as a Mesa chum, repository size does not select a slower transport. The source first sends a small `%archive-ready` header containing the symbolic head, refs, missing-object count, and payload byte count. The receiver authenticates the source and repository, validates explicit Mesa archive limits, records those expectations, and replies with `%archive-accept`. Only then does the source send one `%archive` Gall packet containing all missing immutable Git objects. This separates preparation from bulk delivery, prevents a large noun from being mistaken for an unresponsive preparation step, and ensures duplicate accepts cannot emit the archive twice. Gall supplies one noun; Mesa performs transport fragmentation, congestion control, retransmission, and reassembly beneath the application.

The receiver requires the delivered object and byte counts to match the accepted header, rejects duplicate OIDs and oversized individual objects, recomputes every Git object ID, validates the complete referenced graph, and installs the result atomically. Mesa archives are limited to 250,000 objects, 1 GiB of object payload, and 512 MiB per object; exceeding an absolute limit is an explicit rejection, never a silent downgrade to Hoon pack construction. Accepted Mesa transfers and their source flights have a one-day cleanup horizon, while the original preparation timer becomes inert as soon as the archive header is accepted. A successful or failed receiver releases the transient source flight.

Fine remains a bounded compatibility path, not the primary bulk transport. It is considered only when a directed Mesa route is unavailable. A capable peer then publishes raw object fragments in one-MiB pages and reads a bounded window concurrently; a peer without the capability receives sequential checksummed Git-pack pages. Both modes validate page identity, bounds, object counts, OIDs, and the final ref graph; cancellation yawns only the exact outstanding Fine scries. Progress-sensitive timers terminate stalled reads without penalizing a transfer that is still advancing. Source flights expire if the receiver never releases them. The authenticated API exposes request, preparation, Mesa, Fine, and terminal states, coalesces duplicate actions, and retains results long enough for the initiating browser to observe them. `:urgit +dbug [%state 'transfers']` exposes the same transient records without persisting them. A self-fork takes the same validation path but bypasses network delivery.

A fork records its source ship and repository. “Pull from origin” repeats the same incremental exchange, coalesces with an identical active transfer, and fast-forwards only when the refreshed origin contains the fork's current tip. The origin can grant a ship write access in its repository ACL; an authorized fork may then offer its branch back to the origin. The origin requests missing objects from the fork and accepts only a fast-forward of its default branch. A desk-bound destination runs the proposed tree through the same delayed Clay transaction as Smart HTTP and reports the real success or Ford failure back over Ames.

Forks without write access can open native pull requests from the repository's Pull requests tab. The composer identifies the source fork and native origin, reports the native transfer state, and links back to the origin after creation. A repository can also open a review from any non-default local branch without a network transfer. The origin verifies and stores the proposed object graph but does not move a branch. Pull-request detail compares the stored base and proposed head trees and returns bounded file contents for a red/green textual diff. Review comments are persisted with the pull request, may address the whole review or a specific base/head line, and can be resolved or reopened. A remote ship can append a general review comment through an Ames request; the origin derives the author from the authenticated sending ship, persists the comment, and returns the updated discussion. A merge rechecks that the current destination is an ancestor of the proposed head, then advances atomically. Desk-bound merges are committed only after Clay accepts the projected desk.

Native issues live in repository state independently of Git objects and Clay revisions. Each issue records its author as an Urbit ship, title, bounded body, open or closed state, a deduplicated set of labels, a deduplicated set of ship assignees, creation and update times, and append-only ship-authored comments. Repository summaries include issue metadata and counts but omit bodies and comments; opening an issue reads its complete detail over request-scoped Fine. Remote issue creation and comments are origin-authoritative Ames mutations: the browser supplies the target and bounded issue or comment text, while Gall takes the author from the sending ship and returns the created issue or updated thread. Active identical requests coalesce, and transient status makes success or failure observable. Labels are limited to 20 values of 64 bytes, assignees to 20 ships, issue bodies to 64 KiB, and comments to 16 KiB. Discussion text recognizes `~ship/repository#number` references and links to the peer repository without requiring a global issue index.

Peer operations also write a bounded, transient activity ledger. Incoming snapshot reads and outgoing forks, pushes, and pull requests move from active to success or failure without changing persisted state. The authenticated activity API and top-bar panel expose the peer, repository, direction, time, and terminal message; clearing the ledger has no effect on repositories or transfers.

Incoming native issue, pull-request, and comment mutations can emit notifications according to each repository's event set. The repository stores only those preferences. Urgit sends current `%add-yarn` actions directly to the `%hark` agent with both the global and desk inbox flags enabled. Hark owns delivery and history, grouping yarns under stable `%urgit` issue and pull-request paths. Urgit also keeps a bounded transient mirror of the yarns it emits for its top-bar activity panel; it does not read or duplicate unrelated Hark notifications. Clearing the Urgit panel does not alter Hark history. An empty event set mutes the repository.

## Web interface

`%urgit-fileserver` serves the built React application from `/web` at `/apps/urgit`. It watches Clay for frontend changes, clears Eyre's static-response cache when the tree changes, and unconditionally replaces its binding on load. Extensionless routes fall back to the application shell.

The frontend renders README Markdown into React elements without injecting HTML. Local, public, and peer repository roots use the same renderer; peer READMEs use the bounded Fine file path. Unsaved editor and discussion values are kept in browser local storage under repository- and target-scoped keys. Successful mutations remove their drafts, while navigation and reloads preserve them. Credentials and settings secrets are never draft-persisted.

The main `%urgit` agent owns `/apps/urgit/api`. Administrative and mutation requests require an authenticated Urbit web session; Git Basic credentials are deliberately limited to Git and LFS operations. Read routes expose repository counts, branch trees, Git commits or native Clay revisions, per-file history, branch-aware code search, revision and commit diffs, Clay links and bridge status, peer bookmarks, remote overviews, native issue detail, and pull-request diffs. Mutation routes create and delete repositories, change public access, rotate the hashed write token, manage ship writers and desk bindings, synchronize either side of a Clay binding, edit files, start native forks or updates, manage native issues, and manage pull requests. Mutations reuse the same state transitions as native `%git-action` pokes or the Clay-gated HTTP transaction.

Pull requests record the destination tip that was current when they opened. Integration fast-forwards when possible, recognizes a head already contained by the destination, and otherwise performs a three-way merge against that recorded common base. The merge compares path presence, canonical blob identity, and Git file mode across both sides. Non-overlapping additions, edits, deletions, executable changes, and symlink changes produce a canonical two-parent commit; overlapping changes or structural path collisions return HTTP 409 without advancing the target. A desk-bound target submits the resulting merge tree to Clay before either the ref or pull-request state becomes authoritative.

Code search scans the selected commit's flattened tree without creating a persistent index. It skips binary files and individual blobs larger than 2 MiB, scans at most 2,000 files, returns at most 100 line-level matches, and includes bounded previews. Public repositories expose the same bounded read through their sanitized API. Results deep-link to the exact file and line in the source viewer.

Branch comparison resolves two refs through the same repository object database and compares their flattened trees. The API returns at most 1,000 changed paths and includes text bodies only when each side is at most 256 KiB. The browser renders the existing review diff and can construct a standards-compatible unified patch for `git apply`; patch download is withheld when any body is binary, oversized, or omitted by the path bound. Authenticated and public repository views use the same read-only comparison model.

Web file mutations rewrite only the affected Git tree path on the selected branch. Creating a file constructs missing subtrees, deleting the last file under a directory removes the empty subtree, and editing retains the existing blob mode. Every rewritten tree is sorted by Git's directory-aware byte order before hashing. Each mutation produces an ordinary parented commit; when the selected branch is desk-bound, creation, editing, and deletion all wait for the same Clay validation transaction before the ref advances. Branches can be created from any resolvable revision and selected as the default. The default, protected, and Clay-bound branches cannot be deleted through the web API.

Public repositories additionally expose a narrow unauthenticated API under `/apps/urgit/api/public/repository/<name>`. It returns a sanitized repository view, branches, files, first-parent history, per-file history and blame, branch comparisons, commit diffs, and native issue discussion while omitting write-token state, writer ACLs, Clay bindings, and native origin metadata. `/apps/urgit/api/public/profile` returns the ship identity, its public repository summaries, and the alias, bio, status, color, avatar, and cover from the ship's own Landscape contact profile. The unauthenticated `/urgit` page publishes those self-profile fields as a profile header and public repository index; unavailable profile images fall back to a client-rendered Urbit sigil. `%urgit-fileserver` permits that route, public repository routes, and immutable frontend assets without a login. Private and nonexistent repositories both return 404.

Releases are metadata records rooted at existing `refs/tags/*` refs. A release locks its backing tag against update or deletion until the release is removed. Each records a title, bounded notes, ship author, and creation time. Authenticated and public repository pages can download the referenced commit as a deterministic ustar archive that preserves regular, executable, and symbolic-link tree modes. Archive construction is bounded to 10,000 files and 64 MiB, rejects incomplete trees, and never includes unreachable objects.

## Automation webhooks

Outgoing webhooks subscribe per repository to `push`, `tag`, `pull-request`, `issue`, `release`, and `clay-sync`. `%urgit` sends JSON through Iris with `X-Git-Event`, a unique `X-Git-Delivery`, and `X-Hub-Signature-256: sha256=<hmac>` computed over the exact request bytes using the configured secret. Delivery attempts enter the repository ledger as pending and become success or failure when Iris returns; the most recent 100 are retained, and attempts interrupted by an agent restart settle as failures on load. Every push producer emits the same ordered `updates` envelope with ref, before, after, and deletion fields. Smart HTTP emits push events only after its ref transaction succeeds. A desk-bound update emits push and Clay-sync events only after Clay accepts the projected desk, so rejected Ford builds cannot start external CI.

Each repository can also expose `/apps/urgit/api/hooks/<repository>` as a signed incoming endpoint. Repository names retain a terminal dot suffix exactly as written, rather than treating it as an HTTP file extension. The endpoint accepts GitHub `ping`, `push`, and `pull_request` events, limits bodies to 1 MiB, and validates the same SHA-256 HMAC header before acting. A push stores a bounded upstream notice containing the source repository, ref, before OID, and after OID. Notices are coalesced by ref, so repeated pushes to one branch update a single pending prompt. The web interface prompts the user to pull or dismiss it; receipt alone never changes refs or imports objects. Pull remains explicit so protected branches, fast-forward policy, and Clay validation stay authoritative. A pull-request event returns an immediate accepted response and starts a page-one metadata refresh for the linked GitHub repository, allowing PRs from external GitHub forks to appear without importing those forks into `%urgit`.

## GitHub integration

GitHub repositories enter through the same Git protocol boundary as any other remote. `%urgit` requests the upload-pack advertisement through Iris, retains valid refs and the advertised symbolic `HEAD`, asks for the advertised object graph, and decodes the returned pack with the native pack implementation. Every object ID and complete reachable ref graph is verified before the repository is installed. Pull preserves local-only refs and advances matching refs only when the old local tip is reachable from the advertised GitHub tip; divergence is reported instead of overwriting local work. An update is accepted only for a repository linked to the same GitHub origin and not currently bound to Clay.

Push uses authenticated Smart HTTP receive-pack rather than reconstructing commits through GitHub's REST API. `%urgit` discovers the selected remote branch, requires its advertised tip to be in the local branch's reachable closure, emits a standard compare-and-swap command plus a complete canonical pack, and accepts the update only when GitHub returns both `unpack ok` and `ok <ref>` report-status records. A remote-only commit therefore produces an explicit pull-before-push failure, and GitHub independently enforces its repository and protected-branch policy. Pull and push are capped at 64 MiB and 25,000 objects.

The optional personal access token remains server-side in Gall state and is never included in the web read model. Git Smart HTTP uses it for private repository access; GitHub REST uses it for private metadata and write operations. Issue and pull-request lists are cached as bounded metadata, excluding issue bodies and comments. Page 1 refreshes a cache; a load-more action appears only when GitHub returned a complete 100-item page, and pages 2 through 5 append while deduplicating by GitHub number, for a hard maximum of 500 entries per kind. Opening an empty GitHub-linked pull-request view refreshes page 1 once, and the view retains an explicit refresh action. Opening a cached item starts request-scoped Iris reads for its full body and, for pull requests, branch names, change totals, and a unified diff capped at 4 MiB; these responses are returned directly to Eyre and never enter Gall state. JSON `null` in optional GitHub fields is treated as an absent value. Linked repositories expose the same transient path for an upstream file view: GitHub's Contents API response is limited to 1 MiB, its Base64 payload is decoded and size-checked, then canonicalized for the browser without entering repository or agent state. Fork creation and pull-request creation are direct REST actions. Asynchronous mutations and list synchronization expose transient status to the authenticated web UI.

## Git LFS

The repository URL derives the standard `/<repository>.git/info/lfs` endpoint; `%urgit` accepts both suffixed and unsuffixed forms. Batch requests use the `basic` transfer adapter and SHA-256 identifiers.

The same endpoint implements the Git LFS locking API. Locks are exclusive per repository path, identify the authenticated Basic username or ship session, and support create, filtered listing, owner-partitioned push verification, normal owner unlock, and authorized force unlock. Listings and verification use numeric cursors with a server-enforced page bound.

Gall signs direct object-store PUT and GET actions using the endpoint, bucket, region, and credentials published by the ship's `%storage` agent. No provider URL is compiled into the desk. The signed upload binds the expected LFS OID as its payload hash. A successful transfer is still pending until the LFS client invokes its verify action; `%urgit` then issues a signed HEAD request, checks the stored size, and promotes only the metadata into the repository. Large bytes therefore do not become nouns or persist in the loom.

Cleanup is explicit. `%urgit` computes the complete object closure reachable from every repository ref, inspects reachable blobs for canonical LFS pointers, and compares their SHA-256 identifiers with verified LFS metadata. The settings API previews the count and byte total before deletion. Each run schedules at most 100 signed object-store deletes, and Gall removes authoritative metadata only after the store returns success or confirms the object is already absent. An incomplete Git graph blocks cleanup rather than risking deletion.
