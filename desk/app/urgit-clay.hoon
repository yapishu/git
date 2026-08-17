::  Isolates Clay mutations so their complete failure trace is returned to %urgit.
::
/-  git
/+  dbug, default-agent
%-  agent:dbug
=*  state  ~
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init  `this
++  on-save  !>(~)
++  on-load  |=(* `this)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card:agent:gall _this)
  ?.  =(%git-clay-action mark)
    (on-poke:def mark vase)
  ?>  =(src.bowl our.bowl)
  =/  apply=clay-apply:git  !<(clay-apply:git vase)
  :_  this
  :~  [%pass /apply %arvo %c [%info desk-name.apply delta.apply]]
  ==
::
++  on-peek   on-peek:def
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
