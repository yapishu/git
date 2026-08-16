::  Chunked Git object replication over Ames.
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
      head=@t
      refs=(map @t oid:git)
      objects=@ud
  ==
+$  chunk
  $:  transfer=@uv
      oid=oid:git
      kind=object-kind:git
      size=@ud
      offset=@ud
      data=octs
      final=?
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
      [%begin begin=begin]
      [%chunk chunk=chunk]
      [%offer offer=offer]
      [%ack transfer=@uv]
      [%done transfer=@uv]
      [%result transfer=@uv ok=? message=@t]
      [%error transfer=@uv message=@t]
  ==
--
