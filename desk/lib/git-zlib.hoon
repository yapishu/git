::  Vere-backed zlib decompression.
::
::  The battery labels match Vere's %zlib-v0 jet.  The crashing Hoon body is
::  intentional: callers virtualize this arm and retain their portable Hoon
::  inflater as a fallback when the runtime does not provide the jet.
::
|%
+$  bays  [pos=@ud data=octs]
--
::
~%  %zlib-v0  ..part  ~
|%
++  decompress-zlib
  ~/  %decompress-zlib
  |=  sea=bays
  ^-  [octs bays]
  !!
--
