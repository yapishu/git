::  Native zlib and DEFLATE decoder.
::
/+  git-codec, git-pack
|%
+$  bit-state  [source=octs bit=@ud]
+$  huffman  [codes=(map @ @ud) max=@ud]
+$  inflated  [data=octs consumed=@ud]
::
++  read-bits
  |=  [count=@ud state=bit-state]
  ^-  (unit [value=@ state=bit-state])
  ?:  (gth (add bit.state count) (mul 8 p.source.state))  ~
  `[(cut 0 [bit.state count] q.source.state) state(bit (add bit.state count))]
::
++  align-byte
  |=  state=bit-state
  ^-  bit-state
  =/  remainder=@ud  (mod bit.state 8)
  ?:(=(remainder 0) state state(bit (add bit.state (sub 8 remainder))))
::
++  reverse-bits
  |=  [value=@ width=@ud]
  ^-  @
  =/  out=@  0
  =/  index=@ud  0
  |-
  ?:  =(index width)  out
  $(out (add (mul out 2) (cut 0 [index 1] value)), index +(index))
::
++  huffman-key
  |=  [length=@ud code=@]
  ^-  @
  (add (mul length 65.536) code)
::
++  build-huffman
  |=  lengths=(list @ud)
  ^-  (unit huffman)
  =/  counts=(map @ud @ud)  ~
  =/  max=@ud  0
  =/  scan=(list @ud)  lengths
  |-
  ?^  scan
    =/  length=@ud  i.scan
    =?  counts  !=(length 0)
      (~(put by counts) length (add 1 (fall (~(get by counts) length) 0)))
    =?  max  (gth length max)  length
    $(scan t.scan)
  ?:  =(max 0)  ~
  =/  next=(map @ud @ud)  ~
  =/  code=@ud  0
  =/  bits=@ud  1
  |-
  ?:  (gth bits max)
    =/  table=(map @ @ud)  ~
    =/  symbol=@ud  0
    =/  remaining=(list @ud)  lengths
    |-
    ?~  remaining  `[table max]
    =/  length=@ud  i.remaining
    ?:  =(length 0)
      $(symbol +(symbol), remaining t.remaining)
    =/  assigned=@ud  (need (~(get by next) length))
    =/  reversed=@  (reverse-bits assigned length)
    =.  table  (~(put by table) (huffman-key length reversed) symbol)
    =.  next  (~(put by next) length (add 1 assigned))
    $(symbol +(symbol), remaining t.remaining)
  =/  previous=@ud  (fall (~(get by counts) (dec bits)) 0)
  =.  code  (mul (add code previous) 2)
  =.  next  (~(put by next) bits code)
  $(bits +(bits))
::
++  decode-symbol
  |=  [table=huffman state=bit-state]
  ^-  (unit [symbol=@ud state=bit-state])
  =/  length=@ud  1
  =/  code=@  0
  |-
  ?:  (gth length max.table)  ~
  =/  read=(unit [value=@ state=bit-state])  (read-bits 1 state)
  ?~  read  ~
  =.  code  (add code (mul value.u.read (bex (dec length))))
  =/  symbol=(unit @ud)  (~(get by codes.table) (huffman-key length code))
  ?^  symbol  `[u.symbol state.u.read]
  $(length +(length), state state.u.read)
::
++  fixed-literal-lengths
  ^-  (list @ud)
  =/  symbol=@ud  0
  =/  out=(list @ud)  ~
  |-
  ?:  =(symbol 288)  (flop out)
  =/  length=@ud
    ?:  (lte symbol 143)  8
    ?:  (lte symbol 255)  9
    ?:  (lte symbol 279)  7
    8
  $(symbol +(symbol), out [length out])
::
++  repeat-list
  |=  [count=@ud value=@ud out=(list @ud)]
  ^-  (list @ud)
  ?:  =(count 0)  out
  $(count (dec count), out [value out])
::
++  fixed-distance-lengths
  ^-  (list @ud)
  (repeat-list 32 5 ~)
::
++  dynamic-tables
  |=  state=bit-state
  ^-  (unit [literal=huffman distance=huffman state=bit-state])
  =/  a=(unit [value=@ state=bit-state])  (read-bits 5 state)
  ?~  a  ~
  =/  hlit=@ud  (add 257 value.u.a)
  =/  b=(unit [value=@ state=bit-state])  (read-bits 5 state.u.a)
  ?~  b  ~
  =/  hdist=@ud  (add 1 value.u.b)
  =/  c=(unit [value=@ state=bit-state])  (read-bits 4 state.u.b)
  ?~  c  ~
  =/  hclen=@ud  (add 4 value.u.c)
  =/  order=(list @ud)  ~[16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15]
  =/  code-map=(map @ud @ud)  ~
  =/  index=@ud  0
  =/  cursor=bit-state  state.u.c
  |-
  ?:  =(index hclen)
    =/  code-lengths=(list @ud)  ~
    =/  symbol=@ud  0
    |-
    ?:  =(symbol 19)
      =/  code-table=(unit huffman)  (build-huffman (flop code-lengths))
      ?~  code-table  ~
      =/  total=@ud  (add hlit hdist)
      =/  lengths=(list @ud)  ~
      =/  produced=@ud  0
      =/  stream=bit-state  cursor
      |-
      ?:  =(produced total)
        =/  all=(list @ud)  (flop lengths)
        =/  literal=(unit huffman)  (build-huffman (scag hlit all))
        ?~  literal  ~
        =/  distance=(unit huffman)  (build-huffman (slag hlit all))
        ?~  distance  ~
        `[[u.literal u.distance stream]]
      ?:  (gth produced total)  ~
      =/  decoded=(unit [symbol=@ud state=bit-state])  (decode-symbol u.code-table stream)
      ?~  decoded  ~
      =/  code=@ud  symbol.u.decoded
      ?:  (lte code 15)
        $(lengths [code lengths], produced +(produced), stream state.u.decoded)
      ?:  =(code 16)
        ?~  lengths  ~
        =/  extra=(unit [value=@ state=bit-state])  (read-bits 2 state.u.decoded)
        ?~  extra  ~
        =/  count=@ud  (add 3 value.u.extra)
        ?:  (gth (add produced count) total)  ~
        $(lengths (repeat-list count i.lengths lengths), produced (add produced count), stream state.u.extra)
      ?:  =(code 17)
        =/  extra=(unit [value=@ state=bit-state])  (read-bits 3 state.u.decoded)
        ?~  extra  ~
        =/  count=@ud  (add 3 value.u.extra)
        ?:  (gth (add produced count) total)  ~
        $(lengths (repeat-list count 0 lengths), produced (add produced count), stream state.u.extra)
      ?:  =(code 18)
        =/  extra=(unit [value=@ state=bit-state])  (read-bits 7 state.u.decoded)
        ?~  extra  ~
        =/  count=@ud  (add 11 value.u.extra)
        ?:  (gth (add produced count) total)  ~
        $(lengths (repeat-list count 0 lengths), produced (add produced count), stream state.u.extra)
      ~
    $(code-lengths [(fall (~(get by code-map) symbol) 0) code-lengths], symbol +(symbol))
  =/  next=(unit [value=@ state=bit-state])  (read-bits 3 cursor)
  ?~  next  ~
  =.  code-map  (~(put by code-map) (snag index order) value.u.next)
  $(index +(index), cursor state.u.next)
::
++  length-base
  ^-  (list @ud)
  ~[3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227 258]
::
++  length-extra
  ^-  (list @ud)
  ~[0 0 0 0 0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 0]
::
++  distance-base
  ^-  (list @ud)
  ~[1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1.025 1.537 2.049 3.073 4.097 6.145 8.193 12.289 16.385 24.577]
::
++  distance-extra
  ^-  (list @ud)
  ~[0 0 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13]
::
++  append-byte
  |=  [data=octs byte=@ud]
  ^-  octs
  [(add p.data 1) (can 3 ~[[p.data q.data] [1 byte]])]
::
++  copy-distance
  |=  [data=octs distance=@ud count=@ud]
  ^-  (unit octs)
  ?:  ?|(=(distance 0) (gth distance p.data))  ~
  =/  remaining=@ud  count
  =/  out=octs  data
  |-
  ?:  =(remaining 0)  `out
  =/  byte=@ud  (cut 3 [(sub p.out distance) 1] q.out)
  $(remaining (dec remaining), out (append-byte out byte))
::
++  compressed-block
  |=  [literal=huffman distance=huffman state=bit-state output=octs limit=@ud]
  ^-  (unit [state=bit-state output=octs])
  =/  cursor=bit-state  state
  =/  out=octs  output
  |-
  =/  decoded=(unit [symbol=@ud state=bit-state])  (decode-symbol literal cursor)
  ?~  decoded  ~
  =/  symbol=@ud  symbol.u.decoded
  ?:  (lth symbol 256)
    ?:  (gte p.out limit)  ~
    $(cursor state.u.decoded, out (append-byte out symbol))
  ?:  =(symbol 256)  `[[state.u.decoded out]]
  ?:  (gth symbol 285)  ~
  =/  length-index=@ud  (sub symbol 257)
  =/  extra-count=@ud  (snag length-index length-extra)
  =/  extra=(unit [value=@ state=bit-state])  (read-bits extra-count state.u.decoded)
  ?~  extra  ~
  =/  length=@ud  (add (snag length-index length-base) value.u.extra)
  =/  dist-symbol=(unit [symbol=@ud state=bit-state])  (decode-symbol distance state.u.extra)
  ?~  dist-symbol  ~
  ?:  (gth symbol.u.dist-symbol 29)  ~
  =/  dist-index=@ud  symbol.u.dist-symbol
  =/  dist-extra-count=@ud  (snag dist-index distance-extra)
  =/  dist-extra=(unit [value=@ state=bit-state])  (read-bits dist-extra-count state.u.dist-symbol)
  ?~  dist-extra  ~
  =/  distance-value=@ud  (add (snag dist-index distance-base) value.u.dist-extra)
  ?:  (gth (add p.out length) limit)  ~
  =/  copied=(unit octs)  (copy-distance out distance-value length)
  ?~  copied  ~
  $(cursor state.u.dist-extra, out u.copied)
::
++  inflate-deflate
  |=  [state=bit-state limit=@ud]
  ^-  (unit [state=bit-state output=octs])
  =/  cursor=bit-state  state
  =/  output=octs  [0 0]
  |-
  =/  final-read=(unit [value=@ state=bit-state])  (read-bits 1 cursor)
  ?~  final-read  ~
  =/  type-read=(unit [value=@ state=bit-state])  (read-bits 2 state.u.final-read)
  ?~  type-read  ~
  =/  final=?  =(value.u.final-read 1)
  =/  block-type=@ud  value.u.type-read
  ?:  =(block-type 0)
    =/  aligned=bit-state  (align-byte state.u.type-read)
    =/  length-read=(unit [value=@ state=bit-state])  (read-bits 16 aligned)
    ?~  length-read  ~
    =/  inverse-read=(unit [value=@ state=bit-state])  (read-bits 16 state.u.length-read)
    ?~  inverse-read  ~
    ?.  =(value.u.inverse-read (mix 65.535 value.u.length-read))  ~
    =/  length=@ud  value.u.length-read
    ?:  (gth (add p.output length) limit)  ~
    =/  byte-offset=@ud  (div bit.state.u.inverse-read 8)
    ?:  (gth (add byte-offset length) p.source.state.u.inverse-read)  ~
    =/  chunk=octs  (slice:git-codec source.state.u.inverse-read byte-offset length)
    =.  output  (join:git-codec output chunk)
    =.  cursor  state.u.inverse-read(bit (add bit.state.u.inverse-read (mul length 8)))
    ?:  final  `[cursor output]
    $
  ?:  =(block-type 3)  ~
  =/  tables=(unit [literal=huffman distance=huffman state=bit-state])
    ?:  =(block-type 1)
      =/  literal=(unit huffman)  (build-huffman fixed-literal-lengths)
      ?~  literal  ~
      =/  distance=(unit huffman)  (build-huffman fixed-distance-lengths)
      ?~  distance  ~
      `[[u.literal u.distance state.u.type-read]]
    (dynamic-tables state.u.type-read)
  ?~  tables  ~
  =/  decoded=(unit [state=bit-state output=octs])
    (compressed-block literal.u.tables distance.u.tables state.u.tables output limit)
  ?~  decoded  ~
  =.  cursor  state.u.decoded
  =.  output  output.u.decoded
  ?:  final  `[cursor output]
  $
::
++  zlib-inflate
  |=  [source=octs expected=@ud]
  ^-  (unit inflated)
  ?:  (lth p.source 6)  ~
  =/  cmf=@ud  (byte-at:git-codec source 0)
  =/  flg=@ud  (byte-at:git-codec source 1)
  ?.  =(8 (mod cmf 16))  ~
  ?.  =(0 (mod (add (mul cmf 256) flg) 31))  ~
  ?:  =(1 (cut 0 [5 1] flg))  ~
  =/  decoded=(unit [state=bit-state output=octs])
    (inflate-deflate [[(sub p.source 2) (cut 3 [2 (sub p.source 2)] q.source)] 0] expected)
  ?~  decoded  ~
  ?.  =(p.output.u.decoded expected)  ~
  =/  aligned=bit-state  (align-byte state.u.decoded)
  =/  deflate-bytes=@ud  (div bit.aligned 8)
  =/  checksum-offset=@ud  (add 2 deflate-bytes)
  ?:  (gth (add checksum-offset 4) p.source)  ~
  =/  expected-adler=@ud  (rev 3 4 (cut 3 [checksum-offset 4] q.source))
  ?.  =(expected-adler (adler32:git-pack output.u.decoded))  ~
  `[[output.u.decoded (add checksum-offset 4)]]
--
