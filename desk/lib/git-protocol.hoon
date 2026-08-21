::  Git protocol v0/v1 reference advertisement.
::
/-  git
/+  git-codec
|%
++  starts-with
  |=  [bytes=octs prefix=@t]
  ^-  ?
  =/  width=@ud  (met 3 prefix)
  ?:  (lth p.bytes width)  %.n
  =((slice:git-codec bytes 0 width) [width prefix])
::
++  contains-text
  |=  [bytes=octs needle=@t]
  ^-  ?
  =/  width=@ud  (met 3 needle)
  ?:  =(width 0)  %.y
  =/  offset=@ud  0
  |-
  ?:  (gth (add offset width) p.bytes)  %.n
  ?:  =((slice:git-codec bytes offset width) [width needle])  %.y
  $(offset +(offset))
::
++  oid-at
  |=  [bytes=octs offset=@ud]
  ^-  (unit oid:git)
  ?:  (lth p.bytes (add offset 40))  ~
  =/  value=@  0
  =/  index=@ud  0
  |-
  ?:  =(index 40)  `value
  =/  nibble=(unit @ud)
    (hex-nibble:git-codec (byte-at:git-codec bytes (add offset index)))
  ?~  nibble  ~
  $(value (add (mul value 16) u.nibble), index +(index))
::
++  decimal-at
  |=  [bytes=octs offset=@ud]
  ^-  (unit @ud)
  =/  value=@ud  0
  =/  seen=?  %.n
  |-
  ?:  (gte offset p.bytes)  ?:(seen `value ~)
  =/  byte=@ud  (byte-at:git-codec bytes offset)
  ?:  ?|(=(byte 0) =(byte 10) =(byte 32))  ?:(seen `value ~)
  ?.  &((gte byte '0') (lte byte '9'))  ~
  $(offset +(offset), value (add (mul value 10) (sub byte '0')), seen %.y)
::
++  parse-upload-request
  |=  body=octs
  ^-  (unit upload-request:git)
  =/  decoded=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  decoded  ~
  =/  wants=(set oid:git)  ~
  =/  haves=(set oid:git)  ~
  =/  done=?  %.n
  =/  depth=(unit @ud)  ~
  =/  shallow=(set oid:git)  ~
  =/  deepen-relative=?  %.n
  =/  filter=(unit upload-filter:git)  ~
  =/  packets=(list packet:git-codec)  u.decoded
  |-
  ?~  packets  `[wants haves done depth shallow deepen-relative filter]
  =/  pkt=packet:git-codec  i.packets
  ?.  ?=(%data -.pkt)
    $(packets t.packets)
  =/  payload=octs  payload.pkt
  ?:  (starts-with payload 'want ')
    =/  parsed=(unit oid:git)  (oid-at payload 5)
    ?~  parsed  ~
    %=  $
      packets         t.packets
      wants           (~(put in wants) u.parsed)
      deepen-relative  |(deepen-relative (contains-text payload 'deepen-relative'))
    ==
  ?:  (starts-with payload 'have ')
    =/  parsed=(unit oid:git)  (oid-at payload 5)
    ?~  parsed  ~
    $(packets t.packets, haves (~(put in haves) u.parsed))
  ?:  (starts-with payload 'shallow ')
    =/  parsed=(unit oid:git)  (oid-at payload 8)
    ?~  parsed  ~
    $(packets t.packets, shallow (~(put in shallow) u.parsed))
  ?:  (starts-with payload 'deepen ')
    =/  parsed=(unit @ud)  (decimal-at payload 7)
    ?.  ?&(?=(^ parsed) (gth u.parsed 0) (lte u.parsed 2.147.483.647))  ~
    $(packets t.packets, depth `u.parsed)
  ?:  (starts-with payload 'deepen-relative')
    $(packets t.packets, deepen-relative %.y)
  ?:  (starts-with payload 'filter blob:none')
    $(packets t.packets, filter `[%blob-none])
  ?:  (starts-with payload 'filter blob:limit=')
    =/  parsed=(unit @ud)  (decimal-at payload 18)
    ?~  parsed  ~
    $(packets t.packets, filter `[%blob-limit u.parsed])
  ?:  (starts-with payload 'done\0a')
    $(packets t.packets, done %.y)
  $(packets t.packets)
::
++  zero-oid
  |=  bytes=octs
  ^-  ?
  ?.  =(40 p.bytes)  %.n
  =/  index=@ud  0
  |-
  ?:  =(index 40)  %.y
  ?.  =('0' (byte-at:git-codec bytes index))  %.n
  $(index +(index))
::
++  parsed-oid
  |=  [bytes=octs offset=@ud]
  ^-  (unit (unit oid:git))
  ?:  (lth p.bytes (add offset 40))  ~
  =/  raw=octs  (slice:git-codec bytes offset 40)
  ?:  (zero-oid raw)  `~
  =/  parsed=(unit oid:git)  (oid-at bytes offset)
  ?~  parsed  ~
  ``u.parsed
::
++  valid-ref-char
  |=  char=@tD
  ^-  ?
  ?:  |(&((gte char 'a') (lte char 'z')) &((gte char 'A') (lte char 'Z')))  %.y
  ?:  &((gte char '0') (lte char '9'))  %.y
  ?|  =(char '-')  =(char '_')  =(char '.')  =(char '/')
  ==
::
++  contains-pair
  |=  [value=tape left=@tD right=@tD]
  ^-  ?
  ?~  value  %.n
  ?~  t.value  %.n
  ?:  =(i.value left)
    ?:  =(i.t.value right)  %.y
    $(value t.value)
  $(value t.value)
::
++  ends-with-text
  |=  [value=tape suffix=tape]
  ^-  ?
  ?:  (gth (lent suffix) (lent value))  %.n
  =(suffix (slag (sub (lent value) (lent suffix)) value))
::
++  valid-ref
  |=  ref=@t
  ^-  ?
  =/  chars=tape  (trip ref)
  ?.  ?|  =((scag 11 chars) "refs/heads/")
          =((scag 10 chars) "refs/tags/")
      ==
    %.n
  ?:  ?|  =(chars "refs/heads/")
          =(chars "refs/tags/")
      ==
    %.n
  ?.  (levy chars valid-ref-char)  %.n
  ?:  ?|  (contains-pair chars '/' '/')
          (contains-pair chars '.' '.')
          (ends-with-text chars "/")
          (ends-with-text chars ".")
          (ends-with-text chars ".lock")
      ==
    %.n
  %.y
::
++  parse-receive-command
  |=  payload=octs
  ^-  (unit receive-command:git)
  ?:  (lth p.payload 84)  ~
  ?.  =(' ' (byte-at:git-codec payload 40))  ~
  ?.  =(' ' (byte-at:git-codec payload 81))  ~
  =/  old=(unit (unit oid:git))  (parsed-oid payload 0)
  =/  new=(unit (unit oid:git))  (parsed-oid payload 41)
  ?~  old  ~
  ?~  new  ~
  ::  The ref runs from byte 82 to a NUL, a line feed, or the end of the
  ::  payload.  End-of-payload is a real terminator: git appends the
  ::  capability list after a NUL on the first command line only, so
  ::  every later line is <old> SP <new> SP <ref> and simply stops.
  ::  Treating the end as a parse failure rejected any push of more than
  ::  one ref.  The terminator set is the same rule for every line.
  ::
  =/  cursor=@ud  82
  |-
  =/  terminated=?
    ?:  (gte cursor p.payload)  %.y
    =/  byte=@ud  (byte-at:git-codec payload cursor)
    ?|  =(byte 0)
        =(byte 10)
    ==
  ?.  terminated
    $(cursor +(cursor))
  =/  length=@ud  (sub cursor 82)
  ?:  =(length 0)  ~
  =/  ref-bytes=octs  (slice:git-codec payload 82 length)
  =/  ref=@t  q.ref-bytes
  ?.  (valid-ref ref)  ~
  `[[u.old u.new ref]]
::
::  A receive-pack body of one flush packet and nothing else is git's
::  probe, sent ahead of any request larger than http.postBuffer to
::  check auth and readiness before it commits to the upload.  It asks
::  for no ref update, so it is not a receive-request and must not be
::  parsed as one; the caller answers it before any policy runs.
::
++  receive-probe
  |=  body=octs
  ^-  ?
  =/  next=(unit [pkt=packet:git-codec rest=octs])
    (de-pkt:git-codec body)
  ?~  next  %.n
  ?.  ?=(%flush -.pkt.u.next)  %.n
  =(0 p.rest.u.next)
::
++  parse-receive-request
  |=  body=octs
  ^-  (unit receive-request:git)
  =/  commands=(list receive-command:git)  ~
  =/  remaining=octs  body
  |-
  =/  next=(unit [pkt=packet:git-codec rest=octs])
    (de-pkt:git-codec remaining)
  ?~  next  ~
  ?-  -.pkt.u.next
      %data
    =/  command=(unit receive-command:git)
      (parse-receive-command payload.pkt.u.next)
    ?~  command  ~
    $(remaining rest.u.next, commands [u.command commands])
  ::
      %flush
    ?:  =(0 (lent commands))  ~
    `[(flop commands) rest.u.next]
  ::
      %delim         ~
      %response-end  ~
  ==
::
++  zero-oid-text
  '0000000000000000000000000000000000000000'
::
++  capabilities
  |=  service=@t
  ^-  @t
  ?:  =('git-upload-pack' service)
    'shallow deepen-relative filter allow-reachable-sha1-in-want agent=urgit/0.1'
  'report-status delete-refs no-thin agent=urgit/0.1'
::
++  v2-command
  |=  body=octs
  ^-  (unit @tas)
  =/  decoded=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  decoded  ~
  =/  packets=(list packet:git-codec)  u.decoded
  |-
  ?~  packets  ~
  =/  pkt=packet:git-codec  i.packets
  ?:  ?=(%data -.pkt)
    ?:  (starts-with payload.pkt 'command=ls-refs')  `%ls-refs
    ?:  (starts-with payload.pkt 'command=fetch')  `%fetch
    ?:  (starts-with payload.pkt 'command=object-info')  `%object-info
    $(packets t.packets)
  $(packets t.packets)
::
++  v2-has-line
  |=  [body=octs line=@t]
  ^-  ?
  =/  decoded=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  decoded  %.n
  %+  lien  u.decoded
  |=  pkt=packet:git-codec
  ?&  ?=(%data -.pkt)
      =((text:git-codec line) payload.pkt)
  ==
::
++  v2-capability-advertisement
  ^-  octs
  %-  join-all:git-codec
  %+  weld
    %+  turn
      :~  'version 2\0a'
          'agent=urgit/0.1\0a'
          'ls-refs\0a'
          'fetch=shallow filter\0a'
          'object-info=size\0a'
          'object-format=sha1\0a'
      ==
    |=(line=@t (en-pkt:git-codec [%data (text:git-codec line)]))
  ~[(en-pkt:git-codec [%flush ~])]
::
++  v2-ref-pkt
  |=  [oid=oid:git ref=@t attributes=@t]
  ^-  octs
  (en-pkt:git-codec [%data (text:git-codec (rap 3 ~[(oid-text:git-codec oid) ' ' ref attributes '\0a']))])
::
++  v2-ls-refs
  |=  [repo=repository:git request=octs]
  ^-  octs
  =/  symrefs=?  (v2-has-line request 'symrefs\0a')
  =/  peel=?  (v2-has-line request 'peel\0a')
  =/  head-oid=(unit oid:git)  (resolve-head repo)
  =/  packets=(list octs)  ~
  =?  packets  ?=(^ head-oid)
    =/  attributes=@t
      ?:(symrefs (rap 3 ~[' symref-target:' head.repo]) '')
    ~[(v2-ref-pkt u.head-oid 'HEAD' attributes)]
  =/  entries=(list [@t oid:git])  ~(tap by refs.repo)
  |-
  ?~  entries
    (join-all:git-codec (weld (flop packets) ~[(en-pkt:git-codec [%flush ~])]))
  =/  attributes=@t  ''
  =?  attributes  peel
    =/  peeled=(unit oid:git)  (peeled-tag objects.repo +.i.entries)
    ?~(peeled '' (rap 3 ~[' peeled:' (oid-text:git-codec u.peeled)]))
  %=  $
    entries  t.entries
    packets  [(v2-ref-pkt +.i.entries -.i.entries attributes) packets]
  ==
::
++  v2-sideband-pack
  |=  pack=octs
  ^-  octs
  =/  offset=@ud  0
  =/  packets=(list octs)  ~
  |-
  ?:  (gte offset p.pack)
    (join-all:git-codec (flop packets))
  =/  width=@ud  (min 65.515 (sub p.pack offset))
  =/  chunk=octs  (slice:git-codec pack offset width)
  =/  payload=octs  (join:git-codec (oct:git-codec 1) chunk)
  $(offset (add offset width), packets [(en-pkt:git-codec [%data payload]) packets])
::
++  v2-object-info-oids
  |=  body=octs
  ^-  (unit (list oid:git))
  =/  decoded=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  decoded  ~
  =/  packets=(list packet:git-codec)  u.decoded
  =/  size=?  %.n
  =/  oids=(list oid:git)  ~
  |-
  ?~  packets
    ?.  ?&(size !=(~ oids))  ~
    `(flop oids)
  =/  pkt=packet:git-codec  i.packets
  ?.  ?=(%data -.pkt)
    $(packets t.packets)
  ?:  (starts-with payload.pkt 'size')
    $(packets t.packets, size %.y)
  ?:  (starts-with payload.pkt 'oid ')
    =/  parsed=(unit oid:git)  (oid-at payload.pkt 4)
    ?~  parsed  ~
    $(packets t.packets, oids [u.parsed oids])
  $(packets t.packets)
::
++  v2-object-info
  |=  [objects=(map oid:git object:git) oids=(list oid:git)]
  ^-  (unit octs)
  =/  packets=(list octs)
    ~[(en-pkt:git-codec [%data (text:git-codec 'size\0a')])]
  =/  remaining=(list oid:git)  oids
  |-
  ?~  remaining
    `(join-all:git-codec (weld packets ~[(en-pkt:git-codec [%flush ~])]))
  =/  found=(unit object:git)  (~(get by objects) i.remaining)
  ?~  found  ~
  =/  line=@t
    (rap 3 ~[(oid-text:git-codec i.remaining) ' ' (crip ((d-co:co 1) p.data.u.found)) '\0a'])
  %=  $
    remaining  t.remaining
    packets    (weld packets ~[(en-pkt:git-codec [%data (text:git-codec line)])])
  ==
::
++  receive-status
  |=  [unpack=@t results=(list [ok=? ref=@t message=@t])]
  ^-  octs
  =/  packets=(list octs)
    ~[(en-pkt:git-codec [%data (text:git-codec (rap 3 ~['unpack ' unpack '\0a']))])]
  =/  remaining=(list [ok=? ref=@t message=@t])  results
  |-
  ?~  remaining
    (join-all:git-codec (weld packets ~[(en-pkt:git-codec [%flush ~])]))
  =/  result=[ok=? ref=@t message=@t]  i.remaining
  =/  line=@t
    ?:  ok.result
      (rap 3 ~['ok ' ref.result '\0a'])
    (rap 3 ~['ng ' ref.result ' ' message.result '\0a'])
  $(remaining t.remaining, packets (weld packets ~[(en-pkt:git-codec [%data (text:git-codec line)])]))
::
++  line-payload
  |=  [oid=@t ref=@t caps=(unit @t)]
  ^-  octs
  =/  parts=(list octs)
    :~  (text:git-codec oid)
        (text:git-codec ' ')
        (text:git-codec ref)
    ==
  =?  parts  ?=(^ caps)
    (weld parts ~[(oct:git-codec 0) (text:git-codec u.caps)])
  (join-all:git-codec (weld parts ~[(oct:git-codec 10)]))
::
++  ref-pkt
  |=  [oid=oid:git ref=@t caps=(unit @t)]
  ^-  octs
  (en-pkt:git-codec [%data (line-payload (oid-text:git-codec oid) ref caps)])
::
++  no-refs-pkt
  |=  service=@t
  ^-  octs
  (en-pkt:git-codec [%data (line-payload zero-oid-text 'capabilities^{}' `(capabilities service))])
::
++  resolve-head
  |=  repo=repository:git
  ^-  (unit oid:git)
  (~(get by refs.repo) head.repo)
::
++  peel-object
  |=  $:  objects=(map oid:git object:git)
          oid=oid:git
          visiting=(set oid:git)
      ==
  ^-  (unit oid:git)
  ?:  (~(has in visiting) oid)  ~
  =/  found=(unit object:git)  (~(get by objects) oid)
  ?~  found  ~
  ?.  =(%tag kind.u.found)  `oid
  ?.  (starts-with data.u.found 'object ')  ~
  =/  target=(unit oid:git)  (oid-at data.u.found 7)
  ?~  target  ~
  (peel-object objects u.target (~(put in visiting) oid))
::
++  peeled-tag
  |=  [objects=(map oid:git object:git) oid=oid:git]
  ^-  (unit oid:git)
  =/  found=(unit object:git)  (~(get by objects) oid)
  ?.  ?&(?=(^ found) =(%tag kind.u.found))  ~
  (peel-object objects oid ~)
::
++  advertised-refs
  |=  [repo=repository:git service=@t]
  ^-  octs
  =/  caps=@t  (capabilities service)
  =/  head-oid=(unit oid:git)  (resolve-head repo)
  =/  entries=(list [@t oid:git])  ~(tap by refs.repo)
  ?:  ?&  ?=(~ head-oid)  =(~ entries)  ==
    (join-all:git-codec ~[(no-refs-pkt service) (en-pkt:git-codec [%flush ~])])
  =/  packets=(list octs)  ~
  =/  first=?  &
  =?  packets  ?=(^ head-oid)
    ~[(ref-pkt u.head-oid 'HEAD' `caps)]
  =?  first  ?=(^ head-oid)  |
  |-
  ?~  entries
    (join-all:git-codec (weld (flop packets) ~[(en-pkt:git-codec [%flush ~])]))
  =/  this-caps=(unit @t)  ?:(first `caps ~)
  =/  packet=octs  (ref-pkt +.i.entries -.i.entries this-caps)
  =/  peeled=(unit oid:git)  (peeled-tag objects.repo +.i.entries)
  =/  next-packets=(list octs)
    ?~  peeled  [packet packets]
    =/  peeled-ref=@t  (rap 3 ~[-.i.entries '^{}'])
    [(ref-pkt u.peeled peeled-ref ~) packet packets]
  %=  $
    entries  t.entries
    packets  next-packets
    first    |
  ==
::
++  smart-advertisement
  |=  [repo=repository:git service=@t]
  ^-  octs
  =/  service-line=octs
    (en-pkt:git-codec [%data (text:git-codec (rap 3 ~['# service=' service '\0a']))])
  %-  join-all:git-codec
  ~[service-line (en-pkt:git-codec [%flush ~]) (advertised-refs repo service)]
--
