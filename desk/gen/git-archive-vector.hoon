::  Source archive mode and symlink conformance.
::
/-  git
/+  git-archive, git-clay, git-codec, git-tree
:-  %say
|=  *
:-  %noun
=/  link-data=octs  (text:git-codec 'script')
=/  script-data=octs  (text:git-codec '#!/bin/sh\0aecho archive\0a')
=/  link-oid=oid:git  (object-oid:git-codec %blob link-data)
=/  script-oid=oid:git  (object-oid:git-codec %blob script-data)
=/  objects=(map oid:git object:git)
  %-  malt
  :~  [link-oid [%blob link-data]]
      [script-oid [%blob script-data]]
  ==
=/  tree=[oid=oid:git objects=(map oid:git object:git)]
  %+  store-tree:git-tree
    :~  ['120000' 'link' link-oid]
        ['100755' 'script' script-oid]
    ==
  objects
=/  commit-data=octs
  %-  text:git-codec
  (rap 3 ~['tree ' (oid-text:git-codec oid.tree) '\0a'])
=/  commit-oid=oid:git  (object-oid:git-codec %commit commit-data)
=.  objects.tree  (~(put by objects.tree) commit-oid [%commit commit-data])
=/  archived=(unit octs)  (archive:git-archive objects.tree commit-oid)
?>  ?=(^ archived)
=/  tar=octs  u.archived
=/  link-first=?  =((text:git-codec 'link') (slice:git-codec tar 0 4))
?:  link-first
  ?>  =('2' (byte-at:git-codec tar 156))
  ?>  =((text:git-codec '0000777') (slice:git-codec tar 100 7))
  ?>  =((text:git-codec 'script') (slice:git-codec tar 157 6))
  ?>  =('0' (byte-at:git-codec tar 668))
  ?>  =((text:git-codec '0000755') (slice:git-codec tar 612 7))
  ?>  =(script-data (slice:git-codec tar 1.024 p.script-data))
  %.y
?>  =((text:git-codec 'script') (slice:git-codec tar 0 6))
?>  =('0' (byte-at:git-codec tar 156))
?>  =((text:git-codec '0000755') (slice:git-codec tar 100 7))
?>  =(script-data (slice:git-codec tar 512 p.script-data))
?>  =('2' (byte-at:git-codec tar 1.180))
?>  =((text:git-codec '0000777') (slice:git-codec tar 1.124 7))
?>  =((text:git-codec 'script') (slice:git-codec tar 1.181 6))
%.y
