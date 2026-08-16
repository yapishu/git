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
++  text-before
  |=  [left=@t right=@t]
  ^-  ?
  =/  a=tape  (trip left)
  =/  b=tape  (trip right)
  |-
  ?~  a  ?=(^ b)
  ?~  b  %.n
  ?:  =(i.a i.b)
    $(a t.a, b t.b)
  (lth i.a i.b)
::
++  tree-record
  |=  [mode=@t name=@t oid=oid:git]
  ^-  octs
  %-  join-all:git-codec
  :~  (text:git-codec mode)
      (oct:git-codec 32)
      (text:git-codec name)
      (oct:git-codec 0)
      [20 (rev 3 20 oid)]
  ==
::
++  build-tree
  |=  [files=(list [segments=path data=octs]) objects=(map oid:git object:git)]
  ^-  (unit [oid=oid:git objects=(map oid:git object:git)])
  =/  collect
    |=  $:  remaining=(list [segments=path data=octs])
            leaves=(list [name=@t data=octs])
            directories=(map @tas (list [segments=path data=octs]))
        ==
    ^-  (unit [(list [name=@t data=octs]) (map @tas (list [segments=path data=octs]))])
    ?~  remaining  `[leaves directories]
    =/  file=[segments=path data=octs]  i.remaining
    ?.  ?=(^ segments.file)  ~
    ?.  ?=(^ t.segments.file)  ~
    ?:  ?=(~ t.t.segments.file)
      =/  name=@t  (rap 3 ~[i.segments.file '.' i.t.segments.file])
      $(remaining t.remaining, leaves [[name data.file] leaves])
    =/  directory=@tas  i.segments.file
    =/  maybe-prior=(unit (list [segments=path data=octs]))
      (~(get by directories) directory)
    =/  prior=(list [segments=path data=octs])
      ?~(maybe-prior ~ u.maybe-prior)
    =.  directories
      (~(put by directories) directory [[t.segments.file data.file] prior])
    $(remaining t.remaining, directories directories)
  =/  partition=(unit [(list [name=@t data=octs]) (map @tas (list [segments=path data=octs]))])
    (collect files ~ ~)
  ?~  partition  ~
  =/  entries=(list [sort-key=@t bytes=octs])  ~
  =/  remaining-leaves=(list [name=@t data=octs])  -.u.partition
  |-
  ?^  remaining-leaves
    =/  leaf=[name=@t data=octs]  i.remaining-leaves
    =/  blob=object:git  [%blob data.leaf]
    =/  blob-oid=oid:git  (object-oid:git-codec %blob data.leaf)
    =.  objects  (~(put by objects) blob-oid blob)
    =.  entries  [[name.leaf (tree-record '100644' name.leaf blob-oid)] entries]
    $(remaining-leaves t.remaining-leaves)
  =/  remaining-directories=(list [@tas (list [segments=path data=octs])])
    ~(tap by +.u.partition)
  |-
  ?^  remaining-directories
    =/  directory=@tas  -.i.remaining-directories
    =/  child=(unit [oid=oid:git objects=(map oid:git object:git)])
      (build-tree +.i.remaining-directories objects)
    ?~  child  ~
    =.  objects  objects.u.child
    =/  name=@t  directory
    =/  sort-key=@t  (rap 3 ~[name '/'])
    =.  entries  [[sort-key (tree-record '40000' name oid.u.child)] entries]
    $(remaining-directories t.remaining-directories)
  =/  sorted=(list [sort-key=@t bytes=octs])
    %+  sort  entries
    |=  [a=[sort-key=@t bytes=octs] b=[sort-key=@t bytes=octs]]
    (text-before sort-key.a sort-key.b)
  =/  tree-data=octs
    (join-all:git-codec (turn sorted |=(entry=[sort-key=@t bytes=octs] bytes.entry)))
  =/  tree=object:git  [%tree tree-data]
  =/  tree-oid=oid:git  (object-oid:git-codec %tree tree-data)
  =.  objects  (~(put by objects) tree-oid tree)
  `[tree-oid objects]
::
++  unix-seconds
  |=  now=@da
  ^-  @ud
  (rsh [6 1] (sub now ~1970.1.1))
::
++  snapshot
  |=  $:  files=(map path octs)
          objects=(map oid:git object:git)
          parent=(unit oid:git)
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [commit=oid:git objects=(map oid:git object:git)])
  =/  built=(unit [oid=oid:git objects=(map oid:git object:git)])
    (build-tree ~(tap by files) objects)
  ?~  built  ~
  =/  identity=@t
    =/  who=@t  (scot %p author)
    =/  when=@t  (crip ((d-co:co 1) (unix-seconds now)))
    (rap 3 ~[who ' <' who '@urbit> ' when ' +0000'])
  =/  parent-line=@t
    ?~  parent  ''
    (rap 3 ~['parent ' (oid-text:git-codec u.parent) '\0a'])
  =/  commit-data=octs
    %-  text:git-codec
    %-  rap
    :-  3
    :~  'tree '
        (oid-text:git-codec oid.u.built)
        '\0a'
        parent-line
        'author '
        identity
        '\0a'
        'committer '
        identity
        '\0a\0a'
        message
        '\0a'
    ==
  =/  commit-object=object:git  [%commit commit-data]
  =/  commit-oid=oid:git  (object-oid:git-codec %commit commit-data)
  =/  all=(map oid:git object:git)
    (~(put by objects.u.built) commit-oid commit-object)
  `[commit-oid all]
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
