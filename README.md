# %git

`%git` makes an Urbit ship a native Git remote. Standard Git clients use Smart HTTP through Eyre while Gall owns the object database, refs, and repository policy. No Git executable or server-side sidecar is involved.

## Features

- clone, fetch, push, force-update, and delete refs with ordinary Git clients
- canonical SHA-1 object storage for blobs, trees, commits, and tags
- native pkt-line parsing and pack v2 encoding/decoding in Hoon
- native zlib/DEFLATE plus `REF_DELTA` and `OFS_DELTA` pack ingestion
- reachability-limited packs that do not expose unreferenced objects
- atomic ref transactions protected by per-repository write credentials
- Git LFS batch uploads and downloads backed by the ship's configured object storage
- direct, short-lived Signature V4 transfer actions so large LFS payloads bypass the loom
- stable Smart HTTP remotes at:

```text
https://ship.example/git/<repository>
```

Ames replication, LFS lifecycle policy, richer negotiation, and Clay projection are tracked in [`specs/roadmap.md`](specs/roadmap.md). Protocol boundaries are documented in [`specs/architecture.md`](specs/architecture.md).

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
```

The codec vector's blob OID must be `3b18e512dba79e4c8300dd08aeb37f8e728b8dad`, matching `git hash-object` for `hello world\n`. The pack vectors cover local round trips and stock Git packs containing binary tree data, `REF_DELTA`, and `OFS_DELTA` entries. The storage vector checks that object-store transfers contain authorization, date, and payload-hash headers.

Each repository can be assigned a write token with the `%set-write-token` action. Git and Git LFS clients use any Basic-auth username and that token as the password. Public repositories permit unauthenticated fetches and LFS downloads; uploads require the write token or an authenticated ship session.
