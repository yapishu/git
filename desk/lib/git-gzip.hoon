::  Inbound gzip request bodies (RFC 1952).
::
::  git compresses an upload-pack or a receive-pack request body once it
::  grows past 1,024 bytes and sets Content-Encoding: gzip.  The body is
::  one gzip member: a ten byte header, optional FEXTRA, FNAME, FCOMMENT
::  and FHCRC sections selected by the FLG byte, raw DEFLATE, then CRC32
::  and ISIZE as four little-endian bytes each.
::
::  ISIZE is the size limit +inflate-deflate needs, so the portable Hoon
::  inflater fits this format without a limit invented from outside it.
::  Vere's %zlib-v0 jet is not usable here: it validates the Adler-32 over
::  the decompressed output, which a caller cannot supply before it has
::  decompressed.  GZIP-REQUEST.md section 2 records the measurement.
::
/+  git-codec, git-inflate
|%
::  Neither the member nor its declared output may exceed this.  The
::  inflater is the portable one, at about 12 microseconds per output
::  byte, so the bound is really a bound on the ship time one request may
::  spend: a body at 262,144 bytes measured 4.4 seconds end to end, and
::  262,145 is refused in 32 milliseconds.  256 KiB carries about 5,200
::  want or have lines.  GZIP-REQUEST.md section 3 records the curve.
::
++  input-limit  262.144
::
::  Offset just past a NUL-terminated gzip header string.
::
++  after-nul
  |=  [bytes=octs offset=@ud]
  ^-  (unit @ud)
  ?:  (gte offset p.bytes)  ~
  ?:  =(0 (byte-at:git-codec bytes offset))  `+(offset)
  $(offset +(offset))
::
::  A little-endian field.  $octs atoms are already little-endian, so the
::  cut is the value.
::
++  uint-le
  |=  [bytes=octs offset=@ud width=@ud]
  ^-  (unit @ud)
  ?:  (gth (add offset width) p.bytes)  ~
  `(cut 3 [offset width] q.bytes)
::
::  Offset of the DEFLATE stream, after the header and every optional
::  section the FLG byte selects.  A FNAME nobody expected is a header
::  this arm must still walk past.
::
++  deflate-offset
  |=  body=octs
  ^-  (unit @ud)
  ?:  (lth p.body 18)  ~
  ?.  =(31 (byte-at:git-codec body 0))  ~
  ?.  =(139 (byte-at:git-codec body 1))  ~
  ?.  =(8 (byte-at:git-codec body 2))  ~
  =/  flg=@ud  (byte-at:git-codec body 3)
  ?.  =(0 (cut 0 [5 3] flg))  ~
  =/  after-extra=(unit @ud)
    ?.  =(1 (cut 0 [2 1] flg))  `10
    =/  xlen=(unit @ud)  (uint-le body 10 2)
    ?~  xlen  ~
    =/  next=@ud  (add 12 u.xlen)
    ?:  (gth next p.body)  ~
    `next
  ?~  after-extra  ~
  =/  after-name=(unit @ud)
    ?.  =(1 (cut 0 [3 1] flg))  after-extra
    (after-nul body u.after-extra)
  ?~  after-name  ~
  =/  after-comment=(unit @ud)
    ?.  =(1 (cut 0 [4 1] flg))  after-name
    (after-nul body u.after-name)
  ?~  after-comment  ~
  =/  end=@ud
    ?:  =(1 (cut 0 [1 1] flg))  (add u.after-comment 2)
    u.after-comment
  ?:  (gth (add end 8) p.body)  ~
  `end
::
::  Decompress one gzip member.  ~ for anything this arm does not accept:
::  a bad magic number, a compression method other than DEFLATE, a
::  reserved FLG bit, a truncated header or trailer, a declared output
::  over the limit, a DEFLATE stream that does not inflate, and a stream
::  whose output does not come out at exactly the declared size.
::
++  gunzip
  |=  body=octs
  ^-  (unit octs)
  ?:  (gth p.body input-limit)  ~
  =/  start=(unit @ud)  (deflate-offset body)
  ?~  start  ~
  =/  size=(unit @ud)  (uint-le body (sub p.body 4) 4)
  ?~  size  ~
  ?:  (gth u.size input-limit)  ~
  =/  stream=octs
    (slice:git-codec body u.start (sub (sub p.body 8) u.start))
  =/  out=(unit [state=bit-state:git-inflate output=octs])
    (inflate-deflate:git-inflate [[stream 0] u.size])
  ?~  out  ~
  ?.  =(u.size p.output.u.out)  ~
  `output.u.out
--
