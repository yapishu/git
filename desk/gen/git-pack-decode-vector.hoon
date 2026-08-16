::  Pack encoder/decoder round-trip vector.
::
/-  git
/+  git-codec, git-pack, git-pack-decode
:-  %say
|=  *
:-  %noun
=/  data=octs  (text:git-codec 'native pack ingestion\0a')
=/  object=object:git  [%blob data]
=/  oid=oid:git  (object-oid:git-codec %blob data)
=/  pack=octs  (encode-pack:git-pack ~[object])
=/  decoded=(unit decoded-pack:git-pack-decode)  (decode-pack:git-pack-decode pack)
[ decoded=?=(^ decoded)
  object-present=?&(?=(^ decoded) (~(has by objects.u.decoded) oid))
  exact=?&(?=(^ decoded) =(`object (~(get by objects.u.decoded) oid)))
]
