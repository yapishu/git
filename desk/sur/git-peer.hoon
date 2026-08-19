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
      pages=@ud
  ==
+$  ready
  $:  transfer=@uv
      repository=@t
      head=@t
      refs=(map @t oid:git)
      objects=@ud
      pages=@ud
  ==
+$  accepted
  $:  transfer=@uv
      repository=@t
  ==
+$  prepare
  $:  target=ship
      request=request
  ==
+$  catalog-request
  $:  request=@uv
  ==
+$  catalog-repository
  $:  name=@t
      head=@t
      refs=@ud
      objects=@ud
      writable=?
  ==
+$  catalog
  $:  request=@uv
      repositories=(list catalog-repository)
  ==
+$  browse-view  ?(%overview %issue %pull %file)
::
+$  forge-kind  ?(%issue %pull)
::
+$  forge-comment
  $:  request=@uv
      repository=@t
      kind=forge-kind
      number=@ud
      body=@t
  ==
+$  forge-create-issue
  $:  request=@uv
      repository=@t
      title=@t
      body=@t
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
      [%accepted accepted=accepted]
      [%prepare prepare=prepare]
      [%ready ready=ready]
      [%begin begin=begin]
      [%catalog-request catalog-request=catalog-request]
      [%catalog catalog=catalog]
      [%catalog-error request=@uv message=@t]
      [%browse-request request=@uv repository=@t view=browse-view number=@ud file-path=path]
      [%browse-ready request=@uv repository=@t target=ship pages=@ud]
      [%browse-response request=@uv repository=@t result=json]
      [%browse-begin request=@uv repository=@t pages=@ud]
      [%browse-release request=@uv]
      [%browse-error request=@uv message=@t]
      [%forge-comment comment=forge-comment]
      [%forge-create-issue issue=forge-create-issue]
      [%forge-result request=@uv repository=@t kind=forge-kind number=@ud ok=? message=@t result=(unit json)]
      [%offer offer=offer]
      [%release transfer=@uv]
      [%snapshot transfer=@uv objects=(map oid:git object:git)]
      [%snapshot-error transfer=@uv message=@t]
      [%result transfer=@uv ok=? message=@t]
      [%error transfer=@uv message=@t]
  ==
--
