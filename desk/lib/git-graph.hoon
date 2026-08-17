::  Reachability over canonical Git commit, tree, tag, and blob content.
::
/-  git
/+  git-codec, git-protocol
|%
+$  shallow-result
  $:  reachable=(set oid:git)
      boundaries=(set oid:git)
  ==
::
++  find-byte
  |=  [bytes=octs offset=@ud needle=@ud]
  ^-  (unit @ud)
  ?:  (gte offset p.bytes)  ~
  ?:  =((byte-at:git-codec bytes offset) needle)  `offset
  $(offset +(offset))
::
++  text-object-dependencies
  |=  [data=octs tag=?]
  ^-  (unit (list oid:git))
  =/  refs=(list oid:git)  ~
  =/  offset=@ud  0
  |-
  ?:  (gte offset p.data)  `(flop refs)
  =/  end=(unit @ud)  (find-byte data offset 10)
  ?~  end  ~
  =/  width=@ud  (sub u.end offset)
  ?:  =(width 0)  `(flop refs)
  =/  line=octs  (slice:git-codec data offset width)
  =/  candidate=(unit oid:git)
    ?:  tag
      ?:  (starts-with:git-protocol line 'object ')
        (oid-at:git-protocol line 7)
      ~
    ?:  (starts-with:git-protocol line 'tree ')
      (oid-at:git-protocol line 5)
    ?:  (starts-with:git-protocol line 'parent ')
      (oid-at:git-protocol line 7)
    ~
  =?  refs  ?=(^ candidate)  [u.candidate refs]
  $(offset +(u.end), refs refs)
::
++  tree-dependencies
  |=  data=octs
  ^-  (unit (list oid:git))
  =/  refs=(list oid:git)  ~
  =/  offset=@ud  0
  |-
  ?:  =(offset p.data)  `(flop refs)
  ?:  (gth offset p.data)  ~
  =/  nul=(unit @ud)  (find-byte data offset 0)
  ?~  nul  ~
  =/  oid-offset=@ud  +(u.nul)
  ?:  (gth (add oid-offset 20) p.data)  ~
  =/  raw=octs  (slice:git-codec data oid-offset 20)
  =/  oid=oid:git  (rev 3 20 q.raw)
  $(offset (add oid-offset 20), refs [oid refs])
::
++  dependencies
  |=  obj=object:git
  ^-  (unit (list oid:git))
  ?-  kind.obj
      %blob    `~
      %tree    (tree-dependencies data.obj)
      %commit  (text-object-dependencies data.obj %.n)
      %tag     (text-object-dependencies data.obj %.y)
  ==
::
++  reachable
  |=  [objects=(map oid:git object:git) roots=(set oid:git)]
  ^-  (unit (set oid:git))
  =/  pending=(list oid:git)  ~(tap in roots)
  =/  seen=(set oid:git)  ~
  |-
  ?~  pending  `seen
  =/  oid=oid:git  i.pending
  ?:  (~(has in seen) oid)
    $(pending t.pending)
  =/  found=(unit object:git)  (~(get by objects) oid)
  ?~  found  ~
  =/  deps=(unit (list oid:git))  (dependencies u.found)
  ?~  deps  ~
  %=  $
    pending  (weld u.deps t.pending)
    seen     (~(put in seen) oid)
  ==
::
++  reachable-stopping
  |=  [objects=(map oid:git object:git) roots=(set oid:git) stops=(set oid:git)]
  ^-  (unit (set oid:git))
  =/  pending=(list oid:git)  ~(tap in roots)
  =/  seen=(set oid:git)  ~
  |-
  ?~  pending  `seen
  =/  oid=oid:git  i.pending
  ?:  (~(has in seen) oid)
    $(pending t.pending)
  =/  found=(unit object:git)  (~(get by objects) oid)
  ?~  found  ~
  =/  deps=(unit (list oid:git))
    ?:  ?&  =(%commit kind.u.found)
            (~(has in stops) oid)
        ==
      =/  parts=(unit [tree=oid:git parents=(list oid:git)])
        (commit-parts data.u.found)
      ?~(parts ~ `~[tree.u.parts])
    (dependencies u.found)
  ?~  deps  ~
  %=  $
    pending  (weld u.deps t.pending)
    seen     (~(put in seen) oid)
  ==
::
++  commit-parts
  |=  data=octs
  ^-  (unit [tree=oid:git parents=(list oid:git)])
  =/  tree=(unit oid:git)  ~
  =/  parents=(list oid:git)  ~
  =/  offset=@ud  0
  |-
  ?:  (gte offset p.data)
    ?~(tree ~ `[u.tree (flop parents)])
  =/  end=(unit @ud)  (find-byte data offset 10)
  ?~  end  ~
  =/  width=@ud  (sub u.end offset)
  ?:  =(width 0)
    ?~(tree ~ `[u.tree (flop parents)])
  =/  line=octs  (slice:git-codec data offset width)
  =/  candidate=(unit oid:git)
    ?:  (starts-with:git-protocol line 'tree ')
      (oid-at:git-protocol line 5)
    ?:  (starts-with:git-protocol line 'parent ')
      (oid-at:git-protocol line 7)
    ~
  ?^  candidate
    ?:  (starts-with:git-protocol line 'tree ')
      $(offset +(u.end), tree `u.candidate)
    $(offset +(u.end), parents [u.candidate parents])
  $(offset +(u.end))
::
++  reachable-depth
  |=  [objects=(map oid:git object:git) roots=(set oid:git) depth=@ud]
  ^-  (unit shallow-result)
  ?:  =(depth 0)  ~
  =/  pending=(list [oid=oid:git remaining=@ud])
    (turn ~(tap in roots) |=(id=oid:git [id depth]))
  =/  expanded=(map oid:git @ud)  ~
  =/  reachable=(set oid:git)  ~
  =/  boundaries=(set oid:git)  ~
  |-
  ?~  pending  `[reachable boundaries]
  =/  item=[oid=oid:git remaining=@ud]  i.pending
  =/  previous=(unit @ud)  (~(get by expanded) oid.item)
  ?:  ?&(?=(^ previous) (gte u.previous remaining.item))
    $(pending t.pending)
  =/  found=(unit object:git)  (~(get by objects) oid.item)
  ?~  found  ~
  =.  expanded  (~(put by expanded) oid.item remaining.item)
  =.  reachable  (~(put in reachable) oid.item)
  ?-  kind.u.found
      %blob
    $(pending t.pending)
  ::
      %tree
    =/  deps=(unit (list oid:git))  (tree-dependencies data.u.found)
    ?~  deps  ~
    =/  next=(list [oid=oid:git remaining=@ud])
      (turn u.deps |=(id=oid:git [id remaining.item]))
    $(pending (weld next t.pending))
  ::
      %tag
    =/  deps=(unit (list oid:git))  (text-object-dependencies data.u.found %.y)
    ?~  deps  ~
    =/  next=(list [oid=oid:git remaining=@ud])
      (turn u.deps |=(id=oid:git [id remaining.item]))
    $(pending (weld next t.pending))
  ::
      %commit
    =/  parts=(unit [tree=oid:git parents=(list oid:git)])
      (commit-parts data.u.found)
    ?~  parts  ~
    =/  next=(list [oid=oid:git remaining=@ud])
      ~[[tree.u.parts remaining.item]]
    ?:  =(remaining.item 1)
      =?  boundaries  ?=(^ parents.u.parts)
        (~(put in boundaries) oid.item)
      $(pending (weld next t.pending), boundaries boundaries)
    =/  parent-depth=@ud  (dec remaining.item)
    =/  parents-next=(list [oid=oid:git remaining=@ud])
      (turn parents.u.parts |=(id=oid:git [id parent-depth]))
    $(pending (weld next (weld parents-next t.pending)))
  ==
--
