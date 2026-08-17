|%
+$  oid  @ux
::
+$  object-kind  ?(%blob %tree %commit %tag)
::
+$  object
  $:  kind=object-kind
      data=octs
  ==
::
+$  upload-request
  $:  wants=(set oid)
      haves=(set oid)
      done=?
  ==
::
+$  receive-command
  $:  old=(unit oid)
      new=(unit oid)
      ref=@t
  ==
::
+$  receive-request
  $:  commands=(list receive-command)
      pack=octs
  ==
::
+$  lfs-object
  $:  size=@ud
      object-key=@t
  ==
::
+$  lfs-upload
  $:  size=@ud
      object-key=@t
      expires=@da
  ==
::
+$  clay-link
  $:  clay-revision=@ud
      commit=oid
      direction=?(%clay-to-git %git-to-clay)
      when=@da
  ==
::
+$  desk-binding
  $:  desk-name=desk
      branch=@t
      last-clay=(unit @ud)
      last-git=(unit oid)
      history=(list clay-link)
  ==
::
+$  peer-origin
  $:  ship=ship
      repository=@t
  ==
::
+$  github-origin
  $:  owner=@t
      repository=@t
  ==
::
+$  forge-item
  $:  number=@ud
      title=@t
      state=@t
      url=@t
      author=@t
      draft=?
  ==
::
+$  native-pull
  $:  number=@ud
      source-ship=ship
      source-repository=@t
      title=@t
      state=?(%open %merged %closed)
      head=oid
      base=oid
  ==
::
+$  clay-apply
  $:  desk-name=desk
      delta=nori:clay
  ==
::
+$  repository
  $:  owner=@p
      public-read=?
      head=@t
      refs=(map @t oid)
      protected-refs=(set @t)
      objects=(map oid object)
      writers=(set @p)
      write-token-hash=(unit @)
      lfs-objects=(map @t lfs-object)
      lfs-uploads=(map @t lfs-upload)
      binding=(unit desk-binding)
      peer-origin=(unit peer-origin)
      github-origin=(unit github-origin)
      github-issues=(list forge-item)
      github-pulls=(list forge-item)
      native-pulls=(list native-pull)
  ==
::
+$  state-0
  $:  %0
      repositories=(map @t repository)
      peers=(set @p)
      github-token=(unit @t)
  ==
::
+$  action
  $%  [%create name=@t public-read=?]
      [%delete name=@t]
      [%put-object repository=@t kind=object-kind data=octs]
      [%set-ref repository=@t ref=@t oid=oid]
      [%delete-ref repository=@t ref=@t]
      [%set-protected repository=@t ref=@t protected=?]
      [%set-head repository=@t ref=@t]
      [%set-public repository=@t public-read=?]
      [%grant-writer repository=@t writer=@p]
      [%revoke-writer repository=@t writer=@p]
      [%set-write-token repository=@t token=@t]
      [%clear-write-token repository=@t]
      [%bind-desk repository=@t desk-name=desk branch=@t]
      [%unbind-desk repository=@t]
      [%publish-desk repository=@t message=@t]
      [%add-peer peer=@p]
      [%remove-peer peer=@p]
  ==
--
