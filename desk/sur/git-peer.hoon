::  Git repository coordination over Ames with object graphs read over Fine.
::
/-  git
|%
+$  request
  $:  transfer=@uv
      repository=@t
      haves=(set oid:git)
  ==
+$  begin
  $:  transfer=@uv
      repository=@t
      revision=@ud
      head=@t
      refs=(map @t oid:git)
      objects=@ud
  ==
+$  ready
  $:  transfer=@uv
      repository=@t
      head=@t
      refs=(map @t oid:git)
      objects=@ud
  ==
+$  offer
  $:  transfer=@uv
      repository=@t
      source-repository=@t
      pull-request=?
      title=@t
  ==
+$  packet
  $%  [%request request=request]
      [%ready ready=ready]
      [%begin begin=begin]
      [%offer offer=offer]
      [%release transfer=@uv]
      [%snapshot transfer=@uv objects=(map oid:git object:git)]
      [%snapshot-error transfer=@uv message=@t]
      [%result transfer=@uv ok=? message=@t]
      [%error transfer=@uv message=@t]
  ==
--
