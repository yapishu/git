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
+$  native-pull-1
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
+$  native-pull
  $:  number=@ud
      source-ship=ship
      source-repository=@t
      source-ref=@t
      target-ref=@t
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
+$  notification-event
  ?(%issue %issue-comment %pull-request %pull-comment)
::
+$  hark-flag
  [ship=ship name=term]
::
+$  hark-nest
  [desk=desk flag=hark-flag]
::
+$  hark-rope
  $:  group=(unit hark-flag)
      channel=(unit hark-nest)
      desk=desk
      thread=path
  ==
::
+$  hark-content
  $@  @t
  $%  [%ship ship=ship]
      [%emph text=cord]
  ==
::
+$  hark-button
  [title=cord handler=path]
::
+$  hark-yarn
  $:  id=@uv
      rope=hark-rope
      time=@da
      content=(list hark-content)
      link=path
      button=(unit hark-button)
  ==
::
+$  hark-action
  [%add-yarn all=? desk=? yarn=hark-yarn]
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
      readers=(set @p)
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
      notification-events=(set notification-event)
  ==
::
+$  state-0
  $:  %0
      repositories=(map @t repository-0)
      peers=(set @p)
      github-token=(unit @t)
  ==
::
+$  repository-0
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
      native-pulls=(list native-pull-1)
      native-issues=(list native-issue)
      releases=(map @t release)
      webhooks=(map @ud webhook)
      incoming-hook=(unit incoming-hook)
      webhook-deliveries=(list webhook-delivery)
      upstream-updates=(list upstream-update)
  ==
::
+$  repository-1
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
      native-pulls=(list native-pull-1)
      native-issues=(list native-issue)
      releases=(map @t release)
      webhooks=(map @ud webhook)
      incoming-hook=(unit incoming-hook)
      webhook-deliveries=(list webhook-delivery)
      upstream-updates=(list upstream-update)
      notification-events=(set notification-event)
  ==
::
+$  state-1
  $:  %1
      repositories=(map @t repository-1)
      peers=(set @p)
      github-token=(unit @t)
  ==
::
::  a queued serve request, awaiting the ~s1 snapshot-build timer
::
::    structurally identical to [target=ship request:git-peer]; declared here
::    because sur/git-peer imports sur/git and cannot be imported back.
::
+$  peer-prepare-request
  $:  transfer=@uv
      repository=@t
      haves=(set oid)
  ==
::
+$  peer-prepare-entry
  $:  target=@p
      req=peer-prepare-request
  ==
::
::  the shape installed ships stored before the queue became persistent
::
+$  state-2
  $:  %2
      repositories=(map @t repository)
      peers=(set @p)
      github-token=(unit @t)
  ==
::
+$  state-3
  $:  %3
      repositories=(map @t repository)
      peers=(set @p)
      github-token=(unit @t)
      ::  persisted so an agent reload cannot strand a queued fork
      peer-prepare-queue=(map @uv peer-prepare-entry)
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
      [%grant-reader repository=@t reader=@p]
      [%revoke-reader repository=@t reader=@p]
      [%set-write-token repository=@t token=@t]
      [%clear-write-token repository=@t]
      [%bind-desk repository=@t desk-name=desk branch=@t]
      [%unbind-desk repository=@t]
      [%publish-desk repository=@t message=@t]
      [%add-peer peer=@p]
      [%remove-peer peer=@p]
  ==
--
