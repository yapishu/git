::  Projection between canonical Git trees and mounted Clay paths.
::
/-  git
/+  git-codec, git-protocol
|%
+$  tree-entry
  $:  mode=@t
      name=@t
      oid=oid:git
  ==
::
++  find-byte
  |=  [bytes=octs offset=@ud needle=@ud]
  ^-  (unit @ud)
  ?:  (gte offset p.bytes)  ~
  ?:  =((byte-at:git-codec bytes offset) needle)  `offset
  $(offset +(offset))
::
++  parse-tree
  |=  data=octs
  ^-  (unit (list tree-entry))
  =/  offset=@ud  0
  =/  entries=(list tree-entry)  ~
  |-
  ?:  =(offset p.data)  `(flop entries)
  ?:  (gth offset p.data)  ~
  =/  space=(unit @ud)  (find-byte data offset 32)
  ?~  space  ~
  ?:  =(u.space offset)  ~
  =/  nul=(unit @ud)  (find-byte data +(u.space) 0)
  ?~  nul  ~
  ?:  =(u.nul +(u.space))  ~
  =/  oid-offset=@ud  +(u.nul)
  ?:  (gth (add oid-offset 20) p.data)  ~
  =/  mode-bytes=octs  (slice:git-codec data offset (sub u.space offset))
  =/  name-bytes=octs  (slice:git-codec data +(u.space) (sub u.nul +(u.space)))
  =/  raw-oid=octs  (slice:git-codec data oid-offset 20)
  =/  entry=tree-entry
    [q.mode-bytes q.name-bytes `oid:git`(rev 3 20 q.raw-oid)]
  $(offset (add oid-offset 20), entries [entry entries])
::
++  commit-tree
  |=  [objects=(map oid:git object:git) commit-oid=oid:git]
  ^-  (unit oid:git)
  =/  found=(unit object:git)  (~(get by objects) commit-oid)
  ?~  found  ~
  ?.  =(%commit kind.u.found)  ~
  ?.  (starts-with:git-protocol data.u.found 'tree ')  ~
  =/  tree-oid=(unit oid:git)  (oid-at:git-protocol data.u.found 5)
  ?~  tree-oid  ~
  ?:  (lth p.data.u.found 46)  ~
  ?.  =(10 (byte-at:git-codec data.u.found 45))  ~
  tree-oid
::
++  safe-segment
  |=  value=@t
  ^-  ?
  ?&  !=('' value)
      !=('.' value)
      !=('..' value)
      ((sane %tas) value)
  ==
::
++  directory-path
  |=  [prefix=path name=@t]
  ^-  (unit path)
  ?.  (safe-segment name)  ~
  `(weld prefix ~[name])
::
++  leaf-path
  |=  [prefix=path name=@t]
  ^-  (unit path)
  =/  chars=tape  (trip name)
  =/  index=@ud  0
  =/  dot=(unit @ud)  ~
  =/  remaining=tape  chars
  |-
  ?~  remaining
    ?~  dot  ~
    ?:  |(=(u.dot 0) =(+(u.dot) (lent chars)))  ~
    =/  base=@t  (crip (scag u.dot chars))
    =/  extension=@t  (crip (slag +(u.dot) chars))
    ?.  ?&((safe-segment base) (safe-segment extension))  ~
    `(weld prefix ~[base extension])
  =?  dot  =('.' i.remaining)  `index
  $(remaining t.remaining, index +(index), dot dot)
::
++  walk-tree
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          prefix=path
          files=(map path octs)
          visiting=(set oid:git)
      ==
  ^-  (unit (map path octs))
  ?:  (~(has in visiting) tree-oid)  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?~  found  ~
  ?.  =(%tree kind.u.found)  ~
  =/  parsed=(unit (list tree-entry))  (parse-tree data.u.found)
  ?~  parsed  ~
  =/  remaining=(list tree-entry)  u.parsed
  =.  visiting  (~(put in visiting) tree-oid)
  |-
  ?~  remaining  `files
  =/  entry=tree-entry  i.remaining
  ?:  =('40000' mode.entry)
    =/  child=(unit path)  (directory-path prefix name.entry)
    ?~  child  ~
    =/  walked=(unit (map path octs))
      (walk-tree objects oid.entry u.child files visiting)
    ?~  walked  ~
    $(remaining t.remaining, files u.walked)
  ?.  ?|(=('100644' mode.entry) =('100755' mode.entry))  ~
  =/  file-path=(unit path)  (leaf-path prefix name.entry)
  ?~  file-path  ~
  ?:  (~(has by files) u.file-path)  ~
  =/  blob=(unit object:git)  (~(get by objects) oid.entry)
  ?~  blob  ~
  ?.  =(%blob kind.u.blob)  ~
  $(remaining t.remaining, files (~(put by files) u.file-path data.u.blob))
::
++  flatten-commit
  |=  [objects=(map oid:git object:git) commit-oid=oid:git]
  ^-  (unit (map path octs))
  =/  tree-oid=(unit oid:git)  (commit-tree objects commit-oid)
  ?~  tree-oid  ~
  (walk-tree objects u.tree-oid / ~ ~)
--
