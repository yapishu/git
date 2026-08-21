::  Canonical Git tree traversal and structural editing.
::
/-  git
/+  git-clay, git-codec, git-protocol
|%
+$  flat-entry  [mode=@t oid=oid:git]
::
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
++  walk-tree-index
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          prefix=path
          files=(map path flat-entry)
          visiting=(set oid:git)
      ==
  ^-  (unit (map path flat-entry))
  ?:  (~(has in visiting) tree-oid)  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?.  ?&(?=(^ found) =(%tree kind.u.found))  ~
  =/  parsed=(unit (list tree-entry:git-clay))
    (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =.  visiting  (~(put in visiting) tree-oid)
  =/  remaining=(list tree-entry:git-clay)  u.parsed
  |-
  ?~  remaining  `files
  =/  entry=tree-entry:git-clay  i.remaining
  =/  file-path=(unit path)  (append-segment prefix name.entry)
  ?~  file-path  ~
  ?:  =('40000' mode.entry)
    =/  walked=(unit (map path flat-entry))
      (walk-tree-index objects oid.entry u.file-path files visiting)
    ?~  walked  ~
    $(remaining t.remaining, files u.walked)
  ?.  (blob-mode mode.entry)  $(remaining t.remaining)
  ?:  (~(has by files) u.file-path)  ~
  =/  blob=(unit object:git)  (~(get by objects) oid.entry)
  ?.  ?&(?=(^ blob) =(%blob kind.u.blob))  ~
  $(remaining t.remaining, files (~(put by files) u.file-path [mode.entry oid.entry]))
::
++  flatten-commit-index
  |=  [objects=(map oid:git object:git) commit-oid=oid:git]
  ^-  (unit (map path flat-entry))
  =/  tree-oid=(unit oid:git)  (commit-tree:git-clay objects commit-oid)
  ?~  tree-oid  ~
  (walk-tree-index objects u.tree-oid / ~ ~)
::
++  add-index-paths
  |=  [index=(map path flat-entry) paths=(set path)]
  ^-  (set path)
  %+  roll  ~(tap by index)
  |=  [entry=[file-path=path value=flat-entry] accumulator=(set path)]
  (~(put in accumulator) file-path.entry)
::
++  changed-tree-files
  |=  $:  objects=(map oid:git object:git)
          current=oid:git
          parent=(unit oid:git)
          prefix=path
          visiting=(set oid:git)
          changed=(set path)
      ==
  ^-  (set path)
  ?:  (~(has in visiting) current)  changed
  =/  unchanged=?
    ?~  parent  %.n
    =(current u.parent)
  ?:  unchanged  changed
  =/  current-object=(unit object:git)  (~(get by objects) current)
  ?.  ?&(?=(^ current-object) =(%tree kind.u.current-object))  changed
  =/  current-list=(unit (list tree-entry:git-clay))
    (parse-tree:git-clay data.u.current-object)
  ?~  current-list  changed
  =/  parent-entries=(map @t tree-entry:git-clay)
    ?~  parent  ~
    =/  parent-object=(unit object:git)  (~(get by objects) u.parent)
    ?.  ?&(?=(^ parent-object) =(%tree kind.u.parent-object))  ~
    =/  parent-list=(unit (list tree-entry:git-clay))
      (parse-tree:git-clay data.u.parent-object)
    ?~  parent-list  ~
    %-  malt
    %+  turn  u.parent-list
    |=  entry=tree-entry:git-clay
    [name.entry entry]
  =.  visiting  (~(put in visiting) current)
  =/  remaining=(list tree-entry:git-clay)  u.current-list
  |-
  ?~  remaining  changed
  =/  entry=tree-entry:git-clay  i.remaining
  =/  file-path=(unit path)  (append-segment prefix name.entry)
  ?~  file-path  $(remaining t.remaining)
  =/  old=(unit tree-entry:git-clay)  (~(get by parent-entries) name.entry)
  ?:  =('40000' mode.entry)
    ?.  ?&(?=(^ old) =('40000' mode.u.old))
      =/  indexed=(unit (map path flat-entry))
        (walk-tree-index objects oid.entry u.file-path ~ visiting)
      ?~  indexed  $(remaining t.remaining)
      $(remaining t.remaining, changed (add-index-paths u.indexed changed))
    =/  nested=(set path)
      (changed-tree-files objects oid.entry `oid.u.old u.file-path visiting changed)
    $(remaining t.remaining, changed nested)
  ?.  (blob-mode mode.entry)  $(remaining t.remaining)
  ?:  ?&  ?=(^ old)
          =(mode.entry mode.u.old)
          =(oid.entry oid.u.old)
      ==
    $(remaining t.remaining)
  $(remaining t.remaining, changed (~(put in changed) u.file-path))
::
++  changed-commit-files
  |=  [objects=(map oid:git object:git) current=oid:git parent=(unit oid:git)]
  ^-  (set path)
  =/  current-tree=(unit oid:git)  (commit-tree:git-clay objects current)
  ?~  current-tree  ~
  =/  parent-tree=(unit oid:git)
    ?~  parent  ~
    (commit-tree:git-clay objects u.parent)
  (changed-tree-files objects u.current-tree parent-tree / ~ ~)
::
++  replace-entry
  |=  [entries=(list tree-entry:git-clay) name=@t new-oid=oid:git]
  ^-  (list tree-entry:git-clay)
  %+  turn  entries
  |=  entry=tree-entry:git-clay
  ?:  =(name.entry name)  entry(oid new-oid)
  entry
::
++  remove-entry
  |=  [entries=(list tree-entry:git-clay) name=@t]
  ^-  (list tree-entry:git-clay)
  (skim entries |=(entry=tree-entry:git-clay !=(name.entry name)))
::
++  put-entry
  |=  [entries=(list tree-entry:git-clay) entry=tree-entry:git-clay]
  ^-  (list tree-entry:git-clay)
  [entry (remove-entry entries name.entry)]
::
++  entry-before
  |=  [a=tree-entry:git-clay b=tree-entry:git-clay]
  ^-  ?
  =/  a-key=@t  ?:(=('40000' mode.a) (rap 3 ~[name.a '/']) name.a)
  =/  b-key=@t  ?:(=('40000' mode.b) (rap 3 ~[name.b '/']) name.b)
  (text-before:git-clay a-key b-key)
::
++  store-tree
  |=  [entries=(list tree-entry:git-clay) objects=(map oid:git object:git)]
  ^-  [oid=oid:git objects=(map oid:git object:git)]
  =/  sorted=(list tree-entry:git-clay)  (sort entries entry-before)
  =/  tree-data=octs
    %-  join-all:git-codec
    %+  turn  sorted
    |=  entry=tree-entry:git-clay
    (tree-record:git-clay mode.entry name.entry oid.entry)
  =/  tree-oid=oid:git  (object-oid:git-codec %tree tree-data)
  [tree-oid (~(put by objects) tree-oid [%tree tree-data])]
::
++  upsert-tree
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          segments=path
          replacement=octs
      ==
  ^-  (unit [oid=oid:git objects=(map oid:git object:git)])
  ?~  segments  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?.  ?&(?=(^ found) =(%tree kind.u.found))  ~
  =/  parsed=(unit (list tree-entry:git-clay))
    (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =/  name=@t  `@t`i.segments
  =/  matches=(list tree-entry:git-clay)
    (skim u.parsed |=(entry=tree-entry:git-clay =(name.entry name)))
  ?:  ?=(~ t.segments)
    =/  mode=(unit @t)
      ?~  matches  `'100644'
      ?.  (blob-mode mode.i.matches)  ~
      `mode.i.matches
    ?~  mode  ~
    =/  blob-oid=oid:git  (object-oid:git-codec %blob replacement)
    =/  with-blob=(map oid:git object:git)
      (~(put by objects) blob-oid [%blob replacement])
    `(store-tree (put-entry u.parsed [u.mode name blob-oid]) with-blob)
  =/  child-root=[oid=oid:git objects=(map oid:git object:git)]
    ?~  matches
      (store-tree ~ objects)
    ?.  =('40000' mode.i.matches)  [0x0 objects]
    [oid.i.matches objects]
  ?:  =(0x0 oid.child-root)  ~
  =/  child=(unit [oid=oid:git objects=(map oid:git object:git)])
    (upsert-tree objects.child-root oid.child-root t.segments replacement)
  ?~  child  ~
  `(store-tree (put-entry u.parsed ['40000' name oid.u.child]) objects.u.child)
::
++  upsert-tree-mode
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          segments=path
          replacement=octs
          file-mode=@t
      ==
  ^-  (unit [oid=oid:git objects=(map oid:git object:git)])
  ?.  (blob-mode file-mode)  ~
  ?~  segments  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?.  ?&(?=(^ found) =(%tree kind.u.found))  ~
  =/  parsed=(unit (list tree-entry:git-clay))
    (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =/  name=@t  `@t`i.segments
  =/  matches=(list tree-entry:git-clay)
    (skim u.parsed |=(entry=tree-entry:git-clay =(name.entry name)))
  ?:  ?=(~ t.segments)
    =/  compatible=?
      ?~  matches  %.y
      (blob-mode mode.i.matches)
    ?.  compatible  ~
    =/  blob-oid=oid:git  (object-oid:git-codec %blob replacement)
    =/  with-blob=(map oid:git object:git)
      (~(put by objects) blob-oid [%blob replacement])
    `(store-tree (put-entry u.parsed [file-mode name blob-oid]) with-blob)
  =/  child-root=[oid=oid:git objects=(map oid:git object:git)]
    ?~  matches
      (store-tree ~ objects)
    ?.  =('40000' mode.i.matches)  [0x0 objects]
    [oid.i.matches objects]
  ?:  =(0x0 oid.child-root)  ~
  =/  child=(unit [oid=oid:git objects=(map oid:git object:git)])
    (upsert-tree-mode objects.child-root oid.child-root t.segments replacement file-mode)
  ?~  child  ~
  `(store-tree (put-entry u.parsed ['40000' name oid.u.child]) objects.u.child)
::
++  delete-tree
  |=  $:  objects=(map oid:git object:git)
          tree-oid=oid:git
          segments=path
      ==
  ^-  (unit [empty=? oid=oid:git objects=(map oid:git object:git)])
  ?~  segments  ~
  =/  found=(unit object:git)  (~(get by objects) tree-oid)
  ?.  ?&(?=(^ found) =(%tree kind.u.found))  ~
  =/  parsed=(unit (list tree-entry:git-clay))
    (parse-tree:git-clay data.u.found)
  ?~  parsed  ~
  =/  name=@t  `@t`i.segments
  =/  matches=(list tree-entry:git-clay)
    (skim u.parsed |=(entry=tree-entry:git-clay =(name.entry name)))
  ?~  matches  ~
  =/  target=tree-entry:git-clay  i.matches
  ?:  ?=(~ t.segments)
    ?.  (blob-mode mode.target)  ~
    =/  next=(list tree-entry:git-clay)  (remove-entry u.parsed name)
    =/  stored=[oid=oid:git objects=(map oid:git object:git)]
      (store-tree next objects)
    `[?=(~ next) oid.stored objects.stored]
  ?.  =('40000' mode.target)  ~
  =/  child=(unit [empty=? oid=oid:git objects=(map oid:git object:git)])
    (delete-tree objects oid.target t.segments)
  ?~  child  ~
  =/  next=(list tree-entry:git-clay)
    ?:  empty.u.child
      (remove-entry u.parsed name)
    (put-entry u.parsed ['40000' name oid.u.child])
  =/  stored=[oid=oid:git objects=(map oid:git object:git)]
    (store-tree next objects.u.child)
  `[?=(~ next) oid.stored objects.stored]
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
++  annotated-tag
  |=  $:  objects=(map oid:git object:git)
          target=oid:git
          name=@t
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [tag=oid:git objects=(map oid:git object:git)])
  =/  found=(unit object:git)  (~(get by objects) target)
  ?~  found  ~
  =/  who=@t  (scot %p author)
  =/  when=@t  (crip ((d-co:co 1) (unix-seconds now)))
  =/  identity=@t  (rap 3 ~[who ' <' who '@urbit> ' when ' +0000'])
  =/  tag-data=octs
    %-  text:git-codec
    %-  rap
    :-  3
    :~  'object '
        (oid-text:git-codec target)
        '\0a'
        'type '
        (object-kind-text:git-codec kind.u.found)
        '\0a'
        'tag '
        name
        '\0a'
        'tagger '
        identity
        '\0a\0a'
        message
        '\0a'
    ==
  =/  tag-oid=oid:git  (object-oid:git-codec %tag tag-data)
  `[tag-oid (~(put by objects) tag-oid [%tag tag-data])]
::
++  initial-commit
  |=  $:  objects=(map oid:git object:git)
          file-path=path
          replacement=octs
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [commit=oid:git objects=(map oid:git object:git)])
  =/  empty=[oid=oid:git objects=(map oid:git object:git)]
    (store-tree ~ objects)
  =/  written=(unit [oid=oid:git objects=(map oid:git object:git)])
    (upsert-tree objects.empty oid.empty file-path replacement)
  ?~  written  ~
  =/  identity=@t
    =/  who=@t  (scot %p author)
    =/  when=@t  (crip ((d-co:co 1) (unix-seconds now)))
    (rap 3 ~[who ' <' who '@urbit> ' when ' +0000'])
  =/  commit-data=octs
    %-  text:git-codec
    %-  rap
    :-  3
    :~  'tree '
        (oid-text:git-codec oid.u.written)
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
    (~(put by objects.u.written) commit-oid [%commit commit-data])
  `[commit-oid all]
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
    (upsert-tree objects u.root file-path replacement)
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
::
++  delete-commit
  |=  $:  objects=(map oid:git object:git)
          parent=oid:git
          file-path=path
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [commit=oid:git objects=(map oid:git object:git)])
  =/  root=(unit oid:git)  (commit-tree:git-clay objects parent)
  ?~  root  ~
  =/  rewritten=(unit [empty=? oid=oid:git objects=(map oid:git object:git)])
    (delete-tree objects u.root file-path)
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
::
++  merge-commit
  |=  $:  objects=(map oid:git object:git)
          base=oid:git
          ours=oid:git
          theirs=oid:git
          author=@p
          now=@da
          message=@t
      ==
  ^-  (unit [commit=oid:git objects=(map oid:git object:git)])
  =/  base-files=(unit (map path flat-entry))  (flatten-commit-index objects base)
  =/  our-files=(unit (map path flat-entry))  (flatten-commit-index objects ours)
  =/  their-files=(unit (map path flat-entry))  (flatten-commit-index objects theirs)
  ?.  ?&(?=(^ base-files) ?=(^ our-files) ?=(^ their-files))  ~
  =/  root=(unit oid:git)  (commit-tree:git-clay objects ours)
  ?~  root  ~
  =/  paths=(set path)  ~
  =.  paths
    %+  roll  ~(tap by u.base-files)
    |=  [entry=[file-path=path value=flat-entry] accumulator=(set path)]
    (~(put in accumulator) file-path.entry)
  =.  paths
    %+  roll  ~(tap by u.our-files)
    |=  [entry=[file-path=path value=flat-entry] accumulator=(set path)]
    (~(put in accumulator) file-path.entry)
  =.  paths
    %+  roll  ~(tap by u.their-files)
    |=  [entry=[file-path=path value=flat-entry] accumulator=(set path)]
    (~(put in accumulator) file-path.entry)
  =/  remaining=(list path)  ~(tap in paths)
  =/  merged=(unit [oid=oid:git objects=(map oid:git object:git)])
    |-
    ?~  remaining  `[u.root objects]
    =/  file-path=path  i.remaining
    =/  base-entry=(unit flat-entry)  (~(get by u.base-files) file-path)
    =/  our-entry=(unit flat-entry)  (~(get by u.our-files) file-path)
    =/  their-entry=(unit flat-entry)  (~(get by u.their-files) file-path)
    ?:  |(=(their-entry base-entry) =(their-entry our-entry))
      $(remaining t.remaining)
    ?.  =(our-entry base-entry)  ~
    ?~  their-entry
      =/  deleted=(unit [empty=? oid=oid:git objects=(map oid:git object:git)])
        (delete-tree objects u.root file-path)
      ?~  deleted  ~
      $(remaining t.remaining, root `oid.u.deleted, objects objects.u.deleted)
    =/  blob=(unit object:git)  (~(get by objects) oid.u.their-entry)
    ?.  ?&(?=(^ blob) =(%blob kind.u.blob))  ~
    =/  written=(unit [oid=oid:git objects=(map oid:git object:git)])
      (upsert-tree-mode objects u.root file-path data.u.blob mode.u.their-entry)
    ?~  written  ~
    $(remaining t.remaining, root `oid.u.written, objects objects.u.written)
  ?~  merged  ~
  =/  identity=@t
    =/  who=@t  (scot %p author)
    =/  when=@t  (crip ((d-co:co 1) (unix-seconds now)))
    (rap 3 ~[who ' <' who '@urbit> ' when ' +0000'])
  =/  commit-data=octs
    %-  text:git-codec
    %-  rap
    :-  3
    :~  'tree '
        (oid-text:git-codec oid.u.merged)
        '\0a'
        'parent '
        (oid-text:git-codec ours)
        '\0a'
        'parent '
        (oid-text:git-codec theirs)
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
    (~(put by objects.u.merged) commit-oid [%commit commit-data])
  `[commit-oid all]
--
