::  Canonical Git tree traversal and structural editing.
::
/-  git
/+  git-clay, git-codec, git-protocol
|%
++  blob-mode
  |=  mode=@t
  ^-  ?
  ?|(=('100644' mode) =('100755' mode) =('120000' mode))
::
++  safe-segment
  |=  value=@t
  ^-  ?
  =/  chars=tape  (trip value)
  ?&  !=('' value)
      !=('.' value)
      !=('..' value)
      (lte (lent chars) 255)
      %+  levy  chars
      |=(char=@tD &(!=(char 0) !=(char '/')))
  ==
::
++  append-segment
  |=  [prefix=path name=@t]
  ^-  (unit path)
  ?.  (safe-segment name)  ~
  `(weld prefix ~[`knot`name])
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
  =/  parsed  (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =/  remaining  u.parsed
  =.  visiting  (~(put in visiting) tree-oid)
  |-
  ?~  remaining  `files
  =/  entry  i.remaining
  =/  file-path=(unit path)  (append-segment prefix name.entry)
  ?~  file-path  ~
  ?:  =('40000' mode.entry)
    =/  walked=(unit (map path octs))
      (walk-tree objects oid.entry u.file-path files visiting)
    ?~  walked  ~
    $(remaining t.remaining, files u.walked)
  ?.  (blob-mode mode.entry)  $(remaining t.remaining)
  ?:  (~(has by files) u.file-path)  ~
  =/  blob=(unit object:git)  (~(get by objects) oid.entry)
  ?~  blob  ~
  ?.  =(%blob kind.u.blob)  ~
  $(remaining t.remaining, files (~(put by files) u.file-path data.u.blob))
::
++  flatten-commit
  |=  [objects=(map oid:git object:git) commit-oid=oid:git]
  ^-  (unit (map path octs))
  =/  tree-oid=(unit oid:git)  (commit-tree:git-clay objects commit-oid)
  ?~  tree-oid  ~
  (walk-tree objects u.tree-oid / ~ ~)
::
++  replace-entry
  |=  [entries=(list tree-entry:git-clay) name=@t new-oid=oid:git]
  ^-  (list tree-entry:git-clay)
  %+  turn  entries
  |=  entry=tree-entry:git-clay
  ?:  =(name.entry name)  entry(oid new-oid)
  entry
::
++  store-tree
  |=  [entries=(list tree-entry:git-clay) objects=(map oid:git object:git)]
  ^-  [oid=oid:git objects=(map oid:git object:git)]
  =/  tree-data=octs
    %-  join-all:git-codec
    %+  turn  entries
    |=  entry=tree-entry:git-clay
    (tree-record:git-clay mode.entry name.entry oid.entry)
  =/  tree-oid=oid:git  (object-oid:git-codec %tree tree-data)
  [tree-oid (~(put by objects) tree-oid [%tree tree-data])]
::
++  rewrite-tree
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          segments=path
          replacement=octs
      ==
  ^-  (unit [oid=oid:git objects=(map oid:git object:git)])
  ?~  segments  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?~  found  ~
  ?.  =(%tree kind.u.found)  ~
  =/  parsed  (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =/  name=@t  `@t`i.segments
  =/  matches=(list tree-entry:git-clay)
    (skim u.parsed |=(entry=tree-entry:git-clay =(name.entry name)))
  ?~  matches  ~
  =/  target=tree-entry:git-clay  i.matches
  ?:  ?=(~ t.segments)
    ?.  (blob-mode mode.target)  ~
    =/  old=(unit object:git)  (~(get by objects) oid.target)
    ?.  ?&(?=(^ old) =(%blob kind.u.old))  ~
    =/  blob-oid=oid:git  (object-oid:git-codec %blob replacement)
    =/  with-blob=(map oid:git object:git)
      (~(put by objects) blob-oid [%blob replacement])
    `(store-tree (replace-entry u.parsed name blob-oid) with-blob)
  ?.  =('40000' mode.target)  ~
  =/  child=(unit [oid=oid:git objects=(map oid:git object:git)])
    (rewrite-tree objects oid.target t.segments replacement)
  ?~  child  ~
  `(store-tree (replace-entry u.parsed name oid.u.child) objects.u.child)
::
++  unix-seconds
  |=  now=@da
  ^-  @ud
  (rsh [6 1] (sub now ~1970.1.1))
::
++  edit-commit
  |=  $:  objects=(map oid:git object:git)
          parent=oid:git
          file-path=path
          replacement=octs
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [commit=oid:git objects=(map oid:git object:git)])
  =/  root=(unit oid:git)  (commit-tree:git-clay objects parent)
  ?~  root  ~
  =/  rewritten=(unit [oid=oid:git objects=(map oid:git object:git)])
    (rewrite-tree objects u.root file-path replacement)
  ?~  rewritten  ~
  =/  identity=@t
    =/  who=@t  (scot %p author)
    =/  when=@t  (crip ((d-co:co 1) (unix-seconds now)))
    (rap 3 ~[who ' <' who '@urbit> ' when ' +0000'])
  =/  commit-data=octs
    %-  text:git-codec
    %-  rap
    :-  3
    :~  'tree '
        (oid-text:git-codec oid.u.rewritten)
        '\0a'
        'parent '
        (oid-text:git-codec parent)
        '\0a'
        'author '
        identity
        '\0a'
        'committer '
        identity
        '\0a\0a'
        message
        '\0a'
    ==
  =/  commit-oid=oid:git  (object-oid:git-codec %commit commit-data)
  =/  all=(map oid:git object:git)
    (~(put by objects.u.rewritten) commit-oid [%commit commit-data])
  `[commit-oid all]
--
