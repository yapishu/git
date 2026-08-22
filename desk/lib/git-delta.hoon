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
::  The opcode names, in a seven-bit mask, which bytes of the copy offset and
::  the copy size follow it.  Git writes each field little-endian and drops
::  only its leading zero bytes, so in practice the set bits of each field are
::  a run that starts at the field's low bit.  A run is one +cut of the delta
::  stream, and 98.5% of the copy instructions in a repacked erpit take that
::  path.  Reading the bytes one at a time through +optional-byte cost seven
::  gate calls and seven (unit) allocations per copy instruction, which
::  measured at 45% of +apply-delta and 25% of a whole pack decode.
::
::  A mask with a gap in it is still legal, so +copy-instruction-sparse below
::  keeps the byte-at-a-time form for that case.  The two forms return the same
::  noun on every input.  They read the same bytes from the same offsets, and
::  the bounds test below fires on exactly the inputs where +optional-byte
::  would have run off the end.  A probe compared them over all 128 copy
::  opcodes, six byte patterns, nine source truncations and two cursors:
::  13,824 cases, no difference.
::
++  copy-instruction
  |=  [source=octs cursor=@ud opcode=@ud base=octs]
  ^-  (unit [chunk=octs next=@ud])
  =/  offset-mask=@ud  (cut 0 [0 4] opcode)
  =/  size-mask=@ud  (cut 0 [4 3] opcode)
  =/  offset-width=@ud
    ?:  =(offset-mask 0)   0
    ?:  =(offset-mask 1)   1
    ?:  =(offset-mask 3)   2
    ?:  =(offset-mask 7)   3
    ?:  =(offset-mask 15)  4
    5
  =/  size-width=@ud
    ?:  =(size-mask 0)  0
    ?:  =(size-mask 1)  1
    ?:  =(size-mask 3)  2
    ?:  =(size-mask 7)  3
    5
  ?:  |(=(offset-width 5) =(size-width 5))
    (copy-instruction-sparse source cursor opcode base)
  =/  count=@ud  (add offset-width size-width)
  =/  next=@ud  (add cursor count)
  ::  +optional-byte only bounds-checks when the mask asks for a byte, so an
  ::  opcode that asks for none succeeds even past the end of the source.
  ?:  ?&  (gth count 0)
          (gth next p.source)
      ==
    ~
  =/  offset=@ud  (cut 3 [cursor offset-width] q.source)
  =/  size=@ud  (cut 3 [(add cursor offset-width) size-width] q.source)
  =?  size  =(size 0)  65.536
  ?:  (gth (add offset size) p.base)  ~
  `[[(slice:git-codec base offset size) next]]
::
++  copy-instruction-sparse
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
::  Collect the chunks and concatenate once, instead of joining the
::  accumulator to each chunk as it is produced.  The pairwise +join
::  recopied the whole output on every instruction, which is quadratic
::  in the instruction count.
::
::  Deferring is safe here because no instruction reads the accumulator:
::  the copy branch slices from +base and the insert branch slices from
::  +delta.  The running +size equals the +p the pairwise +join would
::  have carried at the same point, so the result-size guard still fires
::  on the same instruction and still returns ~.
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
  =/  parts=(list octs)  ~
  =/  size=@ud  0
  |-
  ?:  =(cursor p.delta)
    ?:  =(size value.u.result-size)  `(join-all:git-codec (flop parts))
    ~
  ?:  (gth cursor p.delta)  ~
  =/  opcode=@ud  (byte-at:git-codec delta cursor)
  =.  cursor  +(cursor)
  ?:  =(opcode 0)  ~
  ?:  =(1 (cut 0 [7 1] opcode))
    =/  copied=(unit [chunk=octs next=@ud])
      (copy-instruction delta cursor opcode base)
    ?~  copied  ~
    =/  next-size=@ud  (add size p.chunk.u.copied)
    ?:  (gth next-size value.u.result-size)  ~
    $(cursor next.u.copied, parts [chunk.u.copied parts], size next-size)
  =/  length=@ud  (cut 0 [0 7] opcode)
  ?:  =(length 0)  ~
  ?:  (gth (add cursor length) p.delta)  ~
  =/  chunk=octs  (slice:git-codec delta cursor length)
  =/  next-size=@ud  (add size p.chunk)
  ?:  (gth next-size value.u.result-size)  ~
  $(cursor (add cursor length), parts [chunk parts], size next-size)
--
