::  Bounded, occurrence-aware line ancestry for Git and Clay snapshots.
::
::  A line is identified by its bytes and its duplicate ordinal within a file.
::  Walking snapshots newest-to-oldest preserves attribution while that identity
::  remains present.  This tracks inserted blocks and repeated lines without an
::  unbounded edit-distance matrix in the loom.
::
|%
+$  slot
  $:  key=@
      source=@ud
      active=?
  ==
::
++  find-byte
  |=  [data=octs offset=@ud value=@ud]
  ^-  (unit @ud)
  ?:  (gte offset p.data)  ~
  ?:  =(value (cut 3 [offset 1] q.data))  `offset
  $(offset +(offset))
::
++  line-keys
  |=  data=octs
  ^-  (list @)
  =/  offset=@ud  0
  =/  counts=(map @ @ud)  ~
  =/  keys=(list @)  ~
  |-
  ?:  (gth offset p.data)  (flop keys)
  =/  newline=(unit @ud)  (find-byte data offset 10)
  =/  end=@ud  ?~(newline p.data u.newline)
  =/  width=@ud  (sub end offset)
  =/  line=@  (cut 3 [offset width] q.data)
  =/  prior=(unit @ud)  (~(get by counts) line)
  =/  occurrence=@ud  ?~(prior 0 +(u.prior))
  =.  counts  (~(put by counts) line occurrence)
  =.  keys  [(jam [width line occurrence]) keys]
  ?~  newline  (flop keys)
  $(offset +(u.newline), counts counts, keys keys)
::
++  seed
  |=  data=octs
  ^-  (list slot)
  %+  turn  (line-keys data)
  |=(key=@ [key 0 %.y])
::
++  step
  |=  [slots=(list slot) parent=octs source=@ud]
  ^-  (list slot)
  =/  parent-keys=(set @)  (silt (line-keys parent))
  %+  turn  slots
  |=  item=slot
  ?.  active.item  item
  ?:  (~(has in parent-keys) key.item)
    item(source source)
  item(active %.n)
::
++  deactivate
  |=  slots=(list slot)
  ^-  (list slot)
  (turn slots |=(item=slot item(active %.n)))
::
++  any-active
  |=  slots=(list slot)
  ^-  ?
  (lien slots |=(item=slot active.item))
--
