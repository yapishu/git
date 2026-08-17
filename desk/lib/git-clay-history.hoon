::  Native Clay revision metadata for bound Git repositories.
::
|%
+$  revision
  $:  number=@ud
      tako=tako:clay
      timestamp=@da
  ==
::
+$  history
  $:  latest=@ud
      revisions=(list revision)
  ==
::
++  desk-domo
  |=  [who=@p desk-name=desk when=@da]
  ^-  (unit domo:clay)
  %-  mole
  |.(.^(domo:clay %cv /(scot %p who)/[desk-name]/(scot %da when)))
::
++  revision-meta
  |=  [who=@p desk-name=desk number=@ud =domo:clay]
  ^-  (unit revision)
  =/  tako=(unit tako:clay)  (~(get by hit.domo) number)
  ?~  tako  ~
  =/  cass=(unit cass:clay)
    %-  mole
    |.(.^(cass:clay %cw /(scot %p who)/[desk-name]/(scot %ud number)))
  ?~  cass  ~
  `[number u.tako da.u.cass]
::
++  desk-history
  |=  [who=@p desk-name=desk when=@da limit=@ud]
  ^-  (unit history)
  =/  domo=(unit domo:clay)  (desk-domo who desk-name when)
  ?~  domo  ~
  =/  latest=@ud  let.u.domo
  =/  number=@ud  latest
  =/  entries=(list revision)  ~
  =/  count=@ud  0
  |-
  ?:  |(=(0 number) (gte count limit))
    `[latest (flop entries)]
  =/  entry=(unit revision)  (revision-meta who desk-name number u.domo)
  $(number (dec number), entries ?~(entry entries [u.entry entries]), count ?~(entry count +(count)))
::
++  revision-yaki
  |=  [who=@p desk-name=desk number=@ud tako=tako:clay]
  ^-  (unit yaki:clay)
  %-  mole
  |.(.^(yaki:clay %cs /(scot %p who)/[desk-name]/(scot %ud number)/yaki/(scot %uv tako)))
::
++  revision-page
  |=  [who=@p desk-name=desk number=@ud lobe=lobe:clay]
  ^-  (unit page)
  %-  mole
  |.(.^(page %cs /(scot %p who)/[desk-name]/(scot %ud number)/blob/(scot %uv lobe)))
--
