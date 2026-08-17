::  Deterministic POSIX ustar archives for repository trees.
::
/-  git
/+  git-codec, git-tree
|%
+$  tar-header
  $:  name=@t
      mode=@t
      uid=@t
      gid=@t
      size=@t
      mtime=@t
      typeflag=@t
      linkname=@t
      uname=@t
      gname=@t
      devmajor=@t
      devminor=@t
      prefix=@t
  ==
::
++  sud-base
  |=  [value=@u base=@u]
  ^-  @t
  ?>  &((gth base 0) (lte base 10))
  ?:  =(0 value)  '0'
  %-  crip
  %-  flop
  |-  ^-  tape
  ?:(=(0 value) ~ [(add '0' (mod value base)) $(value (div value base))])
::
++  ud-oct  (curr sud-base 8)
::
++  pack
  |=  [field=@t length=@ud]
  ^-  octs
  ?>  (lte (met 3 field) length)
  [length field]
::
++  checksum
  |=  value=@
  ^-  @ud
  (roll (rip 3 value) add)
::
++  encode-header
  =|  check=(unit @t)
  |=  header=tar-header
  ^-  octs
  =/  fields=(list [@t @ud])
    :~  [name.header 100]
        [mode.header 8]
        [uid.header 8]
        [gid.header 8]
        [size.header 12]
        [mtime.header 12]
        [?^(check u.check '        ') 8]
        [typeflag.header 1]
        [linkname.header 100]
        ['ustar' 6]
        ['00' 2]
        [uname.header 32]
        [gname.header 32]
        [devmajor.header 8]
        [devminor.header 8]
        [prefix.header 155]
        ['' 12]
    ==
  =/  bytes=octs
    (join-all:git-codec (turn fields |=(field=[@t @ud] (pack field))))
  ?>  =(512 p.bytes)
  ?^  check  bytes
  $(check `(ud-oct (checksum q.bytes)))
::
++  split-path
  |=  file-path=path
  ^-  (unit [prefix=@t name=@t])
  =/  reversed=path  (flop file-path)
  =|  name-path=path
  |-
  ?~  reversed  ~
  =/  prefix-path=path  (flop t.reversed)
  =/  final-name=path  ?~(name-path [i.reversed ~] name-path)
  =/  prefix-text=@t  ?~(prefix-path '' (rsh [3 1] (spat prefix-path)))
  =/  name-text=@t  (rsh [3 1] (spat final-name))
  ?:  ?&  (lte (met 3 prefix-text) 155)
          (lte (met 3 name-text) 100)
      ==
    `[prefix-text name-text]
  $(reversed t.reversed, name-path [i.reversed name-path])
::
++  file-entry
  |=  [file-path=path mode=@t data=octs]
  ^-  (unit octs)
  =/  names=(unit [prefix=@t name=@t])  (split-path file-path)
  ?~  names  ~
  =/  symlink=?  =('120000' mode)
  =/  executable=?  =('100755' mode)
  =/  body=octs  ?:(symlink [0 0] data)
  =/  linkname=@t  ?:(symlink `@t`q.data '')
  ?:  (gth (met 3 linkname) 100)  ~
  =/  header=tar-header
    :*  name.u.names
        ?:(symlink '0000777' ?:(executable '0000755' '0000644'))
        '0000000'
        '0000000'
        (ud-oct p.body)
        '0'
        ?:(symlink '2' '0')
        linkname
        'urbit'
        'urbit'
        ''
        ''
        prefix.u.names
  ==
  =/  head=octs  (encode-header header)
  =/  padding=@ud  (mod (sub 512 (mod p.body 512)) 512)
  =/  padded=octs  [(add p.body padding) q.body]
  `(join:git-codec head padded)
::
++  archive
  |=  [objects=(map oid:git object:git) commit=oid:git]
  ^-  (unit octs)
  =/  files=(unit (map path flat-entry:git-tree))
    (flatten-commit-index:git-tree objects commit)
  ?~  files  ~
  ?:  (gth (lent ~(tap by u.files)) 10.000)  ~
  =/  remaining=(list [path flat-entry:git-tree])  ~(tap by u.files)
  =/  parts=(list octs)  ~
  =/  total=@ud  1.024
  |-
  ?~  remaining
    =/  result=octs
      `octs`(join-all:git-codec (weld (flop parts) ~[[1.024 0]]))
    `result
  =/  indexed=flat-entry:git-tree  +.i.remaining
  =/  object=(unit object:git)  (~(get by objects) oid.indexed)
  ?.  ?&(?=(^ object) =(%blob kind.u.object))  ~
  =/  entry=(unit octs)
    (file-entry -.i.remaining mode.indexed data.u.object)
  ?~  entry  ~
  =/  bytes=octs  +.entry
  =.  total  (add total p.bytes)
  ?:  (gth total 67.108.864)  ~
  $(remaining t.remaining, parts [bytes parts])
--
