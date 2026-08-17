::  Verified Git pack v2 decoder with native delta resolution.
::
/-  git
/+  git-codec, git-delta, git-inflate, git-zlib
|%
+$  decoded-pack  [objects=(map oid:git object:git)]
+$  packed-kind
  $%  [%full kind=object-kind:git]
      [%ofs base-offset=@ud]
      [%ref base-oid=oid:git]
  ==
+$  packed-entry  [offset=@ud kind=packed-kind data=octs]
+$  resolve-pass-result
  $:  pending=(list packed-entry)
      all=(map oid:git object:git)
      staged=(map oid:git object:git)
      offsets=(map @ud object:git)
      progress=?
  ==
::
++  uint-be-at
  |=  [source=octs offset=@ud width=@ud]
  ^-  (unit @)
  ?:  (gth (add offset width) p.source)  ~
  `(rev 3 width (cut 3 [offset width] q.source))
::
++  kind-for-code
  |=  code=@ud
  ^-  (unit object-kind:git)
  ?:  =(code 1)  ``object-kind:git`%commit
  ?:  =(code 2)  ``object-kind:git`%tree
  ?:  =(code 3)  ``object-kind:git`%blob
  ?:  =(code 4)  ``object-kind:git`%tag
  ~
::
++  raw-entry-header
  |=  [source=octs offset=@ud]
  ^-  (unit [code=@ud size=@ud next=@ud])
  ?:  (gte offset p.source)  ~
  =/  first=@ud  (byte-at:git-codec source offset)
  =/  code=@ud  (cut 0 [4 3] first)
  ?:  ?|  =(code 0)  =(code 5)  ==  ~
  =/  size=@ud  (cut 0 [0 4] first)
  =/  continuation=?  =(1 (cut 0 [7 1] first))
  =/  cursor=@ud  +(offset)
  =/  shift=@ud  4
  |-
  ?.  continuation  `[[code size cursor]]
  ?:  (gte cursor p.source)  ~
  =/  byte=@ud  (byte-at:git-codec source cursor)
  =.  size  (add size (mul (cut 0 [0 7] byte) (bex shift)))
  =.  continuation  =(1 (cut 0 [7 1] byte))
  $(cursor +(cursor), shift (add shift 7))
::
++  entry-header
  |=  [source=octs offset=@ud]
  ^-  (unit [kind=object-kind:git size=@ud next=@ud])
  =/  raw=(unit [code=@ud size=@ud next=@ud])  (raw-entry-header source offset)
  ?~  raw  ~
  =/  kind=(unit object-kind:git)  (kind-for-code code.u.raw)
  ?~  kind  ~
  `[[u.kind size.u.raw next.u.raw]]
::
++  offset-base
  |=  [source=octs offset=@ud current=@ud]
  ^-  (unit [base=@ud next=@ud])
  ?:  (gte offset p.source)  ~
  =/  byte=@ud  (byte-at:git-codec source offset)
  =/  distance=@ud  (cut 0 [0 7] byte)
  =/  cursor=@ud  +(offset)
  |-
  ?:  =(0 (cut 0 [7 1] byte))
    ?:  |(=(distance 0) (gth distance current))  ~
    `[[(sub current distance) cursor]]
  ?:  (gte cursor p.source)  ~
  =.  byte  (byte-at:git-codec source cursor)
  =.  distance  (add (mul +(distance) 128) (cut 0 [0 7] byte))
  $(cursor +(cursor))
::
++  parse-entries
  |=  [source=octs count=@ud trailer=@ud]
  ^-  (unit (list packed-entry))
  =/  cursor=@ud  12
  =/  remaining=@ud  count
  =/  entries=(list packed-entry)  ~
  |-
  ?:  =(remaining 0)
    ?:  =(cursor trailer)  `(flop entries)
    ~
  ?:  (gte cursor trailer)  ~
  =/  entry-offset=@ud  cursor
  =/  header=(unit [code=@ud size=@ud next=@ud])
    (raw-entry-header source cursor)
  ?~  header  ~
  =/  data-offset=@ud  next.u.header
  =/  identified=(unit [kind=packed-kind data-offset=@ud])
    =/  full=(unit object-kind:git)  (kind-for-code code.u.header)
    ?^  full  `[[%full u.full] data-offset]
    ?:  =(code.u.header 6)
      =/  base=(unit [base=@ud next=@ud])
        (offset-base source data-offset entry-offset)
      ?~  base  ~
      `[[%ofs base.u.base] next.u.base]
    ?:  =(code.u.header 7)
      ?:  (gth (add data-offset 20) trailer)  ~
      =/  base-oid=oid:git
        `oid:git`(rev 3 20 (cut 3 [data-offset 20] q.source))
      `[[%ref base-oid] (add data-offset 20)]
    ~
  ?~  identified  ~
  =/  packed=packed-kind  kind.u.identified
  =.  data-offset  data-offset.u.identified
  ::  Vere's %zlib-v0 jet accepts a cursor into the complete byte stream.
  ::  Besides being dramatically faster than interpreted DEFLATE, this avoids
  ::  copying the entire remainder of the pack once for every object.
  =/  jetted  (mule |.((decompress-zlib:git-zlib [data-offset source])))
  ?:  ?=(%& -.jetted)
    =/  result=[octs bays:git-zlib]  p.jetted
    ?.  =(p.-.result size.u.header)  ~
    ?:  (gth pos.+.result trailer)  ~
    =.  cursor  pos.+.result
    $(remaining (dec remaining), entries [[entry-offset packed -.result] entries])
  ::  Older runtimes without the jet retain the portable decoder.
  =/  compressed=octs
    (slice:git-codec source data-offset (sub trailer data-offset))
  =/  inflated=(unit inflated:git-inflate)
    (zlib-inflate:git-inflate compressed size.u.header)
  ?~  inflated  ~
  =.  cursor  (add data-offset consumed.u.inflated)
  $(remaining (dec remaining), entries [[entry-offset packed data.u.inflated] entries])
::
++  resolve-pass
  |=  $:  entries=(list packed-entry)
          all=(map oid:git object:git)
          staged=(map oid:git object:git)
          offsets=(map @ud object:git)
      ==
  ^-  resolve-pass-result
  =/  remaining=(list packed-entry)  entries
  =/  pending=(list packed-entry)  ~
  =/  progress=?  %.n
  |-
  ?~  remaining  [(flop pending) all staged offsets progress]
  =/  entry=packed-entry  i.remaining
  =/  object=(unit object:git)
    ?-  -.kind.entry
        %full  `[kind.kind.entry data.entry]
        %ofs
      =/  base=(unit object:git)  (~(get by offsets) base-offset.kind.entry)
      ?~  base  ~
      =/  applied=(unit octs)  (apply-delta:git-delta data.u.base data.entry)
      ?~  applied  ~
      `[kind.u.base u.applied]
        %ref
      =/  base=(unit object:git)  (~(get by all) base-oid.kind.entry)
      ?~  base  ~
      =/  applied=(unit octs)  (apply-delta:git-delta data.u.base data.entry)
      ?~  applied  ~
      `[kind.u.base u.applied]
    ==
  ?~  object
    $(remaining t.remaining, pending [entry pending])
  =/  oid=oid:git  (object-oid:git-codec kind.u.object data.u.object)
  =.  all  (~(put by all) oid u.object)
  =.  staged  (~(put by staged) oid u.object)
  =.  offsets  (~(put by offsets) offset.entry u.object)
  $(remaining t.remaining, progress %.y)
::
++  resolve-entries
  |=  [entries=(list packed-entry) bases=(map oid:git object:git)]
  ^-  (unit (map oid:git object:git))
  =/  pending=(list packed-entry)  entries
  =/  all=(map oid:git object:git)  bases
  =/  staged=(map oid:git object:git)  ~
  =/  offsets=(map @ud object:git)  ~
  =/  attempts=@ud  (add 1 (lent entries))
  |-
  ?~  pending  `staged
  ?:  =(attempts 0)  ~
  =/  result=resolve-pass-result
    (resolve-pass pending all staged offsets)
  ?.  progress.result  ~
  %=  $
    pending  pending.result
    all      all.result
    staged   staged.result
    offsets  offsets.result
    attempts  (dec attempts)
  ==
::
++  decode-pack-with
  |=  [source=octs bases=(map oid:git object:git)]
  ^-  (unit decoded-pack)
  ?:  (lth p.source 32)  ~
  ?.  =((slice:git-codec source 0 4) (text:git-codec 'PACK'))  ~
  =/  version=(unit @)  (uint-be-at source 4 4)
  ?~  version  ~
  ?.  =(u.version 2)  ~
  =/  count=(unit @)  (uint-be-at source 8 4)
  ?~  count  ~
  =/  trailer-offset=@ud  (sub p.source 20)
  =/  prefix=octs  (slice:git-codec source 0 trailer-offset)
  =/  trailer=@  (rev 3 20 (cut 3 [trailer-offset 20] q.source))
  ?.  =(trailer (sha1-octs:git-codec prefix))  ~
  =/  entries=(unit (list packed-entry))
    (parse-entries source u.count trailer-offset)
  ?~  entries  ~
  =/  objects=(unit (map oid:git object:git))
    (resolve-entries u.entries bases)
  ?~  objects  ~
  `[[u.objects]]
::
++  decode-pack
  |=  source=octs
  ^-  (unit decoded-pack)
  (decode-pack-with source ~)
--
