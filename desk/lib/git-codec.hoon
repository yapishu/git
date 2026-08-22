::  Binary-safe codecs for Git objects and pkt-line framing.
::
/-  git
|%
+$  packet
  $%  [%data payload=octs]
      [%flush ~]
      [%delim ~]
      [%response-end ~]
  ==
::
++  oct
  |=  byte=@
  ^-  octs
  ?>  (lth byte 256)
  [1 byte]
::
++  text
  |=  value=@t
  ^-  octs
  [(met 3 value) value]
::
++  join
  |=  [left=octs right=octs]
  ^-  octs
  [(add p.left p.right) (can 3 ~[[p.left q.left] [p.right q.right]])]
::
::  One +can over every piece.  Folding +join pairwise recopied the
::  accumulator once per piece, which is quadratic in the piece count.
::  +can truncates each piece to its own p and shifts by p, exactly as
::  the fold did, so a piece with p=0 still contributes nothing and a
::  piece whose atom is narrower than p still advances the offset by p.
::
++  join-all
  |=  parts=(list octs)
  ^-  octs
  :-  (roll parts |=([piece=octs total=@ud] (add p.piece total)))
  (can 3 parts)
::
++  byte-at
  |=  [bytes=octs offset=@ud]
  ^-  @ud
  ?>  (lth offset p.bytes)
  (cut 3 [offset 1] q.bytes)
::
++  slice
  |=  [bytes=octs offset=@ud count=@ud]
  ^-  octs
  ?>  (lte (add offset count) p.bytes)
  [count (cut 3 [offset count] q.bytes)]
::
++  hex-fixed
  |=  [width=@ud value=@]
  ^-  @t
  =/  alphabet=@t  '0123456789abcdef'
  =/  chars=tape  ~
  =/  left=@ud  width
  |-
  ?:  =(left 0)
    (crip chars)
  =/  digit=@ud  (mod value 16)
  =/  char=@tD  (cut 3 [digit 1] alphabet)
  $(value (div value 16), left (dec left), chars [char chars])
::
++  hex-nibble
  |=  byte=@ud
  ^-  (unit @ud)
  ?:  &((gte byte 48) (lte byte 57))
    `(sub byte 48)
  ?:  &((gte byte 97) (lte byte 102))
    `(add 10 (sub byte 97))
  ?:  &((gte byte 65) (lte byte 70))
    `(add 10 (sub byte 65))
  ~
::
++  hex4-value
  |=  bytes=octs
  ^-  (unit @ud)
  ?.  =(p.bytes 4)  ~
  =/  a=(unit @ud)  (hex-nibble (byte-at bytes 0))
  =/  b=(unit @ud)  (hex-nibble (byte-at bytes 1))
  =/  c=(unit @ud)  (hex-nibble (byte-at bytes 2))
  =/  d=(unit @ud)  (hex-nibble (byte-at bytes 3))
  ?~  a  ~
  ?~  b  ~
  ?~  c  ~
  ?~  d  ~
  `:(add (mul u.a 4.096) (mul u.b 256) (mul u.c 16) u.d)
::
++  en-pkt
  |=  =packet
  ^-  octs
  ?-  -.packet
      %flush         (text '0000')
      %delim         (text '0001')
      %response-end  (text '0002')
      %data
    ?>  (lte p.payload.packet 65.516)
    =/  total=@ud  (add 4 p.payload.packet)
    (join (text (hex-fixed 4 total)) payload.packet)
  ==
::
++  de-pkt
  |=  bytes=octs
  ^-  (unit [pkt=packet rest=octs])
  ?:  (lth p.bytes 4)  ~
  =/  length=(unit @ud)  (hex4-value (slice bytes 0 4))
  ?~  length  ~
  ?:  =(u.length 0)
    `[[%flush ~] (slice bytes 4 (sub p.bytes 4))]
  ?:  =(u.length 1)
    `[[%delim ~] (slice bytes 4 (sub p.bytes 4))]
  ?:  =(u.length 2)
    `[[%response-end ~] (slice bytes 4 (sub p.bytes 4))]
  ?:  (lth u.length 4)  ~
  ?:  (gth u.length 65.520)  ~
  ?:  (gth u.length p.bytes)  ~
  =/  payload-length=@ud  (sub u.length 4)
  =/  payload=octs  (slice bytes 4 payload-length)
  =/  rest=octs  (slice bytes u.length (sub p.bytes u.length))
  `[[%data payload] rest]
::
++  de-pkts
  |=  bytes=octs
  ^-  (unit (list packet))
  =/  packets=(list packet)  ~
  |-
  ?:  =(p.bytes 0)  `(flop packets)
  =/  next=(unit [pkt=packet rest=octs])  (de-pkt bytes)
  ?~  next  ~
  $(bytes rest.u.next, packets [pkt.u.next packets])
::
++  object-kind-text
  |=  kind=object-kind:git
  ^-  @t
  ?-  kind
      %blob    'blob'
      %tree    'tree'
      %commit  'commit'
      %tag     'tag'
  ==
::
++  canonical-object
  |=  [kind=object-kind:git data=octs]
  ^-  octs
  =/  size=@t  (crip ((d-co:co 1) p.data))
  =/  header=@t
    (rap 3 ~[(object-kind-text kind) ' ' size])
  (join-all ~[(text header) (oct 0) data])
::
++  object-oid
  |=  [kind=object-kind:git data=octs]
  ^-  oid:git
  `oid:git`(sha1-octs (canonical-object kind data))
::
++  sha1-octs
  |=  bytes=octs
  ^-  @
  ::  +sha-1l:sha consumes a big-endian $byts atom.  Git wire bytes and
  ::  $octs are little-endian atoms, so reverse exactly the declared width.
  ::  Keeping the explicit width preserves content ending in zero bytes.
  (sha-1l:sha [p.bytes (rev 3 p.bytes q.bytes)])
::
++  oid-text
  |=  oid=oid:git
  ^-  @t
  (hex-fixed 40 oid)
--
