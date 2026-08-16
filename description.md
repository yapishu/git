I think the project is substantially cooler than “GitHub on Urbit,” though.

%git as a native Git object database

I'd make the first goal brutally narrow:

git clone https://foo.com/git/myrepo
git fetch
git push

against a repo whose authoritative Git database lives inside Gall.

Conceptually:

+$  oid  @ux  :: initially SHA-1; later SHA-256 maybe


+$  object
  $%  [%blob data=@]
      [%tree entries=(list tree-entry)]
      [%commit commit-data]
      [%tag tag-data]
  ==


+$  repository
  $:  refs=(map @t oid)
      objects=(map oid object)
      ...
  ==

Although I probably wouldn't actually normalize every Git object into a typed noun initially. Git's object serialization is itself canonical and hashed, so storing canonical object bytes keyed by OID gives you fewer ways to accidentally create a repository that disagrees with Git:

objects
  sha1 -> [type bytes]

Then decode commit/tree/tag into nouns when needed.

The HTTP surface is pleasingly tiny

For fetch:

GET /git/foo/info/refs?service=git-upload-pack


POST /git/foo/git-upload-pack
Content-Type: application/x-git-upload-pack-request

For push:

GET /git/foo/info/refs?service=git-receive-pack


POST /git/foo/git-receive-pack
Content-Type: application/x-git-receive-pack-request

That's basically it externally. Smart HTTP requires ref discovery before the upload/receive service request.

So Eyre is not merely adequate; Git Smart HTTP was almost designed for your constraint.

The interesting part is what happens behind those four endpoints.

1. pkt-line

First primitive to implement.

Git's wire protocol is built around length-prefixed packets:

0032want 0a53e9...
0032have 441b40...
0000

with special flush/delim/response-end packets. The pack protocol documentation makes pkt-line the framing primitive throughout.

This feels like a tiny Hoon library:

++  en-pkt
++  de-pkt
++  de-pkts

You could probably get git ls-remote talking to the ship extraordinarily early.

2. Ref advertisement

Start with:

HEAD -> refs/heads/main
refs/heads/main -> abc123...
refs/tags/v1.0 -> ...

For v2, initial discovery is even cleaner: you advertise protocol version and capabilities, and ls-refs becomes an explicit command.

I'd actually be tempted to implement protocol v2 first, then add v0 compatibility afterward.

Something like:

version 2
agent=urbit-git/0.1
ls-refs
fetch=shallow
object-format=sha1

Seeing:

$ GIT_TRACE_PACKET=1 git ls-remote https://foo/~sampel/foo

and having the other end literally be Hoon would be delightful.

3. Packfiles are the real project

This is where it graduates from amusing HTTP server to serious implementation.

A packfile contains compressed Git objects, potentially represented as deltas against other objects. You'll need:

PACK header
object entries
  commit
  tree
  blob
  tag


OFS_DELTA
REF_DELTA


zlib streams


trailing checksum

For incoming push, Git sends commands followed by PACK... binary data. The receive-pack request has exactly that structure: ref create/update/delete commands, then the packfile.

So:

git push
   ↓
Eyre
   ↓
pkt-line commands
   ↓
PACK decoder
   ↓
inflate
   ↓
resolve deltas
   ↓
verify object hashes
   ↓
validate ref transition
   ↓
atomic Gall state update

There's something particularly satisfying about Gall here because a push can naturally become one deterministic state transition.

4. Fetch negotiation

This is probably the most algorithmically fun piece.

The client effectively says:

want A
want B


have X
have Y
have Z
...

and your server figures out the object closure needed to get from the client's known DAG to the desired refs, then emits a minimal-ish pack. Git's pack protocol exists specifically to negotiate the smallest useful transfer.

You don't have to be optimal initially.

You could do:

wanted closure
-
known closure
=
objects to send

then pack everything without deltas.

That would be correct but inefficient, which is ideal for v0.1.

Later:

object ordering
delta selection
delta chains
thin packs
shallow clone
filter/blob:none

become optimizations.

And here's where Urbit makes it much more interesting

I would resist reproducing GitHub's account model.

A repo should have an Urbit identity-native authority model.

Imagine:

https://git.example/~sampel-palnet/foo

is canonical.

Inside:

owner: ~sampel-palnet


writers:
  ~sampel-palnet
  ~sampel-palfun
  ~mister-dister


readers:
  public

Authentication could initially be HTTP Basic/token because normal Git already understands that.

But between ships:

~sampel-palnet
      |
      | Ames
      v
%git

could establish repository permissions using @p identity without Git knowing anything about it.

That creates an interesting split:

             external world


        ordinary Git Smart HTTP
                 |
                 v
             +--------+
             |  %git  |
             +--------+
                 |
       Urbit semantics layer
         /              \
       Ames          groups/ACL

The wire format remains 100% Git.

Urbit supplies identity, discovery, permissions, notifications, and social coordination.

There's an even cooler direction: repo replication over Ames

Git already provides the object model, so you could let two %git agents exchange Git object IDs and refs directly without re-running Smart HTTP through Iris/Eyre.

For example:

~zod/%git                        ~nec/%git


refs/heads/main = abc    --->


                       <---  I have abc
                             missing def ghi


def ghi               --->


                       <---  ack

No packfile needed internally unless bandwidth demands it.

Then the same repository is accessible via:

HTTP Git client
     |
     v
  ~zod/%git
     |
    Ames
     |
  ~nec/%git

This starts looking like a genuinely P2P Git forge rather than a Git server.

Git has always had decentralized repository semantics but the social infrastructure got centralized around GitHub/GitLab.

Urbit can supply exactly that missing layer:

Git
  objects
  commits
  branches
  merges
  diffs


Urbit
  identity
  presence
  groups
  messaging
  subscriptions
  permissions
  discovery

That combination makes more conceptual sense to me than decentralized Git projects that have to invent a second identity/network stack.

And then %git + Clay gets weird

This is the part I'd explore after basic interoperability.

There are now two versioned content-address-ish universes living in the same runtime:

Clay                         Git


desk                         repository
revision                     commit
path                         path
file                         blob
desk state                   tree
merge                        merge

They're not isomorphic, but close enough that the border could be really fruitful.

Imagine:

git clone https://ship/git/~zod/base

where the repo is a Git projection of some Clay desk.

Then:

git push origin main

causes the ship to validate the Git tree and commit it into Clay.

Or the reverse:

|commit %foo

produces a Git commit and advances refs/heads/main.

If you got this right, VS Code/Emacs/JetBrains/etc. become perfectly normal development clients for Clay through Git, without requiring them to know that Urbit exists.

That might actually be useful beyond novelty.

A sane implementation sequence

I'd do it in approximately this order:

Git object codec — blob/tree/commit/tag hashing and parsing.
pkt-line codec.
info/refs + v2 ls-refs, until git ls-remote works.
Upload-pack without negotiation sophistication: clone a tiny repo, send every reachable object.
Pack encoder, initially only full objects—no deltas.
Get git clone working.
Implement pack decoder + OFS_DELTA/REF_DELTA.
Implement receive-pack.
Get git push working and refs updating atomically.
Proper have/want negotiation.
Thin packs, filters, shallow clones, tags, capabilities.
Urbit-native ACL/identity.
Ames repo replication.
Clay projection/import.

The standard Git client is an excellent conformance harness the whole way. GIT_TRACE_PACKET=1, GIT_TRACE_CURL=1, and git fsck will tell you exactly how badly you've offended it.

The especially appealing thing compared with Matrix or ATProto is that you don't have another enormous application ontology to implement. The deep part is a compact, old, exquisitely optimized distributed-data protocol: DAG traversal, hashing, binary packing, delta compression, graph negotiation.

And the minimum successful artifact is hilarious:

$ git clone https://my-ship.example/git/hello
Cloning into 'hello'...

with zero Git executable, zero filesystem repo, zero CGI, zero sidecar on the server — the peer on the other end is just a Gall agent manufacturing valid Git protocol and packfiles out of nouns.

I think this one is unusually worth doing.
