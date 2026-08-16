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
+$  packet
  $%  [%request request=request]
      [%begin begin=begin]
      [%chunk chunk=chunk]
      [%ack transfer=@uv]
      [%done transfer=@uv]
      [%error transfer=@uv message=@t]
  ==
--
