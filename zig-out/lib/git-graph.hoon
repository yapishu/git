::  Reachability over canonical Git commit, tree, tag, and blob content.
::
/-  git
/+  git-codec, git-protocol
|%
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
--
