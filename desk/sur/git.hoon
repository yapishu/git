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
+$  upload-filter
  $%  [%blob-none]
      [%blob-limit limit=@ud]
  ==
::
+$  upload-request
  $:  wants=(set oid)
      haves=(set oid)
      done=?
      depth=(unit @ud)
      shallow=(set oid)
      deepen-relative=?
      filter=(unit upload-filter)
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
+$  lfs-lock
  $:  id=@ud
      path=@t
      owner=@t
      locked-at=@da
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
+$  review-comment
  $:  id=@ud
      author=ship
      body=@t
      created=@da
      path=(unit @t)
      line=(unit @ud)
      side=(unit ?(%base %head))
      resolved=?
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
      comments=(list review-comment)
  ==
::
+$  issue-comment
  $:  id=@ud
      author=ship
      body=@t
      created=@da
  ==
::
+$  native-issue
  $:  number=@ud
      author=ship
      title=@t
      body=@t
      state=?(%open %closed)
      labels=(set @t)
      assignees=(set @p)
      created=@da
      updated=@da
      comments=(list issue-comment)
  ==
::
+$  release
  $:  tag=@t
      title=@t
      notes=@t
      author=ship
      created=@da
  ==
::
+$  webhook-event
  ?(%push %tag %pull-request %issue %release %clay-sync)
::
+$  webhook
  $:  id=@ud
      url=@t
      secret=@t
      events=(set webhook-event)
      enabled=?
  ==
::
+$  webhook-delivery
  $:  id=@uv
      hook=@ud
      event=webhook-event
      status=?(%pending %success %failure)
      status-code=@ud
      message=@t
      created=@da
  ==
::
+$  incoming-hook
  $:  secret=@t
      enabled=?
  ==
::
+$  upstream-update
  $:  id=@uv
      source=@t
      ref=@t
      before=@t
      after=@t
      received=@da
  ==
::
+$  webhook-trigger
  $:  repository=@t
      event=webhook-event
      data=json
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
      description=@t
      head=@t
      refs=(map @t oid)
      protected-refs=(set @t)
      objects=(map oid object)
      writers=(set @p)
      write-token-hash=(unit @)
      lfs-objects=(map @t lfs-object)
      lfs-uploads=(map @t lfs-upload)
      lfs-locks=(map @ud lfs-lock)
      binding=(unit desk-binding)
      peer-origin=(unit peer-origin)
      github-origin=(unit github-origin)
      github-issues=(list forge-item)
      github-pulls=(list forge-item)
      native-pulls=(list native-pull)
      native-issues=(list native-issue)
      releases=(map @t release)
      webhooks=(map @ud webhook)
      incoming-hook=(unit incoming-hook)
      webhook-deliveries=(list webhook-delivery)
      upstream-updates=(list upstream-update)
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
      [%set-description repository=@t description=@t]
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
