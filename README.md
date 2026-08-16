# %git

<img width="1053" height="668" alt="image" src="https://github.com/user-attachments/assets/5e7494f4-e5ed-41b9-ba5d-243f9b8fa1e2" />

`%git` makes an Urbit ship a native Git remote. Standard Git clients use Smart HTTP through Eyre while Gall owns the object database, refs, and repository policy. No Git executable or server-side sidecar is involved.

## Features

- clone, fetch, push, force-update, and delete refs with ordinary Git clients
- canonical SHA-1 object storage for blobs, trees, commits, and tags
- native pkt-line parsing and pack v2 encoding/decoding in Hoon
- native zlib/DEFLATE plus `REF_DELTA` and `OFS_DELTA` pack ingestion
- reachability-limited packs that do not expose unreferenced objects
- atomic ref transactions protected by per-repository write credentials
- optional branch-to-desk bindings that apply pushed commits directly to Clay
- Clay-gated pushes: invalid desks are rejected by Git with the complete Ford stack trace
- Clay-to-Git publishing that snapshots a bound desk as canonical blobs, trees, and commits
- authenticated web interface for repositories, files, commits, access, tokens, and Clay publication
- branch browsing, file contents and editing, per-file history, native pull requests, and repository settings
- one-click publication of any mounted Clay desk as a Git repository
- verified, incremental repository forks and updates over Ames in bounded object chunks
- ship write ACLs with fast-forward-only native push-back from authorized forks
- Clay-gated native updates and pull-request merges, with validation failures returned to the sender
- direct GitHub import and update through Git Smart HTTP, preserving branches, tags, commits, trees, blobs, and object IDs
- optional GitHub token support for private imports, GitHub forks, and opening pull requests
- cached GitHub issues and pull-request status, synchronized through the GitHub REST API
- JSON scries and HTTP APIs for repository summaries, refs, first-parent history, and file trees
- Git LFS batch uploads and downloads backed by the ship's configured object storage
- direct, short-lived Signature V4 transfer actions so large LFS payloads bypass the loom
- stable Smart HTTP remotes at:

```text
https://ship.example/git/<repository>
```

LFS lifecycle policy and richer wire negotiation are tracked in [`specs/roadmap.md`](specs/roadmap.md). Protocol boundaries are documented in [`specs/architecture.md`](specs/architecture.md).

## Development

Build directly into a mounted desk:

```sh
zig build -Ddesk=/path/to/pier/git
```

Then commit the `%git` desk and run the protocol vectors:

```hoon
+git!git-codec-vector
+git!git-pack-vector
+git!git-pack-decode-vector
+git!git-stock-pack-vector
+git!git-delta-pack-vector
+git!git-ofs-delta-pack-vector
+git!git-storage-vector
+git!git-clay-vector
```

The codec vector's blob OID must be `3b18e512dba79e4c8300dd08aeb37f8e728b8dad`, matching `git hash-object` for `hello world\n`. The pack vectors cover local round trips and stock Git packs containing binary tree data, `REF_DELTA`, and `OFS_DELTA` entries. The storage vector checks that object-store transfers contain authorization, date, and payload-hash headers.

Each repository can be assigned a write token with the `%set-write-token` action. Git and Git LFS clients use any Basic-auth username and that token as the password. Public repositories permit unauthenticated fetches and LFS downloads; uploads require the write token or an authenticated ship session.

A repository branch can be linked to a Clay desk with `%bind-desk`. A push to that branch is accepted only after Clay applies and validates the projected desk. Ford failures are returned as ordinary Git `ng` report-status messages, so command-line clients, CI, and coding agents receive the compiler trace while the Git ref remains unchanged.

`%publish-desk` snapshots the current bound desk into the linked branch. Clay pages are rendered to their canonical source representation, assembled into ordinary Git blobs and recursively sorted trees, and committed with the ship as author and committer. The existing branch tip becomes the parent.

The web read model is available through `%git` scries at `/repositories/json`, `/repository/<name>/json`, `/repository/<name>/commits/json`, and `/repository/<name>/files/json`.

The authenticated web app is served at `/apps/git`. Its API creates and deletes repositories, publishes mounted desks, changes public-read policy and hashed write tokens, manages ship writers, binds and unbinds Clay desks, browses branches and file history, edits text files, forks public repositories over Ames, opens or merges native pull requests, and imports or updates GitHub repositories. GitHub imports are limited to a 64 MiB pack response and 25,000 objects to protect the loom; large file payloads belong in LFS. The static frontend is built from `fe/` into `desk/web/` by the normal Zig build.
