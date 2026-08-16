::  GitHub Smart HTTP and REST helpers.
::
/-  git
/+  git-codec, git-protocol
|%
++  github-refs
  $:  head=@t
      refs=(map @t oid:git)
  ==
::
++  json-at
  |=  [key=@t jon=json]
  ^-  (unit json)
  ?.  ?=(%o -.jon)  ~
  (~(get by p.jon) key)
::
++  string-at
  |=  [key=@t jon=json]
  ^-  (unit @t)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=(%s -.u.value)  ~
  `p.u.value
::
++  parse-decimal
  |=  text=@t
  ^-  (unit @ud)
  =/  chars=tape  (trip text)
  ?~  chars  ~
  =/  parse
    |=  [remaining=tape value=@ud]
    ^-  (unit @ud)
    ?~  remaining  `value
    ?.  ?&((gte i.remaining '0') (lte i.remaining '9'))  ~
    $(remaining t.remaining, value (add (mul value 10) (sub i.remaining '0')))
  (parse chars 0)
::
++  nat-at
  |=  [key=@t jon=json]
  ^-  (unit @ud)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=(%n -.u.value)  ~
  (parse-decimal p.u.value)
::
++  bool-at
  |=  [key=@t jon=json]
  ^-  (unit ?)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=(%b -.u.value)  ~
  `p.u.value
::
++  nested-string
  |=  [outer=@t inner=@t jon=json]
  ^-  (unit @t)
  =/  value=(unit json)  (json-at outer jon)
  ?~  value  ~
  (string-at inner u.value)
::
++  api-headers
  |=  token=(unit @t)
  ^-  (list [@t @t])
  =/  headers=(list [@t @t])
    :~  ['accept' 'application/vnd.github+json']
        ['x-github-api-version' '2022-11-28']
        ['user-agent' 'urbit-git']
    ==
  ?~  token  headers
  [['authorization' (rap 3 ~['Bearer ' u.token])] headers]
::
++  git-headers
  |=  [token=(unit @t) content-type=(unit @t)]
  ^-  (list [@t @t])
  =/  headers=(list [@t @t])
    :~  ['accept' ?~(content-type 'application/x-git-upload-pack-advertisement' 'application/x-git-upload-pack-result')]
        ['user-agent' 'urbit-git']
    ==
  =?  headers  ?=(^ content-type)
    [['content-type' u.content-type] headers]
  ?~  token  headers
  =/  credentials=octs  (text:git-codec (rap 3 ~['x-access-token:' u.token]))
  =/  encoded=@t  (en:base64:mimes:html credentials)
  [['authorization' (rap 3 ~['Basic ' encoded])] headers]
::
++  api-url
  |=  [owner=@t repository=@t suffix=@t]
  ^-  @t
  (rap 3 ~['https://api.github.com/repos/' owner '/' repository suffix])
::
++  git-url
  |=  [owner=@t repository=@t suffix=@t]
  ^-  @t
  (rap 3 ~['https://github.com/' owner '/' repository '.git' suffix])
::
++  byte-sequence-at
  |=  [source=octs offset=@ud needle=octs]
  ^-  ?
  ?:  (gth (add offset p.needle) p.source)  %.n
  =((slice:git-codec source offset p.needle) needle)
::
++  find-sequence
  |=  [source=octs needle=@t start=@ud]
  ^-  (unit @ud)
  =/  wanted=octs  (text:git-codec needle)
  |-
  ?:  (gth (add start p.wanted) p.source)  ~
  ?:  (byte-sequence-at source start wanted)  `start
  $(start +(start))
::
++  text-through
  |=  [source=octs start=@ud stops=(set @ud)]
  ^-  @t
  =/  cursor=@ud  start
  |-
  ?:  (gte cursor p.source)
    =/  result=octs  (slice:git-codec source start (sub cursor start))
    `@t`q.result
  ?:  (~(has in stops) (byte-at:git-codec source cursor))
    =/  result=octs  (slice:git-codec source start (sub cursor start))
    `@t`q.result
  $(cursor +(cursor))
::
++  advertised-refs
  |=  body=octs
  ^-  (unit github-refs)
  =/  packets=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  packets  ~
  =/  refs=(map @t oid:git)  ~
  =/  head-oid=(unit oid:git)  ~
  =/  symref=(unit @t)  ~
  =/  remaining=(list packet:git-codec)  u.packets
  |-
  ?~  remaining
    =/  chosen=(unit @t)
      ?^  symref
        ?:  (~(has by refs) u.symref)  symref
        ~
      =/  main=(unit oid:git)  (~(get by refs) 'refs/heads/main')
      ?:  ?&(?=(^ main) ?=(^ head-oid) =(u.main u.head-oid))  `'refs/heads/main'
      =/  master=(unit oid:git)  (~(get by refs) 'refs/heads/master')
      ?:  ?&(?=(^ master) ?=(^ head-oid) =(u.master u.head-oid))  `'refs/heads/master'
      =/  entries=(list [@t oid:git])  ~(tap by refs)
      ?~  entries  ~
      `-.i.entries
    ?~  chosen  ~
    `[[u.chosen refs]]
  =/  packet=packet:git-codec  i.remaining
  ?.  ?=(%data -.packet)
    $(remaining t.remaining)
  =/  payload=octs  payload.packet
  ?:  |((lth p.payload 42) !=(' ' (byte-at:git-codec payload 40)))
    $(remaining t.remaining)
  =/  parsed=(unit oid:git)  (oid-at:git-protocol payload 0)
  ?~  parsed  $(remaining t.remaining)
  =/  ref=@t  (text-through payload 41 (silt ~[0 10]))
  =?  head-oid  =('HEAD' ref)
    `u.parsed
  =?  refs  ?&  !=('HEAD' ref)
                 (valid-ref:git-protocol ref)
             ==
    (~(put by refs) ref u.parsed)
  =/  marker=(unit @ud)  (find-sequence payload 'symref=HEAD:' 41)
  =?  symref  ?=(^ marker)
    `(text-through payload (add u.marker 12) (silt ~[0 10 32]))
  $(remaining t.remaining)
::
++  upload-request
  |=  refs=(map @t oid:git)
  ^-  octs
  =/  wants=(set oid:git)  ~
  =/  entries=(list [@t oid:git])  ~(tap by refs)
  |-
  ?~  entries
    =/  ids=(list oid:git)  ~(tap in wants)
    =/  packets=(list octs)  ~
    =/  first=?  %.y
    =/  build
      |=  [remaining=(list oid:git) out=(list octs) first=?]
      ^-  (list octs)
      ?~  remaining  (flop out)
      =/  line=@t
        %+  rap  3
        :~  'want '  (oid-text:git-codec i.remaining)
            ?:(first ' no-progress ofs-delta include-tag\0a' '\0a')
        ==
      $(remaining t.remaining, out [(en-pkt:git-codec [%data (text:git-codec line)]) out], first %.n)
    =.  packets  (build ids ~ %.y)
    (join-all:git-codec (weld packets ~[(en-pkt:git-codec [%flush ~]) (en-pkt:git-codec [%data (text:git-codec 'done\0a')])]))
  =.  wants  (~(put in wants) +.i.entries)
  $(entries t.entries)
::
++  upload-pack
  |=  body=octs
  ^-  (unit octs)
  =/  remaining=octs  body
  |-
  ?:  (starts-with:git-protocol remaining 'PACK')  `remaining
  =/  next=(unit [pkt=packet:git-codec rest=octs])  (de-pkt:git-codec remaining)
  ?~  next  ~
  $(remaining rest.u.next)
::
++  forge-items
  |=  [jon=json include-pulls=?]
  ^-  (unit (list forge-item:git))
  ?.  ?=(%a -.jon)  ~
  =/  items=(list json)  p.jon
  =/  out=(list forge-item:git)  ~
  |-
  ?~  items  `(flop out)
  =/  item=json  i.items
  =/  pull=(unit json)  (json-at 'pull_request' item)
  ?:  !=(include-pulls ?=(^ pull))
    $(items t.items)
  =/  number=(unit @ud)  (nat-at 'number' item)
  =/  title=(unit @t)  (string-at 'title' item)
  =/  state=(unit @t)  (string-at 'state' item)
  =/  url=(unit @t)  (string-at 'html_url' item)
  =/  author=(unit @t)  (nested-string 'user' 'login' item)
  ?.  ?&(?=(^ number) ?=(^ title) ?=(^ state) ?=(^ url) ?=(^ author))
    $(items t.items)
  =/  draft=(unit ?)  (bool-at 'draft' item)
  =/  entry=forge-item:git  [u.number u.title u.state u.url u.author ?~(draft %.n u.draft)]
  $(items t.items, out [entry out])
--
