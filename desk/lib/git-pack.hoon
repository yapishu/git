::  Git pack v2 encoder using full objects and valid stored DEFLATE blocks.
::
/-  git
/+  git-codec
|%
++  uint-be
  |=  [width=@ud value=@]
  ^-  octs
  [width (rev 3 width value)]
::
++  uint-le
  |=  [width=@ud value=@]
  ^-  octs
  [width value]
::
++  object-type-code
  |=  kind=object-kind:git
  ^-  @ud
  ?-  kind
      %commit  1
      %tree    2
      %blob    3
      %tag     4
  ==
::
++  object-header
  |=  [kind=object-kind:git size=@ud]
  ^-  octs
  =/  rest=@ud  (div size 16)
  =/  first=@ud
    %+  add
      (mod size 16)
    (mul (object-type-code kind) 16)
  =?  first  (gth rest 0)  (add first 128)
  =/  bytes=(list octs)  ~[(oct:git-codec first)]
  |-
  ?:  =(rest 0)
    (join-all:git-codec (flop bytes))
  =/  next=@ud  (mod rest 128)
  =/  more=@ud  (div rest 128)
  =?  next  (gth more 0)  (add next 128)
  $(rest more, bytes [(oct:git-codec next) bytes])
::
++  adler32
  |=  data=octs
  ^-  @ud
  `@ud`(adler32:adler:checksum data)
::
++  stored-deflate
  |=  data=octs
  ^-  octs
  =/  blocks=(list octs)  ~
  =/  offset=@ud  0
  |-
  =/  remaining=@ud  (sub p.data offset)
  =/  size=@ud  (min 65.535 remaining)
  =/  final=?  =(size remaining)
  =/  block=octs
    %-  join-all:git-codec
    :~  (oct:git-codec ?:(final 1 0))
        (uint-le 2 size)
        (uint-le 2 (sub 65.535 size))
        (slice:git-codec data offset size)
    ==
  =.  blocks  [block blocks]
  ?:  final
    (join-all:git-codec (flop blocks))
  $(offset (add offset size))
::
++  zlib-store
  |=  data=octs
  ^-  octs
  %-  join-all:git-codec
  :~  [2 0x178]
      (stored-deflate data)
      (uint-be 4 (adler32 data))
  ==
::
++  object-entry
  |=  obj=object:git
  ^-  octs
  (join-all:git-codec ~[(object-header kind.obj p.data.obj) (zlib-store data.obj)])
::
++  pack-prefix
  |=  objects=(list object:git)
  ^-  octs
  =/  entries=(list octs)  (turn objects object-entry)
  %-  join-all:git-codec
  :~  (text:git-codec 'PACK')
      (uint-be 4 2)
      (uint-be 4 (lent objects))
      (join-all:git-codec entries)
  ==
::
++  encode-pack
  |=  objects=(list object:git)
  ^-  octs
  =/  prefix=octs  (pack-prefix objects)
  =/  digest=@  (sha1-octs:git-codec prefix)
  (join:git-codec prefix (uint-be 20 digest))
--
