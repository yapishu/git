::  Verify that Vere's %zlib-v0 jet is available and advances its cursor.
::
/+  git-codec, git-zlib
:-  %say
|=  *
:-  %noun
=/  line=octs  (text:git-codec 'The quick brown fox jumps over the lazy dog. ')
=/  expected=octs
  (join-all:git-codec (turn (gulf 1 20) |=(* line)))
=/  compressed=octs
  [61 0x1c.43a5.4701.8ada.98aa.3c55.1e2a.8c84.29eb.a7e4.a42a.5556.24e7.4a01.2852.2d4b.2fc8.5628.2dcd.2ac8.50af.cb48.53cf.2fca.2a48.56ce.4ccd.2c28.5548.c90b.0178]
=/  result  (mule |.((decompress-zlib:git-zlib [0 compressed])))
[ jetted=?=(%& -.result)
  output-matches=?:(?=(%& -.result) =(expected -.p.result) %.n)
  consumed-all=?:(?=(%& -.result) =(p.compressed pos.+.p.result) %.n)
]
