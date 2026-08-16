::  Git pack delta instruction decoder.
::
/-  git
/+  git-codec
|%
++  size-value
  |=  [source=octs offset=@ud]
  ^-  (unit [value=@ud next=@ud])
  =/  value=@ud  0
  =/  shift=@ud  0
  =/  cursor=@ud  offset
  |-
  ?:  (gte cursor p.source)  ~
  =/  byte=@ud  (byte-at:git-codec source cursor)
  =.  value  (add value (mul (cut 0 [0 7] byte) (bex shift)))
  =.  cursor  +(cursor)
  ?:  =(0 (cut 0 [7 1] byte))  `[[value cursor]]
  ?:  (gte shift 63)  ~
  $(shift (add shift 7))
::
++  optional-byte
  |=  [source=octs cursor=@ud opcode=@ud flag=@ud]
  ^-  (unit [value=@ud next=@ud])
  ?:  =(0 (cut 0 [flag 1] opcode))  `[[0 cursor]]
  ?:  (gte cursor p.source)  ~
  `[[(byte-at:git-codec source cursor) +(cursor)]]
::
++  copy-instruction
  |=  [source=octs cursor=@ud opcode=@ud base=octs]
  ^-  (unit [chunk=octs next=@ud])
  =/  o0=(unit [value=@ud next=@ud])  (optional-byte source cursor opcode 0)
  ?~  o0  ~
  =/  o1=(unit [value=@ud next=@ud])  (optional-byte source next.u.o0 opcode 1)
  ?~  o1  ~
  =/  o2=(unit [value=@ud next=@ud])  (optional-byte source next.u.o1 opcode 2)
  ?~  o2  ~
  =/  o3=(unit [value=@ud next=@ud])  (optional-byte source next.u.o2 opcode 3)
  ?~  o3  ~
  =/  s0=(unit [value=@ud next=@ud])  (optional-byte source next.u.o3 opcode 4)
  ?~  s0  ~
  =/  s1=(unit [value=@ud next=@ud])  (optional-byte source next.u.s0 opcode 5)
  ?~  s1  ~
  =/  s2=(unit [value=@ud next=@ud])  (optional-byte source next.u.s1 opcode 6)
  ?~  s2  ~
  =/  offset=@ud
    %+  add  value.u.o0
    %+  add  (mul value.u.o1 256)
    (add (mul value.u.o2 65.536) (mul value.u.o3 16.777.216))
  =/  size=@ud
    (add value.u.s0 (add (mul value.u.s1 256) (mul value.u.s2 65.536)))
  =?  size  =(size 0)  65.536
  ?:  (gth (add offset size) p.base)  ~
  `[[(slice:git-codec base offset size) next.u.s2]]
::
++  apply-delta
  |=  [base=octs delta=octs]
  ^-  (unit octs)
  =/  base-size=(unit [value=@ud next=@ud])  (size-value delta 0)
  ?~  base-size  ~
  ?.  =(value.u.base-size p.base)  ~
  =/  result-size=(unit [value=@ud next=@ud])
    (size-value delta next.u.base-size)
  ?~  result-size  ~
  =/  cursor=@ud  next.u.result-size
  =/  output=octs  [0 0]
  |-
  ?:  =(cursor p.delta)
    ?:  =(p.output value.u.result-size)  `output
    ~
  ?:  (gth cursor p.delta)  ~
  =/  opcode=@ud  (byte-at:git-codec delta cursor)
  =.  cursor  +(cursor)
  ?:  =(opcode 0)  ~
  ?:  =(1 (cut 0 [7 1] opcode))
    =/  copied=(unit [chunk=octs next=@ud])
      (copy-instruction delta cursor opcode base)
    ?~  copied  ~
    =/  next-output=octs  (join:git-codec output chunk.u.copied)
    ?:  (gth p.next-output value.u.result-size)  ~
    $(cursor next.u.copied, output next-output)
  =/  length=@ud  (cut 0 [0 7] opcode)
  ?:  =(length 0)  ~
  ?:  (gth (add cursor length) p.delta)  ~
  =/  next-output=octs
    (join:git-codec output (slice:git-codec delta cursor length))
  ?:  (gth p.next-output value.u.result-size)  ~
  $(cursor (add cursor length), output next-output)
--
