::  Git object and pkt-line conformance vectors.
::
/+  git-codec
:-  %say
|=  *
:-  %noun
=/  body=octs  (text:git-codec 'hello world\0a')
=/  canonical=octs  (canonical-object:git-codec %blob body)
=/  oid  (object-oid:git-codec %blob body)
=/  framed=octs
  (en-pkt:git-codec [%data (text:git-codec 'want 3b18e512dba79e4c8300dd08aeb37f8e728b8dad\0a')])
=/  decoded  (de-pkt:git-codec framed)
[(oid-text:git-codec oid) (sha1-octs:git-codec canonical) framed decoded]
