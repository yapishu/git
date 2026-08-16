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
++  parse-upload-request
  |=  body=octs
  ^-  (unit upload-request:git)
  =/  decoded=(unit (list packet:git-codec))  (de-pkts:git-codec body)
  ?~  decoded  ~
  =/  wants=(set oid:git)  ~
  =/  haves=(set oid:git)  ~
  =/  done=?  %.n
  =/  packets=(list packet:git-codec)  u.decoded
  |-
  ?~  packets  `[wants haves done]
  =/  pkt=packet:git-codec  i.packets
  ?.  ?=(%data -.pkt)
    $(packets t.packets)
  =/  payload=octs  payload.pkt
  ?:  (starts-with payload 'want ')
    =/  parsed=(unit oid:git)  (oid-at payload 5)
    ?~  parsed  ~
    $(packets t.packets, wants (~(put in wants) u.parsed))
  ?:  (starts-with payload 'have ')
    =/  parsed=(unit oid:git)  (oid-at payload 5)
    ?~  parsed  ~
    $(packets t.packets, haves (~(put in haves) u.parsed))
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
  =/  cursor=@ud  82
  |-
  ?:  (gte cursor p.payload)  ~
  =/  byte=@ud  (byte-at:git-codec payload cursor)
  ?:  ?|  =(byte 0)
          =(byte 10)
      ==
    =/  length=@ud  (sub cursor 82)
    ?:  =(length 0)  ~
    =/  ref-bytes=octs  (slice:git-codec payload 82 length)
    =/  ref=@t  q.ref-bytes
    ?.  (valid-ref ref)  ~
    `[[u.old u.new ref]]
  $(cursor +(cursor))
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
    'agent=urbit-git/0.1'
  'report-status delete-refs no-thin agent=urbit-git/0.1'
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
  %=  $
    entries  t.entries
    packets  [(ref-pkt +.i.entries -.i.entries this-caps) packets]
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
