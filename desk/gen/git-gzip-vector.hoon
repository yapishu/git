::  gzip request-body conformance vectors.
::
::  The three members below were produced by GNU zlib over the same
::  pkt-line upload-pack request: one with FLG 0, one carrying FEXTRA,
::  FNAME, FCOMMENT and FHCRC together, and one whose ISIZE was rewritten
::  to disagree with the stream.  Every negative case is a mutation of a
::  member that decodes, so a pass proves the check and not the fixture.
::
/+  git-codec, git-gzip
:-  %say
|=  *
:-  %noun
=/  payload=octs
  [113 0xa.656e.6f64.3930.3030.3030.3030.0a63.3630.3131.6437.3964.3565.3265.3464.6563.3633.6133.3564.3931.3331.3862.6236.3566.6564.3131.3463.3920.746e.6177.3233.3030.0a64.6164.3862.3832.3765.3866.3733.6265.6138.3064.6430.3033.3863.3465.3937.6162.6432.3135.6538.3162.3320.746e.6177.3233.3030]
=/  plain=octs
  [105 0x7127.811b.9601.7c79.baf0.27e3.3f73.2aa0.b103.8d9d.1373.6961.81a6.ae55.98d7.82ab.bb11.ff21.c48e.5e6a.e72e.b659.3c40.1137.6fb0.572a.1b43.9d4a.d3ef.de4f.b588.8f93.c060.b7db.80c4.e50a.bb79.0e59.0f78.f204.a855.5cc0.040c.40c3.0db9.cb35.0302.0000.0000.0008.8b1f]
=/  flags=octs
  [131 0x7127.811b.9601.7c79.baf0.27e3.3f73.2aa0.b103.8d9d.1373.6961.81a6.ae55.98d7.82ab.bb11.ff21.c48e.5e6a.e72e.b659.3c40.1137.6fb0.572a.1b43.9d4a.d3ef.de4f.b588.8f93.c060.b7db.80c4.e50a.bb79.0e59.0f78.f204.a855.5cc0.040c.40c3.0db9.cb35.295b.0065.746f.6e00.7165.722e.6461.6f6c.7075.6968.0002.4241.0006.0302.0000.0000.1e08.8b1f]
=/  wrong-size=octs
  [105 0x7227.811b.9601.7c79.baf0.27e3.3f73.2aa0.b103.8d9d.1373.6961.81a6.ae55.98d7.82ab.bb11.ff21.c48e.5e6a.e72e.b659.3c40.1137.6fb0.572a.1b43.9d4a.d3ef.de4f.b588.8f93.c060.b7db.80c4.e50a.bb79.0e59.0f78.f204.a855.5cc0.040c.40c3.0db9.cb35.0302.0000.0000.0008.8b1f]
=/  over-limit=octs
  [105 0x400.0127.811b.9601.7c79.baf0.27e3.3f73.2aa0.b103.8d9d.1373.6961.81a6.ae55.98d7.82ab.bb11.ff21.c48e.5e6a.e72e.b659.3c40.1137.6fb0.572a.1b43.9d4a.d3ef.de4f.b588.8f93.c060.b7db.80c4.e50a.bb79.0e59.0f78.f204.a855.5cc0.040c.40c3.0db9.cb35.0302.0000.0000.0008.8b1f]
::
::  One byte of the member, replaced.
::
=/  patch
  |=  [member=octs offset=@ud byte=@ud]
  ^-  octs
  :-  p.member
  %+  can  3
  :~  [offset (cut 3 [0 offset] q.member)]
      [1 byte]
      [(sub p.member +(offset)) (cut 3 [+(offset) (sub p.member +(offset))] q.member)]
  ==
::
=/  decoded=(unit octs)  (gunzip:git-gzip plain)
=/  decoded-flags=(unit octs)  (gunzip:git-gzip flags)
::  A member that decodes, and one whose optional sections all have to be
::  walked past, both give back the request byte for byte.
::
?>  =(`payload decoded)
?>  =(`payload decoded-flags)
::  The offsets in +deflate-offset are not the same offsets, so the two
::  members must agree with each other and not only with the payload.
::
?>  =(decoded decoded-flags)
::  Every rejection.
::
?>  =(~ (gunzip:git-gzip wrong-size))
?>  =(~ (gunzip:git-gzip over-limit))
?>  =(~ (gunzip:git-gzip (patch plain 0 30)))
?>  =(~ (gunzip:git-gzip (patch plain 1 138)))
?>  =(~ (gunzip:git-gzip (patch plain 2 9)))
?>  =(~ (gunzip:git-gzip (patch plain 3 32)))
?>  =(~ (gunzip:git-gzip (patch plain 3 8)))
?>  =(~ (gunzip:git-gzip (patch plain 20 0)))
?>  =(~ (gunzip:git-gzip (slice:git-codec plain 0 10)))
?>  =(~ (gunzip:git-gzip (slice:git-codec plain 0 (sub p.plain 8))))
?>  =(~ (gunzip:git-gzip (slice:git-codec plain 0 (sub p.plain 1))))
?>  =(~ (gunzip:git-gzip (slice:git-codec plain 0 17)))
?>  =(~ (gunzip:git-gzip payload))
?>  =(~ (gunzip:git-gzip [0 0]))
[%noun p.payload p.plain p.flags (mug decoded) %.y]
