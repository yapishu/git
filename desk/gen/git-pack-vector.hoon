::  Single-blob pack conformance vector.
::
/-  git
/+  git-codec, git-pack
:-  %say
|=  *
:-  %noun
=/  blob=object:git  [%blob (text:git-codec 'hello world\0a')]
=/  pack=octs  (encode-pack:git-pack ~[blob])
[p.pack q.pack]
