::  GitHub Smart HTTP and REST helpers.
::
/-  git
/+  git-codec, git-pack, git-protocol
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
++  decimal
  |=  value=@ud
  ^-  @t
  (crip ((d-co:co 1) value))
::
++  detail-json
  |=  [jon=json pull=?]
  ^-  (unit json)
  =/  number=(unit @ud)  (nat-at 'number' jon)
  =/  title=(unit @t)  (string-at 'title' jon)
  =/  state=(unit @t)  (string-at 'state' jon)
  =/  url=(unit @t)  (string-at 'html_url' jon)
  =/  author=(unit @t)  (nested-string 'user' 'login' jon)
  ?.  ?&(?=(^ number) ?=(^ title) ?=(^ state) ?=(^ url) ?=(^ author))
    ~
  =/  body=(unit @t)  (string-at 'body' jon)
  =/  created=(unit @t)  (string-at 'created_at' jon)
  =/  updated=(unit @t)  (string-at 'updated_at' jon)
  =/  comments=(unit @ud)  (nat-at 'comments' jon)
  =/  draft=(unit ?)  (bool-at 'draft' jon)
  =/  merged=(unit ?)  (bool-at 'merged' jon)
  =/  mergeable=(unit ?)  (bool-at 'mergeable' jon)
  =/  additions=(unit @ud)  (nat-at 'additions' jon)
  =/  deletions=(unit @ud)  (nat-at 'deletions' jon)
  =/  changed=(unit @ud)  (nat-at 'changed_files' jon)
  =/  head-ref=(unit @t)  (nested-string 'head' 'ref' jon)
  =/  base-ref=(unit @t)  (nested-string 'base' 'ref' jon)
  =/  result=json
    %-  pairs:enjs:format
    :~  ['number' n+(decimal u.number)]
        ['title' s+u.title]
        ['state' s+u.state]
        ['url' s+u.url]
        ['author' s+u.author]
        ['body' s+?~(body '' u.body)]
        ['created' s+?~(created '' u.created)]
        ['updated' s+?~(updated '' u.updated)]
        ['comments' n+(decimal ?~(comments 0 u.comments))]
        ['pullRequest' b+pull]
        ['draft' b+?~(draft %.n u.draft)]
        ['merged' b+?~(merged %.n u.merged)]
        ['mergeable' b+?~(mergeable %.n u.mergeable)]
        ['mergeableKnown' b+?=(^ mergeable)]
        ['additions' n+(decimal ?~(additions 0 u.additions))]
        ['deletions' n+(decimal ?~(deletions 0 u.deletions))]
        ['changedFiles' n+(decimal ?~(changed 0 u.changed))]
        ['head' s+?~(head-ref '' u.head-ref)]
        ['base' s+?~(base-ref '' u.base-ref)]
    ==
  `result
::
++  file-detail-json
  |=  jon=json
  ^-  (unit json)
  =/  kind=(unit @t)  (string-at 'type' jon)
  =/  encoding=(unit @t)  (string-at 'encoding' jon)
  =/  content=(unit @t)  (string-at 'content' jon)
  =/  path=(unit @t)  (string-at 'path' jon)
  =/  sha=(unit @t)  (string-at 'sha' jon)
  =/  size=(unit @ud)  (nat-at 'size' jon)
  =/  url=(unit @t)  (string-at 'html_url' jon)
  ?.  ?&  ?=(^ kind)  =('file' u.kind)
          ?=(^ encoding)  =('base64' u.encoding)
          ?=(^ content)  ?=(^ path)  ?=(^ sha)  ?=(^ size)
          (lte u.size 1.048.576)
      ==
    ~
  =/  strip-whitespace
    |=  [remaining=tape out=tape]
    ^-  @t
    ?~  remaining  (crip out)
    ?:  ?|  =(9 i.remaining)
            =(10 i.remaining)
            =(13 i.remaining)
            =(32 i.remaining)
        ==
      $(remaining t.remaining)
    $(remaining t.remaining, out (snoc out i.remaining))
  =/  clean=@t  (strip-whitespace (trip u.content) ~)
  =/  decoded=(unit octs)  (de:base64:mimes:html clean)
  ?~  decoded  ~
  ?.  =(p.u.decoded u.size)  ~
  =/  result=json
    %-  pairs:enjs:format
    :~  ['path' s+u.path]
        ['sha' s+u.sha]
        ['size' n+(decimal u.size)]
        ['url' s+?~(url '' u.url)]
        ['content' s+(en:base64:mimes:html u.decoded)]
    ==
  `result
::
++  api-headers
  |=  token=(unit @t)
  ^-  (list [@t @t])
  =/  headers=(list [@t @t])
    :~  ['accept' 'application/vnd.github+json']
        ['x-github-api-version' '2022-11-28']
        ['user-agent' 'urgit']
    ==
  ?~  token  headers
  [['authorization' (rap 3 ~['Bearer ' u.token])] headers]
::
++  git-headers
  |=  [token=(unit @t) content-type=(unit @t)]
  ^-  (list [@t @t])
  =/  headers=(list [@t @t])
    :~  ['accept' ?~(content-type 'application/x-git-upload-pack-advertisement' 'application/x-git-upload-pack-result')]
        ['user-agent' 'urgit']
    ==
  =?  headers  ?=(^ content-type)
    [['content-type' u.content-type] headers]
  ?~  token  headers
  =/  credentials=octs  (text:git-codec (rap 3 ~['x-access-token:' u.token]))
  =/  encoded=@t  (en:base64:mimes:html credentials)
  [['authorization' (rap 3 ~['Basic ' encoded])] headers]
::
++  receive-headers
  |=  [token=(unit @t) content-type=(unit @t)]
  ^-  (list [@t @t])
  =/  headers=(list [@t @t])
    :~  ['accept' ?~(content-type 'application/x-git-receive-pack-advertisement' 'application/x-git-receive-pack-result')]
        ['user-agent' 'urgit']
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
++  receive-request
  |=  [old=(unit oid:git) new=oid:git ref=@t objects=(list object:git)]
  ^-  octs
  =/  old-text=@t  ?~(old zero-oid-text:git-protocol (oid-text:git-codec u.old))
  =/  line=octs
    %-  join-all:git-codec
    :~  (text:git-codec old-text)
        (text:git-codec ' ')
        (text:git-codec (oid-text:git-codec new))
        (text:git-codec ' ')
        (text:git-codec ref)
        (oct:git-codec 0)
        (text:git-codec 'report-status agent=urgit/0.1\0a')
    ==
  %-  join-all:git-codec
  :~  (en-pkt:git-codec [%data line])
      (en-pkt:git-codec [%flush ~])
      (encode-pack:git-pack objects)
  ==
::
++  receive-result
  |=  [body=octs ref=@t]
  ^-  (unit [ok=? message=@t])
  =/  packets=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  packets  ~
  =/  unpacked=?  %.n
  =/  updated=?  %.n
  =/  failure=(unit @t)  ~
  =/  remaining=(list packet:git-codec)  u.packets
  |-
  ?~  remaining
    ?^  failure  `[%.n u.failure]
    ?:  &(unpacked updated)  `[%.y '']
    ~
  =/  packet=packet:git-codec  i.remaining
  ?.  ?=(%data -.packet)
    $(remaining t.remaining)
  =/  payload=octs  payload.packet
  ?:  (starts-with:git-protocol payload 'unpack ok')
    $(remaining t.remaining, unpacked %.y)
  ?:  (starts-with:git-protocol payload 'unpack ')
    $(remaining t.remaining, failure `(text-through payload 7 (silt ~[10])))
  =/  ok-prefix=@t  (rap 3 ~['ok ' ref])
  ?:  (starts-with:git-protocol payload ok-prefix)
    $(remaining t.remaining, updated %.y)
  =/  ng-prefix=@t  (rap 3 ~['ng ' ref ' '])
  ?:  (starts-with:git-protocol payload ng-prefix)
    $(remaining t.remaining, failure `(text-through payload (lent (trip ng-prefix)) (silt ~[10])))
  $(remaining t.remaining)
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
