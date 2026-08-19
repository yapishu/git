::  Native Git object database and Smart HTTP endpoint.
::
/-  git, git-peer
/+  dbug, default-agent, git-archive, git-blame, git-clay, git-clay-history, git-codec, git-github, git-graph, git-pack, git-pack-decode, git-protocol, git-storage, git-tree, git-webhook, server
|%
+$  card  card:agent:gall
+$  lfs-spec  [oid=@t size=@ud]
+$  lfs-request  [eyre-id=@ta repository=@t oid=@t upload=lfs-upload:git]
+$  lfs-delete  [repository=@t oid=@t]
+$  clay-push
  $:  eyre-id=@ta
      api-response=?
      peer-response=(unit [ship=ship transfer=@uv])
      repository=@t
      commands=(list receive-command:git)
      applied=repository:git
      desk-name=desk
      branch=@t
      new-oid=oid:git
      delta=nori:clay
      result=(unit [ok=? message=@t])
      start-at=@da
      timeout-at=@da
  ==
+$  publish-job
  $:  repository=@t
      desk-name=desk
      branch=@t
      clay-revision=(unit @ud)
      message=@t
      paths=(list path)
      files=(map path octs)
  ==
+$  peer-serve
  $:  target=ship
      transfer=@uv
      repository=@t
      pages=@ud
      objects=(list [oid:git object:git])
  ==
+$  peer-receive
  $:  purpose=?(%fork %push %pull)
      source=ship
      source-repository=@t
      local-repository=@t
      title=@t
      public-read=?
      accepted=?
      head=@t
      refs=(map @t oid:git)
      expected=@ud
      received=@ud
      pages=@ud
      completed=(set @ud)
      progress-at=@da
      fine-progress=(map @ud [fag=@ud tot=@ud])
      objects=(map oid:git object:git)
  ==
+$  peer-transfer-debug
  $:  transfer=@uv
      purpose=?(%fork %push %pull)
      source=ship
      source-repository=@t
      local-repository=@t
      stage=?(%request %prepare %fine)
      expected-objects=@ud
      received-objects=@ud
      pages=@ud
      completed-pages=(list @ud)
      fine-progress=(list [revision=@ud fag=@ud tot=@ud])
      progress-at=@da
  ==
+$  peer-serve-debug
  $:  transfer=@uv
      target=ship
      repository=@t
      pages=@ud
      objects=@ud
  ==
+$  peer-result  [status=? message=@t repository=@t]
+$  webhook-flight  [repository=@t hook=@ud delivery=@uv]
+$  peer-browse-serve  [target=ship pages=@ud]
+$  peer-discovery
  $:  peer=ship
      active=?
      ok=?
      message=@t
      repositories=(list catalog-repository:git-peer)
  ==
+$  peer-browse
  $:  peer=ship
      repository=@t
      view=browse-view:git-peer
      number=@ud
      file-path=path
      phase=?(%request %fine)
      active=?
      ok=?
      message=@t
      progress=(unit [boq=@ud fag=@ud tot=@ud])
      progress-at=@da
      expected=@ud
      received=@ud
      parts=(map @ud [length=@ud data=@])
      result=(unit json)
  ==
+$  peer-forge
  $:  peer=ship
      repository=@t
      kind=forge-kind:git-peer
      number=@ud
      active=?
      ok=?
      message=@t
      result=(unit json)
  ==
+$  peer-activity-kind  ?(%fork %serve %push %pull-request)
+$  peer-activity-status  ?(%active %success %failure)
+$  peer-activity
  $:  id=@uv
      kind=peer-activity-kind
      direction=?(%incoming %outgoing)
      peer=ship
      repository=@t
      status=peer-activity-status
      message=@t
      when=@da
  ==
+$  notification-activity
  $:  id=@uv
      event=notification-event:git
      repository=@t
      message=@t
      when=@da
  ==
+$  notification-result
  [cards=(list card) activity=(unit notification-activity)]
+$  blame-table  [sources=(list json) remap=(map @ud @ud)]
+$  github-kind  ?(%import %update %push %push-send %issues %pulls %issue-detail %pull-detail %pull-diff %file-detail %fork %open-pull)
+$  github-request
  $:  job=@uv
      kind=github-kind
      repository=@t
      owner=@t
      remote=@t
      public-read=?
      head=@t
      refs=(map @t oid:git)
      metadata-page=@ud
      api-response=(unit @ta)
      detail-number=@ud
  ==
+$  github-result
  $:  active=?
      ok=?
      kind=github-kind
      repository=@t
      message=@t
  ==
+$  commit-identity
  $:  name=@t
      email=@t
      timestamp=@t
      timezone=@t
  ==
::
++  update-binding-success
  |=  [repo=repository:git new-oid=oid:git clay-revision=(unit @ud) when=@da]
  ^-  repository:git
  ?~  binding.repo  repo
  =/  linked=desk-binding:git
    =/  links=(list clay-link:git)
      ?~  clay-revision  history.u.binding.repo
      =/  link=clay-link:git  [u.clay-revision new-oid %git-to-clay when]
      =/  old-links=(list clay-link:git)  history.u.binding.repo
      [link old-links]
    u.binding.repo(last-clay clay-revision, last-git `new-oid, history links)
  repo(binding `linked)
::
++  receive-results
  |=  [commands=(list receive-command:git) ok=? message=@t]
  ^-  (list [ok=? ref=@t message=@t])
  (turn commands |=(command=receive-command:git [ok ref.command message]))
::
++  push-event-json
  |=  commands=(list receive-command:git)
  ^-  json
  =/  entries=(list json)
    %+  turn  commands
    |=  command=receive-command:git
    %-  pairs:enjs:format
    :~  ['ref' s+ref.command]
        ['before' s+?~(old.command '' (oid-text:git-codec u.old.command))]
        ['after' s+?~(new.command '' (oid-text:git-codec u.new.command))]
        ['deleted' b+?=(~ new.command)]
    ==
  (pairs:enjs:format ~[['updates' [%a entries]]])
::
++  receive-payload
  |=  [unpack=@t results=(list [ok=? ref=@t message=@t])]
  ^-  simple-payload:http
  :_  `(receive-status:git-protocol unpack results)
  :-  200
  :~  ['content-type' 'application/x-git-receive-pack-result']
      ['cache-control' 'no-store']
  ==
::
++  tang-text
  |=  =tang
  ^-  @t
  =/  lines=(list tape)
    %-  zing
    %+  turn  tang
    |=  =tank
    (wash [0 120] tank)
  =/  join-lines
    |=  [remaining=(list tape) out=tape]
    ^-  tape
    ?~  remaining  out
    =/  next=tape
      ?~  out  i.remaining
      :(weld out " | " i.remaining)
    $(remaining t.remaining, out next)
  (crip (scag 60.000 (join-lines lines ~)))
::
++  page-octs
  |=  [our=@p desk-name=desk now=@da =page]
  ^-  (unit octs)
  ?:  =(%hoon p.page)
    =/  source=@t  ;;(@ q.page)
    `[(met 3 source) source]
  ?:  =(%kelvin p.page)
    =/  kal=waft:clay  ;;(waft:clay q.page)
    =/  source=@t
      %+  rap  3
      %+  turn
        %+  sort
          ~(tap in (waft-to-wefts:clay kal))
        |=  [a=weft b=weft]
        ?:  =(lal.a lal.b)
          (gte num.a num.b)
        (gte lal.a lal.b)
      |=  =weft
      (rap 3 '[%' (scot %tas lal.weft) ' ' (scot %ud num.weft) ']\0a' ~)
    `[(met 3 source) source]
  =/  converted=(unit mime)
    %-  mole
    |.
    ?:  =(%mime p.page)
      ;;(mime q.page)
    =/  =dais:clay
      .^(dais:clay %cb /(scot %p our)/[desk-name]/(scot %da now)/[p.page])
    =/  vax=vase  (vale:dais q.page)
    =/  =tube:clay
      .^(tube:clay %cc /(scot %p our)/[desk-name]/(scot %da now)/[p.page]/mime)
    !<(mime (tube vax))
  ?~  converted  ~
  `q.u.converted
::
++  publish-repository
  |=  [repo=repository:git job=publish-job author=@p now=@da]
  ^-  (unit repository:git)
  ?~  binding.repo  ~
  ?.  ?&  =(desk-name.job desk-name.u.binding.repo)
          =(branch.job branch.u.binding.repo)
      ==
    ~
  =/  parent=(unit oid:git)  (~(get by refs.repo) branch.job)
  =/  snapped=(unit [commit=oid:git objects=(map oid:git object:git)])
    (snapshot:git-clay files.job objects.repo parent author now message.job)
  ?~  snapped  ~
  =/  links=(list clay-link:git)
    ?~  clay-revision.job  history.u.binding.repo
    =/  link=clay-link:git  [u.clay-revision.job commit.u.snapped %clay-to-git now]
    =/  old-links=(list clay-link:git)  history.u.binding.repo
    [link old-links]
  =/  linked=desk-binding:git
    u.binding.repo(last-clay clay-revision.job, last-git `commit.u.snapped, history links)
  =/  published=repository:git
    %_  repo
      objects  objects.u.snapped
      refs     (~(put by refs.repo) branch.job commit.u.snapped)
      binding  `linked
    ==
  `published
::
++  binding-json
  |=  binding=(unit desk-binding:git)
  ^-  json
  ?~  binding
    %-  pairs:enjs:format
    ~[['bound' b+%.n]]
  %-  pairs:enjs:format
  :~  ['bound' b+%.y]
      ['desk' s+desk-name.u.binding]
      ['branch' s+branch.u.binding]
      ['lastClay' s+?~(last-clay.u.binding '' (scot %ud u.last-clay.u.binding))]
      ['lastGit' s+?~(last-git.u.binding '' (oid-text:git-codec u.last-git.u.binding))]
      :-  'history'
      :-  %a
      %+  turn  history.u.binding
      |=  link=clay-link:git
      %-  pairs:enjs:format
      :~  ['clayRevision' n+(decimal clay-revision.link)]
          ['commit' s+(oid-text:git-codec commit.link)]
          ['direction' s+direction.link]
          ['when' s+(scot %da when.link)]
      ==
  ==
::
++  decimal
  |=  value=@ud
  ^-  @t
  (crip ((d-co:co 1) value))
::
++  two-digits
  |=  value=@ud
  ^-  tape
  ?:  (lth value 10)
    (weld "0" (a-co:co value))
  (a-co:co value)
::
++  rfc3339
  |=  when=@da
  ^-  @t
  =/  date  (yore when)
  %-  crip
  %+  weld  (a-co:co y.date)
  %+  weld  "-"
  %+  weld  (two-digits m.date)
  %+  weld  "-"
  %+  weld  (two-digits d.t.date)
  %+  weld  "T"
  %+  weld  (two-digits h.t.date)
  %+  weld  ":"
  %+  weld  (two-digits m.t.date)
  %+  weld  ":"
  %+  weld  (two-digits s.t.date)
  "Z"
::
++  lfs-lock-json
  |=  lock=lfs-lock:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' s+(decimal id.lock)]
      ['path' s+path.lock]
      ['locked_at' s+(rfc3339 locked-at.lock)]
      ['owner' (pairs:enjs:format ~[['name' s+owner.lock]])]
  ==
::
++  review-comment-json
  |=  comment=review-comment:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' n+(decimal id.comment)]
      ['author' s+(scot %p author.comment)]
      ['body' s+body.comment]
      ['created' s+(scot %da created.comment)]
      ['path' s+?~(path.comment '' u.path.comment)]
      ['line' n+(decimal ?~(line.comment 0 u.line.comment))]
      ['side' s+?~(side.comment '' u.side.comment)]
      ['resolved' b+resolved.comment]
  ==
::
++  issue-comment-json
  |=  comment=issue-comment:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' n+(decimal id.comment)]
      ['author' s+(scot %p author.comment)]
      ['body' s+body.comment]
      ['created' s+(scot %da created.comment)]
  ==
::
++  native-issue-json
  |=  [issue=native-issue:git include-comments=?]
  ^-  json
  =/  labels-json=(list json)
    (turn ~(tap in labels.issue) |=(label=@t s+label))
  =/  assignees-json=(list json)
    (turn ~(tap in assignees.issue) |=(assignee=@p s+(scot %p assignee)))
  %-  pairs:enjs:format
  :~  ['number' n+(decimal number.issue)]
      ['author' s+(scot %p author.issue)]
      ['title' s+title.issue]
      ['body' s+?:(include-comments body.issue '')]
      ['state' s+state.issue]
      ['labels' [%a labels-json]]
      ['assignees' [%a assignees-json]]
      ['created' s+(scot %da created.issue)]
      ['updated' s+(scot %da updated.issue)]
      ['commentCount' n+(decimal (lent comments.issue))]
      ['comments' [%a ?:(include-comments (turn comments.issue issue-comment-json) ~)]]
  ==
::
++  release-json
  |=  [release=release:git include-notes=?]
  ^-  json
  %-  pairs:enjs:format
  :~  ['tag' s+tag.release]
      ['title' s+title.release]
      ['notes' s+?:(include-notes notes.release '')]
      ['author' s+(scot %p author.release)]
      ['created' s+(scot %da created.release)]
  ==
::
++  webhook-json
  |=  hook=webhook:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' n+(decimal id.hook)]
      ['url' s+url.hook]
      ['enabled' b+enabled.hook]
      ['events' [%a (turn ~(tap in events.hook) |=(event=webhook-event:git s+event))]]
  ==
::
++  webhook-delivery-json
  |=  delivery=webhook-delivery:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' s+(scot %uv id.delivery)]
      ['hook' n+(decimal hook.delivery)]
      ['event' s+event.delivery]
      ['status' s+status.delivery]
      ['statusCode' n+(decimal status-code.delivery)]
      ['message' s+message.delivery]
      ['created' s+(scot %da created.delivery)]
  ==
::
++  upstream-update-json
  |=  update=upstream-update:git
  ^-  json
  %-  pairs:enjs:format
  :~  ['id' s+(scot %uv id.update)]
      ['source' s+source.update]
      ['ref' s+ref.update]
      ['before' s+before.update]
      ['after' s+after.update]
      ['received' s+(scot %da received.update)]
  ==
::
++  dedupe-upstream-updates
  |=  updates=(list upstream-update:git)
  ^-  (list upstream-update:git)
  =/  seen=(set @t)  ~
  =/  kept=(list upstream-update:git)  ~
  |-
  ?~  updates  (flop kept)
  ?:  (~(has in seen) ref.i.updates)
    $(updates t.updates)
  %=  $
    updates  t.updates
    seen     (~(put in seen) ref.i.updates)
    kept     [i.updates kept]
  ==
::
++  default-notification-events
  ^-  (set notification-event:git)
  =/  events=(set notification-event:git)  ~
  =.  events  (~(put in events) %issue)
  =.  events  (~(put in events) %issue-comment)
  =.  events  (~(put in events) %pull-request)
  (~(put in events) %pull-comment)
::
++  repository-json
  |=  [name=@t repo=repository:git]
  ^-  json
  =/  refs-json=(list json)
    %+  turn  ~(tap by refs.repo)
    |=  [ref=@t oid=oid:git]
    =/  peeled=(unit oid:git)  (peeled-tag:git-protocol objects.repo oid)
    =/  target=oid:git  ?~(peeled oid u.peeled)
    =/  mapped=(unit clay-link:git)
      ?~  binding.repo  ~
      (clay-link-for-commit target history.u.binding.repo)
    %-  pairs:enjs:format
    :~  ['name' s+ref]
        ['oid' s+(oid-text:git-codec oid)]
        ['targetOid' s+(oid-text:git-codec target)]
        ['clayRevision' n+(decimal ?~(mapped 0 clay-revision.u.mapped))]
    ==
  =/  writers-json=(list json)
    (turn ~(tap in writers.repo) |=(writer=@p s+(scot %p writer)))
  =/  protected-json=(list json)
    (turn ~(tap in protected-refs.repo) |=(ref=@t s+ref))
  =/  notification-events-json=(list json)
    (turn ~(tap in notification-events.repo) |=(event=notification-event:git s+event))
  =/  head-oid=(unit oid:git)  (~(get by refs.repo) head.repo)
  =/  head-files=(unit (map path octs))
    ?~  head-oid  ~
    (flatten-commit:git-tree objects.repo u.head-oid)
  =/  file-count=@ud  ?~(head-files 0 (lent ~(tap by u.head-files)))
  =/  pulls-json=(list json)
    %+  turn  native-pulls.repo
    |=  pull=native-pull:git
    %-  pairs:enjs:format
    :~  ['number' n+(decimal number.pull)]
        ['sourceShip' s+(scot %p source-ship.pull)]
        ['sourceRepository' s+source-repository.pull]
        ['title' s+title.pull]
        ['state' s+state.pull]
        ['head' s+(oid-text:git-codec head.pull)]
        ['base' s+(oid-text:git-codec base.pull)]
        ['commentCount' n+(decimal (lent comments.pull))]
    ==
  =/  github-item-json
    |=  item=forge-item:git
    ^-  json
    %-  pairs:enjs:format
    :~  ['number' n+(decimal number.item)]
        ['title' s+title.item]
        ['state' s+state.item]
        ['url' s+url.item]
        ['author' s+author.item]
        ['draft' b+draft.item]
    ==
  =/  releases-json=(list json)
    %+  turn  ~(tap by releases.repo)
    |=  entry=[@t release:git]
    (release-json +.entry %.n)
  %-  pairs:enjs:format
  :~  ['name' s+name]
      ['owner' s+(scot %p owner.repo)]
      ['description' s+description.repo]
      ['publicRead' b+public-read.repo]
      ['head' s+head.repo]
      ['refs' [%a refs-json]]
      ['protectedRefs' [%a protected-json]]
      ['objectCount' n+(decimal (lent ~(tap by objects.repo)))]
      ['fileCount' n+(decimal file-count)]
      ['commitCount' n+(decimal (first-parent-count repo head.repo))]
      ['branchCount' n+(decimal (ref-count-prefix refs.repo 'refs/heads/'))]
      ['tagCount' n+(decimal (ref-count-prefix refs.repo 'refs/tags/'))]
      ['lfsObjectCount' n+(decimal (lent ~(tap by lfs-objects.repo)))]
      ['lfsLockCount' n+(decimal (lent ~(tap by lfs-locks.repo)))]
      ['writeTokenSet' b+?=(^ write-token-hash.repo)]
      ['writers' [%a writers-json]]
      ['pullRequests' [%a pulls-json]]
      ['nativeIssues' [%a (turn native-issues.repo |=(issue=native-issue:git (native-issue-json issue %.n)))]]
      ['releases' [%a releases-json]]
      ['webhooks' [%a (turn ~(tap by webhooks.repo) |=(entry=[@ud webhook:git] (webhook-json +.entry)))]]
      ['incomingHookConfigured' b+?=(^ incoming-hook.repo)]
      ['webhookDeliveries' [%a (turn (scag 100 webhook-deliveries.repo) webhook-delivery-json)]]
      ['upstreamUpdates' [%a (turn (dedupe-upstream-updates upstream-updates.repo) upstream-update-json)]]
      ['notificationEvents' [%a notification-events-json]]
      ['githubIssues' [%a (turn github-issues.repo github-item-json)]]
      ['githubPulls' [%a (turn github-pulls.repo github-item-json)]]
      ['binding' (binding-json binding.repo)]
      ['peerOrigin' ?~(peer-origin.repo ~ (pairs:enjs:format ~[['ship' s+(scot %p ship.u.peer-origin.repo)] ['repository' s+repository.u.peer-origin.repo]]))]
      ['githubOrigin' ?~(github-origin.repo ~ (pairs:enjs:format ~[['owner' s+owner.u.github-origin.repo] ['repository' s+repository.u.github-origin.repo]]))]
  ==
::
++  repositories-json
  |=  repos=(map @t repository:git)
  ^-  json
  %-  pairs:enjs:format
  :~  :-  'repositories'
      :-  %a
      %+  turn  ~(tap by repos)
      |=  [name=@t repo=repository:git]
      (repository-json name repo)
  ==
::
++  public-repository-json
  |=  [name=@t repo=repository:git]
  ^-  json
  =/  full=json  (repository-json name repo)
  ?>  ?=([%o *] full)
  =/  fields=(map @t json)  p.full
  =.  fields  (~(del by fields) 'writeTokenSet')
  =.  fields  (~(del by fields) 'writers')
  =.  fields  (~(del by fields) 'binding')
  =.  fields  (~(del by fields) 'peerOrigin')
  =.  fields  (~(del by fields) 'webhooks')
  =.  fields  (~(del by fields) 'incomingHookConfigured')
  =.  fields  (~(del by fields) 'webhookDeliveries')
  =.  fields  (~(del by fields) 'notificationEvents')
  =.  fields  (~(del by fields) 'upstreamUpdates')
  [%o fields]
::
++  latest-file-commits
  |=  [repo=repository:git ref=@t]
  ^-  (map path oid:git)
  =/  start=(unit oid:git)  (revision-oid repo ref)
  ?~  start  ~
  =/  head-files=(unit (map path flat-entry:git-tree))
    (flatten-commit-index:git-tree objects.repo u.start)
  ?~  head-files  ~
  =/  unresolved=(set path)
    %+  roll  ~(tap by u.head-files)
    |=  [entry=[file-path=path value=flat-entry:git-tree] accumulator=(set path)]
    (~(put in accumulator) file-path.entry)
  =/  commits=(map path oid:git)  ~
  =/  current=(unit oid:git)  start
  |-
  ?~  current  commits
  =/  unresolved-paths=(list path)  ~(tap in unresolved)
  ?~  unresolved-paths  commits
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?.  ?&(?=(^ found) =(%commit kind.u.found))  commits
  =/  here=(unit (map path flat-entry:git-tree))
    (flatten-commit-index:git-tree objects.repo u.current)
  ?~  here  commits
  =/  parent=(unit oid:git)  (commit-parent data.u.found)
  =/  before=(map path flat-entry:git-tree)
    ?~  parent  ~
    =/  indexed=(unit (map path flat-entry:git-tree))
      (flatten-commit-index:git-tree objects.repo u.parent)
    ?~(indexed ~ u.indexed)
  =/  remaining=(list path)  unresolved-paths
  =/  updated=[unresolved=(set path) commits=(map path oid:git)]
    |-
    ?~  remaining  [unresolved commits]
    =/  file-path=path  i.remaining
    =/  current-file=(unit flat-entry:git-tree)  (~(get by u.here) file-path)
    =/  parent-file=(unit flat-entry:git-tree)  (~(get by before) file-path)
    ?:  =(current-file parent-file)
      $(remaining t.remaining)
    ?~  current-file
      $(remaining t.remaining)
    %=  $
      remaining   t.remaining
      unresolved  (~(del in unresolved) file-path)
      commits     (~(put by commits) file-path u.current)
    ==
  $(current parent, unresolved unresolved.updated, commits commits.updated)
::
++  repository-files-at-json
  |=  [name=@t repo=repository:git ref=@t]
  ^-  json
  =/  commit=(unit oid:git)  (revision-oid repo ref)
  =/  latest=(map path oid:git)  (latest-file-commits repo ref)
  =/  files=(unit (map path octs))
    ?~  commit  `*(map path octs)
    (flatten-commit:git-tree objects.repo u.commit)
  =/  file-json=(list json)
    ?~  files  ~
    %+  turn  ~(tap by u.files)
    |=  [file-path=path data=octs]
    =/  last-oid=(unit oid:git)  (~(get by latest) file-path)
    =/  last-object=(unit object:git)
      ?~  last-oid  ~
      (~(get by objects.repo) u.last-oid)
    =/  last-commit=json
      ?.  ?&(?=(^ last-oid) ?=(^ last-object) =(%commit kind.u.last-object))  ~
      (commit-summary-json u.last-oid data.u.last-object)
    %-  pairs:enjs:format
    ~[['path' s+(spat file-path)] ['size' n+(decimal p.data)] ['lastCommit' last-commit]]
  %-  pairs:enjs:format
  :~  ['repository' s+name]
      ['head' s+ref]
      ['commit' s+?~(commit '' (oid-text:git-codec u.commit))]
      ['files' [%a file-json]]
  ==
::
++  repository-files-json
  |=  [name=@t repo=repository:git]
  (repository-files-at-json name repo head.repo)
::
++  repository-search-json
  |=  [name=@t repo=repository:git ref=@t query=@t]
  ^-  json
  =/  commit=(unit oid:git)  (revision-oid repo ref)
  =/  files=(unit (map path octs))
    ?~  commit  ~
    (flatten-commit:git-tree objects.repo u.commit)
  =/  remaining=(list [path octs])  ?~(files ~ ~(tap by u.files))
  =/  results=(list json)  ~
  =/  count=@ud  0
  =/  scanned=@ud  0
  =/  finish
    |=  [entries=(list json) matches=@ud files-scanned=@ud truncated=?]
    ^-  json
    %-  pairs:enjs:format
    :~  ['repository' s+name]
        ['head' s+ref]
        ['commit' s+?~(commit '' (oid-text:git-codec u.commit))]
        ['query' s+query]
        ['matchCount' n+(decimal matches)]
        ['filesScanned' n+(decimal files-scanned)]
        ['truncated' b+truncated]
        ['results' [%a (flop entries)]]
    ==
  |-
  ?~  remaining  (finish results count scanned %.n)
  ?:  ?|((gte count 100) (gte scanned 2.000))
    (finish results count scanned %.y)
  =/  file=[file-path=path data=octs]  i.remaining
  =/  file-path=path  file-path.file
  =/  data=octs  data.file
  ?:  ?|(=(0 p.data) (gth p.data 2.097.152) ?=(^ (find-byte:git-clay data 0 0)))
    $(remaining t.remaining, scanned +(scanned))
  =/  scan-line
    |=  [offset=@ud line=@ud entries=(list json) matches=@ud]
    ^-  [(list json) @ud]
    ?:  ?|(=(offset p.data) (gte matches 100))  [entries matches]
    =/  newline=(unit @ud)  (find-byte:git-clay data offset 10)
    =/  end=@ud  ?~(newline p.data u.newline)
    =/  width=@ud  (sub end offset)
    =/  line-data=octs  (slice:git-codec data offset width)
    =/  hit=(unit @ud)  (find-sequence:git-github line-data query 0)
    =/  next-offset=@ud  ?~(newline p.data +(u.newline))
    ?~  hit
      $(offset next-offset, line +(line), entries entries, matches matches)
    =/  preview-start=@ud
      ?:  (gth u.hit 80)
        (sub u.hit 80)
      0
    =/  preview-width=@ud  (min 240 (sub width preview-start))
    =/  preview=octs  (slice:git-codec line-data preview-start preview-width)
    =/  entry=json
      %-  pairs:enjs:format
      :~  ['path' s+(spat file-path)]
          ['line' n+(decimal line)]
          ['column' n+(decimal +(u.hit))]
          ['preview' s+`@t`q.preview]
          ['previewOffset' n+(decimal preview-start)]
      ==
    $(offset next-offset, line +(line), entries [entry entries], matches +(matches))
  =/  searched=[(list json) @ud]  (scan-line 0 1 results count)
  $(remaining t.remaining, results -.searched, count +.searched, scanned +(scanned))
::
++  file-at-commit
  |=  [repo=repository:git commit=oid:git file-path=path]
  ^-  (unit octs)
  =/  files=(unit (map path octs))
    (flatten-commit:git-tree objects.repo commit)
  ?~  files  ~
  (~(get by u.files) file-path)
::
++  revision-oid
  |=  [repo=repository:git revision=@t]
  ^-  (unit oid:git)
  =/  named=(unit oid:git)  (~(get by refs.repo) revision)
  ?^  named  named
  =/  width=@ud  (met 3 revision)
  ?:  =(40 width)
    =/  parsed=(unit oid:git)  (oid-at:git-protocol [40 revision] 0)
    ?~  parsed  ~
    ?.  (~(has by objects.repo) u.parsed)  ~
    parsed
  ?.  ?&((gte width 4) (lth width 40))  ~
  =/  remaining=(list [oid:git object:git])  ~(tap by objects.repo)
  =/  match=(unit oid:git)  ~
  |-
  ?~  remaining  match
  =/  candidate=oid:git  -.i.remaining
  =/  candidate-text=@t  (oid-text:git-codec candidate)
  ?.  (starts-with:git-protocol [(met 3 candidate-text) candidate-text] revision)
    $(remaining t.remaining)
  ?^  match  ~
  $(remaining t.remaining, match `candidate)
::
++  repository-file-at
  |=  [repo=repository:git ref=@t file-path=path]
  ^-  (unit octs)
  =/  commit=(unit oid:git)  (revision-oid repo ref)
  ?~  commit  ~
  (file-at-commit repo u.commit file-path)
::
++  repository-file
  |=  [repo=repository:git file-path=path]
  (repository-file-at repo head.repo file-path)
::
++  repository-file-json
  |=  [name=@t repo=repository:git ref=@t file-path=path data=octs]
  ^-  json
  %-  pairs:enjs:format
  :~  ['repository' s+name]
      ['head' s+ref]
      ['path' s+(spat file-path)]
      ['size' n+(decimal p.data)]
      ['encoding' s+'base64']
      ['content' s+(en:base64:mimes:html data)]
  ==
::
++  repository-file-history-json
  |=  [name=@t repo=repository:git ref=@t file-path=path]
  ^-  json
  =/  current=(unit oid:git)  (revision-oid repo ref)
  =/  entries=(list json)  ~
  =/  count=@ud  0
  |-
  ?:  |(?=(~ current) (gte count 100))
    %-  pairs:enjs:format
    ~[['repository' s+name] ['head' s+ref] ['path' s+(spat file-path)] ['commits' [%a (flop entries)]]]
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?.  ?&(?=(^ found) =(%commit kind.u.found))
    %-  pairs:enjs:format
    ~[['repository' s+name] ['head' s+ref] ['path' s+(spat file-path)] ['commits' [%a (flop entries)]]]
  =/  parent=(unit oid:git)  (commit-parent data.u.found)
  =/  here=(unit octs)  (file-at-commit repo u.current file-path)
  =/  before=(unit octs)
    ?~  parent  ~
    (file-at-commit repo u.parent file-path)
  =/  next-entries=(list json)
    ?:  =(here before)  entries
    =/  entry=json
      %-  pairs:enjs:format
      :~  ['oid' s+(oid-text:git-codec u.current)]
          ['parent' s+?~(parent '' (oid-text:git-codec u.parent))]
          ['subject' s+(commit-subject data.u.found)]
          ['present' b+?=(^ here)]
          ['size' n+(decimal ?~(here 0 p.u.here))]
      ==
    [entry entries]
  $(current parent, entries next-entries, count +(count))
::
++  double-newline
  |=  [data=octs offset=@ud]
  ^-  (unit @ud)
  ?:  (gte +(offset) p.data)  ~
  ?:  ?&  =(10 (byte-at:git-codec data offset))
          =(10 (byte-at:git-codec data +(offset)))
      ==
    `(add offset 2)
  $(offset +(offset))
::
++  commit-header
  |=  [data=octs prefix=@t]
  ^-  (unit @t)
  =/  prefix-width=@ud  (met 3 prefix)
  =/  scan
    |=  offset=@ud
    ^-  (unit @t)
    ?:  (gte offset p.data)  ~
    =/  end=(unit @ud)  (find-byte:git-clay data offset 10)
    ?~  end  ~
    =/  width=@ud  (sub u.end offset)
    ?:  =(width 0)  ~
    =/  line=octs  (slice:git-codec data offset width)
    ?:  (starts-with:git-protocol line prefix)
      =/  value=octs  (slice:git-codec line prefix-width (sub p.line prefix-width))
      =/  text=@t  `@t`q.value
      `text
    $(offset +(u.end))
  (scan 0)
::
++  commit-identity-from-line
  |=  line=@t
  ^-  (unit commit-identity)
  =/  data=octs  [(met 3 line) line]
  =/  open=(unit @ud)  (find-byte:git-clay data 0 60)
  ?~  open  ~
  =/  close=(unit @ud)  (find-byte:git-clay data +(u.open) 62)
  ?~  close  ~
  ?.  (gth u.close +(u.open))  ~
  =/  name-width=@ud
    ?:  ?&  (gth u.open 0)
            =(32 (byte-at:git-codec data (sub u.open 1)))
        ==
      (sub u.open 1)
    u.open
  =/  tail-start=@ud  (add u.close 2)
  ?:  (gte tail-start p.data)  ~
  =/  time-end=(unit @ud)  (find-byte:git-clay data tail-start 32)
  ?~  time-end  ~
  ?:  (gte +(u.time-end) p.data)  ~
  =/  name=octs  (slice:git-codec data 0 name-width)
  =/  email=octs  (slice:git-codec data +(u.open) (sub u.close +(u.open)))
  =/  timestamp=octs  (slice:git-codec data tail-start (sub u.time-end tail-start))
  =/  timezone=octs  (slice:git-codec data +(u.time-end) (sub p.data +(u.time-end)))
  `[`@t`q.name `@t`q.email `@t`q.timestamp `@t`q.timezone]
::
++  commit-identity-at
  |=  [data=octs prefix=@t]
  ^-  (unit commit-identity)
  =/  line=(unit @t)  (commit-header data prefix)
  ?~  line  ~
  (commit-identity-from-line u.line)
::
++  commit-identity-json
  |=  identity=(unit commit-identity)
  ^-  json
  ?~  identity  ~
  %-  pairs:enjs:format
  :~  ['name' s+name.u.identity]
      ['email' s+email.u.identity]
      ['timestamp' s+timestamp.u.identity]
      ['timezone' s+timezone.u.identity]
  ==
::
++  clay-revision-ref
  |=  number=@ud
  ^-  @t
  (cat 3 'r' (decimal number))
::
++  clay-revision-number
  |=  identifier=@t
  ^-  (unit @ud)
  =/  chars=tape  (trip identifier)
  ?.  ?&(?=(^ chars) =('r' i.chars) ?=(^ t.chars))  ~
  (slaw %ud (crip t.chars))
::
++  clay-link-for-revision
  |=  [number=@ud links=(list clay-link:git)]
  ^-  (unit clay-link:git)
  ?~  links  ~
  ?:  =(number clay-revision.i.links)  `i.links
  $(links t.links)
::
++  clay-link-for-commit
  |=  [commit-oid=oid:git links=(list clay-link:git)]
  ^-  (unit clay-link:git)
  ?~  links  ~
  ?:  =(commit-oid commit.i.links)  `i.links
  $(links t.links)
::
++  clay-files-at-revision
  |=  [who=@p desk-name=desk number=@ud now=@da]
  ^-  (unit (map path octs))
  =/  domo=(unit domo:clay)
    (desk-domo:git-clay-history who desk-name now)
  ?~  domo  ~
  ?:  |(=(number 0) (gth number let.u.domo))  ~
  =/  revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name number u.domo)
  ?~  revision  ~
  =/  yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name number tako.u.revision)
  ?~  yaki  ~
  =/  remaining=(list [path lobe:clay])  ~(tap by q.u.yaki)
  =/  result=(map path octs)  ~
  |-
  ?~  remaining  `result
  =/  data=(unit octs)
    (clay-file-octs who desk-name number +.i.remaining now)
  ?~  data  ~
  $(remaining t.remaining, result (~(put by result) -.i.remaining u.data))
::
++  materialize-clay-revision
  |=  [repo=repository:git number=@ud who=@p now=@da]
  ^-  (unit [repo=repository:git commit=oid:git])
  ?~  binding.repo  ~
  =/  existing=(unit clay-link:git)
    (clay-link-for-revision number history.u.binding.repo)
  ?^  existing
    =/  object=(unit object:git)  (~(get by objects.repo) commit.u.existing)
    ?:  ?&(?=(^ object) =(%commit kind.u.object))
      `[repo commit.u.existing]
    ~
  =/  domo=(unit domo:clay)
    (desk-domo:git-clay-history who desk-name.u.binding.repo now)
  ?~  domo  ~
  =/  revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name.u.binding.repo number u.domo)
  ?~  revision  ~
  =/  files=(unit (map path octs))
    (clay-files-at-revision who desk-name.u.binding.repo number now)
  ?~  files  ~
  =/  message=@t
    (rap 3 ~['Clay revision ' (decimal number) ' of %' desk-name.u.binding.repo])
  =/  snapped=(unit [commit=oid:git objects=(map oid:git object:git)])
    (snapshot:git-clay u.files objects.repo ~ who timestamp.u.revision message)
  ?~  snapped  ~
  =/  link=clay-link:git
    [number commit.u.snapped %clay-to-git timestamp.u.revision]
  =/  linked=desk-binding:git
    u.binding.repo(history [link history.u.binding.repo])
  =/  updated=repository:git
    repo(objects objects.u.snapped, binding `linked)
  `[updated commit.u.snapped]
::
++  clay-identity-json
  |=  [who=@p desk-name=desk timestamp=@da]
  ^-  json
  =/  ship-text=@t  (scot %p who)
  %-  pairs:enjs:format
  :~  ['name' s+ship-text]
      ['email' s+(rap 3 ~[ship-text '@urbit'])]
      ['timestamp' s+(decimal (rsh [6 1] (sub timestamp ~1970.1.1)))]
      ['timezone' s+'+0000']
  ==
::
++  clay-revision-summary-json
  |=  [who=@p desk-name=desk revision=revision:git-clay-history binding=desk-binding:git]
  ^-  json
  =/  number=@ud  number.revision
  =/  parent=@t  ?:(=(number 1) '' (clay-revision-ref (dec number)))
  =/  identity=json  (clay-identity-json who desk-name timestamp.revision)
  =/  mapped=(unit clay-link:git)
    (clay-link-for-revision number history.binding)
  %-  pairs:enjs:format
  :~  ['kind' s+'clay']
      ['oid' s+(clay-revision-ref number)]
      ['parent' s+parent]
      ['parents' [%a ?:(=(number 1) ~ ~[s+parent])]]
      ['subject' s+(rap 3 ~['Clay revision ' (decimal number)])]
      ['author' identity]
      ['committer' identity]
      ['revision' n+(decimal number)]
      ['tako' s+(scot %uv tako.revision)]
      ['timestampCase' s+(scot %da timestamp.revision)]
      ['gitCommit' s+?~(mapped '' (oid-text:git-codec commit.u.mapped))]
      ['direction' s+?~(mapped '' direction.u.mapped)]
  ==
::
++  commit-parents
  |=  data=octs
  ^-  (list oid:git)
  =/  offset=@ud  0
  =/  parents=(list oid:git)  ~
  |-
  ?:  (gte offset p.data)  (flop parents)
  =/  end=(unit @ud)  (find-byte:git-clay data offset 10)
  ?~  end  (flop parents)
  =/  width=@ud  (sub u.end offset)
  ?:  =(width 0)  (flop parents)
  =/  line=octs  (slice:git-codec data offset width)
  =/  parent=(unit oid:git)
    ?:  (starts-with:git-protocol line 'parent ')
      (oid-at:git-protocol line 7)
    ~
  =?  parents  ?=(^ parent)  [u.parent parents]
  $(offset +(u.end), parents parents)
::
++  commit-parent
  |=  data=octs
  ^-  (unit oid:git)
  =/  parents=(list oid:git)  (commit-parents data)
  ?~  parents  ~
  `i.parents
::
++  commit-message
  |=  data=octs
  ^-  @t
  =/  start=(unit @ud)  (double-newline data 0)
  ?~  start  ''
  =/  message=octs  (slice:git-codec data u.start (sub p.data u.start))
  `@t`q.message
::
++  commit-subject
  |=  data=octs
  ^-  @t
  =/  text=@t  (commit-message data)
  =/  message=octs  [(met 3 text) text]
  =/  end=(unit @ud)  (find-byte:git-clay message 0 10)
  =/  width=@ud  ?~(end p.message u.end)
  =/  subject=octs  (slice:git-codec message 0 width)
  `@t`q.subject
::
++  commit-summary-json
  |=  [oid=oid:git data=octs]
  ^-  json
  =/  parents=(list oid:git)  (commit-parents data)
  =/  parent=(unit oid:git)  ?~(parents ~ `i.parents)
  %-  pairs:enjs:format
  :~  ['oid' s+(oid-text:git-codec oid)]
      ['parent' s+?~(parent '' (oid-text:git-codec u.parent))]
      ['parents' [%a (turn parents |=(item=oid:git s+(oid-text:git-codec item)))]]
      ['subject' s+(commit-subject data)]
      ['author' (commit-identity-json (commit-identity-at data 'author '))]
      ['committer' (commit-identity-json (commit-identity-at data 'committer '))]
  ==
::
++  repository-commits-json
  |=  [name=@t repo=repository:git ref=@t offset=@ud limit=@ud]
  ^-  json
  =/  current=(unit oid:git)  (revision-oid repo ref)
  =/  entries=(list json)  ~
  =/  scanned=@ud  0
  =/  count=@ud  0
  =/  total=@ud  (first-parent-count repo ref)
  =/  finish
    |=  [more=? page-count=@ud page-entries=(list json)]
    ^-  json
    %-  pairs:enjs:format
    :~  ['repository' s+name]
        ['head' s+ref]
        ['historyKind' s+'git']
        ['commitCount' n+(decimal total)]
        ['offset' n+(decimal offset)]
        ['nextOffset' n+(decimal (add offset page-count))]
        ['hasMore' b+more]
        ['commits' [%a (flop page-entries)]]
    ==
  |-
  ?~  current  (finish %.n count entries)
  ?:  (gte count limit)  (finish %.y count entries)
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?~  found  (finish %.n count entries)
  ?.  =(%commit kind.u.found)  (finish %.n count entries)
  =/  parent=(unit oid:git)  (commit-parent data.u.found)
  ?:  (lth scanned offset)
    $(current parent, scanned +(scanned))
  =/  entry=json  (commit-summary-json u.current data.u.found)
  $(current parent, entries [entry entries], scanned +(scanned), count +(count))
::
++  repository-history-json
  |=  [name=@t repo=repository:git ref=@t who=@p now=@da offset=@ud limit=@ud]
  ^-  json
  ?~  binding.repo
    (repository-commits-json name repo ref offset limit)
  ?.  =(ref branch.u.binding.repo)
    (repository-commits-json name repo ref offset limit)
  =/  native=(unit history:git-clay-history)
    (desk-history:git-clay-history who desk-name.u.binding.repo now (add offset +(limit)))
  ?~  native
    (repository-commits-json name repo ref offset limit)
  =/  page=(list revision:git-clay-history)
    (scag limit (slag offset revisions.u.native))
  =/  entries=(list json)
    %+  turn  page
    |=  revision=revision:git-clay-history
    (clay-revision-summary-json who desk-name.u.binding.repo revision u.binding.repo)
  %-  pairs:enjs:format
  :~  ['repository' s+name]
      ['head' s+ref]
      ['historyKind' s+'clay']
      ['revisionCount' n+(decimal latest.u.native)]
      ['offset' n+(decimal offset)]
      ['nextOffset' n+(decimal (add offset (lent page)))]
      ['hasMore' b+(gth (lent revisions.u.native) (add offset limit))]
      ['commits' [%a entries]]
  ==
::
++  repository-browse-json
  |=  [name=@t repo=repository:git]
  ^-  json
  %-  pairs:enjs:format
  :~  ['revision' s+(repository-revision repo)]
      ['repository' (repository-json name repo)]
      ['files' (repository-files-json name repo)]
      ['commits' (repository-commits-json name repo head.repo 0 50)]
  ==
::
++  repository-revision
  |=  repo=repository:git
  ^-  @t
  =/  visible
    :*  owner.repo
        public-read.repo
        description.repo
        head.repo
        refs.repo
        protected-refs.repo
        writers.repo
        binding.repo
        peer-origin.repo
        github-origin.repo
        github-issues.repo
        github-pulls.repo
        native-pulls.repo
        native-issues.repo
        releases.repo
    ==
  (scot %uv (end 7 (shax (jam visible))))
::
++  repository-stamp-json
  |=  [name=@t repo=repository:git]
  ^-  json
  =/  identity=json
    (pairs:enjs:format ~[['name' s+name]])
  (pairs:enjs:format ~[['repository' identity] ['revision' s+(repository-revision repo)]])
::
++  repository-commit-json
  |=  [name=@t repo=repository:git oid=oid:git]
  ^-  (unit json)
  =/  found=(unit object:git)  (~(get by objects.repo) oid)
  ?.  ?&(?=(^ found) =(%commit kind.u.found))  ~
  =/  parent=(unit oid:git)  (commit-parent data.u.found)
  =/  current-files=(unit (map path octs))  (flatten-commit:git-tree objects.repo oid)
  ?~  current-files  ~
  =/  previous-files=(map path octs)
    ?~  parent  ~
    =/  flattened=(unit (map path octs))  (flatten-commit:git-tree objects.repo u.parent)
    ?~(flattened ~ u.flattened)
  =/  changed=(list json)
    %+  murn  ~(tap by u.current-files)
    |=  entry=[file-path=path data=octs]
    =/  previous=(unit octs)  (~(get by previous-files) file-path.entry)
    ?:  ?&(?=(^ previous) =(data.entry u.previous))  ~
    =/  status=@t  ?~(previous 'added' 'modified')
    =/  old-truncated=?  ?^(previous (gth p.u.previous 262.144) %.n)
    =/  new-truncated=?  (gth p.data.entry 262.144)
    =/  item=json
      %-  pairs:enjs:format
      :~  ['path' s+(spat file-path.entry)]
          ['status' s+status]
          ['oldSize' n+(decimal ?~(previous 0 p.u.previous))]
          ['newSize' n+(decimal p.data.entry)]
          ['oldContent' s+?~(previous '' ?:(old-truncated '' (en:base64:mimes:html u.previous)))]
          ['newContent' s+?:(new-truncated '' (en:base64:mimes:html data.entry))]
          ['truncated' b+|(old-truncated new-truncated)]
      ==
    `item
  =/  deleted=(list json)
    %+  murn  ~(tap by previous-files)
    |=  entry=[file-path=path data=octs]
    ?:  (~(has by u.current-files) file-path.entry)  ~
    =/  truncated=?  (gth p.data.entry 262.144)
    =/  item=json
      %-  pairs:enjs:format
      :~  ['path' s+(spat file-path.entry)]
          ['status' s+'deleted']
          ['oldSize' n+(decimal p.data.entry)]
          ['newSize' n+'0']
          ['oldContent' s+?:(truncated '' (en:base64:mimes:html data.entry))]
          ['newContent' s+'']
          ['truncated' b+truncated]
      ==
    `item
  =/  changes=(list json)  (weld changed deleted)
  =/  tree=(unit @t)  (commit-header data.u.found 'tree ')
  =/  result=json
    %-  pairs:enjs:format
    :~  ['repository' s+name]
        ['commit' (commit-summary-json oid data.u.found)]
        ['tree' s+?~(tree '' u.tree)]
        ['message' s+(commit-message data.u.found)]
        ['changedCount' n+(decimal (lent changes))]
        ['changes' [%a (scag 1.000 changes)]]
    ==
  `result
::
++  clay-file-octs
  |=  [who=@p desk-name=desk number=@ud lobe=lobe:clay now=@da]
  ^-  (unit octs)
  =/  raw=(unit page)
    (revision-page:git-clay-history who desk-name number lobe)
  ?~  raw  ~
  (page-octs who desk-name now u.raw)
::
++  repository-file-at-history
  |=  [repo=repository:git identifier=@t file-path=path who=@p now=@da]
  ^-  (unit octs)
  =/  number=(unit @ud)  (clay-revision-number identifier)
  ?~  number  (repository-file-at repo identifier file-path)
  ?~  binding.repo  (repository-file-at repo identifier file-path)
  =/  desk-name=desk  desk-name.u.binding.repo
  =/  domo=(unit domo:clay)
    (desk-domo:git-clay-history who desk-name now)
  ?~  domo  ~
  =/  revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name u.number u.domo)
  ?~  revision  ~
  =/  yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name u.number tako.u.revision)
  ?~  yaki  ~
  =/  lobe=(unit lobe:clay)  (~(get by q.u.yaki) file-path)
  ?~  lobe  ~
  (clay-file-octs who desk-name u.number u.lobe now)
::
++  clay-file-history-json
  |=  [name=@t repo=repository:git ref=@t file-path=path who=@p now=@da]
  ^-  (unit json)
  ?~  binding.repo  ~
  ?.  =(ref branch.u.binding.repo)  ~
  =/  desk-name=desk  desk-name.u.binding.repo
  =/  native=(unit history:git-clay-history)
    (desk-history:git-clay-history who desk-name now 100)
  ?~  native  ~
  =/  remaining=(list revision:git-clay-history)  revisions.u.native
  =/  entries=(list json)  ~
  |-
  ?~  remaining
    =/  result=json
      %-  pairs:enjs:format
      :~  ['repository' s+name]
          ['head' s+ref]
          ['path' s+(spat file-path)]
          ['historyKind' s+'clay']
          ['revisionCount' n+(decimal latest.u.native)]
          ['commits' [%a (flop entries)]]
      ==
    `result
  =/  revision=revision:git-clay-history  i.remaining
  =/  yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name number.revision tako.revision)
  ?~  yaki  $(remaining t.remaining)
  =/  here=(unit lobe:clay)  (~(get by q.u.yaki) file-path)
  =/  before=(unit lobe:clay)
    ?~  t.remaining  ~
    =/  prior=revision:git-clay-history  i.t.remaining
    =/  prior-yaki=(unit yaki:clay)
      (revision-yaki:git-clay-history who desk-name number.prior tako.prior)
    ?~  prior-yaki  ~
    (~(get by q.u.prior-yaki) file-path)
  ?:  =(here before)  $(remaining t.remaining)
  =/  data=(unit octs)
    ?~  here  ~
    (clay-file-octs who desk-name number.revision u.here now)
  =/  summary=json
    (clay-revision-summary-json who desk-name revision u.binding.repo)
  ?>  ?=([%o *] summary)
  =/  fields=(map @t json)  p.summary
  =.  fields  (~(put by fields) 'present' b+?=(^ here))
  =.  fields  (~(put by fields) 'size' n+(decimal ?~(data 0 p.u.data)))
  =/  item=json  [%o fields]
  $(remaining t.remaining, entries [item entries])
::
++  repository-file-history-view-json
  |=  [name=@t repo=repository:git ref=@t file-path=path who=@p now=@da]
  ^-  json
  =/  native=(unit json)
    (clay-file-history-json name repo ref file-path who now)
  ?~  native  (repository-file-history-json name repo ref file-path)
  u.native
::
++  blame-safe
  |=  data=octs
  ^-  ?
  ?&  (lte p.data 262.144)
      ?=(~ (find-byte:git-clay data 0 0))
  ==
::
++  compact-blame-sources
  |=  [slots=(list slot:git-blame) sources=(list json)]
  ^-  blame-table
  =/  used=(set @ud)
    (silt (turn slots |=(item=slot:git-blame source.item)))
  =/  remaining=(list json)  sources
  =/  old-index=@ud  0
  =/  selected=(list json)  ~
  =/  remap=(map @ud @ud)  ~
  |-
  ?~  remaining  [selected remap]
  ?.  (~(has in used) old-index)
    $(remaining t.remaining, old-index +(old-index))
  =.  remap  (~(put by remap) old-index (lent selected))
  $(remaining t.remaining, old-index +(old-index), selected (weld selected ~[i.remaining]), remap remap)
::
++  blame-lines-json
  |=  [slots=(list slot:git-blame) remap=(map @ud @ud)]
  ^-  (list json)
  =/  remaining=(list slot:git-blame)  slots
  =/  number=@ud  1
  =/  entries=(list json)  ~
  |-
  ?~  remaining  (flop entries)
  =/  mapped=(unit @ud)  (~(get by remap) source.i.remaining)
  ?>  ?=(^ mapped)
  =/  item=json
    %-  pairs:enjs:format
    ~[['line' n+(decimal number)] ['source' n+(decimal u.mapped)]]
  $(remaining t.remaining, number +(number), entries [item entries])
::
++  file-blame-result-json
  |=  $:  name=@t
          ref=@t
          file-path=path
          kind=@t
          slots=(list slot:git-blame)
          sources=(list json)
          truncated=?
      ==
  ^-  json
  =/  table=blame-table  (compact-blame-sources slots sources)
  %-  pairs:enjs:format
  :~  ['repository' s+name]
      ['head' s+ref]
      ['path' s+(spat file-path)]
      ['historyKind' s+kind]
      ['lineCount' n+(decimal (lent slots))]
      ['sourceCount' n+(decimal (lent sources.table))]
      ['truncated' b+truncated]
      ['sources' [%a sources.table]]
      ['lines' [%a (blame-lines-json slots remap.table)]]
  ==
::
++  git-file-blame-json
  |=  [name=@t repo=repository:git ref=@t file-path=path]
  ^-  (unit json)
  =/  current=(unit oid:git)  (revision-oid repo ref)
  ?~  current  ~
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?.  ?&(?=(^ found) =(%commit kind.u.found))  ~
  =/  current-data=(unit octs)  (file-at-commit repo u.current file-path)
  ?.  ?&(?=(^ current-data) (blame-safe u.current-data))  ~
  =/  slots=(list slot:git-blame)  (seed:git-blame u.current-data)
  ?:  (gth (lent slots) 10.000)  ~
  =/  sources=(list json)  ~[(commit-summary-json u.current data.u.found)]
  =/  cursor=oid:git  u.current
  =/  cursor-data=octs  data.u.found
  =/  scanned=@ud  1
  |-
  ?:  !(any-active:git-blame slots)
    `(file-blame-result-json name ref file-path 'git' slots sources %.n)
  ?:  (gte scanned 200)
    `(file-blame-result-json name ref file-path 'git' slots sources %.y)
  =/  parent=(unit oid:git)  (commit-parent cursor-data)
  ?~  parent
    `(file-blame-result-json name ref file-path 'git' slots sources %.n)
  =/  parent-object=(unit object:git)  (~(get by objects.repo) u.parent)
  ?.  ?&(?=(^ parent-object) =(%commit kind.u.parent-object))
    `(file-blame-result-json name ref file-path 'git' slots sources %.y)
  =/  parent-data=(unit octs)  (file-at-commit repo u.parent file-path)
  ?~  parent-data
    `(file-blame-result-json name ref file-path 'git' (deactivate:git-blame slots) sources %.n)
  ?.  (blame-safe u.parent-data)
    `(file-blame-result-json name ref file-path 'git' slots sources %.y)
  =/  next-slots=(list slot:git-blame)
    (step:git-blame slots u.parent-data scanned)
  =/  next-sources=(list json)
    (weld sources ~[(commit-summary-json u.parent data.u.parent-object)])
  $(slots next-slots, sources next-sources, cursor u.parent, cursor-data data.u.parent-object, scanned +(scanned))
::
++  clay-file-blame-json
  |=  [name=@t repo=repository:git ref=@t file-path=path who=@p now=@da]
  ^-  (unit json)
  ?~  binding.repo  ~
  =/  desk-name=desk  desk-name.u.binding.repo
  =/  domo=(unit domo:clay)
    (desk-domo:git-clay-history who desk-name now)
  ?~  domo  ~
  =/  requested=(unit @ud)  (clay-revision-number ref)
  =/  number=@ud
    ?~  requested
      ?.  =(ref branch.u.binding.repo)  0
      let.u.domo
    u.requested
  ?:  |(=(number 0) (gth number let.u.domo))  ~
  =/  revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name number u.domo)
  ?~  revision  ~
  =/  yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name number tako.u.revision)
  ?~  yaki  ~
  =/  lobe=(unit lobe:clay)  (~(get by q.u.yaki) file-path)
  ?~  lobe  ~
  =/  current-data=(unit octs)
    (clay-file-octs who desk-name number u.lobe now)
  ?.  ?&(?=(^ current-data) (blame-safe u.current-data))  ~
  =/  slots=(list slot:git-blame)  (seed:git-blame u.current-data)
  ?:  (gth (lent slots) 10.000)  ~
  =/  sources=(list json)
    ~[(clay-revision-summary-json who desk-name u.revision u.binding.repo)]
  =/  cursor=@ud  number
  =/  scanned=@ud  1
  |-
  ?:  !(any-active:git-blame slots)
    `(file-blame-result-json name ref file-path 'clay' slots sources %.n)
  ?:  =(cursor 1)
    `(file-blame-result-json name ref file-path 'clay' slots sources %.n)
  ?:  (gte scanned 200)
    `(file-blame-result-json name ref file-path 'clay' slots sources %.y)
  =/  parent-number=@ud  (dec cursor)
  =/  parent-revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name parent-number u.domo)
  ?~  parent-revision
    `(file-blame-result-json name ref file-path 'clay' slots sources %.y)
  =/  parent-yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name parent-number tako.u.parent-revision)
  ?~  parent-yaki
    `(file-blame-result-json name ref file-path 'clay' slots sources %.y)
  =/  parent-lobe=(unit lobe:clay)  (~(get by q.u.parent-yaki) file-path)
  ?~  parent-lobe
    `(file-blame-result-json name ref file-path 'clay' (deactivate:git-blame slots) sources %.n)
  =/  parent-data=(unit octs)
    (clay-file-octs who desk-name parent-number u.parent-lobe now)
  ?.  ?&(?=(^ parent-data) (blame-safe u.parent-data))
    `(file-blame-result-json name ref file-path 'clay' slots sources %.y)
  =/  next-slots=(list slot:git-blame)
    (step:git-blame slots u.parent-data scanned)
  =/  next-sources=(list json)
    (weld sources ~[(clay-revision-summary-json who desk-name u.parent-revision u.binding.repo)])
  $(slots next-slots, sources next-sources, cursor parent-number, scanned +(scanned))
::
++  repository-file-blame-view-json
  |=  [name=@t repo=repository:git ref=@t file-path=path who=@p now=@da]
  ^-  (unit json)
  =/  native=(unit json)
    (clay-file-blame-json name repo ref file-path who now)
  ?~  native  (git-file-blame-json name repo ref file-path)
  native
::
++  clay-change-json
  |=  [file-path=path previous=(unit octs) current=(unit octs)]
  ^-  json
  =/  status=@t  ?~(current 'deleted' ?~(previous 'added' 'modified'))
  =/  old-truncated=?  ?^(previous (gth p.u.previous 262.144) %.n)
  =/  new-truncated=?  ?^(current (gth p.u.current 262.144) %.n)
  %-  pairs:enjs:format
  :~  ['path' s+(spat file-path)]
      ['status' s+status]
      ['oldSize' n+(decimal ?~(previous 0 p.u.previous))]
      ['newSize' n+(decimal ?~(current 0 p.u.current))]
      ['oldContent' s+?~(previous '' ?:(old-truncated '' (en:base64:mimes:html u.previous)))]
      ['newContent' s+?~(current '' ?:(new-truncated '' (en:base64:mimes:html u.current)))]
      ['truncated' b+|(old-truncated new-truncated)]
  ==
::
++  clay-change-placeholder-json
  |=  [file-path=path status=@t]
  ^-  json
  %-  pairs:enjs:format
  :~  ['path' s+(spat file-path)]
      ['status' s+status]
      ['oldSize' n+'0']
      ['newSize' n+'0']
      ['oldContent' s+'']
      ['newContent' s+'']
      ['truncated' b+%.y]
  ==
::
++  clay-revision-detail-json
  |=  [name=@t repo=repository:git number=@ud who=@p now=@da]
  ^-  (unit json)
  ?~  binding.repo  ~
  =/  desk-name=desk  desk-name.u.binding.repo
  =/  domo=(unit domo:clay)
    (desk-domo:git-clay-history who desk-name now)
  ?~  domo  ~
  ?:  |(=(number 0) (gth number let.u.domo))  ~
  =/  revision=(unit revision:git-clay-history)
    (revision-meta:git-clay-history who desk-name number u.domo)
  ?~  revision  ~
  =/  current-yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history who desk-name number tako.u.revision)
  ?~  current-yaki  ~
  =/  previous-number=(unit @ud)  ?:(=(number 1) ~ `(dec number))
  =/  previous-yaki=(unit yaki:clay)
    ?~  previous-number  ~
    =/  previous-tako=(unit tako:clay)  (~(get by hit.u.domo) u.previous-number)
    ?~  previous-tako  ~
    (revision-yaki:git-clay-history who desk-name u.previous-number u.previous-tako)
  =/  previous-files=(map path lobe:clay)
    ?~(previous-yaki *(map path lobe:clay) q.u.previous-yaki)
  =/  current-files=(map path lobe:clay)  q.u.current-yaki
  =/  changed-files=(list [path lobe:clay])
    %+  skim  ~(tap by current-files)
    |=  entry=[file-path=path lobe=lobe:clay]
    =/  old-lobe=(unit lobe:clay)  (~(get by previous-files) file-path.entry)
    !=(old-lobe `lobe.entry)
  =/  rich-changed=(list json)
    %+  murn  (scag 12 changed-files)
    |=  entry=[file-path=path lobe=lobe:clay]
    =/  old-lobe=(unit lobe:clay)  (~(get by previous-files) file-path.entry)
    =/  current=(unit octs)
      (clay-file-octs who desk-name number lobe.entry now)
    =/  previous=(unit octs)
      ?~  previous-number  ~
      ?~  old-lobe  ~
      (clay-file-octs who desk-name u.previous-number u.old-lobe now)
    `(clay-change-json file-path.entry previous current)
  =/  remaining-changed=(list json)
    %+  turn  (scag 488 (slag 12 changed-files))
    |=  entry=[file-path=path lobe=lobe:clay]
    =/  old-lobe=(unit lobe:clay)  (~(get by previous-files) file-path.entry)
    =/  status=@t  ?~(old-lobe 'added' 'modified')
    (clay-change-placeholder-json file-path.entry status)
  =/  deleted-files=(list [path lobe:clay])
    %+  skim  ~(tap by previous-files)
    |=  entry=[file-path=path lobe=lobe:clay]
    =(%.n (~(has by current-files) file-path.entry))
  =/  rich-deleted=(list json)
    %+  murn  (scag 12 deleted-files)
    |=  entry=[file-path=path lobe=lobe:clay]
    =/  previous=(unit octs)
      ?~  previous-number  ~
      (clay-file-octs who desk-name u.previous-number lobe.entry now)
    `(clay-change-json file-path.entry previous ~)
  =/  remaining-deleted=(list json)
    %+  turn  (scag 488 (slag 12 deleted-files))
    |=  entry=[file-path=path lobe=lobe:clay]
    (clay-change-placeholder-json file-path.entry 'deleted')
  =/  changes=(list json)
    :(weld rich-changed remaining-changed rich-deleted remaining-deleted)
  =/  total-changes=@ud  (add (lent changed-files) (lent deleted-files))
  =/  summary=json
    (clay-revision-summary-json who desk-name u.revision u.binding.repo)
  =/  result=json
    %-  pairs:enjs:format
    :~  ['repository' s+name]
        ['historyKind' s+'clay']
        ['commit' summary]
        ['tree' s+(scot %uv tako.u.revision)]
        ['message' s+(rap 3 ~['Clay revision ' (decimal number)])]
        ['revision' n+(decimal number)]
        ['tako' s+(scot %uv tako.u.revision)]
        ['timestampCase' s+(scot %da timestamp.u.revision)]
        ['changedCount' n+(decimal total-changes)]
        ['changesTruncated' b+(gth total-changes 1.000)]
        ['changes' [%a changes]]
    ==
  `result
::
++  repository-history-detail-json
  |=  [name=@t repo=repository:git identifier=@t who=@p now=@da]
  ^-  (unit json)
  =/  clay-number=(unit @ud)  (clay-revision-number identifier)
  ?~  clay-number
    =/  parsed=(unit oid:git)  (revision-oid repo identifier)
    ?~  parsed  ~
    (repository-commit-json name repo u.parsed)
  ?~  binding.repo
    =/  parsed=(unit oid:git)  (revision-oid repo identifier)
    ?~  parsed  ~
    (repository-commit-json name repo u.parsed)
  (clay-revision-detail-json name repo u.clay-number who now)
::
++  repository-diff-json
  |=  [name=@t repo=repository:git base=oid:git head=oid:git]
  ^-  (unit json)
  =/  base-files=(unit (map path octs))  (flatten-commit:git-tree objects.repo base)
  =/  head-files=(unit (map path octs))  (flatten-commit:git-tree objects.repo head)
  ?.  ?&(?=(^ base-files) ?=(^ head-files))  ~
  =/  changed=(list json)
    %+  murn  ~(tap by u.head-files)
    |=  entry=[file-path=path data=octs]
    =/  previous=(unit octs)  (~(get by u.base-files) file-path.entry)
    ?:  ?&(?=(^ previous) =(data.entry u.previous))  ~
    =/  status=@t  ?~(previous 'added' 'modified')
    =/  old-truncated=?  ?^(previous (gth p.u.previous 262.144) %.n)
    =/  new-truncated=?  (gth p.data.entry 262.144)
    =/  item=json
      %-  pairs:enjs:format
      :~  ['path' s+(spat file-path.entry)]
          ['status' s+status]
          ['oldSize' n+(decimal ?~(previous 0 p.u.previous))]
          ['newSize' n+(decimal p.data.entry)]
          ['oldContent' s+?~(previous '' ?:(old-truncated '' (en:base64:mimes:html u.previous)))]
          ['newContent' s+?:(new-truncated '' (en:base64:mimes:html data.entry))]
          ['truncated' b+|(old-truncated new-truncated)]
      ==
    `item
  =/  deleted=(list json)
    %+  murn  ~(tap by u.base-files)
    |=  entry=[file-path=path data=octs]
    ?:  (~(has by u.head-files) file-path.entry)  ~
    =/  truncated=?  (gth p.data.entry 262.144)
    =/  item=json
      %-  pairs:enjs:format
      :~  ['path' s+(spat file-path.entry)]
          ['status' s+'deleted']
          ['oldSize' n+(decimal p.data.entry)]
          ['newSize' n+'0']
          ['oldContent' s+?:(truncated '' (en:base64:mimes:html data.entry))]
          ['newContent' s+'']
          ['truncated' b+truncated]
      ==
    `item
  =/  changes=(list json)  (weld changed deleted)
  =/  result=json
    %-  pairs:enjs:format
    :~  ['repository' s+name]
        ['base' s+(oid-text:git-codec base)]
        ['head' s+(oid-text:git-codec head)]
        ['changedCount' n+(decimal (lent changes))]
        ['changesTruncated' b+(gth (lent changes) 1.000)]
        ['changes' [%a (scag 1.000 changes)]]
    ==
  `result
::
++  first-parent-count
  |=  [repo=repository:git ref=@t]
  ^-  @ud
  =/  current=(unit oid:git)  (revision-oid repo ref)
  =/  count=@ud  0
  |-
  ?:  |(?=(~ current) (gte count 10.000))  count
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?.  ?&(?=(^ found) =(%commit kind.u.found))  count
  $(current (commit-parent data.u.found), count +(count))
::
++  ref-count-prefix
  |=  [refs=(map @t oid:git) prefix=@t]
  ^-  @ud
  =/  matching=(list [@t oid:git])
    %+  skim  ~(tap by refs)
    |=  entry=[@t oid:git]
    =/  ref=@t  -.entry
    (starts-with:git-protocol [(met 3 ref) ref] prefix)
  (lent matching)
::
++  settle-webhook-repository
  |=  repo=repository:git
  ^-  repository:git
  =/  deliveries=(list webhook-delivery:git)
    %+  turn  webhook-deliveries.repo
    |=  delivery=webhook-delivery:git
    ?:  =(%pending status.delivery)
      delivery(status %failure, status-code 0, message 'delivery interrupted by agent restart')
    delivery
  %=  repo
    webhook-deliveries  deliveries
    upstream-updates    (dedupe-upstream-updates upstream-updates.repo)
  ==
::
++  migrate-repository-0
  |=  repo=repository-0:git
  ^-  repository:git
  :*  owner.repo
      public-read.repo
      description.repo
      head.repo
      refs.repo
      protected-refs.repo
      objects.repo
      writers.repo
      write-token-hash.repo
      lfs-objects.repo
      lfs-uploads.repo
      lfs-locks.repo
      binding.repo
      peer-origin.repo
      github-origin.repo
      github-issues.repo
      github-pulls.repo
      native-pulls.repo
      native-issues.repo
      releases.repo
      webhooks.repo
      incoming-hook.repo
      webhook-deliveries.repo
      upstream-updates.repo
      default-notification-events
  ==
::
++  migrate-state-0
  |=  stored=state-0:git
  ^-  state-1:git
  =/  remaining=(list [@t repository-0:git])  ~(tap by repositories.stored)
  =/  migrated=(map @t repository:git)  ~
  =.  migrated
    |-
    ?~  remaining  migrated
    =.  migrated
      (~(put by migrated) -.i.remaining (migrate-repository-0 +.i.remaining))
    $(remaining t.remaining)
  [%1 migrated peers.stored github-token.stored]
::
++  settle-webhook-state
  |=  stored=state-1:git
  ^-  state-1:git
  =/  remaining=(list [@t repository:git])  ~(tap by repositories.stored)
  =/  settled=(map @t repository:git)  ~
  |-
  ?~  remaining  stored(repositories settled)
  %=  $
    remaining  t.remaining
    settled    (~(put by settled) -.i.remaining (settle-webhook-repository +.i.remaining))
  ==
::
++  peer-browse-join
  |=  [pages=(map @ud [length=@ud data=@]) expected=@ud]
  ^-  (unit @)
  =/  revision=@ud  1
  =/  offset=@ud  0
  =/  encoded=@  0
  |-
  ?:  (gth revision expected)  `encoded
  =/  page=(unit [length=@ud data=@])  (~(get by pages) revision)
  ?~  page  ~
  =/  page-length=@ud  -.u.page
  =/  page-data=@  +.u.page
  %=  $
    revision  +(revision)
    offset    (add offset page-length)
    encoded   (mix encoded (lsh [3 offset] page-data))
  ==
::
++  peer-browse-yawns
  |=  [request=@uv peer=ship pages=@ud]
  ^-  (list card)
  %+  turn  (gulf 1 pages)
  |=  revision=@ud
  =/  scry-path=path
    /g/x/(scot %ud revision)/urgit//1/browse/(scot %uv request)
  [%pass /peer/browse-cancel/(scot %uv request)/(scot %ud revision) %arvo %a %yawn [peer scry-path]]
::
++  peer-fine-name
  |=  transfer=@uv
  ^-  @ta
  (scot %uv (cut 0 [0 64] transfer))
--
::
%-  agent:dbug
=|  state-1:git
=*  state  -
=/  in-flight  *(map @uv lfs-request)
=/  lfs-deletes  *(map @uv lfs-delete)
=/  request-count=@ud  0
=/  pending-clay  *(unit clay-push)
=/  pending-publish  *(unit publish-job)
=/  peer-serving  *(map @uv peer-serve)
=/  peer-receiving  *(map @uv peer-receive)
=/  peer-results  *(map @uv peer-result)
=/  peer-discoveries  *(map @uv peer-discovery)
=/  peer-browses  *(map @uv peer-browse)
=/  peer-browse-serving  *(map @uv peer-browse-serve)
=/  peer-forges  *(map @uv peer-forge)
=/  peer-activities  *(list peer-activity)
=/  notification-activities  *(list notification-activity)
=/  github-in-flight  *(map @uv github-request)
=/  github-results  *(map @uv github-result)
=/  webhook-in-flight  *(map @uv webhook-flight)
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %urgit]
      [%pass /eyre/api-connect %arvo %e %connect [~ /apps/urgit/api] %urgit]
  ==
::
++  on-save
  !>(state)
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  loaded=state-1:git
    ?:  ?=([%0 *] q.old)
      (settle-webhook-state (migrate-state-0 !<(state-0:git old)))
    (settle-webhook-state !<(state-1:git old))
  :_  this(state loaded, in-flight ~, lfs-deletes ~, request-count 0, pending-clay ~, pending-publish ~, peer-serving ~, peer-receiving ~, peer-results ~, peer-discoveries ~, peer-browses ~, peer-browse-serving ~, peer-forges ~, peer-activities ~, notification-activities ~, github-in-flight ~, github-results ~, webhook-in-flight ~)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %urgit]
      [%pass /eyre/api-connect %arvo %e %connect [~ /apps/urgit/api] %urgit]
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+  mark  (on-poke:def mark vase)
      %git-action
    ?>  =(src.bowl our.bowl)
    (handle-action !<(action:git vase))
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    (handle-http eyre-id req)
  ::
      %git-peer
    (handle-peer !<(packet:git-peer vase))
  ::
      %git-webhook-event
    ?>  =(src.bowl our.bowl)
    =/  trigger=webhook-trigger:git  !<(webhook-trigger:git vase)
    (dispatch-webhooks repository.trigger event.trigger data.trigger)
  ==
::
++  peer-card
  |=  [target=ship wire=wire packet=packet:git-peer]
  ^-  card
  [%pass wire %agent [target %urgit] %poke %git-peer !>(packet)]
::
++  peer-activity-put
  |=  event=peer-activity
  ^-  (list peer-activity)
  =/  others=(list peer-activity)
    %+  skim  peer-activities
    |=  existing=peer-activity
    !=(id.event id.existing)
  =/  combined=(list peer-activity)  [event others]
  (scag 50 combined)
::
++  peer-activity-start
  |=  [id=@uv kind=peer-activity-kind direction=?(%incoming %outgoing) peer=ship repository=@t message=@t]
  ^-  (list peer-activity)
  (peer-activity-put [id kind direction peer repository %active message now.bowl])
::
++  peer-activity-finish
  |=  [id=@uv ok=? message=@t]
  ^-  (list peer-activity)
  %+  turn  peer-activities
  |=  event=peer-activity
  ?:  !=(id id.event)  event
  event(status ?:(ok %success %failure), message message, when now.bowl)
::
++  notification-activity-put
  |=  event=notification-activity
  ^-  (list notification-activity)
  =/  combined=(list notification-activity)  [event notification-activities]
  (scag 50 combined)
::
++  peer-transfer-yawns
  |=  [transfer=@uv peer=ship pages=@ud completed=(set @ud)]
  ^-  (list card)
  %+  murn  (gulf 1 pages)
  |=  revision=@ud
  =/  issued=?
    ?:  =(revision 1)  %.y
    (~(has in completed) (sub revision 1))
  ?.  ?&(issued !(~(has in completed) revision))  ~
  =/  scry-path=path
    /g/x/(scot %ud revision)/urgit//1/fine/(peer-fine-name transfer)
  `[%pass /peer/fine-cancel/(scot %uv transfer)/(scot %ud revision) %arvo %a %yawn [peer scry-path]]
::
++  peer-object-pages
  |=  objects=(list [oid:git object:git])
  ^-  (list octs)
  =/  remaining  objects
  =/  page=(map oid:git object:git)  ~
  =/  pages=(list octs)  ~
  =/  count=@ud  0
  =/  bytes=@ud  0
  =/  packed-page
    |=  entries=(map oid:git object:git)
    ^-  octs
    (encode-pack:git-pack ~(val by entries))
  |-
  ?~  remaining
    ?:  =(count 0)
      ?~  pages  [(packed-page page) ~]
      (flop pages)
    (flop [(packed-page page) pages])
  =/  object-bytes=@ud  (add 64 p.data.+.i.remaining)
  =/  page-full=?
    |(=(count 256) ?&((gth count 0) (gth (add bytes object-bytes) 524.288)))
  ?:  page-full
    $(page ~, pages [(packed-page page) pages], count 0, bytes 0)
  =/  next-page=(map oid:git object:git)
    (~(put by page) -.i.remaining +.i.remaining)
  %=  $
    remaining  t.remaining
    page       next-page
    count      +(count)
    bytes      (add bytes object-bytes)
  ==
::
++  peer-browse-pages
  |=  result=json
  ^-  (list [length=@ud data=@])
  =/  encoded=@  (jam result)
  =/  size=@ud  (met 3 encoded)
  =/  offset=@ud  0
  =/  pages=(list [length=@ud data=@])  ~
  |-
  ?:  =(offset size)  (flop pages)
  =/  length=@ud  (min 65.536 (sub size offset))
  =/  data=@  (cut 3 [offset length] encoded)
  $(offset (add offset length), pages [[length data] pages])
::
++  peer-fail
  |=  [target=ship transfer=@uv message=@t]
  ^-  (quip card _this)
  :_  this
  :~  (peer-card target /peer/error/(scot %uv transfer) [%error transfer message])
  ==
::
++  peer-valid-refs
  |=  [refs=(map @t oid:git) objects=(map oid:git object:git)]
  ^-  ?
  %+  levy  ~(tap by refs)
  |=  entry=[@t oid:git]
  (~(has by objects) +.entry)
::
++  peer-finish
  |=  transfer=@uv
  ^-  (quip card _this)
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  =/  flight=peer-receive  u.found
  ?.  ?&  =(expected.flight received.flight)
          (peer-valid-refs refs.flight objects.flight)
          (~(has by refs.flight) head.flight)
      ==
    =.  peer-receiving  (~(del by peer-receiving) transfer)
    =.  peer-results  (~(put by peer-results) transfer [%.n 'received repository graph is incomplete' local-repository.flight])
    =.  peer-activities
      (peer-activity-finish transfer %.n 'received repository graph is incomplete')
    `this
  =/  existing=(unit repository:git)  (~(get by repositories) local-repository.flight)
  ?:  =(%pull purpose.flight)
    ?~  existing
      (peer-push-finish flight transfer %.n 'destination repository disappeared')
    =/  incoming=(unit oid:git)  (~(get by refs.flight) head.flight)
    =/  base=(unit oid:git)  (~(get by refs.u.existing) head.u.existing)
    ?~  incoming
      (peer-push-finish flight transfer %.n 'pull request requires source and destination branch heads')
    ?~  base
      (peer-push-finish flight transfer %.n 'pull request requires source and destination branch heads')
    ?>  ?=(^ incoming)
    ?>  ?=(^ base)
    =/  incoming-oid=oid:git  u.incoming
    =/  base-oid=oid:git  u.base
    =/  number=@ud  (add 1 (lent native-pulls.u.existing))
    =/  pull=native-pull:git
      [number source.flight source-repository.flight title.flight %open incoming-oid base-oid ~]
    =/  updated=repository:git
      u.existing(objects objects.flight, native-pulls [pull native-pulls.u.existing])
    =.  repositories  (~(put by repositories) local-repository.flight updated)
    =/  notice=notification-result
      %-  repository-notification
      :*  local-repository.flight
          updated
          %pull-request
          /[local-repository.flight]/pull/(scot %ud number)
          (rap 3 ~[(scot %p source.flight) ' opened pull request #' (decimal number) ' in ' local-repository.flight ': ' title.flight])
      ==
    =.  notification-activities
      ?~  activity.notice
        notification-activities
      (notification-activity-put u.activity.notice)
    =/  notices=(list card)  cards.notice
    =/  finished=(quip card _this)
      (peer-push-finish flight transfer %.y (rap 3 ~['pull request #' (decimal number) ' opened']))
    [(weld notices -.finished) +.finished]
  ?:  =(%push purpose.flight)
    ?~  existing
      (peer-push-finish flight transfer %.n 'destination repository disappeared')
    ?.  =(head.flight head.u.existing)
      (peer-push-finish flight transfer %.n 'default branch does not match destination')
    =/  incoming=(unit oid:git)  (~(get by refs.flight) head.flight)
    ?~  incoming
      (peer-push-finish flight transfer %.n 'source default branch is missing')
    =/  previous=(unit oid:git)  (~(get by refs.u.existing) head.u.existing)
    =/  reachable=(unit (set oid:git))
      (reachable:git-graph objects.flight (silt ~[u.incoming]))
    =/  fast-forward=?
      ?~  previous  %.y
      ?~  reachable  %.n
      (~(has in u.reachable) u.previous)
    ?.  fast-forward
      (peer-push-finish flight transfer %.n 'update is not a fast-forward')
    =/  updated=repository:git
      u.existing(objects objects.flight, refs (~(put by refs.u.existing) head.u.existing u.incoming))
    ?^  binding.updated
      ?:  ?|(=(^ pending-clay) =(^ pending-publish))
        (peer-push-finish flight transfer %.n 'another Clay operation is in progress')
      =/  files=(unit (map path octs))
        (flatten-commit:git-clay objects.updated u.incoming)
      ?~  files
        (peer-push-finish flight transfer %.n 'linked branch must resolve to a valid desk-shaped Git commit')
      =/  delta=(unit nori:clay)
        (clay-delta desk-name.u.binding.updated u.files)
      ?~  delta
        (peer-push-finish flight transfer %.n 'unable to read linked Clay desk')
      ?>  ?=(%& -.u.delta)
      ?:  =(~ p.u.delta)
        =.  repositories  (~(put by repositories) local-repository.flight updated)
        (peer-push-finish flight transfer %.y 'fast-forward update accepted')
      =/  start-at=@da  (add now.bowl ~s1)
      =/  timeout-at=@da  (add now.bowl ~s15)
      =/  pending=clay-push
        :*  'peer'
            %.n
            `[[source.flight transfer]]
            local-repository.flight
            ~
            updated
            desk-name.u.binding.updated
            branch.u.binding.updated
            u.incoming
            u.delta
            ~
            start-at
            timeout-at
        ==
      =.  peer-receiving  (~(del by peer-receiving) transfer)
      =.  pending-clay  `pending
      :_  this
      :~  [%pass /clay-start %arvo %b %wait start-at]
          [%pass /clay-timeout %arvo %b %wait timeout-at]
      ==
    =.  repositories  (~(put by repositories) local-repository.flight updated)
    (peer-push-finish flight transfer %.y 'fast-forward update accepted')
  =/  repo=repository:git
    ?~  existing
      :*  our.bowl
          public-read.flight
          ''
          head.flight
          refs.flight
          ~
          objects.flight
          (silt ~[our.bowl])
          ~
          ~
          ~
          ~
          ~
          `[[source.flight source-repository.flight]]
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          default-notification-events
      ==
    u.existing(head head.flight, refs refs.flight, objects objects.flight, peer-origin `[[source.flight source-repository.flight]])
  =.  repositories  (~(put by repositories) local-repository.flight repo)
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-results  (~(put by peer-results) transfer [%.y 'complete' local-repository.flight])
  =.  peer-activities  (peer-activity-finish transfer %.y 'fork complete')
  `this
::
++  peer-push-finish
  |=  [flight=peer-receive transfer=@uv ok=? message=@t]
  ^-  (quip card _this)
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-activities  (peer-activity-finish transfer ok message)
  :_  this
  :~  (peer-card source.flight /peer/result/(scot %uv transfer) [%result transfer ok message])
  ==
::
++  peer-error
  |=  [transfer=@uv message=@t]
  ^-  (quip card _this)
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  ?.  =(src.bowl source.u.found)  `this
  =/  flight=peer-receive  u.found
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-results  (~(put by peer-results) transfer [%.n message local-repository.u.found])
  =.  peer-activities  (peer-activity-finish transfer %.n message)
  :_  this
  ?:  =('' head.flight)  ~
  (peer-transfer-yawns transfer source.flight pages.flight completed.flight)
::
++  handle-peer
  |=  packet=packet:git-peer
  ^-  (quip card _this)
  ?-  -.packet
      %request
    (peer-request request.packet)
  ::
      %accepted
    (peer-accepted accepted.packet)
  ::
      %prepare
    ?>  =(src.bowl our.bowl)
    (peer-prepare target.prepare.packet request.prepare.packet)
  ::
      %ready
    (peer-ready ready.packet)
  ::
      %begin
    (peer-begin begin.packet)
  ::
      %catalog-request
    (peer-catalog-request catalog-request.packet)
  ::
      %catalog
    (peer-catalog catalog.packet)
  ::
      %catalog-error
    (peer-catalog-error request.packet message.packet)
  ::
      %browse-request
    (peer-browse-request request.packet repository.packet view.packet number.packet file-path.packet)
  ::
      %browse-ready
    (peer-browse-ready request.packet repository.packet target.packet pages.packet)
  ::
      %browse-response
    (peer-browse-response request.packet repository.packet result.packet)
  ::
      %browse-begin
    (peer-browse-begin request.packet repository.packet pages.packet)
  ::
      %browse-release
    (peer-browse-release request.packet)
  ::
      %browse-error
    (peer-browse-error request.packet message.packet)
  ::
      %forge-comment
    (peer-forge-comment comment.packet)
  ::
      %forge-create-issue
    (peer-forge-create-issue issue.packet)
  ::
      %forge-result
    (peer-forge-result request.packet repository.packet kind.packet number.packet ok.packet message.packet result.packet)
  ::
      %offer
    (peer-offer offer.packet)
  ::
      %release
    (peer-release transfer.packet)
  ::
      %snapshot
    (peer-snapshot transfer.packet objects.packet)
  ::
      %snapshot-error
    (peer-snapshot-fail transfer.packet message.packet)
  ::
      %result
    (peer-result-received transfer.packet ok.packet message.packet)
  ::
      %error
    (peer-error transfer.packet message.packet)
  ==
::
++  peer-catalog-request
  |=  msg=catalog-request:git-peer
  ^-  (quip card _this)
  =/  public-repositories=(list catalog-repository:git-peer)
    %+  murn  ~(tap by repositories)
    |=  entry=[@t repository:git]
    =/  name=@t  -.entry
    =/  repo=repository:git  +.entry
    ?.  public-read.repo  ~
    `[name head.repo (lent ~(tap by refs.repo)) (lent ~(tap by objects.repo)) (~(has in writers.repo) src.bowl)]
  :_  this
  :~  (peer-card src.bowl /peer/catalog/(scot %uv request.msg) [%catalog request.msg (scag 200 public-repositories)])
  ==
::
++  peer-catalog
  |=  msg=catalog:git-peer
  ^-  (quip card _this)
  =/  found=(unit peer-discovery)  (~(get by peer-discoveries) request.msg)
  ?~  found  `this
  ?.  =(src.bowl peer.u.found)  `this
  =.  peer-discoveries
    (~(put by peer-discoveries) request.msg u.found(active %.n, ok %.y, message 'complete', repositories repositories.msg))
  `this
::
++  peer-catalog-error
  |=  [request=@uv message=@t]
  ^-  (quip card _this)
  =/  found=(unit peer-discovery)  (~(get by peer-discoveries) request)
  ?~  found  `this
  ?.  =(src.bowl peer.u.found)  `this
  =.  peer-discoveries
    (~(put by peer-discoveries) request u.found(active %.n, ok %.n, message message))
  `this
::
++  peer-browse-request
  |=  [request=@uv repository=@t view=browse-view:git-peer number=@ud file-path=path]
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository)
  ?.  ?&(?=(^ found) public-read.u.found)
    :_  this
    :~  (peer-card src.bowl /peer/browse-error/(scot %uv request) [%browse-error request 'repository is unavailable or not public'])
    ==
  =/  detail=(unit json)
    ?:  =(%stamp view)
      `(repository-stamp-json repository u.found)
    ?:  =(%overview view)
      `(repository-browse-json repository u.found)
    ?:  =(%issue view)
      =/  issue=(unit native-issue:git)  (native-issue-at u.found number)
      ?~  issue  ~
      `(pairs:enjs:format ~[['repository' (repository-json repository u.found)] ['issue' (native-issue-json u.issue %.y)]])
    ?:  =(%pull view)
      =/  pull=(unit native-pull:git)  (native-pull-at u.found number)
      ?~  pull  ~
      =/  pull-json=(unit json)  (native-pull-detail-json repository u.found u.pull)
      ?~  pull-json  ~
      `(pairs:enjs:format ~[['repository' (repository-json repository u.found)] ['pull' u.pull-json]])
    ?:  =(%commit view)
      ?~  file-path  ~
      (repository-history-detail-json repository u.found i.file-path our.bowl now.bowl)
    =/  data=(unit octs)  (repository-file u.found file-path)
    ?~  data  ~
    ?:  (gth p.u.data 4.194.304)  ~
    `(pairs:enjs:format ~[['repository' (repository-json repository u.found)] ['file' (repository-file-json repository u.found head.u.found file-path u.data)]])
  ?~  detail
    :_  this
    :~  (peer-card src.bowl /peer/browse-error/(scot %uv request) [%browse-error request 'requested item is unavailable, incomplete, or too large to preview'])
    ==
  =/  browse-path=path  /browse/(scot %uv request)
  =/  result=json  u.detail
  =/  pages=(list [length=@ud data=@])  (peer-browse-pages result)
  =.  peer-browse-serving
    (~(put by peer-browse-serving) request [src.bowl (lent pages)])
  :_  this
  =/  page-cards=(list card)
    %+  turn  pages
    |=  page=[length=@ud data=@]
    [%pass /peer/browse-grow/(scot %uv request) %grow browse-path noun+!>(page)]
  =/  ready-cards=(list card)
    :~  [%pass /peer/browse-ready/(scot %uv request) %agent [our.bowl %urgit] %poke %git-peer !>([%browse-ready request repository src.bowl (lent pages)])]
    ==
  (weld page-cards ready-cards)
::
++  peer-browse-ready
  |=  [request=@uv repository=@t target=ship pages=@ud]
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  :_  this
  :~  (peer-card target /peer/browse-begin/(scot %uv request) [%browse-begin request repository pages])
  ==
::
++  peer-browse-response
  |=  [request=@uv repository=@t result=json]
  ^-  (quip card _this)
  =/  found=(unit peer-browse)  (~(get by peer-browses) request)
  ?~  found  `this
  ?.  ?&  active.u.found
          =(src.bowl peer.u.found)
          =(repository repository.u.found)
      ==
    `this
  =/  valid=?
    ?.  ?=([%o *] result)  %.n
    =/  repository-json=(unit json)  (~(get by p.result) 'repository')
    ?~  repository-json  %.n
    ?.  ?=([%o *] u.repository-json)  %.n
    =/  name-json=(unit json)  (~(get by p.u.repository-json) 'name')
    ?~  name-json  %.n
    ?&(?=([%s *] u.name-json) =(p.u.name-json repository))
  ?.  valid
    =.  peer-browses
      (~(put by peer-browses) request u.found(active %.n, ok %.n, message 'peer browse result has the wrong repository identity'))
    `this
  =.  peer-browses
    (~(put by peer-browses) request u.found(active %.n, ok %.y, message 'complete', result `result))
  `this
::
++  peer-browse-begin
  |=  [request=@uv repository=@t pages=@ud]
  ^-  (quip card _this)
  =/  found=(unit peer-browse)  (~(get by peer-browses) request)
  ?~  found  `this
  ?.  ?&  active.u.found
          =(src.bowl peer.u.found)
          =(repository repository.u.found)
      ==
    `this
  ?:  =(%fine phase.u.found)  `this
  ?.  (gth pages 0)
    =.  peer-browses
      (~(put by peer-browses) request u.found(active %.n, ok %.n, message 'peer browse announced an empty Fine transfer'))
    `this
  =.  peer-browses
    (~(put by peer-browses) request u.found(phase %fine, message 'reading peer overview over Fine', progress [~ [16 0 pages]], progress-at now.bowl, expected pages, received 0, parts ~))
  :_  this
  =/  page-reads=(list card)
    %+  turn  (gulf 1 pages)
    |=  revision=@ud
    =/  scry-path=path
      /g/x/(scot %ud revision)/urgit//1/browse/(scot %uv request)
    [%pass /peer/browse/(scot %uv request)/(scot %ud revision) %keen %.n src.bowl scry-path]
  =/  stall-cards=(list card)
    :~  [%pass /peer/browse-stall/(scot %uv request) %arvo %b %wait (add now.bowl ~s30)]
    ==
  (weld page-reads stall-cards)
::
++  peer-browse-release
  |=  request=@uv
  ^-  (quip card _this)
  =/  found=(unit peer-browse-serve)  (~(get by peer-browse-serving) request)
  ?~  found  `this
  ?.  =(src.bowl target.u.found)  `this
  =/  culls=(list card)
    %+  turn  (gulf 1 pages.u.found)
    |=  revision=@ud
    [%pass /peer/browse-cull/(scot %uv request)/(scot %ud revision) %cull [%ud revision] /browse/(scot %uv request)]
  :_  this(peer-browse-serving (~(del by peer-browse-serving) request))
  culls
::
++  peer-browse-error
  |=  [request=@uv message=@t]
  ^-  (quip card _this)
  =/  found=(unit peer-browse)  (~(get by peer-browses) request)
  ?~  found  `this
  ?.  =(src.bowl peer.u.found)  `this
  =.  peer-browses
    (~(put by peer-browses) request u.found(active %.n, ok %.n, message message))
  `this
::
++  peer-forge-reply
  |=  [target=ship request=@uv repository=@t kind=forge-kind:git-peer number=@ud ok=? message=@t result=(unit json)]
  ^-  (quip card _this)
  :_  this
  :~  (peer-card target /peer/forge-result/(scot %uv request) [%forge-result request repository kind number ok message result])
  ==
::
++  peer-forge-comment
  |=  msg=forge-comment:git-peer
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository.msg)
  ?.  ?&(?=(^ found) public-read.u.found)
    (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.n 'repository is unavailable or not public' ~)
  ?:  =(%issue kind.msg)
    =/  issue=(unit native-issue:git)  (native-issue-at u.found number.msg)
    ?~  issue
      (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.n 'issue not found' ~)
    =/  comment=issue-comment:git
      [(add 1 (lent comments.u.issue)) src.bowl body.msg now.bowl]
    =/  updated-issue=native-issue:git
      u.issue(comments (weld comments.u.issue ~[comment]), updated now.bowl)
    =/  issues=(list native-issue:git)
      %+  turn  native-issues.u.found
      |=  candidate=native-issue:git
      ?:(=(number.candidate number.msg) updated-issue candidate)
    =/  updated-repo=repository:git  u.found(native-issues issues)
    =.  repositories  (~(put by repositories) repository.msg updated-repo)
    =/  notice=notification-result
      %-  repository-notification
      :*  repository.msg
          updated-repo
          %issue-comment
          /[repository.msg]/issue/(scot %ud number.msg)
          (rap 3 ~[(scot %p src.bowl) ' commented on issue #' (decimal number.msg) ' in ' repository.msg ': ' title.updated-issue])
      ==
    =.  notification-activities
      ?~  activity.notice
        notification-activities
      (notification-activity-put u.activity.notice)
    =/  notices=(list card)  cards.notice
    =/  replied=(quip card _this)
      (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.y 'comment added' `(native-issue-json updated-issue %.y))
    [(weld notices -.replied) +.replied]
  =/  pull=(unit native-pull:git)  (native-pull-at u.found number.msg)
  ?~  pull
    (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.n 'pull request not found' ~)
  =/  comment=review-comment:git
    [(add 1 (lent comments.u.pull)) src.bowl body.msg now.bowl ~ ~ ~ %.n]
  =/  updated-pull=native-pull:git
    u.pull(comments (weld comments.u.pull ~[comment]))
  =/  pulls=(list native-pull:git)
    %+  turn  native-pulls.u.found
    |=  candidate=native-pull:git
    ?:(=(number.candidate number.msg) updated-pull candidate)
  =/  updated-repo=repository:git  u.found(native-pulls pulls)
  =.  repositories  (~(put by repositories) repository.msg updated-repo)
  =/  result=(unit json)
    (native-pull-detail-json repository.msg updated-repo updated-pull)
  ?~  result
    (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.n 'comment was added but pull request detail could not be rendered' ~)
  =/  notice=notification-result
    %-  repository-notification
    :*  repository.msg
        updated-repo
        %pull-comment
        /[repository.msg]/pull/(scot %ud number.msg)
        (rap 3 ~[(scot %p src.bowl) ' commented on pull request #' (decimal number.msg) ' in ' repository.msg ': ' title.updated-pull])
    ==
  =.  notification-activities
    ?~  activity.notice
      notification-activities
    (notification-activity-put u.activity.notice)
  =/  notices=(list card)  cards.notice
  =/  replied=(quip card _this)
    (peer-forge-reply src.bowl request.msg repository.msg kind.msg number.msg %.y 'comment added' `u.result)
  [(weld notices -.replied) +.replied]
::
++  peer-forge-create-issue
  |=  msg=forge-create-issue:git-peer
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository.msg)
  ?.  ?&(?=(^ found) public-read.u.found)
    (peer-forge-reply src.bowl request.msg repository.msg %issue 0 %.n 'repository is unavailable or not public' ~)
  ?.  ?&  !=('' title.msg)
          (lte (met 3 title.msg) 200)
          (lte (met 3 body.msg) 65.536)
      ==
    (peer-forge-reply src.bowl request.msg repository.msg %issue 0 %.n 'title is required and limited to 200 bytes; body is limited to 64 KiB' ~)
  =/  number=@ud  (add 1 (lent native-issues.u.found))
  =/  issue=native-issue:git
    [number src.bowl title.msg body.msg %open ~ ~ now.bowl now.bowl ~]
  =.  repositories
    (~(put by repositories) repository.msg u.found(native-issues [issue native-issues.u.found]))
  =/  updated-repo=repository:git  u.found(native-issues [issue native-issues.u.found])
  =/  result=json  (native-issue-json issue %.y)
  =/  notice=notification-result
    %-  repository-notification
    :*  repository.msg
        updated-repo
        %issue
        /[repository.msg]/issue/(scot %ud number)
        (rap 3 ~[(scot %p src.bowl) ' opened issue #' (decimal number) ' in ' repository.msg ': ' title.msg])
    ==
  =.  notification-activities
    ?~  activity.notice
      notification-activities
    (notification-activity-put u.activity.notice)
  =/  notices=(list card)  cards.notice
  =/  dispatched=(quip card _this)
    (dispatch-webhooks repository.msg %issue result)
  =/  reply-cards=(list card)
    :~  (peer-card src.bowl /peer/forge-result/(scot %uv request.msg) [%forge-result request.msg repository.msg %issue 0 %.y 'issue opened' `result])
    ==
  :_  +.dispatched
  (weld -.dispatched (weld notices reply-cards))
::
++  peer-forge-result
  |=  [request=@uv repository=@t kind=forge-kind:git-peer number=@ud ok=? message=@t result=(unit json)]
  ^-  (quip card _this)
  =/  found=(unit peer-forge)  (~(get by peer-forges) request)
  ?~  found  `this
  ?.  ?&  active.u.found
          =(src.bowl peer.u.found)
          =(repository repository.u.found)
          =(kind kind.u.found)
          =(number number.u.found)
      ==
    `this
  =.  peer-forges
    (~(put by peer-forges) request u.found(active %.n, ok ok, message message, result result))
  `this
::
++  peer-offer
  |=  offer=offer:git-peer
  ^-  (quip card _this)
  =/  activity-kind=peer-activity-kind
    ?:(pull-request.offer %pull-request %push)
  =.  peer-activities
    (peer-activity-start transfer.offer activity-kind %incoming src.bowl repository.offer 'update offered')
  =/  found=(unit repository:git)  (~(get by repositories) repository.offer)
  ?~  found
    =.  peer-activities
      (peer-activity-finish transfer.offer %.n 'destination repository not found')
    (peer-fail src.bowl transfer.offer 'destination repository not found')
  ?.  |(pull-request.offer (~(has in writers.u.found) src.bowl))
    =.  peer-activities
      (peer-activity-finish transfer.offer %.n 'ship is not authorized to update this repository')
    (peer-fail src.bowl transfer.offer 'ship is not authorized to update this repository')
  ?:  (~(has by peer-receiving) transfer.offer)
    =.  peer-activities
      (peer-activity-finish transfer.offer %.n 'transfer identifier is already active')
    (peer-fail src.bowl transfer.offer 'transfer identifier is already active')
  =/  haves=(set oid:git)
    (silt (turn ~(tap by objects.u.found) |=(entry=[oid:git object:git] -.entry)))
  =/  flight=peer-receive
    :*  ?:(pull-request.offer %pull %push)
        src.bowl
        source-repository.offer
        repository.offer
        title.offer
        public-read.u.found
        %.n
        ''
        ~
        0
        0
        0
        ~
        now.bowl
        ~
        objects.u.found
    ==
  =.  peer-receiving  (~(put by peer-receiving) transfer.offer flight)
  :_  this
  :~  (peer-card src.bowl /peer/request/(scot %uv transfer.offer) [%request transfer.offer source-repository.offer haves])
      [%pass /peer/request-timeout/(scot %uv transfer.offer) %arvo %b %wait (add now.bowl ~s45)]
  ==
::
++  peer-result-received
  |=  [transfer=@uv ok=? message=@t]
  ^-  (quip card _this)
  =/  found=(unit peer-result)  (~(get by peer-results) transfer)
  ?~  found  `this
  =.  peer-results  (~(put by peer-results) transfer [ok message repository.u.found])
  =.  peer-activities  (peer-activity-finish transfer ok message)
  `this
::
++  peer-request
  |=  req=request:git-peer
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository.req)
  ?~  found  (peer-fail src.bowl transfer.req 'repository not found')
  =/  origin-request=?
    ?~  peer-origin.u.found  %.n
    =(src.bowl ship.u.peer-origin.u.found)
  ?.  |(public-read.u.found origin-request)
    (peer-fail src.bowl transfer.req 'repository is not public')
  ?:  (~(has by peer-serving) transfer.req)
    :_  this
    :~  (peer-card src.bowl /peer/accepted/(scot %uv transfer.req) [%accepted transfer.req repository.req])
    ==
  :_  this
  :~  (peer-card src.bowl /peer/accepted/(scot %uv transfer.req) [%accepted transfer.req repository.req])
      [%pass /peer/prepare/(scot %uv transfer.req) %agent [our.bowl %urgit] %poke %git-peer !>([%prepare src.bowl req])]
  ==
::
++  peer-accepted
  |=  msg=accepted:git-peer
  ^-  (quip card _this)
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer.msg)
  ?~  found  `this
  ?.  ?&  =(src.bowl source.u.found)
          =(repository.msg source-repository.u.found)
      ==
    `this
  =/  next=peer-receive  u.found(accepted %.y, progress-at now.bowl)
  =.  peer-receiving  (~(put by peer-receiving) transfer.msg next)
  =.  peer-results
    (~(put by peer-results) transfer.msg [%.n 'peer is preparing repository snapshot' local-repository.u.found])
  :_  this
  :~  [%pass /peer/prepare-timeout/(scot %uv transfer.msg) %arvo %b %wait (add now.bowl ~m10)]
  ==
::
++  peer-prepare
  |=  [target=ship req=request:git-peer]
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository.req)
  ?~  found  (peer-fail target transfer.req 'repository not found')
  =/  origin-request=?
    ?~  peer-origin.u.found  %.n
    =(target ship.u.peer-origin.u.found)
  ?.  |(public-read.u.found origin-request)
    (peer-fail target transfer.req 'repository is not public')
  ?:  (~(has by peer-serving) transfer.req)
    `this
  =/  superseded=(list [@uv peer-serve])
    %+  skim  ~(tap by peer-serving)
    |=  entry=[@uv peer-serve]
    =/  prior=peer-serve  +.entry
    ?&  =(target target.prior)
        =(repository.req repository.prior)
    ==
  =/  superseded-ids=(set @uv)
    (silt (turn superseded |=(entry=[@uv peer-serve] -.entry)))
  =/  cleanup-cards=(list card)
    %-  zing
    %+  turn  superseded
    |=  entry=[@uv peer-serve]
    =/  old-transfer=@uv  -.entry
    =/  old=peer-serve  +.entry
    ?:  =(pages.old 0)  ~
    %+  turn  (gulf 1 pages.old)
    |=  revision=@ud
    [%pass /peer/cull/(scot %uv old-transfer)/(scot %ud revision) %cull [%ud revision] /fine/(peer-fine-name old-transfer)]
  =.  peer-serving
    %-  malt
    %+  murn  ~(tap by peer-serving)
    |=  entry=[@uv peer-serve]
    ?:  (~(has in superseded-ids) -.entry)  ~
    `entry
  =.  peer-activities
    %+  turn  peer-activities
    |=  event=peer-activity
    ?.  (~(has in superseded-ids) id.event)  event
    event(status %failure, message 'repository snapshot superseded by a newer request', when now.bowl)
  =/  objects=(list [oid:git object:git])
    %+  murn  ~(tap by objects.u.found)
    |=  entry=[oid:git object:git]
    ?:  (~(has in haves.req) -.entry)  ~
    `entry
  =/  pages=(list octs)  (peer-object-pages objects)
  =/  flight=peer-serve  [target transfer.req repository.req (lent pages) objects]
  =.  peer-serving  (~(put by peer-serving) transfer.req flight)
  =.  peer-activities
    (peer-activity-start transfer.req %serve %incoming target repository.req 'repository snapshot requested')
  =/  snapshot-path=path  /fine/(peer-fine-name transfer.req)
  =/  object-pages=(list card)
    %+  turn  pages
    |=  page=octs
    [%pass /peer/grow/(scot %uv transfer.req) %grow snapshot-path noun+!>(page)]
  =/  final-cards=(list card)
    :~  [%pass /peer/ready/(scot %uv transfer.req) %agent [our.bowl %urgit] %poke %git-peer !>([%ready transfer.req repository.req head.u.found refs.u.found (lent objects) (lent pages)])]
        [%pass /peer/serve-timeout/(scot %uv transfer.req) %arvo %b %wait (add now.bowl ~m10)]
    ==
  :_  this
  (weld cleanup-cards (weld object-pages final-cards))
::
++  peer-ready
  |=  msg=ready:git-peer
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  =/  found=(unit peer-serve)  (~(get by peer-serving) transfer.msg)
  ?~  found  `this
  :_  this
  :~  (peer-card target.u.found /peer/begin/(scot %uv transfer.msg) [%begin transfer.msg repository.msg 1 head.msg refs.msg objects.msg pages.msg])
  ==
::
++  peer-begin
  |=  msg=begin:git-peer
  ^-  (quip card _this)
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer.msg)
  ?~  found  `this
  ?.  ?&  =(src.bowl source.u.found)
          =(repository.msg source-repository.u.found)
      ==
    `this
  ?.  ?&  (gth pages.msg 0)
          (lte pages.msg (max 1 objects.msg))
      ==
    :_  this
    :~  [%pass /peer/begin-error/(scot %uv transfer.msg) %agent [our.bowl %urgit] %poke %git-peer !>([%snapshot-error transfer.msg 'peer announced an invalid Fine page count'])]
    ==
  =/  next=peer-receive
    u.found(head head.msg, refs refs.msg, expected objects.msg, pages pages.msg, completed ~, progress-at now.bowl, fine-progress ~)
  =.  peer-receiving  (~(put by peer-receiving) transfer.msg next)
  =.  peer-results
    (~(put by peer-results) transfer.msg [%.n 'reading repository over Fine' local-repository.u.found])
  ?:  =(src.bowl our.bowl)
    =/  serving=(unit peer-serve)  (~(get by peer-serving) transfer.msg)
    ?~  serving
      (peer-snapshot-fail transfer.msg 'local repository snapshot is unavailable')
    (peer-snapshot transfer.msg (silt objects.u.serving))
  :_  this
  =/  scry-path=path
    /g/x/1/urgit//1/fine/(peer-fine-name transfer.msg)
  :~  [%pass /peer/fine/(scot %uv transfer.msg)/1 %keen %.n src.bowl scry-path]
  ==
::
++  peer-release
  |=  transfer=@uv
  ^-  (quip card _this)
  =/  found=(unit peer-serve)  (~(get by peer-serving) transfer)
  ?~  found  `this
  ?.  =(src.bowl target.u.found)  `this
  =.  peer-activities  (peer-activity-finish transfer %.y 'repository snapshot delivered')
  =/  count=@ud  pages.u.found
  =/  culls=(list card)
    ?:  =(0 count)  ~
    %+  turn  (gulf 1 count)
    |=  revision=@ud
    [%pass /peer/cull/(scot %uv transfer)/(scot %ud revision) %cull [%ud revision] /fine/(peer-fine-name transfer)]
  :_  this(peer-serving (~(del by peer-serving) transfer))
  culls
::
++  peer-snapshot-fail
  |=  [transfer=@uv message=@t]
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  =/  flight=peer-receive  u.found
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-activities  (peer-activity-finish transfer %.n message)
  =/  release=card
    (peer-card source.flight /peer/release/(scot %uv transfer) [%release transfer])
  =/  cancel-cards=(list card)
    ?:  =('' head.flight)  ~
    (peer-transfer-yawns transfer source.flight pages.flight completed.flight)
  ?:  =(%fork purpose.flight)
    =.  peer-results
      (~(put by peer-results) transfer [%.n message local-repository.flight])
    [(weld cancel-cards [release ~]) this]
  =/  result-cards=(list card)
    :~  release
        (peer-card source.flight /peer/result/(scot %uv transfer) [%result transfer %.n message])
    ==
  :_  this
  (weld cancel-cards result-cards)
::
++  peer-snapshot
  |=  [transfer=@uv incoming=(map oid:git object:git)]
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  =/  flight=peer-receive  u.found
  =/  count=@ud  (lent ~(tap by incoming))
  ?.  (lte (add received.flight count) expected.flight)
    (peer-snapshot-fail transfer 'Fine repository snapshot exceeded the expected object count')
  ?:  ?&  (gth expected.flight 0)
          =(count 0)
      ==
    (peer-snapshot-fail transfer 'Fine repository snapshot contained an empty object page')
  =/  novel=?
    %+  levy  ~(tap by incoming)
    |=  entry=[oid:git object:git]
    !(~(has by objects.flight) -.entry)
  ?.  novel
    (peer-snapshot-fail transfer 'Fine repository snapshot contained a duplicate object')
  =/  valid=?
    %+  levy  ~(tap by incoming)
    |=  entry=[oid:git object:git]
    =/  object=object:git  +.entry
    =(-.entry (object-oid:git-codec kind.object data.object))
  ?.  valid
    (peer-snapshot-fail transfer 'Fine repository object failed content-address validation')
  =/  next=peer-receive
    flight(objects (merge-objects objects.flight incoming), received (add received.flight count), progress-at now.bowl)
  =.  peer-receiving  (~(put by peer-receiving) transfer next)
  ?.  =(received.next expected.next)
    `this
  =/  finished=(quip card _this)  (peer-finish transfer)
  =/  release=card
    (peer-card source.flight /peer/release/(scot %uv transfer) [%release transfer])
  [(weld [release ~] -.finished) +.finished]
::
++  handle-action
  |=  act=action:git
  ^-  (quip card _this)
  ?-  -.act
      %create
    ?:  (~(has by repositories) name.act)
      `this
    =/  repo=repository:git
      :*  our.bowl
          public-read.act
          ''
          'refs/heads/main'
          ~
          ~
          ~
          (silt ~[our.bowl])
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          ~
          default-notification-events
      ==
    `this(repositories (~(put by repositories) name.act repo))
  ::
      %delete
    `this(repositories (~(del by repositories) name.act))
  ::
      %put-object
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  oid=oid:git  (object-oid:git-codec kind.act data.act)
    =/  repo=repository:git  u.found(objects (~(put by objects.u.found) oid [kind.act data.act]))
    `this(repositories (~(put by repositories) repository.act repo))
  ::
      %set-ref
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    ?.  (~(has by objects.u.found) oid.act)  `this
    =/  old=(unit oid:git)  (~(get by refs.u.found) ref.act)
    =/  repo=repository:git  u.found(refs (~(put by refs.u.found) ref.act oid.act))
    =.  repositories  (~(put by repositories) repository.act repo)
    (dispatch-webhooks repository.act %push (push-event-json ~[[old `oid.act ref.act]]))
  ::
      %delete-ref
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  old=(unit oid:git)  (~(get by refs.u.found) ref.act)
    ?~  old  `this
    =/  repo=repository:git  u.found(refs (~(del by refs.u.found) ref.act))
    =.  repositories  (~(put by repositories) repository.act repo)
    (dispatch-webhooks repository.act %push (push-event-json ~[[old ~ ref.act]]))
  ::
      %set-protected
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    ?.  ?&  (valid-ref:git-protocol ref.act)
            (starts-with 'refs/heads/' ref.act)
        ==
      `this
    =/  protected-refs=(set @t)
      ?:(protected.act (~(put in protected-refs.u.found) ref.act) (~(del in protected-refs.u.found) ref.act))
    =/  repo=repository:git  u.found(protected-refs protected-refs)
    `this(repositories (~(put by repositories) repository.act repo))
  ::
      %set-head
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    `this(repositories (~(put by repositories) repository.act u.found(head ref.act)))
  ::
      %set-public
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    `this(repositories (~(put by repositories) repository.act u.found(public-read public-read.act)))
  ::
      %set-description
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  clean=@t  (crip (scag 500 (trip description.act)))
    `this(repositories (~(put by repositories) repository.act u.found(description clean)))
  ::
      %grant-writer
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  repo=repository:git  u.found(writers (~(put in writers.u.found) writer.act))
    `this(repositories (~(put by repositories) repository.act repo))
  ::
      %revoke-writer
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  repo=repository:git  u.found(writers (~(del in writers.u.found) writer.act))
    `this(repositories (~(put by repositories) repository.act repo))
  ::
      %set-write-token
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  digest=@  (shas %git-write-token token.act)
    `this(repositories (~(put by repositories) repository.act u.found(write-token-hash `digest)))
  ::
      %clear-write-token
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    `this(repositories (~(put by repositories) repository.act u.found(write-token-hash ~)))
  ::
      %bind-desk
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    ?.  (valid-ref:git-protocol branch.act)  `this
    ?.  (starts-with 'refs/heads/' branch.act)  `this
    =/  desks=(unit (set desk))
      %-  mole
      |.(.^((set desk) %cd /(scot %p our.bowl)//(scot %da now.bowl)))
    ?~  desks  `this
    ?.  (~(has in u.desks) desk-name.act)  `this
    =/  binding=desk-binding:git  [desk-name.act branch.act ~ ~ ~]
    `this(repositories (~(put by repositories) repository.act u.found(binding `binding)))
  ::
      %unbind-desk
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    `this(repositories (~(put by repositories) repository.act u.found(binding ~)))
  ::
      %publish-desk
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    ?~  binding.u.found  `this
    ?^  pending-clay  `this
    ?^  pending-publish  `this
    =/  desks=(unit (set desk))
      %-  mole
      |.(.^((set desk) %cd /(scot %p our.bowl)//(scot %da now.bowl)))
    ?~  desks  `this
    ?.  (~(has in u.desks) desk-name.u.binding.u.found)  `this
    =/  desk-files=(unit (list spur))
      %-  mole
      |.(.^((list spur) %ct /(scot %p our.bowl)/[desk-name.u.binding.u.found]/(scot %da now.bowl)))
    ?~  desk-files  `this
    =/  job=publish-job
      :*  repository.act
          desk-name.u.binding.u.found
          branch.u.binding.u.found
          ~
          message.act
          u.desk-files
          ~
      ==
    ?~  paths.job
      =/  published=(unit repository:git)
        (publish-repository u.found job our.bowl now.bowl)
      ?~  published  `this
      =.  repositories  (~(put by repositories) repository.job u.published)
      `this
    :_  this(pending-publish `job)
    (publish-next job)
  ::
      %add-peer
    `this(peers (~(put in peers) peer.act))
  ::
      %remove-peer
    `this(peers (~(del in peers) peer.act))
  ==
::
++  publish-next
  |=  job=publish-job
  ^-  (list card)
  ?~  paths.job  ~
  :~  [%pass /clay-publish %arvo %c %warp our.bowl desk-name.job ~ %sing %q da+now.bowl i.paths.job]
  ==
::
++  query-value
  |=  [key=@t args=(list [key=@t value=@t])]
  ^-  (unit @t)
  ?~  args  ~
  ?:  =(key key.i.args)  `value.i.args
  $(args t.args)
::
++  decimal
  |=  value=@ud
  ^-  @t
  (crip ((d-co:co 1) value))
::
++  starts-with
  |=  [prefix=@t value=@t]
  ^-  ?
  =/  pre=tape  (trip prefix)
  =/  val=tape  (trip value)
  ?.  (lte (lent pre) (lent val))  %.n
  =(pre (scag (lent pre) val))
::
++  repository-name
  |=  segment=@t
  ^-  @t
  =/  chars=tape  (trip segment)
  ?.  (gte (lent chars) 4)  segment
  ?.  =(".git" (slag (sub (lent chars) 4) chars))  segment
  (crip (scag (sub (lent chars) 4) chars))
::
++  json-at
  |=  [key=@t jon=json]
  ^-  (unit json)
  ?.  ?=([%o *] jon)  ~
  (~(get by p.jon) key)
::
++  string-at
  |=  [key=@t jon=json]
  ^-  (unit @t)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=([%s *] u.value)  ~
  `p.u.value
::
++  parse-decimal
  |=  text=@t
  ^-  (unit @ud)
  =/  chars=tape  (trip text)
  ?~  chars  ~
  =/  parse
    |=  [remaining=tape value=@ud]
    ^-  (unit @ud)
    ?~  remaining  `value
    ?.  ?&((gte i.remaining '0') (lte i.remaining '9'))  ~
    $(remaining t.remaining, value (add (mul value 10) (sub i.remaining '0')))
  (parse chars 0)
::
++  nat-at
  |=  [key=@t jon=json]
  ^-  (unit @ud)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=([%n *] u.value)  ~
  (parse-decimal p.u.value)
::
++  bool-at
  |=  [key=@t jon=json]
  ^-  (unit ?)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=([%b *] u.value)  ~
  `p.u.value
::
++  string-list-at
  |=  [key=@t jon=json]
  ^-  (unit (list @t))
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=([%a *] u.value)  ~
  =/  items=(list json)  p.u.value
  =/  out=(list @t)  ~
  |-
  ?~  items  `(flop out)
  ?.  ?=([%s *] i.items)  ~
  $(items t.items, out [p.i.items out])
::
++  webhook-events-at
  |=  [key=@t jon=json]
  ^-  (unit (set webhook-event:git))
  =/  values=(unit (list @t))  (string-list-at key jon)
  ?~  values  ~
  =/  remaining=(list @t)  u.values
  =/  events=(set webhook-event:git)  ~
  |-
  ?~  remaining  `events
  =/  event=(unit webhook-event:git)
    ?:  =('push' i.remaining)          `%push
    ?:  =('tag' i.remaining)           `%tag
    ?:  =('pull-request' i.remaining)  `%pull-request
    ?:  =('issue' i.remaining)         `%issue
    ?:  =('release' i.remaining)       `%release
    ?:  =('clay-sync' i.remaining)     `%clay-sync
    ~
  ?~  event  ~
  $(remaining t.remaining, events (~(put in events) u.event))
::
++  notification-events-at
  |=  [key=@t jon=json]
  ^-  (unit (set notification-event:git))
  =/  values=(unit (list @t))  (string-list-at key jon)
  ?~  values  ~
  =/  remaining=(list @t)  u.values
  =/  events=(set notification-event:git)  ~
  |-
  ?~  remaining  `events
  =/  event=(unit notification-event:git)
    ?:  =('issue' i.remaining)          `%issue
    ?:  =('issue-comment' i.remaining)  `%issue-comment
    ?:  =('pull-request' i.remaining)   `%pull-request
    ?:  =('pull-comment' i.remaining)   `%pull-comment
    ~
  ?~  event  ~
  $(remaining t.remaining, events (~(put in events) u.event))
::
++  ship-list-at
  |=  [key=@t jon=json]
  ^-  (unit (list @p))
  =/  texts=(unit (list @t))  (string-list-at key jon)
  ?~  texts  ~
  =/  remaining=(list @t)  u.texts
  =/  out=(list @p)  ~
  |-
  ?~  remaining  `(flop out)
  =/  parsed=(unit @p)  (slaw %p i.remaining)
  ?~  parsed  ~
  $(remaining t.remaining, out [u.parsed out])
::
++  native-issue-at
  |=  [repo=repository:git number=@ud]
  ^-  (unit native-issue:git)
  =/  matches=(list native-issue:git)
    (skim native-issues.repo |=(issue=native-issue:git =(number.issue number)))
  ?~  matches  ~
  `i.matches
::
++  native-pull-at
  |=  [repo=repository:git number=@ud]
  ^-  (unit native-pull:git)
  =/  matches=(list native-pull:git)
    (skim native-pulls.repo |=(pull=native-pull:git =(number.pull number)))
  ?~  matches  ~
  `i.matches
::
++  native-pull-detail-json
  |=  [name=@t repo=repository:git pull=native-pull:git]
  ^-  (unit json)
  =/  diff=(unit json)  (repository-diff-json name repo base.pull head.pull)
  ?~  diff  ~
  ?.  ?=([%o *] u.diff)  ~
  =/  fields=(map @t json)  p.u.diff
  =.  fields  (~(put by fields) 'number' n+(decimal number.pull))
  =.  fields  (~(put by fields) 'title' s+title.pull)
  =.  fields  (~(put by fields) 'state' s+state.pull)
  =.  fields  (~(put by fields) 'sourceShip' s+(scot %p source-ship.pull))
  =.  fields  (~(put by fields) 'sourceRepository' s+source-repository.pull)
  =.  fields  (~(put by fields) 'comments' [%a (turn comments.pull review-comment-json)])
  `[%o fields]
::
++  valid-lfs-oid
  |=  oid=@t
  ^-  ?
  =/  chars=tape  (trip oid)
  ?.  =(64 (lent chars))  %.n
  (levy chars |=(char=@tD ?|(&((gte char '0') (lte char '9')) &((gte char 'a') (lte char 'f')))))
::
++  lfs-pointer-oid
  |=  data=octs
  ^-  (unit @t)
  ?:  (gth p.data 1.024)  ~
  =/  chars=tape  (trip q.data)
  =/  marker=tape  "oid sha256:"
  =/  location=(unit @ud)  (find marker chars)
  ?~  location  ~
  =/  start=@ud  (add u.location (lent marker))
  =/  candidate=tape  (scag 64 (slag start chars))
  ?.  =(64 (lent candidate))  ~
  =/  oid=@t  (crip candidate)
  ?:  (valid-lfs-oid oid)
    `oid
  ~
::
++  referenced-lfs
  |=  repo=repository:git
  ^-  (unit (set @t))
  =/  roots=(set oid:git)
    (silt (turn ~(tap by refs.repo) |=(entry=[@t oid:git] +.entry)))
  =/  closure=(unit (set oid:git))
    (reachable:git-graph objects.repo roots)
  ?~  closure  ~
  =/  ids=(list oid:git)  ~(tap in u.closure)
  =/  live=(set @t)  ~
  |-
  ?~  ids  `live
  =/  found=(unit object:git)  (~(get by objects.repo) i.ids)
  ?.  ?&(?=(^ found) =(%blob kind.u.found))
    $(ids t.ids)
  =/  pointer=(unit @t)  (lfs-pointer-oid data.u.found)
  ?.  ?&(?=(^ pointer) (~(has by lfs-objects.repo) u.pointer))
    $(ids t.ids)
  $(ids t.ids, live (~(put in live) u.pointer))
::
++  lfs-gc-json
  |=  repo=repository:git
  ^-  (unit json)
  =/  live=(unit (set @t))  (referenced-lfs repo)
  ?~  live  ~
  =/  candidates=(list [@t lfs-object:git])
    %+  skim  ~(tap by lfs-objects.repo)
    |=  entry=[@t lfs-object:git]
    !(~(has in u.live) -.entry)
  =/  remaining=(list [@t lfs-object:git])  candidates
  =/  bytes=@ud  0
  =.  bytes
    |-
    ?~  remaining  bytes
    $(remaining t.remaining, bytes (add bytes size.+.i.remaining))
  =/  items=(list json)
    %+  turn  candidates
    |=  entry=[@t lfs-object:git]
    =/  oid=@t  -.entry
    =/  object=lfs-object:git  +.entry
    (pairs:enjs:format ~[['oid' s+oid] ['size' n+(decimal size.object)]])
  =/  result=json
    %-  pairs:enjs:format
    :~  ['candidateCount' n+(decimal (lent candidates))]
        ['candidateBytes' n+(decimal bytes)]
        ['candidates' [%a (scag 100 items)]]
        ['truncated' b+(gth (lent candidates) 100)]
    ==
  `result
::
++  parse-lfs-specs
  |=  jon=json
  ^-  (unit (list lfs-spec))
  =/  value=(unit json)  (json-at 'objects' jon)
  ?~  value  ~
  ?.  ?=([%a *] u.value)  ~
  =/  items=(list json)  p.u.value
  =/  out=(list lfs-spec)  ~
  |-
  ?~  items  `(flop out)
  =/  oid=(unit @t)  (string-at 'oid' i.items)
  =/  size=(unit @ud)  (nat-at 'size' i.items)
  ?.  ?&(?=(^ oid) ?=(^ size) (valid-lfs-oid u.oid))  ~
  $(items t.items, out [[u.oid u.size] out])
::
++  json-payload
  |=  [status=@ud jon=json]
  ^-  simple-payload:http
  :_  `(json-to-octs:server jon)
  :-  status
  :~  ['content-type' 'application/vnd.git-lfs+json']
      ['cache-control' 'no-store']
  ==
::
++  api-json-payload
  |=  [status=@ud jon=json]
  ^-  simple-payload:http
  :_  `(json-to-octs:server jon)
  :-  status
  :~  ['content-type' 'application/json; charset=utf-8']
      ['cache-control' 'no-store']
  ==
::
++  api-error
  |=  [eyre-id=@ta status=@ud message=@t]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  (api-json-payload status (pairs:enjs:format ~[['error' s+message]]))
::
++  api-ok
  |=  [eyre-id=@ta status=@ud]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  (api-json-payload status (pairs:enjs:format ~[['ok' b+%.y]]))
::
++  api-json
  |=  [eyre-id=@ta status=@ud jon=json]
  ^-  (list card)
  (give-simple-payload:app:server eyre-id (api-json-payload status jon))
::
++  api-archive
  |=  [eyre-id=@ta name=@t data=octs]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  :_  `data
  :-  200
  :~  ['content-type' 'application/x-tar']
      ['content-disposition' (rap 3 ~['attachment; filename="' name '.tar"'])]
      ['cache-control' 'no-store']
  ==
::
++  api-body
  |=  req=inbound-request:eyre
  ^-  (unit json)
  ?~  body.request.req  ~
  (de:json:html q.u.body.request.req)
::
++  valid-repository-name
  |=  name=@t
  ^-  ?
  =/  chars=tape  (trip name)
  ?.  ?&((gth (lent chars) 0) (lte (lent chars) 100))  %.n
  %+  levy  chars
  |=  char=@tD
  ?|  &((gte char 'a') (lte char 'z'))
      &((gte char 'A') (lte char 'Z'))
      &((gte char '0') (lte char '9'))
      =('-' char)
      =('_' char)
      =('.' char)
  ==
::
++  api-terminal-name
  |=  [segment=@t extension=(unit @ta)]
  ^-  @t
  ?~  extension  segment
  (rap 3 ~[segment '.' `@t`u.extension])
::
++  api-file-path
  |=  [segments=(list @t) extension=(unit @ta)]
  ^-  (unit path)
  ?~  segments  ~
  =/  segments=(list @t)
    ?~  extension  segments
    =/  reversed=(list @t)  (flop segments)
    ?~  reversed  segments
    =/  leaf=@t  (rap 3 ~[i.reversed '.' `@t`u.extension])
    (flop [leaf t.reversed])
  =/  parse
    |=  [remaining=(list @t) out=path]
    ^-  (unit path)
    ?~  remaining  `(flop out)
    =/  chars=tape  (trip i.remaining)
    ?.  ?&  !=('' i.remaining)
            !=('.' i.remaining)
            !=('..' i.remaining)
            (lte (lent chars) 255)
            %+  levy  chars
            |=(char=@tD &(!=(char 0) !=(char '/')))
        ==
      ~
    $(remaining t.remaining, out [`knot`i.remaining out])
  (parse segments ~)
::
++  api-with-action
  |=  [eyre-id=@ta status=@ud act=action:git]
  ^-  (quip card _this)
  =/  [cards=(list card) next=_this]  (handle-action act)
  [(weld cards (api-ok eyre-id status)) next]
::
++  peer-results-json
  ^-  json
  =/  entries=(list json)
    %+  turn  ~(tap by peer-results)
    |=  entry=[@uv peer-result]
    =/  transfer=@uv  -.entry
    =/  result=peer-result  +.entry
    =/  flight=(unit peer-receive)  (~(get by peer-receiving) transfer)
    %-  pairs:enjs:format
    :~  ['transfer' s+(scot %uv transfer)]
        ['active' b+?=(^ flight)]
        ['ok' b+status.result]
        ['message' s+message.result]
        ['repository' s+repository.result]
        ['received' n+(decimal ?~(flight 0 received.u.flight))]
        ['expected' n+(decimal ?~(flight 0 expected.u.flight))]
        ['pages' n+(decimal ?~(flight 0 pages.u.flight))]
        ['completedPages' n+(decimal ?~(flight 0 ~(wyt in completed.u.flight)))]
        ['fineFragmentsReceived' n+(decimal ?~(flight 0 (roll ~(val by fine-progress.u.flight) |=([[fag=@ud tot=@ud] sum=@ud] (add fag sum)))))]
        ['fineFragmentsTotal' n+(decimal ?~(flight 0 (roll ~(val by fine-progress.u.flight) |=([[fag=@ud tot=@ud] sum=@ud] (add tot sum)))))]
    ==
  (pairs:enjs:format ~[['transfers' [%a entries]]])
::
++  peer-discoveries-json
  ^-  json
  =/  entries=(list json)
    %+  turn  ~(tap by peer-discoveries)
    |=  entry=[@uv peer-discovery]
    =/  request=@uv  -.entry
    =/  discovery=peer-discovery  +.entry
    =/  repositories-json=(list json)
      %+  turn  repositories.discovery
      |=  repo=catalog-repository:git-peer
      %-  pairs:enjs:format
      :~  ['name' s+name.repo]
          ['head' s+head.repo]
          ['refs' n+(decimal refs.repo)]
          ['objects' n+(decimal objects.repo)]
          ['writable' b+writable.repo]
      ==
    %-  pairs:enjs:format
    :~  ['request' s+(scot %uv request)]
        ['ship' s+(scot %p peer.discovery)]
        ['active' b+active.discovery]
        ['ok' b+ok.discovery]
        ['message' s+message.discovery]
        ['repositories' [%a repositories-json]]
    ==
  (pairs:enjs:format ~[['discoveries' [%a entries]]])
::
++  peers-json
  ^-  json
  =/  entries=(list json)
    (turn ~(tap in peers) |=(peer=@p s+(scot %p peer)))
  (pairs:enjs:format ~[['peers' [%a entries]]])
::
++  peer-browses-json
  ^-  json
  =/  entries=(list json)
    %+  turn  ~(tap by peer-browses)
    |=  entry=[@uv peer-browse]
    =/  request=@uv  -.entry
    =/  browse=peer-browse  +.entry
    %-  pairs:enjs:format
    :~  ['request' s+(scot %uv request)]
        ['ship' s+(scot %p peer.browse)]
        ['repository' s+repository.browse]
        ['view' s+view.browse]
        ['number' n+(decimal number.browse)]
        ['path' s+(spat file-path.browse)]
        ['phase' s+phase.browse]
        ['active' b+active.browse]
        ['ok' b+ok.browse]
        ['message' s+message.browse]
        :-  'progress'
        ?~  progress.browse  ~
        %-  pairs:enjs:format
        :~  ['blockExponent' n+(decimal boq.u.progress.browse)]
            ['received' n+(decimal fag.u.progress.browse)]
            ['expected' n+(decimal tot.u.progress.browse)]
        ==
        ['result' ?~(result.browse ~ u.result.browse)]
    ==
  (pairs:enjs:format ~[['browses' [%a entries]]])
::
++  start-peer-browse
  |=  [eyre-id=@ta peer=ship repository=@t view=browse-view:git-peer number=@ud file-path=path]
  ^-  (quip card _this)
  =/  duplicate=(unit [@uv peer-browse])
    =/  matches=(list [@uv peer-browse])
      %+  murn  ~(tap by peer-browses)
      |=  entry=[@uv peer-browse]
      =/  browse=peer-browse  +.entry
      ?.  ?&  active.browse
              =(peer peer.browse)
              =(repository repository.browse)
              =(view view.browse)
              =(number number.browse)
              =(file-path file-path.browse)
          ==
        ~
      `entry
    ?~(matches ~ `i.matches)
  ?^  duplicate
    :_  this
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv -.u.duplicate)] ['deduplicated' b+%.y]]))
  =/  request=@uv
    `@uv`(shas %git-peer-browse (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =.  peer-browses
    (~(put by peer-browses) request [peer repository view number file-path %request %.y %.n 'reading from peer' ~ now.bowl 0 0 ~ ~])
  :_  this
  %+  weld
    :~  (peer-card peer /peer/browse-request/(scot %uv request) [%browse-request request repository view number file-path])
        [%pass /peer/browse-timeout/(scot %uv request) %arvo %b %wait (add now.bowl ~s45)]
    ==
  (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv request)]]))
::
++  peer-forges-json
  ^-  json
  =/  entries=(list json)
    %+  turn  ~(tap by peer-forges)
    |=  entry=[@uv peer-forge]
    =/  request=@uv  -.entry
    =/  forge=peer-forge  +.entry
    %-  pairs:enjs:format
    :~  ['request' s+(scot %uv request)]
        ['ship' s+(scot %p peer.forge)]
        ['repository' s+repository.forge]
        ['kind' s+kind.forge]
        ['number' n+(decimal number.forge)]
        ['active' b+active.forge]
        ['ok' b+ok.forge]
        ['message' s+message.forge]
        ['result' ?~(result.forge ~ u.result.forge)]
    ==
  (pairs:enjs:format ~[['requests' [%a entries]]])
::
++  start-peer-forge-comment
  |=  [eyre-id=@ta peer=ship repository=@t kind=forge-kind:git-peer number=@ud body=@t]
  ^-  (quip card _this)
  =/  duplicate=(unit [@uv peer-forge])
    =/  matches=(list [@uv peer-forge])
      %+  murn  ~(tap by peer-forges)
      |=  entry=[@uv peer-forge]
      =/  forge=peer-forge  +.entry
      ?.  ?&  active.forge
              =(peer peer.forge)
              =(repository repository.forge)
              =(kind kind.forge)
              =(number number.forge)
          ==
        ~
      `entry
    ?~(matches ~ `i.matches)
  ?^  duplicate
    :_  this
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv -.u.duplicate)] ['deduplicated' b+%.y]]))
  =/  request=@uv
    `@uv`(shas %git-peer-forge (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =.  peer-forges
    (~(put by peer-forges) request [peer repository kind number %.y %.n 'sending comment to repository owner' ~])
  :_  this
  %+  weld
    :~  (peer-card peer /peer/forge-comment/(scot %uv request) [%forge-comment request repository kind number body])
        [%pass /peer/forge-timeout/(scot %uv request) %arvo %b %wait (add now.bowl ~s30)]
    ==
  (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv request)]]))
::
++  start-peer-forge-issue
  |=  [eyre-id=@ta peer=ship repository=@t title=@t body=@t]
  ^-  (quip card _this)
  =/  duplicate=(unit [@uv peer-forge])
    =/  matches=(list [@uv peer-forge])
      %+  murn  ~(tap by peer-forges)
      |=  entry=[@uv peer-forge]
      =/  forge=peer-forge  +.entry
      ?.  ?&  active.forge
              =(peer peer.forge)
              =(repository repository.forge)
              =(%issue kind.forge)
              =(0 number.forge)
          ==
        ~
      `entry
    ?~(matches ~ `i.matches)
  ?^  duplicate
    :_  this
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv -.u.duplicate)] ['deduplicated' b+%.y]]))
  =/  request=@uv
    `@uv`(shas %git-peer-issue (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =.  peer-forges
    (~(put by peer-forges) request [peer repository %issue 0 %.y %.n 'opening issue on repository owner' ~])
  :_  this
  %+  weld
    :~  (peer-card peer /peer/forge-issue/(scot %uv request) [%forge-create-issue request repository title body])
        [%pass /peer/forge-timeout/(scot %uv request) %arvo %b %wait (add now.bowl ~s30)]
    ==
  (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv request)]]))
::
++  peer-activities-json
  ^-  json
  =/  entries=(list json)
    %+  turn  peer-activities
    |=  event=peer-activity
    %-  pairs:enjs:format
    :~  ['id' s+(scot %uv id.event)]
        ['kind' s+kind.event]
        ['direction' s+direction.event]
        ['ship' s+(scot %p peer.event)]
        ['repository' s+repository.event]
        ['status' s+status.event]
        ['message' s+message.event]
        ['when' s+(scot %da when.event)]
    ==
  =/  notifications=(list json)
    %+  turn  notification-activities
    |=  event=notification-activity
    %-  pairs:enjs:format
    :~  ['id' s+(scot %uv id.event)]
        ['event' s+event.event]
        ['repository' s+repository.event]
        ['message' s+message.event]
        ['when' s+(scot %da when.event)]
    ==
  (pairs:enjs:format ~[['activity' [%a entries]] ['notifications' [%a notifications]]])
::
++  github-results-json
  ^-  json
  =/  entries=(list json)
    %+  turn  ~(tap by github-results)
    |=  entry=[@uv github-result]
    =/  job=@uv  -.entry
    =/  result=github-result  +.entry
    %-  pairs:enjs:format
    :~  ['job' s+(scot %uv job)]
        ['active' b+active.result]
        ['ok' b+ok.result]
        ['kind' s+kind.result]
        ['repository' s+repository.result]
        ['message' s+message.result]
    ==
  %-  pairs:enjs:format
  :~  ['tokenSet' b+?=(^ github-token)]
      ['jobs' [%a entries]]
  ==
::
++  github-start
  |=  [ctx=github-request request=request:http]
  ^-  (quip card _this)
  =/  request-id=@uv
    `@uv`(shas %git-github-request (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =.  ctx  ctx(job request-id)
  =.  github-in-flight  (~(put by github-in-flight) request-id ctx)
  =.  github-results
    (~(put by github-results) request-id [%.y %.n kind.ctx repository.ctx 'contacting GitHub'])
  :_  this
  :~  [%pass /github/(scot %uv request-id) %arvo %i %request request *outbound-config:iris]
  ==
::
++  dispatch-webhooks
  |=  [name=@t event=webhook-event:git data=json]
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) name)
  ?~  found  `this
  =/  hooks=(list [@ud webhook:git])
    %+  skim  ~(tap by webhooks.u.found)
    |=  entry=[@ud webhook:git]
    ?&  enabled.+.entry
        (~(has in events.+.entry) event)
    ==
  ?~  hooks  `this
  =/  payload=json
    %-  pairs:enjs:format
    :~  ['event' s+event]
        ['repository' s+name]
        ['owner' s+(scot %p owner.u.found)]
        ['sentAt' s+(scot %da now.bowl)]
        ['data' data]
    ==
  =/  body=octs  (json-to-octs:server payload)
  =/  remaining=(list [@ud webhook:git])  hooks
  =/  cards=(list card)  ~
  =/  flights=(map @uv webhook-flight)  webhook-in-flight
  =/  deliveries=(list webhook-delivery:git)  ~
  =/  count=@ud  request-count
  =/  result=[cards=(list card) flights=(map @uv webhook-flight) deliveries=(list webhook-delivery:git) count=@ud]
    |-
    ?~  remaining  [cards flights deliveries count]
    =/  hook=webhook:git  +.i.remaining
    =/  delivery-id=@uv
      `@uv`(shas %git-webhook (cat 3 eny.bowl count))
    =/  signature=@t  (signature:git-webhook secret.hook body)
    =/  headers=(list [@t @t])
      :~  ['content-type' 'application/json']
          ['user-agent' 'urgit-webhook/1']
          ['x-git-event' event]
          ['x-git-delivery' (scot %uv delivery-id)]
          ['x-hub-signature-256' signature]
      ==
    =/  card=card
      [%pass /webhook/(scot %uv delivery-id) %arvo %i %request [%'POST' url.hook headers `body] *outbound-config:iris]
    =/  delivery=webhook-delivery:git
      [delivery-id id.hook event %pending 0 'delivery queued' now.bowl]
    $(remaining t.remaining, cards [card cards], flights (~(put by flights) delivery-id [name id.hook delivery-id]), deliveries [delivery deliveries], count +(count))
  =.  request-count  count.result
  =.  webhook-in-flight  flights.result
  =/  updated=repository:git
    u.found(webhook-deliveries (scag 100 (weld deliveries.result webhook-deliveries.u.found)))
  =.  repositories  (~(put by repositories) name updated)
  [(flop cards.result) this]
::
++  repository-notification
  |=  [name=@t repo=repository:git event=notification-event:git thread=path message=@t]
  ^-  notification-result
  ?.  (~(has in notification-events.repo) event)  [~ ~]
  =/  id=@uv  `@uv`(end 7 (shas %urgit-notification eny.bowl))
  =/  rope=hark-rope:git  [~ ~ %urgit thread]
  =/  yarn=hark-yarn:git  [id rope now.bowl ~[message] /apps/urgit ~]
  =/  card=card
    [%pass /hark/(scot %uv id) %agent [our.bowl %hark] %poke %hark-action !>(`hark-action:git`[%add-yarn & & yarn])]
  [[card ~] `[id event name message now.bowl]]
::
++  accept-receive
  |=  $:  eyre-id=@ta
          name=@t
          commands=(list receive-command:git)
          applied=repository:git
          clay=(unit [desk-name=desk commit=oid:git])
      ==
  ^-  (quip card _this)
  =.  repositories  (~(put by repositories) name applied)
  =^  push-cards  this
    (dispatch-webhooks name %push (push-event-json commands))
  ?~  clay
    :_  this
    %+  weld  push-cards
    %+  give-simple-payload:app:server  eyre-id
    (receive-payload 'ok' (receive-results commands %.y ''))
  =/  data=json
    (pairs:enjs:format ~[['desk' s+desk-name.u.clay] ['commit' s+(oid-text:git-codec commit.u.clay)]])
  =^  sync-cards  this
    (dispatch-webhooks name %clay-sync data)
  :_  this
  %+  weld  (weld push-cards sync-cards)
  %+  give-simple-payload:app:server  eyre-id
  (receive-payload 'ok' (receive-results commands %.y ''))
::
++  handle-incoming-hook
  |=  [eyre-id=@ta req=inbound-request:eyre name=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (api-error eyre-id 405 'webhook endpoint requires POST')
  =/  found=(unit repository:git)  (~(get by repositories) name)
  ?~  found
    :_  this
    (api-error eyre-id 404 'webhook endpoint not found')
  ?~  incoming-hook.u.found
    :_  this
    (api-error eyre-id 404 'webhook endpoint not found')
  ?.  enabled.u.incoming-hook.u.found
    :_  this
    (api-error eyre-id 404 'webhook endpoint not found')
  ?~  body.request.req
    :_  this
    (api-error eyre-id 400 'webhook body is required')
  =/  raw=@  q.u.body.request.req
  =/  body=octs  [(met 3 raw) raw]
  ?:  (gth p.body 1.048.576)
    :_  this
    (api-error eyre-id 413 'webhook body exceeds 1 MiB')
  =/  supplied=(unit @t)
    (get-header:http 'x-hub-signature-256' header-list.request.req)
  ?.  ?&  ?=(^ supplied)
          (verify:git-webhook secret.u.incoming-hook.u.found body u.supplied)
      ==
    :_  this
    (api-error eyre-id 401 'webhook signature is invalid')
  =/  event=(unit @t)  (get-header:http 'x-github-event' header-list.request.req)
  ?:  ?&(?=(^ event) =('ping' u.event))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&(?=(^ event) =('pull_request' u.event))
    ?~  github-origin.u.found
      :_  this
      (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['message' s+'pull request event accepted; repository has no GitHub origin']]))
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  ctx=github-request  [0v0 %pulls name owner remote public-read.u.found '' ~ 1 ~ 0]
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote '/pulls?state=all&per_page=100&page=1') (api-headers:git-github github-token) ~]
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['message' s+'pull request metadata refresh started']])))
  ?.  ?&(?=(^ event) =('push' u.event))
    :_  this
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['message' s+'event ignored']]))
  =/  jon=(unit json)  (de:json:html q.body)
  ?~  jon
    :_  this
    (api-error eyre-id 400 'webhook body is not valid JSON')
  =/  notice=(unit push-notice:git-webhook)  (github-push:git-webhook u.jon)
  ?~  notice
    :_  this
    (api-error eyre-id 422 'push webhook is missing ref, before, or after')
  =/  update-id=@uv
    `@uv`(shas %git-upstream-update (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =/  update=upstream-update:git
    [update-id source.u.notice ref.u.notice before.u.notice after.u.notice now.bowl]
  =/  remaining=(list upstream-update:git)
    (skim upstream-updates.u.found |=(prior=upstream-update:git !=(ref.prior ref.update)))
  =/  updated=repository:git
    u.found(upstream-updates (scag 50 (weld ~[update] remaining)))
  =.  repositories  (~(put by repositories) name updated)
  :_  this
  (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['update' s+(scot %uv update-id)]]))
::
++  handle-public-api
  |=  [eyre-id=@ta req=inbound-request:eyre line=request-line:server]
  ^-  (quip card _this)
  =/  site=(list @t)  site.line
  =/  method=@tas  method.request.req
  ?.  =(%'GET' method)
    :_  this
    (api-error eyre-id 405 'public repository API is read-only')
  ?:  ?=([%apps %urgit %api %public %repository @ ~] site)
    =/  name=@t  (api-terminal-name i.t.t.t.t.t.site ext.line)
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    :_  this
    (api-json eyre-id 200 (public-repository-json name u.found))
  ?:  ?=([%apps %urgit %api %public %repository @ %issues @ ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  issue=(unit native-issue:git)  (native-issue-at u.found u.number)
    ?~  issue
      :_  this
      (api-error eyre-id 404 'issue not found')
    :_  this
    (api-json eyre-id 200 (native-issue-json u.issue %.y))
  ?:  ?=([%apps %urgit %api %public %repository @ %releases ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  tag=(unit @t)  (query-value 'tag' args.line)
    ?~  tag
      :_  this
      (api-error eyre-id 422 'tag is required')
    =/  release=(unit release:git)  (~(get by releases.u.found) u.tag)
    ?~  release
      :_  this
      (api-error eyre-id 404 'release not found')
    :_  this
    (api-json eyre-id 200 (release-json u.release %.y))
  ?:  ?=([%apps %urgit %api %public %repository @ %archive ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  ref=(unit @t)  (query-value 'ref' args.line)
    ?~  ref
      :_  this
      (api-error eyre-id 422 'ref is required')
    =/  target=(unit oid:git)  (revision-oid u.found u.ref)
    ?~  target
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  peeled=(unit oid:git)  (peeled-tag:git-protocol objects.u.found u.target)
    =/  commit=oid:git  ?~(peeled u.target u.peeled)
    =/  archive=(unit octs)  (archive:git-archive objects.u.found commit)
    ?~  archive
      :_  this
      (api-error eyre-id 422 'archive requires a complete commit tree of at most 10,000 files and 64 MiB')
    :_  this
    (api-archive eyre-id name u.archive)
  ?:  ?=([%apps %urgit %api %public %repository @ %files ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-files-at-json name u.found ref))
  ?:  ?=([%apps %urgit %api %public %repository @ %search ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  query=(unit @t)  (query-value 'q' args.line)
    ?.  ?&(?=(^ query) (gte (met 3 u.query) 2) (lte (met 3 u.query) 200))
      :_  this
      (api-error eyre-id 422 'q must be between 2 and 200 bytes')
    :_  this
    (api-json eyre-id 200 (repository-search-json name u.found ref u.query))
  ?:  ?=([%apps %urgit %api %public %repository @ %commits ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  offset-text=(unit @t)  (query-value 'offset' args.line)
    =/  offset=(unit @ud)  ?~(offset-text `0 (slaw %ud u.offset-text))
    =/  limit-text=(unit @t)  (query-value 'limit' args.line)
    =/  limit=(unit @ud)  ?~(limit-text `50 (slaw %ud u.limit-text))
    ?.  ?&(?=(^ offset) ?=(^ limit) (lte u.offset 10.000) (gth u.limit 0) (lte u.limit 50))
      :_  this
      (api-error eyre-id 422 'offset must be at most 10000 and limit must be between 1 and 50')
    :_  this
    (api-json eyre-id 200 (repository-history-json name u.found ref our.bowl now.bowl u.offset u.limit))
  ?:  ?=([%apps %urgit %api %public %repository @ %compare ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  base-ref=(unit @t)  (query-value 'base' args.line)
    =/  head-ref=(unit @t)  (query-value 'head' args.line)
    ?.  ?&(?=(^ base-ref) ?=(^ head-ref))
      :_  this
      (api-error eyre-id 422 'base and head refs are required')
    =/  base=(unit oid:git)  (revision-oid u.found u.base-ref)
    =/  head=(unit oid:git)  (revision-oid u.found u.head-ref)
    ?.  ?&(?=(^ base) ?=(^ head))
      :_  this
      (api-error eyre-id 404 'base or head ref not found')
    =/  diff=(unit json)  (repository-diff-json name u.found u.base u.head)
    ?~  diff
      :_  this
      (api-error eyre-id 422 'commits do not have readable trees')
    :_  this
    (api-json eyre-id 200 u.diff)
  ?:  ?=([%apps %urgit %api %public %repository @ %commit @ ~] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  oid-text=@t  i.t.t.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  detail=(unit json)
      (repository-history-detail-json name u.found oid-text our.bowl now.bowl)
    ?~  detail
      :_  this
      (api-error eyre-id 404 'commit not found')
    :_  this
    (api-json eyre-id 200 u.detail)
  ?:  ?=([%apps %urgit %api %public %repository @ %file-history *] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-file-history-view-json name u.found ref u.file-path our.bowl now.bowl))
  ?:  ?=([%apps %urgit %api %public %repository @ %file-blame *] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    =/  blame=(unit json)
      (repository-file-blame-view-json name u.found ref u.file-path our.bowl now.bowl)
    ?~  blame
      :_  this
      (api-error eyre-id 422 'blame is available for text files up to 256 KiB and 10,000 lines')
    :_  this
    (api-json eyre-id 200 u.blame)
  ?:  ?=([%apps %urgit %api %public %repository @ %file *] site)
    =/  name=@t  i.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ found) public-read.u.found)
      :_  this
      (api-error eyre-id 404 'public repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    =/  data=(unit octs)
      (repository-file-at-history u.found ref u.file-path our.bowl now.bowl)
    ?~  data
      :_  this
      (api-error eyre-id 404 'file not found')
    :_  this
    (api-json eyre-id 200 (repository-file-json name u.found ref u.file-path u.data))
  :_  this
  (api-error eyre-id 404 'public repository route not found')
::
++  handle-api
  |=  [eyre-id=@ta req=inbound-request:eyre line=request-line:server]
  ^-  (quip card _this)
  =/  site=(list @t)  site.line
  ?:  ?=([%apps %urgit %api %hooks @ ~] site)
    (handle-incoming-hook eyre-id req (api-terminal-name i.t.t.t.t.site ext.line))
  ?:  ?=([%apps %urgit %api %public *] site)
    (handle-public-api eyre-id req line)
  ?.  authenticated.req
    :_  this
    (api-error eyre-id 401 'Urbit login required')
  =/  method=@tas  method.request.req
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %github %status ~] site)
      ==
    :_  this
    (api-json eyre-id 200 github-results-json)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %github %token ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  token=(unit @t)  (string-at 'token' u.jon)
    ?.  ?&(?=(^ token) !=('' u.token))
      :_  this
      (api-error eyre-id 422 'non-empty token is required')
    =.  github-token  `u.token
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %github %token ~] site)
      ==
    =.  github-token  ~
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %github %import ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  owner=(unit @t)  (string-at 'owner' u.jon)
    =/  remote=(unit @t)  (string-at 'repository' u.jon)
    =/  local=(unit @t)  (string-at 'name' u.jon)
    =/  public=(unit ?)  (bool-at 'publicRead' u.jon)
    ?.  ?&  ?=(^ owner)  ?=(^ remote)  ?=(^ local)  ?=(^ public)
            (valid-repository-name u.owner)
            (valid-repository-name u.remote)
            (valid-repository-name u.local)
        ==
      :_  this
      (api-error eyre-id 422 'owner, repository, name, and publicRead are required')
    =/  existing=(unit repository:git)  (~(get by repositories) u.local)
    =/  conflict=(unit @t)
      ?~  existing  ~
      ?~  github-origin.u.existing
        `'local repository already exists and is not linked to GitHub'
      ?.  ?&  =(u.owner owner.u.github-origin.u.existing)
              =(u.remote repository.u.github-origin.u.existing)
              ?=(~ binding.u.existing)
          ==
        `'GitHub origin does not match or repository is bound to Clay'
      ~
    ?^  conflict
      :_  this
      (api-error eyre-id 409 u.conflict)
    =/  kind=github-kind  ?^(existing %update %import)
    =/  ctx=github-request  [0v0 kind u.local u.owner u.remote u.public '' ~ 0 ~ 0]
    =/  request=request:http
      :*  %'GET'
          (git-url:git-github u.owner u.remote '/info/refs?service=git-upload-pack')
          (git-headers:git-github github-token ~)
          ~
      ==
    =/  [cards=(list card) next=_this]  (github-start ctx request)
    :_  next
    (weld cards (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['message' s+'GitHub import started']])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %github %metadata ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  requested=(unit @t)  (string-at 'kind' u.jon)
    =/  requested-page=(unit @ud)  (nat-at 'page' u.jon)
    ?.  ?&  ?=(^ requested)
            ?|  =('issues' u.requested)
                =('pulls' u.requested)
            ==
        ==
      :_  this
      (api-error eyre-id 422 'kind must be issues or pulls')
    =/  page=@ud  ?~(requested-page 1 u.requested-page)
    ?.  &((gte page 1) (lte page 5))
      :_  this
      (api-error eyre-id 422 'page must be between 1 and 5')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  kind=github-kind  ?:(=('issues' u.requested) %issues %pulls)
    =/  ctx=github-request  [0v0 kind name owner remote public-read.u.found '' ~ page ~ 0]
    =/  suffix=@t
      %+  rap  3
      :~  ?:(=(%issues kind) '/issues?state=all&per_page=100&page=' '/pulls?state=all&per_page=100&page=')
          (decimal page)
      ==
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (api-headers:git-github github-token) ~]
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %github %issues @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    =/  raw-number=@t  i.t.t.t.t.t.t.t.site
    =/  number=(unit @ud)  (parse-decimal raw-number)
    ?.  ?&(?=(^ number) (gth u.number 0))
      :_  this
      (api-error eyre-id 422 'positive GitHub issue number required')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  suffix=@t  (rap 3 ~['/issues/' (decimal u.number)])
    =/  ctx=github-request
      [0v0 %issue-detail name owner remote public-read.u.found '' ~ 0 `eyre-id u.number]
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (api-headers:git-github github-token) ~]
    (github-start ctx request)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %github %pulls @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    =/  raw-number=@t  i.t.t.t.t.t.t.t.site
    =/  number=(unit @ud)  (parse-decimal raw-number)
    ?.  ?&(?=(^ number) (gth u.number 0))
      :_  this
      (api-error eyre-id 422 'positive GitHub pull-request number required')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  suffix=@t  (rap 3 ~['/pulls/' (decimal u.number)])
    =/  ctx=github-request
      [0v0 %pull-detail name owner remote public-read.u.found '' ~ 0 `eyre-id u.number]
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (api-headers:git-github github-token) ~]
    (github-start ctx request)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %github %pulls @ %diff ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    =/  raw-number=@t  i.t.t.t.t.t.t.t.site
    =/  number=(unit @ud)  (parse-decimal raw-number)
    ?.  ?&(?=(^ number) (gth u.number 0))
      :_  this
      (api-error eyre-id 422 'positive GitHub pull-request number required')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  suffix=@t  (rap 3 ~['/pulls/' (decimal u.number)])
    =/  ctx=github-request
      [0v0 %pull-diff name owner remote public-read.u.found '' ~ 0 `eyre-id u.number]
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (diff-headers:git-github github-token) ~]
    (github-start ctx request)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %github %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    =/  file-path=(unit path)
      (api-file-path t.t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  path-text=@t  (crip (slag 1 (trip (spat u.file-path))))
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t
      ?^  requested  u.requested
      ?:  (starts-with 'refs/heads/' head.u.found)
        (crip (slag 11 (trip head.u.found)))
      head.u.found
    ?.  ?&  !=('' ref)
            (lte (met 3 ref) 500)
        ==
      :_  this
      (api-error eyre-id 422 'valid GitHub ref required')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  suffix=@t
      %+  rap  3
      :~  '/contents/'
          (uri-encode:git-storage path-text)
          '?ref='
          (uri-encode:git-storage ref)
      ==
    =/  ctx=github-request
      [0v0 %file-detail name owner remote public-read.u.found path-text ~ 0 `eyre-id 0]
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (api-headers:git-github github-token) ~]
    (github-start ctx request)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %github %push ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    ?~  github-token
      :_  this
      (api-error eyre-id 409 'connect a GitHub token first')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  branch=(unit @t)  (string-at 'branch' u.jon)
    ?~  branch
      :_  this
      (api-error eyre-id 422 'branch is required')
    ?.  ?&  (valid-ref:git-protocol u.branch)
            (starts-with:git-protocol (text:git-codec u.branch) 'refs/heads/')
        ==
      :_  this
      (api-error eyre-id 422 'branch must be a valid refs/heads ref')
    ?.  (~(has by refs.u.found) u.branch)
      :_  this
      (api-error eyre-id 404 'local branch not found')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  ctx=github-request  [0v0 %push name owner remote public-read.u.found u.branch ~ 0 ~ 0]
    =/  request=request:http
      :*  %'GET'
          (git-url:git-github owner remote '/info/refs?service=git-receive-pack')
          (receive-headers:git-github github-token ~)
          ~
      ==
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %github %fork ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    ?~  github-token
      :_  this
      (api-error eyre-id 409 'connect a GitHub token first')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  ctx=github-request  [0v0 %fork name owner remote public-read.u.found '' ~ 0 ~ 0]
    =/  headers=(list [@t @t])
      [['content-type' 'application/json'] (api-headers:git-github github-token)]
    =/  request=request:http
      [%'POST' (api-url:git-github owner remote '/forks') headers `(as-octs:mimes:html '{}')]
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %github %pull ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  github-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository has no GitHub origin')
    ?~  github-token
      :_  this
      (api-error eyre-id 409 'connect a GitHub token first')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  title=(unit @t)  (string-at 'title' u.jon)
    =/  head=(unit @t)  (string-at 'head' u.jon)
    =/  base=(unit @t)  (string-at 'base' u.jon)
    =/  description=(unit @t)  (string-at 'body' u.jon)
    ?.  ?&  ?=(^ title)  ?=(^ head)  ?=(^ base)
            !=('' u.title)  !=('' u.head)  !=('' u.base)
        ==
      :_  this
      (api-error eyre-id 422 'title, head, and base are required')
    =/  payload=json
      %-  pairs:enjs:format
      :~  ['title' s+u.title]
          ['head' s+u.head]
          ['base' s+u.base]
          ['body' s+?~(description '' u.description)]
      ==
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  ctx=github-request  [0v0 %open-pull name owner remote public-read.u.found '' ~ 0 ~ 0]
    =/  headers=(list [@t @t])
      [['content-type' 'application/json'] (api-headers:git-github github-token)]
    =/  request=request:http
      :*  %'POST'
          (api-url:git-github owner remote '/pulls')
          headers
          `(as-octs:mimes:html (en:json:html payload))
      ==
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %activity ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-activities-json)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %activity ~] site)
      ==
    =.  peer-activities  ~
    =.  notification-activities  ~
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %peers ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peers-json)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %peers ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    ?~  ship-text
      :_  this
      (api-error eyre-id 422 'ship is required')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    ?~  peer
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    (api-with-action eyre-id 200 [%add-peer u.peer])
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %peers ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    ?~  ship-text
      :_  this
      (api-error eyre-id 422 'ship is required')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    ?~  peer
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    (api-with-action eyre-id 200 [%remove-peer u.peer])
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %browses ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-browses-json)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %browses ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  request-text=(unit @t)  (string-at 'request' u.jon)
    ?~  request-text
      :_  this
      (api-error eyre-id 422 'request is required')
    =/  request=(unit @uv)  (slaw %uv u.request-text)
    ?~  request
      :_  this
      (api-error eyre-id 422 'invalid browse request')
    =/  found=(unit peer-browse)  (~(get by peer-browses) u.request)
    ?~  found
      :_  this
      (api-error eyre-id 404 'browse request not found')
    =.  peer-browses  (~(del by peer-browses) u.request)
    :_  this
    =/  response=(list card)
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
    ?.  =(%fine phase.u.found)  response
    =/  cancel-cards=(list card)
      (peer-browse-yawns u.request peer.u.found expected.u.found)
    =/  release-cards=(list card)
      :~  [%pass /peer/browse-release/(scot %uv u.request) %agent [peer.u.found %urgit] %poke %git-peer !>([%browse-release u.request])]
      ==
    (weld cancel-cards (weld release-cards response))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %browse @ @ ~] site)
      ==
    =/  ship-text=@t  i.t.t.t.t.t.site
    =/  repository=@t  (api-terminal-name i.t.t.t.t.t.t.site ext.line)
    =/  peer=(unit @p)  (slaw %p ship-text)
    ?.  ?&(?=(^ peer) (valid-repository-name repository))
      :_  this
      (api-error eyre-id 422 'valid ship and repository are required')
    (start-peer-browse eyre-id u.peer repository %overview 0 ~)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %stamp @ @ ~] site)
      ==
    =/  ship-text=@t  i.t.t.t.t.t.site
    =/  repository=@t  (api-terminal-name i.t.t.t.t.t.t.site ext.line)
    =/  peer=(unit @p)  (slaw %p ship-text)
    ?.  ?&(?=(^ peer) (valid-repository-name repository))
      :_  this
      (api-error eyre-id 422 'valid ship and repository are required')
    (start-peer-browse eyre-id u.peer repository %stamp 0 ~)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %detail ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  repository=(unit @t)  (string-at 'repository' u.jon)
    =/  kind-text=(unit @t)  (string-at 'kind' u.jon)
    =/  number=(unit @ud)  (nat-at 'number' u.jon)
    ?.  ?&  ?=(^ ship-text)
            ?=(^ repository)
            ?=(^ kind-text)
            ?=(^ number)
            (gth u.number 0)
            (valid-repository-name u.repository)
        ==
      :_  this
      (api-error eyre-id 422 'ship, repository, kind, and positive number are required')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    =/  view=(unit browse-view:git-peer)
      ?:  =('issue' u.kind-text)  `%issue
      ?:  =('pull' u.kind-text)   `%pull
      ~
    ?.  ?&(?=(^ peer) ?=(^ view))
      :_  this
      (api-error eyre-id 422 'ship and kind must be valid')
    (start-peer-browse eyre-id u.peer u.repository u.view u.number ~)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %file @ @ *] site)
      ==
    =/  ship-text=@t  i.t.t.t.t.t.site
    =/  repository=@t  i.t.t.t.t.t.t.site
    =/  peer=(unit @p)  (slaw %p ship-text)
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.t.site ext.line)
    ?.  ?&  ?=(^ peer)
            (valid-repository-name repository)
            ?=(^ file-path)
            !=(~ u.file-path)
        ==
      :_  this
      (api-error eyre-id 422 'valid ship, repository, and file path are required')
    (start-peer-browse eyre-id u.peer repository %file 0 u.file-path)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %commit ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  repository=(unit @t)  (string-at 'repository' u.jon)
    =/  identifier=(unit @t)  (string-at 'oid' u.jon)
    ?.  ?&  ?=(^ ship-text)
            ?=(^ repository)
            ?=(^ identifier)
            (valid-repository-name u.repository)
            (lte (met 3 u.identifier) 128)
        ==
      :_  this
      (api-error eyre-id 422 'ship, repository, and commit are required')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    ?~  peer
      :_  this
      (api-error eyre-id 422 'ship must be valid')
    (start-peer-browse eyre-id u.peer u.repository %commit 0 [u.identifier ~])
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %forge ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-forges-json)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %forge ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  request-text=(unit @t)  (string-at 'request' u.jon)
    =/  request=(unit @uv)  ?~(request-text ~ (slaw %uv u.request-text))
    ?.  ?&(?=(^ request) (~(has by peer-forges) u.request))
      :_  this
      (api-error eyre-id 404 'forge request not found')
    =.  peer-forges  (~(del by peer-forges) u.request)
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %issues ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  repository=(unit @t)  (string-at 'repository' u.jon)
    =/  title=(unit @t)  (string-at 'title' u.jon)
    =/  body=(unit @t)  (string-at 'body' u.jon)
    ?.  ?&  ?=(^ ship-text)
            ?=(^ repository)
            ?=(^ title)
            ?=(^ body)
            !=('' u.title)
            (lte (met 3 u.title) 200)
            (lte (met 3 u.body) 65.536)
            (valid-repository-name u.repository)
        ==
      :_  this
      (api-error eyre-id 422 'ship, repository, and a title up to 200 bytes are required; body is limited to 64 KiB')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    ?~  peer
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    (start-peer-forge-issue eyre-id u.peer u.repository u.title u.body)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %forge ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  repository=(unit @t)  (string-at 'repository' u.jon)
    =/  kind-text=(unit @t)  (string-at 'kind' u.jon)
    =/  number=(unit @ud)  (nat-at 'number' u.jon)
    =/  body=(unit @t)  (string-at 'body' u.jon)
    ?.  ?&  ?=(^ ship-text)
            ?=(^ repository)
            ?=(^ kind-text)
            ?=(^ number)
            ?=(^ body)
            (gth u.number 0)
            !=('' u.body)
            (lte (met 3 u.body) 16.384)
            (valid-repository-name u.repository)
        ==
      :_  this
      (api-error eyre-id 422 'ship, repository, kind, positive number, and a comment up to 16 KiB are required')
    =/  peer=(unit @p)  (slaw %p u.ship-text)
    =/  kind=(unit forge-kind:git-peer)
      ?:  =('issue' u.kind-text)  `%issue
      ?:  =('pull' u.kind-text)   `%pull
      ~
    ?.  ?&(?=(^ peer) ?=(^ kind))
      :_  this
      (api-error eyre-id 422 'ship and kind must be valid')
    (start-peer-forge-comment eyre-id u.peer u.repository u.kind u.number u.body)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %discoveries ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-discoveries-json)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %discover ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    ?~  ship-text
      :_  this
      (api-error eyre-id 422 'ship is required')
    =/  source=(unit @p)  (slaw %p u.ship-text)
    ?~  source
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    =/  duplicate=(unit [@uv peer-discovery])
      =/  matches=(list [@uv peer-discovery])
        %+  murn  ~(tap by peer-discoveries)
        |=  entry=[@uv peer-discovery]
        =/  discovery=peer-discovery  +.entry
        ?.  ?&(active.discovery =(u.source peer.discovery))  ~
        `entry
      ?~(matches ~ `i.matches)
    ?^  duplicate
      :_  this
      (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv -.u.duplicate)] ['deduplicated' b+%.y]]))
    =/  request=@uv
      `@uv`(shas %git-peer-discovery (cat 3 eny.bowl request-count))
    =.  request-count  +(request-count)
    =.  peer-discoveries
      (~(put by peer-discoveries) request [u.source %.y %.n 'contacting peer' ~])
    :_  this
    %+  weld
      :~  (peer-card u.source /peer/catalog-request/(scot %uv request) [%catalog-request request])
          [%pass /peer/discovery-timeout/(scot %uv request) %arvo %b %wait (add now.bowl ~s30)]
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['request' s+(scot %uv request)]]))
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %discoveries ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  request-text=(unit @t)  (string-at 'request' u.jon)
    ?~  request-text
      :_  this
      (api-error eyre-id 422 'request is required')
    =/  request=(unit @uv)  (slaw %uv u.request-text)
    ?~  request
      :_  this
      (api-error eyre-id 422 'invalid discovery request')
    ?.  (~(has by peer-discoveries) u.request)
      :_  this
      (api-error eyre-id 404 'discovery request not found')
    =.  peer-discoveries  (~(del by peer-discoveries) u.request)
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %peer %transfers ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-results-json)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %peer %transfers ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  transfer-text=(unit @t)  (string-at 'transfer' u.jon)
    ?~  transfer-text
      :_  this
      (api-error eyre-id 422 'transfer is required')
    =/  transfer=(unit @uv)  (slaw %uv u.transfer-text)
    ?~  transfer
      :_  this
      (api-error eyre-id 422 'invalid transfer identifier')
    =/  active=?  (~(has by peer-receiving) u.transfer)
    =/  recorded=?  (~(has by peer-results) u.transfer)
    ?.  |(active recorded)
      :_  this
      (api-error eyre-id 404 'transfer not found')
    ?:  active
      =/  canceled=(quip card _this)
        (peer-snapshot-fail u.transfer 'transfer cancelled')
      :_  +.canceled
      (weld -.canceled (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]])))
    =.  peer-results  (~(del by peer-results) u.transfer)
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %fork ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  source-repository=(unit @t)  (string-at 'repository' u.jon)
    =/  local-repository=(unit @t)  (string-at 'name' u.jon)
    =/  public=(unit ?)  (bool-at 'publicRead' u.jon)
    ?.  ?&  ?=(^ ship-text)
            ?=(^ source-repository)
            ?=(^ local-repository)
            ?=(^ public)
            (valid-repository-name u.source-repository)
            (valid-repository-name u.local-repository)
        ==
      :_  this
      (api-error eyre-id 422 'ship, repository, name, and publicRead are required')
    =/  source=(unit @p)  (slaw %p u.ship-text)
    ?~  source
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    =/  duplicate=(unit [@uv peer-receive])
      =/  matches=(list [@uv peer-receive])
        %+  murn  ~(tap by peer-receiving)
        |=  entry=[@uv peer-receive]
        =/  flight=peer-receive  +.entry
        ?.  ?&  =(%fork purpose.flight)
                =(u.source source.flight)
                =(u.source-repository source-repository.flight)
                =(u.local-repository local-repository.flight)
            ==
          ~
        `entry
      ?~(matches ~ `i.matches)
    ?^  duplicate
      :_  this
      (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv -.u.duplicate)] ['deduplicated' b+%.y]]))
    =/  existing=(unit repository:git)  (~(get by repositories) u.local-repository)
    =/  conflict=(unit @t)
      ?~  existing  ~
      ?~  peer-origin.u.existing
        `'repository already exists and is not a peer fork'
      ?.  ?&  =(u.source ship.u.peer-origin.u.existing)
              =(u.source-repository repository.u.peer-origin.u.existing)
              ?=(~ binding.u.existing)
          ==
        `'peer origin does not match or repository is bound to Clay'
      ~
    ?^  conflict
      :_  this
      (api-error eyre-id 409 u.conflict)
    =/  transfer=@uv
      `@uv`(shas %git-peer-transfer (cat 3 eny.bowl request-count))
    =.  request-count  +(request-count)
    =/  base-objects=(map oid:git object:git)
      ?~(existing ~ objects.u.existing)
    =/  haves=(set oid:git)
      (silt (turn ~(tap by base-objects) |=(entry=[oid:git object:git] -.entry)))
    =/  flight=peer-receive
      :*  %fork
          u.source
          u.source-repository
          u.local-repository
          ''
          ?^(existing public-read.u.existing u.public)
          %.n
          ''
          ~
          0
          0
          0
          ~
          now.bowl
          ~
          base-objects
      ==
    =.  peer-receiving  (~(put by peer-receiving) transfer flight)
    =.  peer-results  (~(put by peer-results) transfer [%.n 'transferring' u.local-repository])
    =.  peer-activities
      (peer-activity-start transfer %fork %outgoing u.source u.local-repository 'transferring repository')
    :_  this
    %+  weld
      :~  (peer-card u.source /peer/request/(scot %uv transfer) [%request transfer u.source-repository haves])
          [%pass /peer/request-timeout/(scot %uv transfer) %arvo %b %wait (add now.bowl ~s45)]
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %push ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  name=(unit @t)  (string-at 'name' u.jon)
    ?~  name
      :_  this
      (api-error eyre-id 422 'name is required')
    =/  found=(unit repository:git)  (~(get by repositories) u.name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  peer-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository is not a native fork')
    =/  transfer=@uv
      `@uv`(shas %git-peer-push (cat 3 eny.bowl request-count))
    =.  request-count  +(request-count)
    =.  peer-results  (~(put by peer-results) transfer [%.n 'offering update' u.name])
    =.  peer-activities
      (peer-activity-start transfer %push %outgoing ship.u.peer-origin.u.found u.name 'offering update')
    :_  this
    %+  weld
      :~  (peer-card ship.u.peer-origin.u.found /peer/offer/(scot %uv transfer) [%offer transfer repository.u.peer-origin.u.found u.name %.n ''])
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %peer %pull-request ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  name=(unit @t)  (string-at 'name' u.jon)
    =/  title=(unit @t)  (string-at 'title' u.jon)
    ?.  ?&(?=(^ name) ?=(^ title) !=('' u.title))
      :_  this
      (api-error eyre-id 422 'name and title are required')
    =/  found=(unit repository:git)  (~(get by repositories) u.name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  peer-origin.u.found
      :_  this
      (api-error eyre-id 409 'repository is not a native fork')
    =/  transfer=@uv
      `@uv`(shas %git-peer-pull (cat 3 eny.bowl request-count))
    =.  request-count  +(request-count)
    =.  peer-results  (~(put by peer-results) transfer [%.n 'opening pull request' u.name])
    =.  peer-activities
      (peer-activity-start transfer %pull-request %outgoing ship.u.peer-origin.u.found u.name 'opening pull request')
    :_  this
    %+  weld
      :~  (peer-card ship.u.peer-origin.u.found /peer/offer/(scot %uv transfer) [%offer transfer repository.u.peer-origin.u.found u.name %.y u.title])
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repositories ~] site)
      ==
    :_  this
    (api-json eyre-id 200 (repositories-json repositories))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %desks ~] site)
      ==
    =/  desks=(unit (set desk))
      %-  mole
      |.(.^((set desk) %cd /(scot %p our.bowl)//(scot %da now.bowl)))
    ?~  desks
      :_  this
      (api-error eyre-id 503 'unable to list Clay desks')
    =/  entries=(list json)
      %+  turn  ~(tap in u.desks)
      |=(desk-name=desk s+desk-name)
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['desks' [%a entries]]]))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ ~] site)
      ==
    =/  name=@t  (api-terminal-name i.t.t.t.t.site ext.line)
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    :_  this
    (api-json eyre-id 200 (repository-json name u.found))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %issues ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  title=(unit @t)  (string-at 'title' u.jon)
    =/  body=(unit @t)  (string-at 'body' u.jon)
    ?.  ?&  ?=(^ title)
            ?=(^ body)
            !=('' u.title)
            (lte (met 3 u.title) 200)
            (lte (met 3 u.body) 65.536)
        ==
      :_  this
      (api-error eyre-id 422 'title is required and limited to 200 bytes; body is limited to 64 KiB')
    =/  number=@ud  (add 1 (lent native-issues.u.found))
    =/  issue=native-issue:git
      [number our.bowl u.title u.body %open ~ ~ now.bowl now.bowl ~]
    =.  repositories
      (~(put by repositories) name u.found(native-issues [issue native-issues.u.found]))
    =/  dispatched=(quip card _this)
      (dispatch-webhooks name %issue (native-issue-json issue %.y))
    :_  +.dispatched
    (weld -.dispatched (api-json eyre-id 201 (native-issue-json issue %.y)))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %issues @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  issue=(unit native-issue:git)  (native-issue-at u.found u.number)
    ?~  issue
      :_  this
      (api-error eyre-id 404 'issue not found')
    :_  this
    (api-json eyre-id 200 (native-issue-json u.issue %.y))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %issues @ %comments ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  issue=(unit native-issue:git)  (native-issue-at u.found u.number)
    ?~  issue
      :_  this
      (api-error eyre-id 404 'issue not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  body=(unit @t)  (string-at 'body' u.jon)
    ?.  ?&(?=(^ body) !=('' u.body) (lte (met 3 u.body) 16.384))
      :_  this
      (api-error eyre-id 422 'comment body is required and limited to 16 KiB')
    =/  comment=issue-comment:git
      [(add 1 (lent comments.u.issue)) our.bowl u.body now.bowl]
    =/  issues=(list native-issue:git)
      %+  turn  native-issues.u.found
      |=  candidate=native-issue:git
      ?:  =(number.candidate u.number)
        candidate(comments (weld comments.candidate ~[comment]), updated now.bowl)
      candidate
    =.  repositories  (~(put by repositories) name u.found(native-issues issues))
    :_  this
    (api-json eyre-id 201 (issue-comment-json comment))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %issues @ %state ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  (native-issue-at u.found u.number)
      :_  this
      (api-error eyre-id 404 'issue not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  requested=(unit @t)  (string-at 'state' u.jon)
    ?.  ?&(?=(^ requested) ?|(=('open' u.requested) =('closed' u.requested)))
      :_  this
      (api-error eyre-id 422 'state must be open or closed')
    =/  next-state=?(%open %closed)  ?:(=('open' u.requested) %open %closed)
    =/  issues=(list native-issue:git)
      %+  turn  native-issues.u.found
      |=  candidate=native-issue:git
      ?:(=(number.candidate u.number) candidate(state next-state, updated now.bowl) candidate)
    =.  repositories  (~(put by repositories) name u.found(native-issues issues))
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['state' s+next-state]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %issues @ %labels ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  (native-issue-at u.found u.number)
      :_  this
      (api-error eyre-id 404 'issue not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  labels=(unit (list @t))  (string-list-at 'labels' u.jon)
    ?.  ?&  ?=(^ labels)
            (lte (lent u.labels) 20)
            (levy u.labels |=(label=@t ?&(!=('' label) (lte (met 3 label) 64))))
        ==
      :_  this
      (api-error eyre-id 422 'labels must be an array of at most 20 non-empty strings, each at most 64 bytes')
    =/  next-labels=(set @t)  (silt u.labels)
    =/  issues=(list native-issue:git)
      %+  turn  native-issues.u.found
      |=  candidate=native-issue:git
      ?:(=(number.candidate u.number) candidate(labels next-labels, updated now.bowl) candidate)
    =.  repositories  (~(put by repositories) name u.found(native-issues issues))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %issues @ %assignees ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'issue number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  (native-issue-at u.found u.number)
      :_  this
      (api-error eyre-id 404 'issue not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  assignees=(unit (list @p))  (ship-list-at 'assignees' u.jon)
    ?.  ?&(?=(^ assignees) (lte (lent u.assignees) 20))
      :_  this
      (api-error eyre-id 422 'assignees must be an array of at most 20 valid ship names')
    =/  next-assignees=(set @p)  (silt u.assignees)
    =/  issues=(list native-issue:git)
      %+  turn  native-issues.u.found
      |=  candidate=native-issue:git
      ?:(=(number.candidate u.number) candidate(assignees next-assignees, updated now.bowl) candidate)
    =.  repositories  (~(put by repositories) name u.found(native-issues issues))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %clay %status ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    :_  this
    (api-json eyre-id 200 (clay-bridge-status-json name u.found our.bowl now.bowl))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %files ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-files-at-json name u.found ref))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %search ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  query=(unit @t)  (query-value 'q' args.line)
    ?.  ?&(?=(^ query) (gte (met 3 u.query) 2) (lte (met 3 u.query) 200))
      :_  this
      (api-error eyre-id 422 'q must be between 2 and 200 bytes')
    :_  this
    (api-json eyre-id 200 (repository-search-json name u.found ref u.query))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %commits ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  offset-text=(unit @t)  (query-value 'offset' args.line)
    =/  offset=(unit @ud)  ?~(offset-text `0 (slaw %ud u.offset-text))
    =/  limit-text=(unit @t)  (query-value 'limit' args.line)
    =/  limit=(unit @ud)  ?~(limit-text `50 (slaw %ud u.limit-text))
    ?.  ?&(?=(^ offset) ?=(^ limit) (lte u.offset 10.000) (gth u.limit 0) (lte u.limit 50))
      :_  this
      (api-error eyre-id 422 'offset must be at most 10000 and limit must be between 1 and 50')
    :_  this
    (api-json eyre-id 200 (repository-history-json name u.found ref our.bowl now.bowl u.offset u.limit))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %compare ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  base-ref=(unit @t)  (query-value 'base' args.line)
    =/  head-ref=(unit @t)  (query-value 'head' args.line)
    ?.  ?&(?=(^ base-ref) ?=(^ head-ref))
      :_  this
      (api-error eyre-id 422 'base and head refs are required')
    =/  base=(unit oid:git)  (revision-oid u.found u.base-ref)
    =/  head=(unit oid:git)  (revision-oid u.found u.head-ref)
    ?.  ?&(?=(^ base) ?=(^ head))
      :_  this
      (api-error eyre-id 404 'base or head ref not found')
    =/  diff=(unit json)  (repository-diff-json name u.found u.base u.head)
    ?~  diff
      :_  this
      (api-error eyre-id 422 'commits do not have readable trees')
    :_  this
    (api-json eyre-id 200 u.diff)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %commit @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  oid-text=@t  i.t.t.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  detail=(unit json)
      (repository-history-detail-json name u.found oid-text our.bowl now.bowl)
    ?~  detail
      :_  this
      (api-error eyre-id 404 'commit not found')
    :_  this
    (api-json eyre-id 200 u.detail)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %file-history *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?~  (revision-oid u.found ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-file-history-view-json name u.found ref u.file-path our.bowl now.bowl))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %file-blame *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    =/  blame=(unit json)
      (repository-file-blame-view-json name u.found ref u.file-path our.bowl now.bowl)
    ?~  blame
      :_  this
      (api-error eyre-id 422 'blame is available for text files up to 256 KiB and 10,000 lines')
    :_  this
    (api-json eyre-id 200 u.blame)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    =/  data=(unit octs)
      (repository-file-at-history u.found ref u.file-path our.bowl now.bowl)
    ?~  data
      :_  this
      (api-error eyre-id 404 'file not found')
    :_  this
    (api-json eyre-id 200 (repository-file-json name u.found ref u.file-path u.data))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  encoded=(unit @t)  (string-at 'content' u.jon)
    =/  message=(unit @t)  (string-at 'message' u.jon)
    =/  requested-ref=(unit @t)  (string-at 'ref' u.jon)
    ?.  ?&(?=(^ encoded) ?=(^ message) !=('' u.message))
      :_  this
      (api-error eyre-id 422 'base64 content and a non-empty commit message are required')
    =/  branch-ref=@t  ?~(requested-ref head.u.found u.requested-ref)
    ?.  ?&  (valid-ref:git-protocol branch-ref)
            (starts-with 'refs/heads/' branch-ref)
        ==
      :_  this
      (api-error eyre-id 422 'ref must be a valid branch')
    =/  data=(unit octs)  (de:base64:mimes:html u.encoded)
    ?~  data
      :_  this
      (api-error eyre-id 422 'content is not valid base64')
    =/  parent=(unit oid:git)  (~(get by refs.u.found) branch-ref)
    ?:  ?&(?=(~ parent) !=(branch-ref head.u.found))
      :_  this
      (api-error eyre-id 404 'branch not found')
    =/  snapped=(unit [commit=oid:git objects=(map oid:git object:git)])
      ?~  parent
        (initial-commit:git-tree objects.u.found u.file-path u.data our.bowl now.bowl u.message)
      (edit-commit:git-tree objects.u.found u.parent u.file-path u.data our.bowl now.bowl u.message)
    ?~  snapped
      :_  this
      (api-error eyre-id 422 'file path conflicts with the tree or branch head is invalid')
    =/  applied=repository:git
      u.found(objects objects.u.snapped, refs (~(put by refs.u.found) branch-ref commit.u.snapped))
    ?~  binding.applied
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?.  =(branch-ref branch.u.binding.applied)
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  clay-files=(unit (map path octs))
      (flatten-commit:git-clay objects.applied commit.u.snapped)
    ?~  clay-files
      :_  this
      (api-error eyre-id 422 'commit cannot be projected onto the linked Clay desk')
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.applied u.clay-files)
    ?~  delta
      :_  this
      (api-error eyre-id 409 'unable to read linked Clay desk')
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =/  clay-revision=(unit @ud)
        %-  mole
        |.(ud:.^(cass:clay %cw /(scot %p our.bowl)/[desk-name.u.binding.applied]/(scot %da now.bowl)))
      =/  linked=repository:git
        (update-binding-success applied commit.u.snapped clay-revision now.bowl)
      =.  repositories  (~(put by repositories) name linked)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    =/  start-at=@da  (add now.bowl ~s1)
    =/  timeout-at=@da  (add now.bowl ~s15)
    =/  pending=clay-push
      :*  eyre-id
          %.y
          ~
          name
          ~
          applied
          desk-name.u.binding.applied
          branch.u.binding.applied
          commit.u.snapped
          u.delta
          ~
          start-at
          timeout-at
      ==
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-start %arvo %b %wait start-at]
        [%pass /clay-timeout %arvo %b %wait timeout-at]
    ==
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site ext.line)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  message=(unit @t)  (string-at 'message' u.jon)
    =/  requested-ref=(unit @t)  (string-at 'ref' u.jon)
    ?.  ?&(?=(^ message) !=('' u.message))
      :_  this
      (api-error eyre-id 422 'non-empty commit message is required')
    =/  branch-ref=@t  ?~(requested-ref head.u.found u.requested-ref)
    ?.  ?&  (valid-ref:git-protocol branch-ref)
            (starts-with 'refs/heads/' branch-ref)
        ==
      :_  this
      (api-error eyre-id 422 'ref must be a valid branch')
    =/  parent=(unit oid:git)  (~(get by refs.u.found) branch-ref)
    ?~  parent
      :_  this
      (api-error eyre-id 404 'branch not found')
    =/  snapped=(unit [commit=oid:git objects=(map oid:git object:git)])
      (delete-commit:git-tree objects.u.found u.parent u.file-path our.bowl now.bowl u.message)
    ?~  snapped
      :_  this
      (api-error eyre-id 404 'file not found or branch head is not a valid Git tree')
    =/  applied=repository:git
      u.found(objects objects.u.snapped, refs (~(put by refs.u.found) branch-ref commit.u.snapped))
    ?~  binding.applied
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?.  =(branch-ref branch.u.binding.applied)
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  clay-files=(unit (map path octs))
      (flatten-commit:git-clay objects.applied commit.u.snapped)
    ?~  clay-files
      :_  this
      (api-error eyre-id 422 'commit cannot be projected onto the linked Clay desk')
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.applied u.clay-files)
    ?~  delta
      :_  this
      (api-error eyre-id 409 'unable to read linked Clay desk')
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =/  clay-revision=(unit @ud)
        %-  mole
        |.(ud:.^(cass:clay %cw /(scot %p our.bowl)/[desk-name.u.binding.applied]/(scot %da now.bowl)))
      =/  linked=repository:git
        (update-binding-success applied commit.u.snapped clay-revision now.bowl)
      =.  repositories  (~(put by repositories) name linked)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    =/  start-at=@da  (add now.bowl ~s1)
    =/  timeout-at=@da  (add now.bowl ~s15)
    =/  pending=clay-push
      :*  eyre-id
          %.y
          ~
          name
          ~
          applied
          desk-name.u.binding.applied
          branch.u.binding.applied
          commit.u.snapped
          u.delta
          ~
          start-at
          timeout-at
      ==
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-start %arvo %b %wait start-at]
        [%pass /clay-timeout %arvo %b %wait timeout-at]
    ==
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repositories ~] site)
      ==
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  name=(unit @t)  (string-at 'name' u.jon)
    =/  public=(unit ?)  (bool-at 'publicRead' u.jon)
    ?.  ?&(?=(^ name) ?=(^ public) (valid-repository-name u.name))
      :_  this
      (api-error eyre-id 422 'name and publicRead are required; name may contain letters, numbers, dot, dash, and underscore')
    ?:  (~(has by repositories) u.name)
      :_  this
      (api-error eyre-id 409 'repository already exists')
    (api-with-action eyre-id 201 [%create u.name u.public])
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ ~] site)
      ==
    =/  name=@t  (api-terminal-name i.t.t.t.t.site ext.line)
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%delete name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %public ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  public=(unit ?)  (bool-at 'publicRead' u.jon)
    ?~  public
      :_  this
      (api-error eyre-id 422 'publicRead is required')
    (api-with-action eyre-id 200 [%set-public name u.public])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %description ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  description=(unit @t)  (string-at 'description' u.jon)
    ?~  description
      :_  this
      (api-error eyre-id 422 'description is required')
    (api-with-action eyre-id 200 [%set-description name u.description])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %branches ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  branch-name=(unit @t)  (string-at 'name' u.jon)
    =/  source-name=(unit @t)  (string-at 'source' u.jon)
    ?.  ?&(?=(^ branch-name) ?=(^ source-name))
      :_  this
      (api-error eyre-id 422 'name and source are required')
    =/  branch-ref=@t  (rap 3 ~['refs/heads/' u.branch-name])
    ?.  (valid-ref:git-protocol branch-ref)
      :_  this
      (api-error eyre-id 422 'branch name is invalid')
    ?:  (~(has by refs.u.found) branch-ref)
      :_  this
      (api-error eyre-id 409 'branch already exists')
    =/  source=(unit oid:git)  (revision-oid u.found u.source-name)
    ?~  source
      :_  this
      (api-error eyre-id 404 'branch source not found')
    (api-with-action eyre-id 201 [%set-ref name branch-ref u.source])
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %branches ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  branch-name=(unit @t)  (string-at 'name' u.jon)
    ?~  branch-name
      :_  this
      (api-error eyre-id 422 'name is required')
    =/  branch-ref=@t  (rap 3 ~['refs/heads/' u.branch-name])
    ?.  (~(has by refs.u.found) branch-ref)
      :_  this
      (api-error eyre-id 404 'branch not found')
    ?:  =(branch-ref head.u.found)
      :_  this
      (api-error eyre-id 409 'cannot delete the default branch')
    ?:  (~(has in protected-refs.u.found) branch-ref)
      :_  this
      (api-error eyre-id 409 'cannot delete a protected branch')
    ?:  ?&(?=(^ binding.u.found) =(branch-ref branch.u.binding.u.found))
      :_  this
      (api-error eyre-id 409 'cannot delete a branch linked to a Clay desk')
    (api-with-action eyre-id 200 [%delete-ref name branch-ref])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %branches %default ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  branch-name=(unit @t)  (string-at 'name' u.jon)
    ?~  branch-name
      :_  this
      (api-error eyre-id 422 'name is required')
    =/  branch-ref=@t  (rap 3 ~['refs/heads/' u.branch-name])
    ?.  (~(has by refs.u.found) branch-ref)
      :_  this
      (api-error eyre-id 404 'branch not found')
    (api-with-action eyre-id 200 [%set-head name branch-ref])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %notifications ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  events=(unit (set notification-event:git))
      (notification-events-at 'events' u.jon)
    ?~  events
      :_  this
      (api-error eyre-id 422 'events must contain only issue, issue-comment, pull-request, or pull-comment')
    =/  updated=repository:git  u.found(notification-events u.events)
    =.  repositories  (~(put by repositories) name updated)
    :_  this
    (api-json eyre-id 200 (repository-json name updated))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %webhooks ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  url=(unit @t)  (string-at 'url' u.jon)
    =/  secret=(unit @t)  (string-at 'secret' u.jon)
    =/  events=(unit (set webhook-event:git))  (webhook-events-at 'events' u.jon)
    ?.  ?&  ?=(^ url)
            ?=(^ secret)
            ?=(^ events)
            ?=(^ ~(tap in u.events))
            |((starts-with 'https://' u.url) (starts-with 'http://' u.url))
            (lte (met 3 u.url) 2.048)
            !=('' u.secret)
            (lte (met 3 u.secret) 256)
        ==
      :_  this
      (api-error eyre-id 422 'url, secret, and at least one valid event are required')
    =/  entries=(list [@ud webhook:git])  ~(tap by webhooks.u.found)
    =/  next-id=@ud  1
    =.  next-id
      |-
      ?~  entries  next-id
      $(entries t.entries, next-id (max next-id +(id.+.i.entries)))
    =/  hook=webhook:git  [next-id u.url u.secret u.events %.y]
    =/  updated=repository:git
      u.found(webhooks (~(put by webhooks.u.found) next-id hook))
    =.  repositories  (~(put by repositories) name updated)
    :_  this
    (api-json eyre-id 201 (webhook-json hook))
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %webhooks ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  id=(unit @ud)  (nat-at 'id' u.jon)
    ?.  ?&(?=(^ id) (~(has by webhooks.u.found) u.id))
      :_  this
      (api-error eyre-id 404 'webhook not found')
    =.  repositories
      (~(put by repositories) name u.found(webhooks (~(del by webhooks.u.found) u.id)))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %webhooks @ %test ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  id=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?.  ?&(?=(^ id) ?=(^ found) (~(has by webhooks.u.found) u.id))
      :_  this
      (api-error eyre-id 404 'webhook not found')
    =/  hook=webhook:git  (~(got by webhooks.u.found) u.id)
    =/  test-repo=repository:git
      u.found(webhooks (~(put by webhooks.u.found) u.id hook(events (silt ~[%push]))))
    =.  repositories  (~(put by repositories) name test-repo)
    =/  result=(quip card _this)
      (dispatch-webhooks name %push (pairs:enjs:format ~[['test' b+%.y]]))
    =/  restored=(unit repository:git)  (~(get by repositories.+.result) name)
    =/  next=_this
      ?~  restored  +.result
      +.result(repositories (~(put by repositories.+.result) name u.restored(webhooks (~(put by webhooks.u.restored) u.id hook))))
    :_  next
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %incoming-hook ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  secret=(unit @t)  (string-at 'secret' u.jon)
    ?.  ?&(?=(^ secret) !=('' u.secret) (lte (met 3 u.secret) 256))
      :_  this
      (api-error eyre-id 422 'a non-empty secret up to 256 bytes is required')
    =.  repositories
      (~(put by repositories) name u.found(incoming-hook `[[u.secret %.y]]))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %incoming-hook ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =.  repositories  (~(put by repositories) name u.found(incoming-hook ~))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %upstream-updates ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  id-text=(unit @t)  (string-at 'id' u.jon)
    =/  id=(unit @uv)  ?~(id-text ~ (slaw %uv u.id-text))
    ?~  id
      :_  this
      (api-error eyre-id 422 'valid update id required')
    =/  matches=(list upstream-update:git)
      (skim upstream-updates.u.found |=(update=upstream-update:git =(id.update u.id)))
    =/  updates=(list upstream-update:git)
      ?~  matches  upstream-updates.u.found
      (skim upstream-updates.u.found |=(update=upstream-update:git !=(ref.update ref.i.matches)))
    =.  repositories  (~(put by repositories) name u.found(upstream-updates updates))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %releases ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  tag=(unit @t)  (string-at 'tag' u.jon)
    =/  title=(unit @t)  (string-at 'title' u.jon)
    =/  notes=(unit @t)  (string-at 'notes' u.jon)
    ?.  ?&  ?=(^ tag)
            ?=(^ title)
            ?=(^ notes)
            !=('' u.tag)
            !=('' u.title)
            (lte (met 3 u.title) 200)
            (lte (met 3 u.notes) 65.536)
        ==
      :_  this
      (api-error eyre-id 422 'tag and title are required; notes are limited to 64 KiB')
    =/  tag-ref=@t  (rap 3 ~['refs/tags/' u.tag])
    ?.  (~(has by refs.u.found) tag-ref)
      :_  this
      (api-error eyre-id 404 'tag not found')
    ?:  (~(has by releases.u.found) u.tag)
      :_  this
      (api-error eyre-id 409 'release already exists for this tag')
    =/  release=release:git  [u.tag u.title u.notes our.bowl now.bowl]
    =.  repositories
      (~(put by repositories) name u.found(releases (~(put by releases.u.found) u.tag release)))
    =/  dispatched=(quip card _this)
      (dispatch-webhooks name %release (release-json release %.y))
    :_  +.dispatched
    (weld -.dispatched (api-json eyre-id 201 (release-json release %.y)))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %releases ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  tag=(unit @t)  (query-value 'tag' args.line)
    ?~  tag
      :_  this
      (api-error eyre-id 422 'tag is required')
    =/  release=(unit release:git)  (~(get by releases.u.found) u.tag)
    ?~  release
      :_  this
      (api-error eyre-id 404 'release not found')
    :_  this
    (api-json eyre-id 200 (release-json u.release %.y))
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %releases ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  tag=(unit @t)  (string-at 'tag' u.jon)
    ?.  ?&(?=(^ tag) (~(has by releases.u.found) u.tag))
      :_  this
      (api-error eyre-id 404 'release not found')
    =.  repositories
      (~(put by repositories) name u.found(releases (~(del by releases.u.found) u.tag)))
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %archive ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  ref=(unit @t)  (query-value 'ref' args.line)
    ?~  ref
      :_  this
      (api-error eyre-id 422 'ref is required')
    =/  target=(unit oid:git)  (revision-oid u.found u.ref)
    ?~  target
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  peeled=(unit oid:git)  (peeled-tag:git-protocol objects.u.found u.target)
    =/  commit=oid:git  ?~(peeled u.target u.peeled)
    =/  archive=(unit octs)  (archive:git-archive objects.u.found commit)
    ?~  archive
      :_  this
      (api-error eyre-id 422 'archive requires a complete commit tree of at most 10,000 files and 64 MiB')
    :_  this
    (api-archive eyre-id name u.archive)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %tags ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  tag-name=(unit @t)  (string-at 'name' u.jon)
    =/  target-name=(unit @t)  (string-at 'target' u.jon)
    =/  message=(unit @t)  (string-at 'message' u.jon)
    ?.  ?&(?=(^ tag-name) ?=(^ target-name) ?=(^ message))
      :_  this
      (api-error eyre-id 422 'name, target, and message are required')
    =/  tag-ref=@t  (rap 3 ~['refs/tags/' u.tag-name])
    ?.  (valid-ref:git-protocol tag-ref)
      :_  this
      (api-error eyre-id 422 'tag name is invalid')
    ?:  (~(has by refs.u.found) tag-ref)
      :_  this
      (api-error eyre-id 409 'tag already exists')
    =/  clay-number=(unit @ud)  (clay-revision-number u.target-name)
    =/  prepared=(unit [repo=repository:git target=oid:git])
      ?~  clay-number
        =/  target=(unit oid:git)  (revision-oid u.found u.target-name)
        ?~  target  ~
        `[u.found u.target]
      (materialize-clay-revision u.found u.clay-number our.bowl now.bowl)
    ?~  prepared
      :_  this
      (api-error eyre-id 404 'tag target not found')
    =/  applied=repository:git
      ?:  =('' u.message)
        repo.u.prepared(refs (~(put by refs.repo.u.prepared) tag-ref target.u.prepared))
      =/  tagged=(unit [tag=oid:git objects=(map oid:git object:git)])
        (annotated-tag:git-tree objects.repo.u.prepared target.u.prepared u.tag-name our.bowl now.bowl u.message)
      ?~  tagged  repo.u.prepared
      repo.u.prepared(objects objects.u.tagged, refs (~(put by refs.repo.u.prepared) tag-ref tag.u.tagged))
    =.  repositories  (~(put by repositories) name applied)
    =/  tag-oid=oid:git  (need (~(get by refs.applied) tag-ref))
    =/  event-data=json
      %-  pairs:enjs:format
      :~  ['ref' s+tag-ref]
          ['oid' s+(oid-text:git-codec tag-oid)]
          ['target' s+(oid-text:git-codec target.u.prepared)]
          ['clayRevision' n+(decimal ?~(clay-number 0 u.clay-number))]
      ==
    =/  dispatched=(quip card _this)  (dispatch-webhooks name %tag event-data)
    :_  +.dispatched
    (weld -.dispatched (api-json eyre-id 201 (pairs:enjs:format ~[['ok' b+%.y] ['ref' s+tag-ref] ['oid' s+(oid-text:git-codec tag-oid)]])))
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %tags ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  tag-name=(unit @t)  (string-at 'name' u.jon)
    ?~  tag-name
      :_  this
      (api-error eyre-id 422 'name is required')
    =/  tag-ref=@t  (rap 3 ~['refs/tags/' u.tag-name])
    ?.  (~(has by refs.u.found) tag-ref)
      :_  this
      (api-error eyre-id 404 'tag not found')
    ?:  (~(has by releases.u.found) u.tag-name)
      :_  this
      (api-error eyre-id 409 'delete the release before deleting its tag')
    =.  repositories  (~(put by repositories) name u.found(refs (~(del by refs.u.found) tag-ref)))
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %pulls ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  title=(unit @t)  (string-at 'title' u.jon)
    =/  branch=(unit @t)  (string-at 'branch' u.jon)
    ?.  ?&  ?=(^ title)
            ?=(^ branch)
            !=('' u.title)
            (lte (met 3 u.title) 200)
            (starts-with 'refs/heads/' u.branch)
            (valid-ref:git-protocol u.branch)
        ==
      :_  this
      (api-error eyre-id 422 'title and a valid source branch are required')
    ?:  =(u.branch head.u.found)
      :_  this
      (api-error eyre-id 422 'source branch must differ from the default branch')
    =/  incoming=(unit oid:git)  (~(get by refs.u.found) u.branch)
    ?~  incoming
      :_  this
      (api-error eyre-id 404 'source branch not found')
    =/  base=(unit oid:git)  (~(get by refs.u.found) head.u.found)
    ?~  base
      :_  this
      (api-error eyre-id 409 'default branch has no head')
    ?:  =(u.incoming u.base)
      :_  this
      (api-error eyre-id 409 'source branch has no changes')
    =/  number=@ud  (add 1 (lent native-pulls.u.found))
    =/  pull=native-pull:git
      [number our.bowl name u.title %open u.incoming u.base ~]
    =.  repositories
      (~(put by repositories) name u.found(native-pulls [pull native-pulls.u.found]))
    =/  event-data=json
      (pairs:enjs:format ~[['number' n+(decimal number)] ['title' s+u.title] ['branch' s+u.branch] ['state' s+'open']])
    =/  dispatched=(quip card _this)
      (dispatch-webhooks name %pull-request event-data)
    :_  +.dispatched
    (weld -.dispatched (api-json eyre-id 201 (pairs:enjs:format ~[['ok' b+%.y] ['number' n+(decimal number)]])))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %pulls @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'pull request number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  matches=(list native-pull:git)
      (skim native-pulls.u.found |=(pull=native-pull:git =(number.pull u.number)))
    ?~  matches
      :_  this
      (api-error eyre-id 404 'pull request not found')
    =/  pull=native-pull:git  i.matches
    =/  diff=(unit json)  (repository-diff-json name u.found base.pull head.pull)
    ?~  diff
      :_  this
      (api-error eyre-id 409 'pull request objects are incomplete')
    ?>  ?=([%o *] u.diff)
    =/  fields=(map @t json)  p.u.diff
    =.  fields
      (~(put by fields) 'comments' [%a (turn comments.pull review-comment-json)])
    :_  this
    (api-json eyre-id 200 [%o fields])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %pulls @ %comments ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'pull request number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  matches=(list native-pull:git)
      (skim native-pulls.u.found |=(pull=native-pull:git =(number.pull u.number)))
    ?~  matches
      :_  this
      (api-error eyre-id 404 'pull request not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  body=(unit @t)  (string-at 'body' u.jon)
    =/  path-text=(unit @t)  (string-at 'path' u.jon)
    =/  line-number=(unit @ud)  (nat-at 'line' u.jon)
    =/  side-text=(unit @t)  (string-at 'side' u.jon)
    ?.  ?&  ?=(^ body)
            ?=(^ path-text)
            ?=(^ line-number)
            ?=(^ side-text)
            !=('' u.body)
            (lte (met 3 u.body) 16.384)
            (lte (met 3 u.path-text) 2.048)
        ==
      :_  this
      (api-error eyre-id 422 'body, path, line, and side are required; comment body is limited to 16 KiB')
    =/  anchored=?  !=('' u.path-text)
    ?.  ?:  anchored
          ?&  (gth u.line-number 0)
              ?|  =('base' u.side-text)
                  =('head' u.side-text)
              ==
          ==
        ?&(=(0 u.line-number) =('' u.side-text))
      :_  this
      (api-error eyre-id 422 'line comments require a path, positive line, and base or head side')
    =/  pull=native-pull:git  i.matches
    =/  comment-id=@ud  (add 1 (lent comments.pull))
    =/  comment-author=@p  our.bowl
    =/  comment-body=@t  u.body
    =/  comment-created=@da  now.bowl
    =/  comment-path=(unit @t)  ?:(anchored `u.path-text ~)
    =/  comment-line=(unit @ud)  ?:(anchored `u.line-number ~)
    =/  comment-side=(unit ?(%base %head))
      ?:(anchored `?:(=('base' u.side-text) %base %head) ~)
    =/  comment=review-comment:git
      [comment-id comment-author comment-body comment-created comment-path comment-line comment-side %.n]
    =/  pulls=(list native-pull:git)
      %+  turn  native-pulls.u.found
      |=  candidate=native-pull:git
      ?:  =(number.candidate u.number)
        candidate(comments (weld comments.candidate ~[comment]))
      candidate
    =.  repositories
      (~(put by repositories) name u.found(native-pulls pulls))
    :_  this
    (api-json eyre-id 201 (review-comment-json comment))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %pulls @ %comments @ %resolve ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    =/  comment-id=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.t.t.site)
    ?.  ?&(?=(^ number) ?=(^ comment-id))
      :_  this
      (api-error eyre-id 422 'pull request or comment number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  matches=(list native-pull:git)
      (skim native-pulls.u.found |=(pull=native-pull:git =(number.pull u.number)))
    ?~  matches
      :_  this
      (api-error eyre-id 404 'pull request not found')
    =/  pull=native-pull:git  i.matches
    =/  comment-matches=(list review-comment:git)
      (skim comments.pull |=(comment=review-comment:git =(id.comment u.comment-id)))
    ?~  comment-matches
      :_  this
      (api-error eyre-id 404 'review comment not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  resolved=(unit ?)  (bool-at 'resolved' u.jon)
    ?~  resolved
      :_  this
      (api-error eyre-id 422 'resolved flag is required')
    =/  updated-comments=(list review-comment:git)
      %+  turn  comments.pull
      |=  comment=review-comment:git
      ?:(=(id.comment u.comment-id) comment(resolved u.resolved) comment)
    =/  updated=review-comment:git
      i.comment-matches(resolved u.resolved)
    =/  pulls=(list native-pull:git)
      %+  turn  native-pulls.u.found
      |=  candidate=native-pull:git
      ?:(=(number.candidate u.number) candidate(comments updated-comments) candidate)
    =.  repositories
      (~(put by repositories) name u.found(native-pulls pulls))
    :_  this
    (api-json eyre-id 200 (review-comment-json updated))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %pulls @ %state ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'pull request number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  matches=(list native-pull:git)
      (skim native-pulls.u.found |=(pull=native-pull:git =(number.pull u.number)))
    ?~  matches
      :_  this
      (api-error eyre-id 404 'pull request not found')
    =/  pull=native-pull:git  i.matches
    ?:  =(%merged state.pull)
      :_  this
      (api-error eyre-id 409 'merged pull requests cannot be reopened or closed')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  requested=(unit @t)  (string-at 'state' u.jon)
    ?.  ?&(?=(^ requested) ?|(=('open' u.requested) =('closed' u.requested)))
      :_  this
      (api-error eyre-id 422 'state must be open or closed')
    =/  next-state=?(%open %closed)  ?:(=('open' u.requested) %open %closed)
    =/  pulls=(list native-pull:git)
      %+  turn  native-pulls.u.found
      |=  candidate=native-pull:git
      ?:(=(number.candidate u.number) candidate(state next-state) candidate)
    =.  repositories
      (~(put by repositories) name u.found(native-pulls pulls))
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['state' s+next-state]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %pulls @ %merge ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  number=(unit @ud)  (slaw %ud i.t.t.t.t.t.t.site)
    ?~  number
      :_  this
      (api-error eyre-id 422 'pull request number is invalid')
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  matches=(list native-pull:git)
      (skim native-pulls.u.found |=(pull=native-pull:git =(number.pull u.number)))
    ?~  matches
      :_  this
      (api-error eyre-id 404 'pull request not found')
    =/  pull=native-pull:git  i.matches
    ?.  =(%open state.pull)
      :_  this
      (api-error eyre-id 409 'pull request is not open')
    =/  current=(unit oid:git)  (~(get by refs.u.found) head.u.found)
    ?~  current
      :_  this
      (api-error eyre-id 409 'destination branch has no head')
    =/  incoming-reachable=(unit (set oid:git))
      (reachable:git-graph objects.u.found (silt ~[head.pull]))
    =/  current-reachable=(unit (set oid:git))
      (reachable:git-graph objects.u.found (silt ~[u.current]))
    ?.  ?&(?=(^ incoming-reachable) ?=(^ current-reachable))
      :_  this
      (api-error eyre-id 409 'pull request object graph is incomplete')
    =/  fast-forward=?  (~(has in u.incoming-reachable) u.current)
    =/  already-merged=?  (~(has in u.current-reachable) head.pull)
    =/  common-base=?
      ?&  (~(has in u.incoming-reachable) base.pull)
          (~(has in u.current-reachable) base.pull)
      ==
    ?.  |(fast-forward already-merged common-base)
      :_  this
      (api-error eyre-id 409 'pull request branches no longer share the recorded base')
    =/  integrated=(unit [commit=oid:git objects=(map oid:git object:git)])
      ?:  fast-forward  `[head.pull objects.u.found]
      ?:  already-merged  `[u.current objects.u.found]
      (merge-commit:git-tree objects.u.found base.pull u.current head.pull our.bowl now.bowl (rap 3 ~['Merge pull request #' (decimal number.pull) ': ' title.pull]))
    ?~  integrated
      :_  this
      (api-error eyre-id 409 'pull request has conflicting file changes')
    =/  merge-oid=oid:git  commit.u.integrated
    =/  pulls=(list native-pull:git)
      %+  turn  native-pulls.u.found
      |=  candidate=native-pull:git
      ?:  =(number.candidate number.pull)
        candidate(state %merged)
      candidate
    =/  applied=repository:git
      u.found(objects objects.u.integrated, refs (~(put by refs.u.found) head.u.found merge-oid), native-pulls pulls)
    =/  clay-linked=?
      ?~  binding.applied  %.n
      =(head.applied branch.u.binding.applied)
    ?.  clay-linked
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec merge-oid)]]))
    ?>  ?=(^ binding.applied)
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  files=(unit (map path octs))
      (flatten-commit:git-clay objects.applied merge-oid)
    ?~  files
      :_  this
      (api-error eyre-id 409 'pull request head is not a desk-shaped Git commit')
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.applied u.files)
    ?~  delta
      :_  this
      (api-error eyre-id 409 'unable to read linked Clay desk')
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec merge-oid)]]))
    =/  start-at=@da  (add now.bowl ~s1)
    =/  timeout-at=@da  (add now.bowl ~s15)
    =/  pending=clay-push
      :*  eyre-id
          %.y
          ~
          name
          ~
          applied
          desk-name.u.binding.applied
          branch.u.binding.applied
          merge-oid
          u.delta
          ~
          start-at
          timeout-at
      ==
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-start %arvo %b %wait start-at]
        [%pass /clay-timeout %arvo %b %wait timeout-at]
    ==
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %writers ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ship-text=(unit @t)  (string-at 'ship' u.jon)
    =/  allowed=(unit ?)  (bool-at 'allowed' u.jon)
    ?.  ?&(?=(^ ship-text) ?=(^ allowed))
      :_  this
      (api-error eyre-id 422 'ship and allowed are required')
    =/  writer=(unit @p)  (slaw %p u.ship-text)
    ?~  writer
      :_  this
      (api-error eyre-id 422 'ship must be a valid Urbit ID')
    ?:  u.allowed
      (api-with-action eyre-id 200 [%grant-writer name u.writer])
    (api-with-action eyre-id 200 [%revoke-writer name u.writer])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %protected ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  ref=(unit @t)  (string-at 'ref' u.jon)
    =/  protected=(unit ?)  (bool-at 'protected' u.jon)
    ?.  ?&  ?=(^ ref)
            ?=(^ protected)
            (valid-ref:git-protocol u.ref)
            (starts-with 'refs/heads/' u.ref)
        ==
      :_  this
      (api-error eyre-id 422 'a valid branch ref and protected flag are required')
    (api-with-action eyre-id 200 [%set-protected name u.ref u.protected])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %token ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  token=(unit @t)  (string-at 'token' u.jon)
    ?.  ?&(?=(^ token) !=('' u.token))
      :_  this
      (api-error eyre-id 422 'non-empty token is required')
    (api-with-action eyre-id 200 [%set-write-token name u.token])
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %urgit %api %repository @ %token ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%clear-write-token name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %bind ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  desk-text=(unit @t)  (string-at 'desk' u.jon)
    =/  branch=(unit @t)  (string-at 'branch' u.jon)
    ?.  ?&(?=(^ desk-text) ?=(^ branch))
      :_  this
      (api-error eyre-id 422 'desk and branch are required')
    =/  desk-name=(unit @tas)  (slaw %tas u.desk-text)
    ?~  desk-name
      :_  this
      (api-error eyre-id 422 'desk must be a valid term')
    ?.  ?&  (starts-with 'refs/heads/' u.branch)
            (valid-ref:git-protocol u.branch)
        ==
      :_  this
      (api-error eyre-id 422 'branch must be a valid refs/heads/... ref')
    =/  desks=(unit (set desk))
      %-  mole
      |.(.^((set desk) %cd /(scot %p our.bowl)//(scot %da now.bowl)))
    ?.  ?&(?=(^ desks) (~(has in u.desks) u.desk-name))
      :_  this
      (api-error eyre-id 404 'Clay desk not found')
    (api-with-action eyre-id 200 [%bind-desk name u.desk-name u.branch])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %unbind ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%unbind-desk name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %publish ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  binding.u.found
      :_  this
      (api-error eyre-id 409 'repository is not bound to a Clay desk')
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  message=(unit @t)  (string-at 'message' u.jon)
    ?.  ?&(?=(^ message) !=('' u.message))
      :_  this
      (api-error eyre-id 422 'non-empty message is required')
    (api-with-action eyre-id 202 [%publish-desk name u.message])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %clay %apply ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    ?~  binding.u.found
      :_  this
      (api-error eyre-id 409 'repository is not bound to a Clay desk')
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  head-oid=(unit oid:git)
      (~(get by refs.u.found) branch.u.binding.u.found)
    ?~  head-oid
      :_  this
      (api-error eyre-id 409 'linked branch has no head')
    =/  files=(unit (map path octs))
      (flatten-commit:git-clay objects.u.found u.head-oid)
    ?~  files
      :_  this
      (api-error eyre-id 422 'linked branch is not a valid desk-shaped Git commit')
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.u.found u.files)
    ?~  delta
      :_  this
      (api-error eyre-id 409 'unable to read linked Clay desk')
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =/  clay-revision=(unit @ud)
        %-  mole
        |.(ud:.^(cass:clay %cw /(scot %p our.bowl)/[desk-name.u.binding.u.found]/(scot %da now.bowl)))
      =/  linked=repository:git
        (update-binding-success u.found u.head-oid clay-revision now.bowl)
      =.  repositories  (~(put by repositories) name linked)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec u.head-oid)]]))
    =/  start-at=@da  (add now.bowl ~s1)
    =/  timeout-at=@da  (add now.bowl ~s15)
    =/  pending=clay-push
      :*  eyre-id
          %.y
          ~
          name
          ~
          u.found
          desk-name.u.binding.u.found
          branch.u.binding.u.found
          u.head-oid
          u.delta
          ~
          start-at
          timeout-at
      ==
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-start %arvo %b %wait start-at]
        [%pass /clay-timeout %arvo %b %wait timeout-at]
    ==
  ?:  ?&  =(%'GET' method)
          ?=([%apps %urgit %api %repository @ %lfs %gc ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  preview=(unit json)  (lfs-gc-json u.found)
    ?~  preview
      :_  this
      (api-error eyre-id 409 'repository object graph is incomplete')
    :_  this
    (api-json eyre-id 200 u.preview)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %urgit %api %repository @ %lfs %gc ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  settings=(unit [credentials=credentials:git-storage configuration=configuration:git-storage])
      storage-settings
    ?~  settings
      :_  this
      (api-error eyre-id 503 'ship object storage is not configured')
    =/  live=(unit (set @t))  (referenced-lfs u.found)
    ?~  live
      :_  this
      (api-error eyre-id 409 'repository object graph is incomplete')
    =/  candidates=(list [@t lfs-object:git])
      %+  skim  ~(tap by lfs-objects.u.found)
      |=  entry=[@t lfs-object:git]
      !(~(has in u.live) -.entry)
    =.  candidates  (scag 100 candidates)
    =/  cards=(list card)  ~
    =/  scheduled=@ud  0
    |-
    ?~  candidates
      :_  this
      (weld cards (api-json eyre-id 202 (pairs:enjs:format ~[['scheduled' n+(decimal scheduled)]])))
    =/  request-id=@uv
      `@uv`(shas %git-lfs-delete (cat 3 eny.bowl request-count))
    =.  request-count  +(request-count)
    =/  signed=signed-request:git-storage
      (sign:git-storage 'DELETE' 'application/octet-stream' [0 0] credentials.u.settings configuration.u.settings object-key.+.i.candidates now.bowl)
    =.  lfs-deletes  (~(put by lfs-deletes) request-id [name -.i.candidates])
    =.  cards
      [[%pass /lfs-delete/(scot %uv request-id) %arvo %i %request [%'DELETE' url.signed headers.signed ~] *outbound-config:iris] cards]
    $(candidates t.candidates, scheduled +(scheduled))
  :_  this
  (api-error eyre-id 404 'API route not found')
::
++  lfs-error
  |=  [status=@ud message=@t]
  ^-  simple-payload:http
  (json-payload status (pairs:enjs:format ~[['message' s+message]]))
::
++  storage-settings
  ^-  (unit [credentials=credentials:git-storage configuration=configuration:git-storage])
  =/  found-credentials=(unit json)
    %-  mole
    |.(.^(json %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/credentials/json))
  ?~  found-credentials  ~
  =/  found-configuration=(unit json)
    %-  mole
    |.(.^(json %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/configuration/json))
  ?~  found-configuration  ~
  =/  get-string
    |=  [jon=json keys=(list @t)]
    ^-  @t
    ?~  keys  ?:(?=([%s *] jon) p.jon '')
    ?.  ?=([%o *] jon)  ''
    =/  value=(unit json)  (~(get by p.jon) i.keys)
    ?~  value  ''
    $(jon u.value, keys t.keys)
  =/  credentials=credentials:git-storage
    :*  (get-string u.found-credentials ~['storage-update' 'credentials' 'endpoint'])
        (get-string u.found-credentials ~['storage-update' 'credentials' 'accessKeyId'])
        (get-string u.found-credentials ~['storage-update' 'credentials' 'secretAccessKey'])
    ==
  =/  configuration=configuration:git-storage
    :*  (get-string u.found-configuration ~['storage-update' 'configuration' 'currentBucket'])
        (get-string u.found-configuration ~['storage-update' 'configuration' 'region'])
    ==
  =/  service=@t
    (get-string u.found-configuration ~['storage-update' 'configuration' 'service'])
  ?.  =('credentials' service)  ~
  ?.  ?&  !=('' endpoint.credentials)
          !=('' access-key-id.credentials)
          !=('' secret-access-key.credentials)
          !=('' current-bucket.configuration)
          !=('' region.configuration)
      ==
    ~
  `[credentials configuration]
::
++  write-authorized
  |=  [repo=repository:git req=inbound-request:eyre]
  ^-  ?
  ?:  authenticated.req  %.y
  ?~  write-token-hash.repo  %.n
  =/  header=(unit @t)  (get-header:http 'authorization' header-list.request.req)
  ?~  header  %.n
  ?.  (starts-with 'Basic ' u.header)  %.n
  =/  decoded=(unit octs)
    (de:base64:mimes:html (crip (slag 6 (trip u.header))))
  ?~  decoded  %.n
  =/  credentials=tape  (trip q.u.decoded)
  =/  colon=(unit @ud)  (find ":" credentials)
  ?~  colon  %.n
  =/  token=@t  (crip (slag +(u.colon) credentials))
  =(u.write-token-hash.repo (shas %git-write-token token))
::
++  lfs-principal
  |=  req=inbound-request:eyre
  ^-  (unit @t)
  ?:  authenticated.req  `(scot %p our.bowl)
  =/  header=(unit @t)  (get-header:http 'authorization' header-list.request.req)
  ?~  header  ~
  ?.  (starts-with 'Basic ' u.header)  ~
  =/  decoded=(unit octs)
    (de:base64:mimes:html (crip (slag 6 (trip u.header))))
  ?~  decoded  ~
  =/  credentials=tape  (trip q.u.decoded)
  =/  colon=(unit @ud)  (find ":" credentials)
  ?~  colon  ~
  =/  user=@t  (crip (scag u.colon credentials))
  ?:(=('' user) `'git' `user)
::
++  merge-objects
  |=  [current=(map oid:git object:git) staged=(map oid:git object:git)]
  ^-  (map oid:git object:git)
  =/  entries=(list [oid:git object:git])  ~(tap by staged)
  |-
  ?~  entries  current
  $(entries t.entries, current (~(put by current) -.i.entries +.i.entries))
::
++  apply-receive
  |=  [repo=repository:git commands=(list receive-command:git) staged=(map oid:git object:git)]
  ^-  (unit repository:git)
  =/  combined=(map oid:git object:git)  (merge-objects objects.repo staged)
  =/  working=(map @t oid:git)  refs.repo
  =/  seen=(set @t)  ~
  =/  remaining=(list receive-command:git)  commands
  |-
  ?~  remaining  `repo(objects combined, refs working)
  =/  command=receive-command:git  i.remaining
  ?:  (~(has in seen) ref.command)  ~
  ?.  =(old.command (~(get by refs.repo) ref.command))  ~
  =.  seen  (~(put in seen) ref.command)
  ?~  new.command
    =.  working  (~(del by working) ref.command)
    $(remaining t.remaining)
  ?.  (~(has by combined) u.new.command)  ~
  =.  working  (~(put by working) ref.command u.new.command)
  $(remaining t.remaining)
::
++  receive-policy-error
  |=  [repo=repository:git commands=(list receive-command:git) staged=(map oid:git object:git)]
  ^-  (unit @t)
  =/  combined=(map oid:git object:git)  (merge-objects objects.repo staged)
  =/  remaining=(list receive-command:git)  commands
  |-
  ?~  remaining  ~
  =/  command=receive-command:git  i.remaining
  =/  release-tag=?
    ?.  (starts-with 'refs/tags/' ref.command)  %.n
    (~(has by releases.repo) (crip (slag 10 (trip ref.command))))
  ?:  release-tag
    `'release tags cannot be updated or deleted; delete the release first'
  ?.  (~(has in protected-refs.repo) ref.command)
    $(remaining t.remaining)
  ?~  old.command
    $(remaining t.remaining)
  ?~  new.command
    `'protected branch cannot be deleted'
  =/  reachable=(unit (set oid:git))
    (reachable:git-graph combined (silt ~[u.new.command]))
  ?.  ?&  ?=(^ reachable)
          (~(has in u.reachable) u.old.command)
      ==
    `'protected branch requires a fast-forward update'
  $(remaining t.remaining)
::
++  command-for-ref
  |=  [commands=(list receive-command:git) ref=@t]
  ^-  (unit receive-command:git)
  ?~  commands  ~
  ?:  =(ref ref.i.commands)  `i.commands
  $(commands t.commands)
::
++  clay-delta
  |=  [desk-name=desk files=(map path octs)]
  ^-  (unit nori:clay)
  =/  old-files=(unit (list spur))
    %-  mole
    |.(.^((list spur) %ct /(scot %p our.bowl)/[desk-name]/(scot %da now.bowl)))
  ?~  old-files  ~
  =/  old-set=(set path)  (silt u.old-files)
  =/  old-bytes=(unit (map path octs))
    (clay-current-files desk-name)
  =/  changes=(list [p=path q=miso:clay])
    %+  murn  ~(tap by files)
    |=  [file-path=path data=octs]
    ^-  (unit [p=path q=miso:clay])
    =/  old-data=(unit octs)
      ?~  old-bytes  ~
      (~(get by u.old-bytes) file-path)
    ?:  ?&(?=(^ old-data) =(u.old-data data))  ~
    =/  =mime  [/ data]
    =/  change=miso:clay
      ?:  (~(has in old-set) file-path)
        [%mut %mime !>(mime)]
      [%ins %mime !>(mime)]
    `[file-path change]
  =/  deletes=(list [p=path q=miso:clay])
    %+  murn  u.old-files
    |=  file-path=spur
    ^-  (unit [p=path q=miso:clay])
    ?:  (~(has by files) file-path)  ~
    `[file-path %del ~]
  `[%& (weld changes deletes)]
::
++  clay-current-files
  |=  desk-name=desk
  ^-  (unit (map path octs))
  =/  native=(unit history:git-clay-history)
    (desk-history:git-clay-history our.bowl desk-name now.bowl 1)
  ?~  native  ~
  ?~  revisions.u.native  `*(map path octs)
  =/  revision=revision:git-clay-history  i.revisions.u.native
  =/  yaki=(unit yaki:clay)
    (revision-yaki:git-clay-history our.bowl desk-name number.revision tako.revision)
  ?~  yaki  ~
  =/  remaining=(list [path lobe:clay])  ~(tap by q.u.yaki)
  =/  result=(map path octs)  ~
  |-
  ?~  remaining  `result
  =/  data=(unit octs)
    (clay-file-octs our.bowl desk-name number.revision +.i.remaining now.bowl)
  ?~  data  ~
  $(remaining t.remaining, result (~(put by result) -.i.remaining u.data))
::
++  file-maps-equal
  |=  [left=(map path octs) right=(map path octs)]
  ^-  ?
  ?.  =((lent ~(tap by left)) (lent ~(tap by right)))  %.n
  =/  remaining=(list [path octs])  ~(tap by left)
  |-
  ?~  remaining  %.y
  =/  found=(unit octs)  (~(get by right) -.i.remaining)
  ?.  ?&(?=(^ found) =(u.found +.i.remaining))  %.n
  $(remaining t.remaining)
::
++  clay-bridge-status-json
  |=  [name=@t repo=repository:git who=@p now=@da]
  ^-  json
  ?~  binding.repo
    %-  pairs:enjs:format
    ~[['bound' b+%.n] ['relation' s+'unbound']]
  =/  binding=desk-binding:git  u.binding.repo
  =/  native=(unit history:git-clay-history)
    (desk-history:git-clay-history who desk-name.binding now 1)
  =/  current-revision=(unit @ud)
    ?~  native  ~
    `latest.u.native
  =/  current-meta=(unit revision:git-clay-history)
    ?~  native  ~
    ?~  revisions.u.native  ~
    `i.revisions.u.native
  =/  branch-oid=(unit oid:git)  (~(get by refs.repo) branch.binding)
  =/  branch-files=(unit (map path octs))
    ?~  branch-oid  ~
    (flatten-commit:git-clay objects.repo u.branch-oid)
  =/  clay-files=(unit (map path octs))
    (clay-current-files desk-name.binding)
  =/  contents-match=?
    ?.  ?&(?=(^ branch-files) ?=(^ clay-files))  %.n
    (file-maps-equal u.branch-files u.clay-files)
  =/  clay-matches-last=?  =(current-revision last-clay.binding)
  =/  git-matches-last=?  =(branch-oid last-git.binding)
  =/  relation=@t
    ?:  ?&  ?=(^ last-clay.binding)
            ?=(^ last-git.binding)
            clay-matches-last
            git-matches-last
        ==
      'in-sync'
    ?:  contents-match  'in-sync'
    ?:  ?&(?=(^ last-clay.binding) ?=(^ last-git.binding) clay-matches-last !git-matches-last)
      'git-ahead'
    ?:  ?&(?=(^ last-clay.binding) ?=(^ last-git.binding) !clay-matches-last git-matches-last)
      'clay-ahead'
    ?:  ?&(?=(^ last-clay.binding) ?=(^ last-git.binding))
      'diverged'
    'unmapped'
  %-  pairs:enjs:format
  :~  ['bound' b+%.y]
      ['repository' s+name]
      ['desk' s+desk-name.binding]
      ['branch' s+branch.binding]
      ['relation' s+relation]
      ['contentsMatch' b+contents-match]
      ['canonicalDifference' b+?&(=('in-sync' relation) !contents-match)]
      ['clayRevision' n+?~(current-revision '0' (decimal u.current-revision))]
      ['clayTimestamp' s+?~(current-meta '' (scot %da timestamp.u.current-meta))]
      ['clayTako' s+?~(current-meta '' (scot %uv tako.u.current-meta))]
      ['branchCommit' s+?~(branch-oid '' (oid-text:git-codec u.branch-oid))]
      ['mappedRevision' n+?~(last-clay.binding '0' (decimal u.last-clay.binding))]
      ['mappedCommit' s+?~(last-git.binding '' (oid-text:git-codec u.last-git.binding))]
      ['canApply' b+?&(?=(^ branch-files) ?=(^ clay-files) !=('in-sync' relation))]
      ['canPublish' b+?&(?=(^ clay-files) !=('in-sync' relation))]
  ==
::
++  update-binding-success
  |=  [repo=repository:git new-oid=oid:git clay-revision=(unit @ud) when=@da]
  ^-  repository:git
  ?~  binding.repo  repo
  =/  links=(list clay-link:git)
    ?~  clay-revision  history.u.binding.repo
    =/  link=clay-link:git  [u.clay-revision new-oid %git-to-clay when]
    =/  old-links=(list clay-link:git)  history.u.binding.repo
    [link old-links]
  =/  linked=desk-binding:git
    u.binding.repo(last-clay clay-revision, last-git `new-oid, history links)
  repo(binding `linked)
::
++  receive-results
  |=  [commands=(list receive-command:git) ok=? message=@t]
  ^-  (list [ok=? ref=@t message=@t])
  (turn commands |=(command=receive-command:git [ok ref.command message]))
::
++  tang-text
  |=  =tang
  ^-  @t
  =/  lines=(list tape)
    %-  zing
    %+  turn  tang
    |=  =tank
    (wash [0 120] tank)
  =/  join-lines
    |=  [remaining=(list tape) out=tape]
    ^-  tape
    ?~  remaining  out
    =/  next=tape
      ?~  out  i.remaining
      :(weld out " | " i.remaining)
    $(remaining t.remaining, out next)
  (crip (scag 60.000 (join-lines lines ~)))
::
++  receive-payload
  |=  [unpack=@t results=(list [ok=? ref=@t message=@t])]
  ^-  simple-payload:http
  :_  `(receive-status:git-protocol unpack results)
  :-  200
  :~  ['content-type' 'application/x-git-receive-pack-result']
      ['cache-control' 'no-store']
  ==
::
++  public-base
  |=  req=inbound-request:eyre
  ^-  @t
  =/  host=@t  (fall (get-header:http 'host' header-list.request.req) 'localhost')
  =/  forwarded=(unit @t)  (get-header:http 'x-forwarded-proto' header-list.request.req)
  =/  scheme=@t
    ?^  forwarded  u.forwarded
    ?:(?|((starts-with 'localhost' host) (starts-with '127.0.0.1' host)) 'http' 'https')
  (rap 3 ~[scheme '://' host])
::
++  object-key
  |=  [repository=@t oid=@t]
  ^-  @t
  (rap 3 ~['git-lfs/' (scot %p our.bowl) '/' repository '/' oid])
::
++  headers-json
  |=  headers=(list [@t @t])
  ^-  json
  (pairs:enjs:format (turn headers |=([key=@t value=@t] [key s+value])))
::
++  action-json
  |=  signed=signed-request:git-storage
  ^-  json
  %-  pairs:enjs:format
  :~  ['href' s+url.signed]
      ['header' (headers-json headers.signed)]
      ['expires_in' n+'600']
  ==
::
++  verify-action-json
  |=  [req=inbound-request:eyre repository=@t oid=@t]
  ^-  json
  =/  href=@t
    %+  rap  3
    :~  (public-base req)  '/git/'  repository
        '/info/lfs/objects/'  oid  '/verify'
    ==
  %-  pairs:enjs:format
  ~[['href' s+href] ['expires_in' n+'600']]
::
++  handle-http
  |=  [eyre-id=@ta req=inbound-request:eyre]
  ^-  (quip card _this)
  =/  line=request-line:server  (parse-request-line:server url.request.req)
  =/  site=(list @t)  site.line
  ?:  (starts-with '/apps/urgit/api' url.request.req)
    (handle-api eyre-id req line)
  ?:  ?=([%git @ %info %lfs %locks %verify ~] site)
    (handle-lfs-lock-verify eyre-id req (repository-name i.t.site))
  ?:  ?=([%git @ %info %lfs %locks @ %unlock ~] site)
    (handle-lfs-unlock eyre-id req (repository-name i.t.site) i.t.t.t.t.t.site)
  ?:  ?=([%git @ %info %lfs %locks ~] site)
    (handle-lfs-locks eyre-id req line (repository-name i.t.site))
  ?:  ?=([%git @ %info %lfs %objects %batch ~] site)
    (handle-lfs-batch eyre-id req (repository-name i.t.site))
  ?:  ?=([%git @ %info %lfs %objects @ %verify ~] site)
    (handle-lfs-verify eyre-id req (repository-name i.t.site) i.t.t.t.t.t.site)
  ?:  ?=([%git @ %info %refs ~] site)
    (handle-discovery eyre-id req line (repository-name i.t.site))
  ?:  ?=([%git @ %git-upload-pack ~] site)
    (handle-upload-pack eyre-id req (repository-name i.t.site))
  ?:  ?=([%git @ %git-receive-pack ~] site)
    (handle-receive-pack eyre-id req (repository-name i.t.site))
  :_  this
  (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'repository route not found\0a'))
::
++  handle-discovery
  |=  [eyre-id=@ta req=inbound-request:eyre line=request-line:server repo-name=@t]
  ^-  (quip card _this)
  ?.  =(%'GET' method.request.req)
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] `(text:git-codec 'method not allowed\0a'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'repository not found\0a'))
  =/  service=(unit @t)  (query-value 'service' args.line)
  ?~  service
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'missing service\0a'))
  ?.  ?|  =('git-upload-pack' u.service)
          =('git-receive-pack' u.service)
      ==
    :_  this
    (give-http eyre-id 403 ~[['content-type' 'text/plain']] `(text:git-codec 'service disabled\0a'))
  =/  authorized=?
    ?:  =('git-upload-pack' u.service)
      ?|(public-read.u.found authenticated.req (write-authorized u.found req))
    (write-authorized u.found req)
  ?.  authorized
    :_  this
    %-  give-http
    :*  eyre-id
        401
        ~[['content-type' 'text/plain'] ['www-authenticate' 'Basic realm="git"']]
        `(text:git-codec 'repository authentication required\0a')
    ==
  =/  protocol=(unit @t)
    (get-header:http 'git-protocol' header-list.request.req)
  =/  use-v2=?
    ?&  =('git-upload-pack' u.service)
        ?=(^ protocol)
        =('version=2' u.protocol)
    ==
  =/  body=octs
    ?:(use-v2 v2-capability-advertisement:git-protocol (smart-advertisement:git-protocol u.found u.service))
  =/  content-type=@t
    (rap 3 ~['application/x-' u.service '-advertisement'])
  =/  headers=(list [@t @t])
    :~  ['content-type' content-type]
        ['cache-control' 'no-cache, max-age=0, must-revalidate']
        ['pragma' 'no-cache']
    ==
  [(give-simple-payload:app:server eyre-id [[200 headers] `body]) this]
::
++  handle-upload-pack
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] `(text:git-codec 'method not allowed\0a'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'repository not found\0a'))
  ?.  ?|(public-read.u.found authenticated.req (write-authorized u.found req))
    :_  this
    (give-http eyre-id 403 ~[['content-type' 'text/plain']] `(text:git-codec 'repository is private\0a'))
  ?~  body.request.req
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'missing upload-pack request\0a'))
  =/  v2-command=(unit @tas)
    (v2-command:git-protocol u.body.request.req)
  ?:  ?&(?=(^ v2-command) =(%ls-refs u.v2-command))
    =/  response=octs
      (v2-ls-refs:git-protocol u.found u.body.request.req)
    =/  headers=(list [@t @t])
      :~  ['content-type' 'application/x-git-upload-pack-result']
          ['cache-control' 'no-store']
      ==
    :_  this
    (give-http eyre-id 200 headers `response)
  ?:  ?&(?=(^ v2-command) =(%object-info u.v2-command))
    =/  requested=(unit (list oid:git))
      (v2-object-info-oids:git-protocol u.body.request.req)
    ?~  requested
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'invalid protocol v2 object-info request\0a'))
    =/  advertised-roots=(set oid:git)
      %-  silt
      %+  turn  ~(tap by refs.u.found)
      |=  entry=[@t oid:git]
      +.entry
    =/  advertised=(unit (set oid:git))
      (reachable:git-graph objects.u.found advertised-roots)
    ?.  ?&  ?=(^ advertised)
            (levy u.requested |=(oid=oid:git (~(has in u.advertised) oid)))
        ==
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'object is not reachable from an advertised ref\0a'))
    =/  response=(unit octs)
      (v2-object-info:git-protocol objects.u.found u.requested)
    ?~  response
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'object not found\0a'))
    =/  headers=(list [@t @t])
      :~  ['content-type' 'application/x-git-upload-pack-result']
          ['cache-control' 'no-store']
      ==
    :_  this
    (give-http eyre-id 200 headers `u.response)
  ?:  ?&(?=(^ v2-command) !=(%fetch u.v2-command))
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'unsupported protocol v2 command\0a'))
  =/  use-v2=?  ?&(?=(^ v2-command) =(%fetch u.v2-command))
  =/  parsed=(unit upload-request:git)
    (parse-upload-request:git-protocol u.body.request.req)
  ?~  parsed
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'invalid upload-pack request\0a'))
  ?:  =(0 (lent ~(tap in wants.u.parsed)))
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'upload-pack request has no wants\0a'))
  ?.  (levy ~(tap in wants.u.parsed) |=(oid=oid:git (~(has by objects.u.found) oid)))
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'requested object not found\0a'))
  =/  wanted-full=(unit (set oid:git))
    (reachable:git-graph objects.u.found wants.u.parsed)
  ?~  wanted-full
    :_  this
    (give-http eyre-id 500 ~[['content-type' 'text/plain']] `(text:git-codec 'repository graph is incomplete\0a'))
  =/  advertised-roots=(set oid:git)
    %-  silt
    %+  turn  ~(tap by refs.u.found)
    |=  entry=[@t oid:git]
    +.entry
  =/  advertised-closure=(unit (set oid:git))
    (reachable:git-graph objects.u.found advertised-roots)
  ?~  advertised-closure
    :_  this
    (give-http eyre-id 500 ~[['content-type' 'text/plain']] `(text:git-codec 'advertised repository graph is incomplete\0a'))
  ?.  (levy ~(tap in wants.u.parsed) |=(oid=oid:git (~(has in u.advertised-closure) oid)))
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'requested object is not reachable from an advertised ref\0a'))
  =/  effective-shallow=(set oid:git)
    (~(int in shallow.u.parsed) u.wanted-full)
  =/  unshallow-all=?
    ?^  depth.u.parsed
      =(2.147.483.647 u.depth.u.parsed)
    %.n
  =/  depth-result=(unit shallow-result:git-graph)
    ?~  depth.u.parsed  ~
    ?:  unshallow-all
      `[u.wanted-full ~]
    ?:  ?=(~ effective-shallow)
      (reachable-depth:git-graph objects.u.found wants.u.parsed u.depth.u.parsed)
    ?.  deepen-relative.u.parsed
      =/  stopped=(unit (set oid:git))
        (reachable-stopping:git-graph objects.u.found wants.u.parsed effective-shallow)
      ?~(stopped ~ `[u.stopped effective-shallow])
    =/  stopped=(unit (set oid:git))
      (reachable-stopping:git-graph objects.u.found wants.u.parsed effective-shallow)
    ?~  stopped  ~
    =/  extension=(unit shallow-result:git-graph)
      (reachable-depth:git-graph objects.u.found effective-shallow +(u.depth.u.parsed))
    ?~  extension  ~
    `[(~(uni in u.stopped) reachable.u.extension) boundaries.u.extension]
  =/  wanted-closure=(unit (set oid:git))
    ?~(depth.u.parsed wanted-full ?~(depth-result ~ `reachable.u.depth-result))
  ?~  wanted-closure
    :_  this
    (give-http eyre-id 500 ~[['content-type' 'text/plain']] `(text:git-codec 'shallow repository graph is incomplete\0a'))
  =/  common=(set oid:git)
    (~(int in haves.u.parsed) u.advertised-closure)
  =/  common-closure=(unit (set oid:git))
    ?:  ?=(~ effective-shallow)
      (reachable:git-graph objects.u.found common)
    (reachable-stopping:git-graph objects.u.found common effective-shallow)
  ?~  common-closure
    :_  this
    (give-http eyre-id 500 ~[['content-type' 'text/plain']] `(text:git-codec 'common repository graph is incomplete\0a'))
  =/  transfer=(set oid:git)
    (~(dif in u.wanted-closure) u.common-closure)
  =/  filtered-transfer=(set oid:git)
    ?~  filter.u.parsed  transfer
    =/  traversed=(set oid:git)
      %-  silt
      %+  skim  ~(tap in transfer)
      |=  oid=oid:git
      =/  object=object:git  (need (~(get by objects.u.found) oid))
      ?-  u.filter.u.parsed
          %blob-none
        !=(%blob kind.object)
      ::
          [%blob-limit *]
        ?|  !=(%blob kind.object)
            (lte p.data.object limit.u.filter.u.parsed)
        ==
      ==
    ::  A promisor fetch repeats its filter while directly wanting an
    ::  omitted blob.  Direct wants must survive traversal filtering.
    (~(uni in traversed) (~(int in wants.u.parsed) transfer))
  =/  common-list=(list oid:git)  ~(tap in common)
  =/  shallow-packets=(list octs)
    ?~  depth.u.parsed  ~
    ?~  depth-result  ~
    =/  packets=(list octs)
      %+  turn  ~(tap in boundaries.u.depth-result)
      |=  oid=oid:git
      (en-pkt:git-codec [%data (text:git-codec (rap 3 ~['shallow ' (oid-text:git-codec oid) '\0a']))])
    =?  packets  ?&(|(deepen-relative.u.parsed unshallow-all) !=(~ effective-shallow))
      %+  weld  packets
      %+  turn  ~(tap in effective-shallow)
      |=  oid=oid:git
      (en-pkt:git-codec [%data (text:git-codec (rap 3 ~['unshallow ' (oid-text:git-codec oid) '\0a']))])
    packets
  =/  shallow-lines=octs  (join-all:git-codec shallow-packets)
  =/  shallow-status=octs
    ?~  shallow-packets  [0 0]
    (join-all:git-codec ~[shallow-lines (en-pkt:git-codec [%flush ~])])
  =/  status=octs
    ?~  common-list
      (en-pkt:git-codec [%data (text:git-codec 'NAK\0a')])
    =/  line=@t
      (rap 3 ~['ACK ' (oid-text:git-codec i.common-list) '\0a'])
    (en-pkt:git-codec [%data (text:git-codec line)])
  ::  Without multi_ack, a request ending in flush receives negotiation
  ::  status only.  The pack begins after the client sends done.
  ?.  done.u.parsed
    =/  headers=(list [@t @t])
      :~  ['content-type' 'application/x-git-upload-pack-result']
          ['cache-control' 'no-store']
      ==
    :_  this
    =/  negotiation=octs
      ?:  use-v2
        %-  join-all:git-codec
        :~  (en-pkt:git-codec [%data (text:git-codec 'acknowledgments\0a')])
            status
            (en-pkt:git-codec [%flush ~])
        ==
      ?~(depth.u.parsed status shallow-status)
    (give-http eyre-id 200 headers `negotiation)
  =/  objects=(list object:git)
    %+  turn  ~(tap in filtered-transfer)
    |=(oid=oid:git (need (~(get by objects.u.found) oid)))
  =/  pack=octs  (encode-pack:git-pack objects)
  =/  final-shallow=octs
    ?:  ?&  ?=(^ depth.u.parsed)
            ?|(unshallow-all deepen-relative.u.parsed ?=(~ shallow.u.parsed))
        ==
      shallow-status
    [0 0]
  =/  response=octs
    ?:  use-v2
      =/  shallow-section=octs
        ?:  =(0 p.final-shallow)  [0 0]
        %-  join-all:git-codec
        :~  (en-pkt:git-codec [%data (text:git-codec 'shallow-info\0a')])
            shallow-lines
            (en-pkt:git-codec [%delim ~])
        ==
      %-  join-all:git-codec
      :~  shallow-section
          (en-pkt:git-codec [%data (text:git-codec 'packfile\0a')])
          (v2-sideband-pack:git-protocol pack)
          (en-pkt:git-codec [%flush ~])
      ==
    (join-all:git-codec ~[final-shallow status pack])
  =/  headers=(list [@t @t])
    :~  ['content-type' 'application/x-git-upload-pack-result']
        ['cache-control' 'no-store']
    ==
  :_  this
  (give-http eyre-id 200 headers `response)
::
++  handle-receive-pack
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] `(text:git-codec 'method not allowed\0a'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-http eyre-id 404 ~[['content-type' 'text/plain']] `(text:git-codec 'repository not found\0a'))
  ?.  (write-authorized u.found req)
    :_  this
    %-  give-http
    :*  eyre-id
        401
        ~[['content-type' 'text/plain'] ['www-authenticate' 'Basic realm="git"']]
        `(text:git-codec 'repository authentication required\0a')
    ==
  ?~  body.request.req
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'missing receive-pack request\0a'))
  =/  parsed=(unit receive-request:git)
    (parse-receive-request:git-protocol u.body.request.req)
  ?~  parsed
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'invalid receive-pack request\0a'))
  =/  staged=(unit (map oid:git object:git))
    ?:  =(0 p.pack.u.parsed)
      `~
    =/  decoded=(unit decoded-pack:git-pack-decode)
      (decode-pack-with:git-pack-decode pack.u.parsed objects.u.found)
    ?~  decoded  ~
    `objects.u.decoded
  ?~  staged
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    (receive-payload 'invalid or unsupported pack' (receive-results commands.u.parsed %.n 'unpack failed'))
  =/  policy-error=(unit @t)
    (receive-policy-error u.found commands.u.parsed u.staged)
  ?^  policy-error
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    (receive-payload 'ok' (receive-results commands.u.parsed %.n u.policy-error))
  =/  applied=(unit repository:git)
    (apply-receive u.found commands.u.parsed u.staged)
  ?~  applied
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    (receive-payload 'ok' (receive-results commands.u.parsed %.n 'stale or invalid ref update'))
  ?^  binding.u.applied
    =/  linked-command=(unit receive-command:git)
      (command-for-ref commands.u.parsed branch.u.binding.u.applied)
    ?~  linked-command
      (accept-receive eyre-id repo-name commands.u.parsed u.applied ~)
    =/  maybe-pending=(unit clay-push)  pending-clay
    ?^  maybe-pending
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.n 'linked desk update already in progress'))
    ?^  pending-publish
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.n 'linked desk publish already in progress'))
    ?~  new.u.linked-command
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.n 'cannot delete a branch linked to a Clay desk'))
    =/  files=(unit (map path octs))
      (flatten-commit:git-clay objects.u.applied u.new.u.linked-command)
    ?~  files
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.n 'linked branch must resolve to a valid desk-shaped Git commit'))
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.u.applied u.files)
    ?~  delta
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.n 'unable to read linked Clay desk'))
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =/  clay=[desk-name=desk commit=oid:git]
        [desk-name.u.binding.u.applied u.new.u.linked-command]
      (accept-receive eyre-id repo-name commands.u.parsed u.applied `clay)
    =/  pending=clay-push
      =/  start-at=@da  (add now.bowl ~s1)
      =/  timeout-at=@da  (add now.bowl ~s15)
      :*  eyre-id
          %.n
          ~
          repo-name
          commands.u.parsed
          u.applied
          desk-name.u.binding.u.applied
          branch.u.binding.u.applied
          u.new.u.linked-command
          u.delta
          ~
          start-at
          timeout-at
      ==
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-start %arvo %b %wait start-at.pending]
        [%pass /clay-timeout %arvo %b %wait timeout-at.pending]
    ==
  (accept-receive eyre-id repo-name commands.u.parsed u.applied ~)
::
++  handle-lfs-locks
  |=  [eyre-id=@ta req=inbound-request:eyre line=request-line:server repo-name=@t]
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'repository not found'))
  ?:  =(%'GET' method.request.req)
    ?.  ?|(public-read.u.found authenticated.req (write-authorized u.found req))
      :_  this
      (give-simple-payload:app:server eyre-id (lfs-error 403 'pull access is required to list locks'))
    =/  path-filter=(unit @t)  (query-value 'path' args.line)
    =/  id-text=(unit @t)  (query-value 'id' args.line)
    =/  id-filter=(unit @ud)  ?~(id-text ~ (slaw %ud u.id-text))
    ?:  ?&(?=(^ id-text) ?=(~ id-filter))
      :_  this
      (give-simple-payload:app:server eyre-id (lfs-error 422 'lock id is invalid'))
    =/  cursor-text=(unit @t)  (query-value 'cursor' args.line)
    =/  cursor-filter=(unit @ud)  ?~(cursor-text `0 (slaw %ud u.cursor-text))
    ?~  cursor-filter
      :_  this
      (give-simple-payload:app:server eyre-id (lfs-error 422 'lock cursor is invalid'))
    =/  limit-text=(unit @t)  (query-value 'limit' args.line)
    =/  requested-limit=(unit @ud)  ?~(limit-text `100 (slaw %ud u.limit-text))
    ?~  requested-limit
      :_  this
      (give-simple-payload:app:server eyre-id (lfs-error 422 'lock limit is invalid'))
    =/  limit=@ud  (min 100 (max 1 u.requested-limit))
    =/  entries=(list [@ud lfs-lock:git])  ~(tap by lfs-locks.u.found)
    =.  entries
      %+  sort  entries
      |=  [a=[@ud lfs-lock:git] b=[@ud lfs-lock:git]]
      (lth -.a -.b)
    =.  entries
      %+  skim  entries
      |=  entry=[@ud lfs-lock:git]
      ?&  (gth -.entry u.cursor-filter)
          ?~(path-filter %.y =(path.+.entry u.path-filter))
          ?~(id-filter %.y =(-.entry u.id-filter))
      ==
    =/  more=?  (gth (lent entries) limit)
    =/  shown=(list [@ud lfs-lock:git])  (scag limit entries)
    =/  fields=(list [@t json])
      ~[['locks' [%a (turn shown |=(entry=[@ud lfs-lock:git] (lfs-lock-json +.entry)))]]]
    =.  fields
      ?.  more  fields
      =/  last=[@ud lfs-lock:git]  (snag (dec limit) shown)
      =/  next=json  s+(decimal -.last)
      (weld fields ~[['next_cursor' next]])
    :_  this
    (give-simple-payload:app:server eyre-id (json-payload 200 (pairs:enjs:format fields)))
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 405 'method not allowed'))
  ?.  (write-authorized u.found req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'push access is required to create a lock'))
  =/  principal=(unit @t)  (lfs-principal req)
  ?~  principal
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'lock owner could not be determined'))
  ?~  body.request.req
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'missing lock request'))
  =/  jon=(unit json)  (de:json:html q.u.body.request.req)
  ?~  jon
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'invalid JSON'))
  =/  lock-path=(unit @t)  (string-at 'path' u.jon)
  ?.  ?&  ?=(^ lock-path)
          !=('' u.lock-path)
          (lte (met 3 u.lock-path) 2.048)
          !=('/' (cut 3 [0 1] u.lock-path))
      ==
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'lock path must be a relative repository path'))
  =/  conflicts=(list [@ud lfs-lock:git])
    (skim ~(tap by lfs-locks.u.found) |=(entry=[@ud lfs-lock:git] =(path.+.entry u.lock-path)))
  ?^  conflicts
    =/  response=json
      %-  pairs:enjs:format
      :~  ['lock' (lfs-lock-json +.i.conflicts)]
          ['message' s+'path is already locked']
      ==
    :_  this
    (give-simple-payload:app:server eyre-id (json-payload 409 response))
  =/  entries=(list [@ud lfs-lock:git])  ~(tap by lfs-locks.u.found)
  =/  next-id=@ud  1
  =.  next-id
    |-
    ?~  entries  next-id
    $(entries t.entries, next-id (max next-id (add 1 -.i.entries)))
  =/  lock=lfs-lock:git  [next-id u.lock-path u.principal now.bowl]
  =/  updated=repository:git
    u.found(lfs-locks (~(put by lfs-locks.u.found) next-id lock))
  =.  repositories  (~(put by repositories) repo-name updated)
  :_  this
  (give-simple-payload:app:server eyre-id (json-payload 201 (pairs:enjs:format ~[['lock' (lfs-lock-json lock)]])))
::
++  handle-lfs-lock-verify
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 405 'method not allowed'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'repository not found'))
  ?.  (write-authorized u.found req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'push access is required to verify locks'))
  =/  principal=(unit @t)  (lfs-principal req)
  ?~  principal
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'lock owner could not be determined'))
  =/  jon=json
    ?~  body.request.req  [%o ~]
    =/  parsed=(unit json)  (de:json:html q.u.body.request.req)
    ?~(parsed [%o ~] u.parsed)
  =/  cursor-text=(unit @t)  (string-at 'cursor' jon)
  =/  cursor=(unit @ud)  ?~(cursor-text `0 (slaw %ud u.cursor-text))
  ?~  cursor
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'lock cursor is invalid'))
  =/  requested-limit=(unit @ud)  (nat-at 'limit' jon)
  =/  limit=@ud  (min 100 (max 1 ?~(requested-limit 100 u.requested-limit)))
  =/  entries=(list [@ud lfs-lock:git])  ~(tap by lfs-locks.u.found)
  =.  entries
    %+  sort  entries
    |=  [a=[@ud lfs-lock:git] b=[@ud lfs-lock:git]]
    (lth -.a -.b)
  =.  entries  (skim entries |=(entry=[@ud lfs-lock:git] (gth -.entry u.cursor)))
  =/  more=?  (gth (lent entries) limit)
  =/  shown=(list [@ud lfs-lock:git])  (scag limit entries)
  =/  ours=(list json)
    %+  turn
      (skim shown |=(entry=[@ud lfs-lock:git] =(owner.+.entry u.principal)))
    |=(entry=[@ud lfs-lock:git] (lfs-lock-json +.entry))
  =/  theirs=(list json)
    %+  turn
      (skim shown |=(entry=[@ud lfs-lock:git] !=(owner.+.entry u.principal)))
    |=(entry=[@ud lfs-lock:git] (lfs-lock-json +.entry))
  =/  fields=(list [@t json])  ~[['ours' [%a ours]] ['theirs' [%a theirs]]]
  =.  fields
    ?.  more  fields
    =/  last=[@ud lfs-lock:git]  (snag (dec limit) shown)
    =/  next=json  s+(decimal -.last)
    (weld fields ~[['next_cursor' next]])
  :_  this
  (give-simple-payload:app:server eyre-id (json-payload 200 (pairs:enjs:format fields)))
::
++  handle-lfs-unlock
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t id-text=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 405 'method not allowed'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'repository not found'))
  ?.  (write-authorized u.found req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'push access is required to delete a lock'))
  =/  principal=(unit @t)  (lfs-principal req)
  ?~  principal
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'lock owner could not be determined'))
  =/  lock-id=(unit @ud)  (slaw %ud id-text)
  ?~  lock-id
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'lock id is invalid'))
  =/  lock=(unit lfs-lock:git)  (~(get by lfs-locks.u.found) u.lock-id)
  ?~  lock
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'lock not found'))
  =/  force=?
    ?~  body.request.req  %.n
    =/  parsed=(unit json)  (de:json:html q.u.body.request.req)
    ?~  parsed  %.n
    (fall (bool-at 'force' u.parsed) %.n)
  ?.  |(force =(owner.u.lock u.principal))
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 403 'only the lock owner may unlock without force'))
  =/  updated=repository:git
    u.found(lfs-locks (~(del by lfs-locks.u.found) u.lock-id))
  =.  repositories  (~(put by repositories) repo-name updated)
  :_  this
  (give-simple-payload:app:server eyre-id (json-payload 200 (pairs:enjs:format ~[['lock' (lfs-lock-json u.lock)]])))
::
++  handle-lfs-batch
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 405 'method not allowed'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'repository not found'))
  ?~  body.request.req
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'missing batch request'))
  =/  jon=(unit json)  (de:json:html q.u.body.request.req)
  ?~  jon
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'invalid JSON'))
  =/  operation=(unit @t)  (string-at 'operation' u.jon)
  ?.  ?&(?=(^ operation) ?|(=(u.operation 'upload') =(u.operation 'download')))
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'operation must be upload or download'))
  =/  hash-algorithm=(unit @t)  (string-at 'hash_algo' u.jon)
  ?:  ?&(?=(^ hash-algorithm) !=(u.hash-algorithm 'sha256'))
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 409 'only sha256 object identifiers are supported'))
  =/  specs=(unit (list lfs-spec))  (parse-lfs-specs u.jon)
  ?~  specs
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'invalid object list'))
  ?:  (gth (lent u.specs) 1.000)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 413 'batch exceeds 1000 objects'))
  =/  allowed=?
    ?:  =(u.operation 'upload')
      (write-authorized u.found req)
    ?|(public-read.u.found authenticated.req (write-authorized u.found req))
  ?.  allowed
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 401 'repository authentication required'))
  =/  settings=(unit [credentials=credentials:git-storage configuration=configuration:git-storage])
    storage-settings
  ?~  settings
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 503 'ship object storage is not configured'))
  =/  working=repository:git  u.found
  =/  objects=(list json)  ~
  =/  remaining=(list lfs-spec)  u.specs
  |-
  ?~  remaining
    =.  repositories  (~(put by repositories) repo-name working)
    =/  response=json
      %-  pairs:enjs:format
      :~  ['transfer' s+'basic']
          ['objects' a+(flop objects)]
          ['hash_algo' s+'sha256']
      ==
    :_  this
    (give-simple-payload:app:server eyre-id (json-payload 200 response))
  =/  spec=lfs-spec  i.remaining
  =/  existing=(unit lfs-object:git)  (~(get by lfs-objects.working) oid.spec)
  ?:  =(u.operation 'download')
    ?~  existing
      =/  item=json
        %-  pairs:enjs:format
        :~  ['oid' s+oid.spec]
            ['size' n+(decimal size.spec)]
            ['error' (pairs:enjs:format ~[['code' n+'404'] ['message' s+'object does not exist']])]
        ==
      $(remaining t.remaining, objects [item objects])
    ?:  !=(size.spec size.u.existing)
      =/  item=json
        %-  pairs:enjs:format
        :~  ['oid' s+oid.spec]
            ['size' n+(decimal size.spec)]
            ['error' (pairs:enjs:format ~[['code' n+'422'] ['message' s+'object size does not match']])]
        ==
      $(remaining t.remaining, objects [item objects])
    =/  signed=signed-request:git-storage
      (sign:git-storage 'GET' 'application/octet-stream' [0 0] credentials.u.settings configuration.u.settings object-key.u.existing now.bowl)
    =/  actions=json
      (pairs:enjs:format ~[['download' (action-json signed)]])
    =/  item=json
      %-  pairs:enjs:format
      :~  ['oid' s+oid.spec]
          ['size' n+(decimal size.spec)]
          ['authenticated' b+%.y]
          ['actions' actions]
      ==
    $(remaining t.remaining, objects [item objects])
  ?:  ?=(^ existing)
    ?:  =(size.spec size.u.existing)
      =/  item=json
        (pairs:enjs:format ~[['oid' s+oid.spec] ['size' n+(decimal size.spec)] ['authenticated' b+%.y]])
      $(remaining t.remaining, objects [item objects])
    =/  item=json
      %-  pairs:enjs:format
      :~  ['oid' s+oid.spec]
          ['size' n+(decimal size.spec)]
          ['error' (pairs:enjs:format ~[['code' n+'422'] ['message' s+'object size does not match']])]
      ==
    $(remaining t.remaining, objects [item objects])
  =/  key=@t  (object-key repo-name oid.spec)
  =/  signed=signed-request:git-storage
    (sign-hash:git-storage 'PUT' 'application/octet-stream' oid.spec credentials.u.settings configuration.u.settings key now.bowl)
  =/  upload=lfs-upload:git  [size.spec key (add now.bowl ~m15)]
  =.  working  working(lfs-uploads (~(put by lfs-uploads.working) oid.spec upload))
  =/  actions=json
    %-  pairs:enjs:format
    :~  ['upload' (action-json signed)]
        ['verify' (verify-action-json req repo-name oid.spec)]
    ==
  =/  item=json
    %-  pairs:enjs:format
    :~  ['oid' s+oid.spec]
        ['size' n+(decimal size.spec)]
        ['authenticated' b+%.y]
        ['actions' actions]
    ==
  $(remaining t.remaining, objects [item objects])
::
++  handle-lfs-verify
  |=  [eyre-id=@ta req=inbound-request:eyre repo-name=@t oid=@t]
  ^-  (quip card _this)
  ?.  =(%'POST' method.request.req)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 405 'method not allowed'))
  =/  found=(unit repository:git)  (~(get by repositories) repo-name)
  ?~  found
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'repository not found'))
  =/  pending=(unit lfs-upload:git)  (~(get by lfs-uploads.u.found) oid)
  ?~  pending
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 404 'upload is not pending'))
  ?:  (gth now.bowl expires.u.pending)
    =/  repo=repository:git  u.found(lfs-uploads (~(del by lfs-uploads.u.found) oid))
    =.  repositories  (~(put by repositories) repo-name repo)
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 410 'upload verification expired'))
  ?~  body.request.req
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'missing verification body'))
  =/  jon=(unit json)  (de:json:html q.u.body.request.req)
  ?~  jon
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 400 'invalid JSON'))
  =/  body-oid=(unit @t)  (string-at 'oid' u.jon)
  =/  body-size=(unit @ud)  (nat-at 'size' u.jon)
  ?.  ?&  ?=(^ body-oid)
          ?=(^ body-size)
          =(u.body-oid oid)
          =(u.body-size size.u.pending)
      ==
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 422 'verification does not match pending upload'))
  =/  settings=(unit [credentials=credentials:git-storage configuration=configuration:git-storage])
    storage-settings
  ?~  settings
    :_  this
    (give-simple-payload:app:server eyre-id (lfs-error 503 'ship object storage is not configured'))
  =/  signed=signed-request:git-storage
    (sign:git-storage 'HEAD' 'application/octet-stream' [0 0] credentials.u.settings configuration.u.settings object-key.u.pending now.bowl)
  =/  request-id=@uv
    `@uv`(shas %git-lfs-request (cat 3 eny.bowl request-count))
  =.  request-count  +(request-count)
  =.  in-flight  (~(put by in-flight) request-id [eyre-id repo-name oid u.pending])
  :_  this
  :~  [%pass /iris/(scot %uv request-id) %arvo %i %request [%'HEAD' url.signed headers.signed ~] *outbound-config:iris]
  ==
::
++  give-http
  |=  [eyre-id=@ta status=@ud headers=(list [@t @t]) body=(unit octs)]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  [[status headers] body]
--
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
      [%x %dbug %state ~]
    =/  transfers=(list peer-transfer-debug)
      %+  turn  ~(tap by peer-receiving)
      |=  entry=[@uv peer-receive]
      =/  transfer=@uv  -.entry
      =/  flight=peer-receive  +.entry
      :*  transfer
          purpose.flight
          source.flight
          source-repository.flight
          local-repository.flight
          ?:(=('' head.flight) ?:(accepted.flight %prepare %request) %fine)
          expected.flight
          received.flight
          pages.flight
          %+  sort  ~(tap in completed.flight)
          |=  [a=@ud b=@ud]  (lth a b)
          %+  turn  ~(tap by fine-progress.flight)
          |=  progress=[@ud [fag=@ud tot=@ud]]
          [revision=-.progress fag=fag.+.progress tot=tot.+.progress]
          progress-at.flight
      ==
    =/  serving=(list peer-serve-debug)
      %+  turn  ~(tap by peer-serving)
      |=  entry=[@uv peer-serve]
      =/  flight=peer-serve  +.entry
      [transfer=-.entry target=target.flight repository=repository.flight pages=pages.flight objects=(lent objects.flight)]
    ``noun+!>([transfers=transfers serving=serving results=~(tap by peer-results)])
  ::
      [%x %repositories ~]
    =/  visible=(map @t repository:git)
      %-  malt
      %+  murn  ~(tap by repositories)
      |=  entry=[@t repository:git]
      ?.  public-read.+.entry  ~
      `entry
    ``json+!>((repositories-json visible))
  ::
      [%x %repository @ ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ?.  public-read.u.found  [~ ~]
    ``json+!>((repository-json name u.found))
  ::
      [%x %repository @ %files ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ?.  public-read.u.found  [~ ~]
    ``json+!>((repository-files-json name u.found))
  ::
      [%x %repository @ %commits ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ?.  public-read.u.found  [~ ~]
    ``json+!>((repository-history-json name u.found head.u.found our.bowl now.bowl 0 50))
  ::
      [%x %repository @ %browse ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ?.  public-read.u.found  [~ ~]
    ``json+!>((repository-browse-json name u.found))
  ::
      [%x %fine @ ~]
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.path)
    ?~  transfer  [~ ~]
    =/  found=(unit peer-serve)  (~(get by peer-serving) u.transfer)
    ?~  found  [~ ~]
    =/  objects=(map oid:git object:git)  (silt objects.u.found)
    ``noun+!>(objects)
  ==
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
      [%http-response @ ~]  [~ this]
  ==
++  on-leave  on-leave:def
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?.  =(/clay-push wire)
    (on-agent:def wire sign)
  =/  maybe-pending=(unit clay-push)  pending-clay
  ?~  maybe-pending  `this
  =/  pending=clay-push  u.maybe-pending
  ?.  ?=(%poke-ack -.sign)
    (on-agent:def wire sign)
  =/  report-at=@da  (add now.bowl ~s1)
  ?~  p.sign
    =.  pending  pending(result `[%.y ''])
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-timeout %arvo %b %rest timeout-at.pending]
        [%pass /clay-report %arvo %b %wait report-at]
    ==
  =/  detail=@t  (tang-text u.p.sign)
  =/  message=@t
    ?:  =('' detail)
      'Clay rejected the linked desk update'
    (rap 3 ~['Clay rejected the linked desk update: ' detail])
  =.  pending  pending(result `[%.n message])
  =.  pending-clay  `pending
  :_  this
  :~  [%pass /clay-timeout %arvo %b %rest timeout-at.pending]
      [%pass /clay-report %arvo %b %wait report-at]
  ==
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  =/  error-cards
    |=  [eyre-id=@ta status=@ud message=@t]
    ^-  (list card)
    =/  jon=json  (pairs:enjs:format ~[['message' s+message]])
    %+  give-simple-payload:app:server  eyre-id
    [[status ~[['content-type' 'application/vnd.git-lfs+json'] ['cache-control' 'no-store']]] `(json-to-octs:server jon)]
  ?+  wire  (on-arvo:def wire sign-arvo)
      [%eyre *]  `this
      [%peer %fine @ @ ~]
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  revision=(unit @ud)  (slaw %ud i.t.t.t.wire)
    ?~  revision  `this
    =/  found=(unit peer-receive)
      (~(get by peer-receiving) u.transfer)
    ?~  found  `this
    =/  fail
      |=  message=@t
      ^-  packet:git-peer
      [%snapshot-error u.transfer message]
    ?:  (~(has in completed.u.found) u.revision)  `this
    =/  packet=packet:git-peer
      ?.  ?&((gth u.revision 0) (lte u.revision pages.u.found))
        (fail 'Fine repository response used an invalid page revision')
      ?.  ?=([%ames %sage *] sign-arvo)
        (fail 'Fine repository read failed')
      =/  =sage:mess:ames  sage.sign-arvo
      ?.  =(ship.p.sage source.u.found)
        (fail 'Fine response came from the wrong ship')
      ?~  q.sage
        (fail 'Fine repository snapshot is unavailable')
      ?.  =(%noun p.q.sage)
        (fail 'Fine repository snapshot has the wrong mark')
      =/  packed=(unit octs)
        %-  mole
        |.(;;(octs +.q.q.sage))
      ?~  packed
        (fail 'Fine repository pack page has the wrong shape')
      =/  decoded=(unit decoded-pack:git-pack-decode)
        (decode-pack:git-pack-decode u.packed)
      ?~  decoded
        (fail 'Fine repository pack page failed checksum or object decoding')
      [%snapshot u.transfer objects.u.decoded]
    =/  snapshot-card=card
      [%pass /peer/snapshot/(scot %uv u.transfer) %agent [our.bowl %urgit] %poke %git-peer !>(packet)]
    ?.  ?=([%snapshot *] packet)
      :_  this
      :~  snapshot-card
      ==
    =.  peer-receiving
      (~(put by peer-receiving) u.transfer u.found(completed (~(put in completed.u.found) u.revision)))
    :_  this
    =/  next-revision=@ud  +(u.revision)
    ?:  (gth next-revision pages.u.found)  [snapshot-card ~]
    =/  next-path=path
      /g/x/(scot %ud next-revision)/urgit//1/fine/(peer-fine-name u.transfer)
    :~  snapshot-card
        [%pass /peer/fine/(scot %uv u.transfer)/(scot %ud next-revision) %keen %.n source.u.found next-path]
    ==
  ::
      [%peer %rate @ @ ~]
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  revision=(unit @ud)  (slaw %ud i.t.t.t.wire)
    ?~  revision  `this
    =/  found=(unit peer-receive)  (~(get by peer-receiving) u.transfer)
    ?~  found  `this
    ?.  ?=([%ames %rate *] sign-arvo)  `this
    =/  [tag=@tas =spar:ames =rate:ames]
      ;;([@tas spar:ames rate:ames] +.sign-arvo)
    ?@  rate  `this
    ?.  =(ship.spar source.u.found)  `this
    =/  previous=(unit [fag=@ud tot=@ud])
      (~(get by fine-progress.u.found) u.revision)
    ?.  ?~(previous %.y (gth fag.rate fag.u.previous))  `this
    =/  next=peer-receive
      u.found(progress-at now.bowl, fine-progress (~(put by fine-progress.u.found) u.revision [fag.rate tot.rate]))
    =.  peer-receiving  (~(put by peer-receiving) u.transfer next)
    `this
  ::
      [%peer %browse @ @ ~]
    =/  request=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  request  `this
    =/  revision=(unit @ud)  (slaw %ud i.t.t.t.wire)
    ?~  revision  `this
    =/  found=(unit peer-browse)  (~(get by peer-browses) u.request)
    ?~  found  `this
    ?.  ?&(active.u.found =(%fine phase.u.found))  `this
    =/  release-card=card
      [%pass /peer/browse-release/(scot %uv u.request) %agent [peer.u.found %urgit] %poke %git-peer !>([%browse-release u.request])]
    =/  fail
      |=  message=@t
      ^-  (quip card _this)
      =.  peer-browses
        (~(put by peer-browses) u.request u.found(active %.n, ok %.n, message message))
      :_  this
      :~  release-card
      ==
    ?.  ?&((gth u.revision 0) (lte u.revision expected.u.found))
      (fail 'peer overview Fine response used an invalid page revision')
    ?:  (~(has by parts.u.found) u.revision)  `this
    =/  page=(unit [length=@ud data=@])
      ?.  ?=([%ames %sage *] sign-arvo)  ~
      =/  =sage:mess:ames  sage.sign-arvo
      ?.  =(ship.p.sage peer.u.found)  ~
      ?~  q.sage  ~
      ?.  =(%noun p.q.sage)  ~
      %-  mole
      |.(;;([@ud @] +.q.q.sage))
    ?~  page
      (fail 'peer overview Fine page was unavailable or malformed')
    ?.  ?&  (gth length.u.page 0)
            (lte length.u.page 65.536)
            (lte (met 3 data.u.page) length.u.page)
        ==
      (fail 'peer overview Fine page had an invalid size')
    =/  next-parts=(map @ud [length=@ud data=@])
      (~(put by parts.u.found) u.revision u.page)
    =/  next-received=@ud  +(received.u.found)
    =/  next=peer-browse
      u.found(parts next-parts, received next-received, progress [~ [16 next-received expected.u.found]], progress-at now.bowl, message (rap 3 ~['received ' (decimal next-received) ' of ' (decimal expected.u.found) ' Fine pages']))
    =.  peer-browses  (~(put by peer-browses) u.request next)
    ?.  =(next-received expected.next)  `this
    =/  encoded=(unit @)  (peer-browse-join parts.next expected.next)
    ?~  encoded
      (fail 'peer overview Fine pages were incomplete')
    =/  result=(unit json)
      %-  mole
      |.(;;(json (cue u.encoded)))
    ?~  result
      (fail 'peer overview Fine pages did not decode as JSON')
    =/  expected-repository=@t  repository.u.found
    =/  valid=?
      ?.  ?=([%o *] u.result)  %.n
      =/  repository-json=(unit json)  (~(get by p.u.result) 'repository')
      ?~  repository-json  %.n
      ?.  ?=([%o *] u.repository-json)  %.n
      =/  name-json=(unit json)  (~(get by p.u.repository-json) 'name')
      ?~  name-json  %.n
      ?&(?=([%s *] u.name-json) =(p.u.name-json expected-repository))
    ?.  valid
      (fail 'peer browse result has the wrong repository identity')
    =.  peer-browses
      (~(put by peer-browses) u.request next(active %.n, ok %.y, message 'complete', result `u.result))
    :_  this
    :~  release-card
    ==
  ::
      [%peer %browse-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  request=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  request  `this
    =/  found=(unit peer-browse)  (~(get by peer-browses) u.request)
    ?~  found  `this
    ?.  active.u.found  `this
    ?:  =(%fine phase.u.found)  `this
    =.  peer-browses
      (~(put by peer-browses) u.request u.found(active %.n, ok %.n, message 'peer did not answer the repository browse request'))
    `this
  ::
      [%peer %browse-stall @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  request=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  request  `this
    =/  found=(unit peer-browse)  (~(get by peer-browses) u.request)
    ?~  found  `this
    ?.  ?&  active.u.found
            =(%fine phase.u.found)
        ==
      `this
    ?~  progress.u.found
      :_  this
      :~  [%pass /peer/browse-stall/(scot %uv u.request) %arvo %b %wait (add now.bowl ~s30)]
      ==
    ?.  (gte (sub now.bowl progress-at.u.found) ~m2)
      :_  this
      :~  [%pass /peer/browse-stall/(scot %uv u.request) %arvo %b %wait (add now.bowl ~s30)]
      ==
    =.  peer-browses
      (~(put by peer-browses) u.request u.found(active %.n, ok %.n, message 'Fine transfer stalled without page progress'))
    :_  this
    =/  cancel-cards=(list card)
      (peer-browse-yawns u.request peer.u.found expected.u.found)
    =/  release-cards=(list card)
      :~  [%pass /peer/browse-release/(scot %uv u.request) %agent [peer.u.found %urgit] %poke %git-peer !>([%browse-release u.request])]
      ==
    (weld cancel-cards release-cards)
  ::
      [%peer %stall @ @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  checkpoint=(unit @ud)  (slaw %ud i.t.t.t.wire)
    ?~  checkpoint  `this
    =/  found=(unit peer-receive)  (~(get by peer-receiving) u.transfer)
    ?~  found  `this
    ?.  =(u.checkpoint received.u.found)  `this
    ?.  (gte (sub now.bowl progress-at.u.found) ~m2)
      :_  this
      :~  [%pass /peer/stall/(scot %uv u.transfer)/(scot %ud received.u.found) %arvo %b %wait (add now.bowl ~s30)]
      ==
    =/  packet=packet:git-peer
      [%snapshot-error u.transfer 'Fine repository read stalled without fragment progress']
    :_  this
    :~  [%pass /peer/stall-result/(scot %uv u.transfer) %agent [our.bowl %urgit] %poke %git-peer !>(packet)]
    ==
  ::
      [%peer %request-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  found=(unit peer-receive)  (~(get by peer-receiving) u.transfer)
    ?~  found  `this
    ?:  accepted.u.found  `this
    ?.  =('' head.u.found)  `this
    =/  packet=packet:git-peer
      [%snapshot-error u.transfer 'peer did not answer the repository transfer request']
    :_  this
    :~  [%pass /peer/request-timeout-result/(scot %uv u.transfer) %agent [our.bowl %urgit] %poke %git-peer !>(packet)]
    ==
  ::
      [%peer %prepare-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  found=(unit peer-receive)  (~(get by peer-receiving) u.transfer)
    ?~  found  `this
    ?.  ?&(accepted.u.found =('' head.u.found))  `this
    =/  packet=packet:git-peer
      [%snapshot-error u.transfer 'peer did not finish preparing the repository snapshot']
    :_  this
    :~  [%pass /peer/prepare-timeout-result/(scot %uv u.transfer) %agent [our.bowl %urgit] %poke %git-peer !>(packet)]
    ==
  ::
      [%peer %serve-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  found=(unit peer-serve)  (~(get by peer-serving) u.transfer)
    ?~  found  `this
    =.  peer-activities
      %+  turn  peer-activities
      |=  event=peer-activity
      ?:  !=(u.transfer id.event)  event
      event(status %failure, message 'repository snapshot expired before release', when now.bowl)
    =/  count=@ud  pages.u.found
    =/  culls=(list card)
      ?:  =(0 count)  ~
      %+  turn  (gulf 1 count)
      |=  revision=@ud
      [%pass /peer/cull/(scot %uv u.transfer)/(scot %ud revision) %cull [%ud revision] /fine/(peer-fine-name u.transfer)]
    :_  this(peer-serving (~(del by peer-serving) u.transfer))
    culls
  ::
      [%peer %forge-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  request=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  request  `this
    =/  found=(unit peer-forge)  (~(get by peer-forges) u.request)
    ?~  found  `this
    ?.  active.u.found  `this
    =.  peer-forges
      (~(put by peer-forges) u.request u.found(active %.n, ok %.n, message 'peer did not answer the forge request'))
    `this
  ::
      [%peer %discovery-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  request=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  request  `this
    =/  found=(unit peer-discovery)  (~(get by peer-discoveries) u.request)
    ?~  found  `this
    ?.  active.u.found  `this
    =.  peer-discoveries
      (~(put by peer-discoveries) u.request u.found(active %.n, ok %.n, message 'peer discovery timed out'))
    `this
  ::
      [%clay-publish ~]
    =/  maybe-job=(unit publish-job)  pending-publish
    ?~  maybe-job  `this
    =/  job=publish-job  u.maybe-job
    ?.  ?=([%clay %writ *] sign-arvo)
      `this(pending-publish ~)
    =/  riot=riot:clay  p.sign-arvo
    ?~  riot  `this(pending-publish ~)
    ?~  paths.job  `this(pending-publish ~)
    ?.  =(q.u.riot i.paths.job)
      `this(pending-publish ~)
    =/  raw-cage=cage  r.u.riot
    =/  raw-page=page  [p.raw-cage q.q.raw-cage]
    =/  data=(unit octs)
      (page-octs our.bowl desk-name.job now.bowl raw-page)
    ?~  data  `this(pending-publish ~)
    =/  next-job=publish-job
      =/  clay-revision=(unit @ud)
        ?:  ?=([%ud @] q.p.u.riot)
          `p.q.p.u.riot
        clay-revision.job
      :*  repository.job
          desk-name.job
          branch.job
          clay-revision
          message.job
          `(list path)`t.paths.job
          (~(put by files.job) i.paths.job u.data)
      ==
    =.  pending-publish  `next-job
    ?^  paths.next-job
      :_  this
      :~  [%pass /clay-publish %arvo %c %warp our.bowl desk-name.next-job ~ %sing %q da+now.bowl i.paths.next-job]
      ==
    =/  current=(unit repository:git)  (~(get by repositories) repository.next-job)
    ?~  current  `this(pending-publish ~)
    =/  published=(unit repository:git)
      (publish-repository u.current next-job our.bowl now.bowl)
    ?~  published  `this(pending-publish ~)
    =.  repositories  (~(put by repositories) repository.next-job u.published)
    `this(pending-publish ~)
  ::
      [%clay-start ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  maybe-pending=(unit clay-push)  pending-clay
    ?~  maybe-pending  `this
    =/  pending=clay-push  u.maybe-pending
    ?^  error.sign-arvo
      =/  detail=@t  (tang-text u.error.sign-arvo)
      =/  message=@t
        ?:  =('' detail)
          'Clay rejected the linked desk update'
        (rap 3 ~['Clay rejected the linked desk update: ' detail])
      =/  report-at=@da  (add now.bowl ~s1)
      =.  pending  pending(result `[%.n message])
      =.  pending-clay  `pending
      :_  this
      :~  [%pass /clay-timeout %arvo %b %rest timeout-at.pending]
          [%pass /clay-report %arvo %b %wait report-at]
      ==
    :_  this
    :~  [%pass /clay-push %agent [our.bowl %urgit-clay] %poke %git-clay-action !>([desk-name.pending delta.pending])]
    ==
  ::
      [%clay-timeout ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  maybe-pending=(unit clay-push)  pending-clay
    ?~  maybe-pending  `this
    =/  pending=clay-push  u.maybe-pending
    ?^  error.sign-arvo
      `this(pending-clay ~)
    =/  report-at=@da  (add now.bowl ~s1)
    =.  pending  pending(result `[%.n 'Clay update timed out without a result'])
    =.  pending-clay  `pending
    :_  this
    :~  [%pass /clay-report %arvo %b %wait report-at]
    ==
  ::
      [%clay-report ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    =/  maybe-pending=(unit clay-push)  pending-clay
    ?~  maybe-pending  `this
    =/  pending=clay-push  u.maybe-pending
    ?^  error.sign-arvo
      `this(pending-clay ~)
    =/  maybe-result=(unit [ok=? message=@t])  result.pending
    ?~  maybe-result
      `this(pending-clay ~)
    =/  result=[ok=? message=@t]  u.maybe-result
    =.  repositories
      ?.  ok.result  repositories
      =/  clay-revision=(unit @ud)
        %-  mole
        |.(ud:.^(cass:clay %cw /(scot %p our.bowl)/[desk-name.pending]/(scot %da now.bowl)))
      =/  applied=repository:git
        (update-binding-success applied.pending new-oid.pending clay-revision now.bowl)
      (~(put by repositories) repository.pending applied)
    =/  webhook-cards=(list card)
      ?.  ok.result  ~
      =/  push-data=json  (push-event-json commands.pending)
      =/  clay-data=json
        %-  pairs:enjs:format
        :~  ['desk' s+desk-name.pending]
            ['commit' s+(oid-text:git-codec new-oid.pending)]
        ==
      :~  [%pass /webhook/push %agent [our.bowl %urgit] %poke %git-webhook-event !>([repository.pending %push push-data])]
          [%pass /webhook/clay-sync %agent [our.bowl %urgit] %poke %git-webhook-event !>([repository.pending %clay-sync clay-data])]
      ==
    =.  pending-clay  ~
    =.  peer-activities
      ?~  peer-response.pending  peer-activities
      %+  turn  peer-activities
      |=  event=peer-activity
      ?:  !=(transfer.u.peer-response.pending id.event)  event
      event(status ?:(ok.result %success %failure), message message.result, when now.bowl)
    :_  this
    ?^  peer-response.pending
      =/  packet=packet:git-peer
        [%result transfer.u.peer-response.pending ok.result message.result]
      =/  response-cards=(list card)
        ~[[%pass /peer/result/(scot %uv transfer.u.peer-response.pending) %agent [ship.u.peer-response.pending %urgit] %poke %git-peer !>(packet)]]
      (weld webhook-cards response-cards)
    ?:  api-response.pending
      =/  jon=json
        ?:  ok.result
          (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec new-oid.pending)]])
        (pairs:enjs:format ~[['error' s+message.result]])
      %+  weld  webhook-cards
      %+  give-simple-payload:app:server  eyre-id.pending
      [[?:(ok.result 200 422) ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server jon)]
    %+  weld  webhook-cards
    %+  give-simple-payload:app:server  eyre-id.pending
    (receive-payload 'ok' (receive-results commands.pending ok.result message.result))
  ::
      [%webhook @ ~]
    =/  delivery-id=(unit @uv)  (slaw %uv i.t.wire)
    ?~  delivery-id  `this
    =/  context=(unit webhook-flight)  (~(get by webhook-in-flight) u.delivery-id)
    ?~  context  `this
    =.  webhook-in-flight  (~(del by webhook-in-flight) u.delivery-id)
    =/  found=(unit repository:git)
      (~(get by repositories) repository.u.context)
    ?~  found  `this
    =/  status-code=@ud
      ?.  ?=([%iris %http-response *] sign-arvo)  0
      =/  response=client-response:iris  client-response.sign-arvo
      ?.  ?=(%finished -.response)  0
      status-code.response-header.response
    =/  ok=?  &((gte status-code 200) (lth status-code 300))
    =/  message=@t
      ?:  ok  'delivered'
      ?:(=(status-code 0) 'request failed' (rap 3 ~['HTTP ' (decimal status-code)]))
    =/  deliveries=(list webhook-delivery:git)
      %+  turn  webhook-deliveries.u.found
      |=  delivery=webhook-delivery:git
      ?:  !=(id.delivery u.delivery-id)  delivery
      delivery(status ?:(ok %success %failure), status-code status-code, message message)
    =/  updated=repository:git  u.found(webhook-deliveries deliveries)
    `this(repositories (~(put by repositories) repository.u.context updated))
  ::
      [%github @ ~]
    =/  request-id=(unit @uv)  (slaw %uv i.t.wire)
    ?~  request-id  `this
    =/  context=(unit github-request)  (~(get by github-in-flight) u.request-id)
    ?~  context  `this
    =.  github-in-flight  (~(del by github-in-flight) u.request-id)
    =/  result-kind=github-kind
      ?:(=(%push-send kind.u.context) %push kind.u.context)
    =/  fail
      |=  message=@t
      ^-  (quip card _this)
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.n result-kind repository.u.context message])
      ?~  api-response.u.context  `this
      :_  this
      %+  give-simple-payload:app:server  u.api-response.u.context
      [[502 ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server (pairs:enjs:format ~[['error' s+message]]))]
    ?.  ?=([%iris %http-response *] sign-arvo)
      (fail 'GitHub request failed')
    =/  response=client-response:iris  client-response.sign-arvo
    ?.  ?=(%finished -.response)
      (fail 'GitHub response was incomplete')
    =/  status=@ud  status-code.response-header.response
    ?.  &((gte status 200) (lth status 300))
      =/  detail=@t
        ?~  full-file.response  ''
        (crip (scag 500 (trip `@t`q.data.u.full-file.response)))
      (fail ?:(=('' detail) (rap 3 ~['GitHub returned HTTP ' (decimal status)]) detail))
    =/  body=octs  ?~(full-file.response [0 0] data.u.full-file.response)
    ?:  =(%file-detail kind.u.context)
      ?:  (gth p.body 2.200.000)
        (fail 'GitHub file response exceeds the 1 MiB content limit')
      =/  jon=(unit json)  (de:json:html q.body)
      ?~  jon
        (fail 'GitHub returned invalid JSON')
      =/  detail=(unit json)  (file-detail-json:git-github u.jon)
      ?~  detail
        (fail 'GitHub returned an invalid or oversized file')
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y %file-detail repository.u.context 'GitHub file loaded'])
      ?~  api-response.u.context  `this
      :_  this
      %+  give-simple-payload:app:server  u.api-response.u.context
      [[200 ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server u.detail)]
    ?:  =(%pull-diff kind.u.context)
      ?:  (gth p.body 4.194.304)
        (fail 'GitHub pull-request diff exceeds the 4 MiB display limit')
      =/  result=json
        %-  pairs:enjs:format
        :~  ['encoding' s+'base64']
            ['size' n+(decimal p.body)]
            ['content' s+(en:base64:mimes:html body)]
        ==
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y %pull-diff repository.u.context 'GitHub pull-request diff loaded'])
      ?~  api-response.u.context  `this
      :_  this
      %+  give-simple-payload:app:server  u.api-response.u.context
      [[200 ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server result)]
    ?:  ?|  =(%issue-detail kind.u.context)
            =(%pull-detail kind.u.context)
        ==
      =/  jon=(unit json)  (de:json:html q.body)
      ?~  jon
        (fail 'GitHub returned invalid JSON')
      =/  detail=(unit json)
        (detail-json:git-github u.jon =(%pull-detail kind.u.context))
      ?~  detail
        (fail 'GitHub returned an invalid issue or pull-request detail')
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y kind.u.context repository.u.context 'GitHub detail loaded'])
      ?~  api-response.u.context  `this
      :_  this
      %+  give-simple-payload:app:server  u.api-response.u.context
      [[200 ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server u.detail)]
    ?:  =(%push kind.u.context)
      =/  advertised=(unit github-refs:git-github)
        (advertised-refs:git-github body)
      ?~  advertised
        (fail 'GitHub did not advertise a usable branch')
      =/  found=(unit repository:git)  (~(get by repositories) repository.u.context)
      ?~  found
        (fail 'local repository disappeared during GitHub sync')
      =/  new=(unit oid:git)  (~(get by refs.u.found) head.u.context)
      ?~  new
        (fail 'local branch disappeared during GitHub sync')
      =/  closure=(unit (set oid:git))
        (reachable:git-graph objects.u.found (silt ~[u.new]))
      ?~  closure
        (fail 'local branch does not have a complete reachable object graph')
      =/  old=(unit oid:git)  (~(get by refs.u.advertised) head.u.context)
      ?:  ?&  ?=(^ old)
              !(~(has in u.closure) u.old)
          ==
        (fail 'GitHub branch has commits that are not local; pull before pushing')
      =/  ids=(list oid:git)  ~(tap in u.closure)
      ?:  (gth (lent ids) 25.000)
        (fail 'GitHub push exceeds the 25,000 object limit')
      =/  objects=(list object:git)
        %+  turn  ids
        |=  id=oid:git
        (~(got by objects.u.found) id)
      =/  request-body=octs
        (receive-request:git-github old u.new head.u.context objects)
      ?:  (gth p.request-body 67.108.864)
        (fail 'GitHub push exceeds the 64 MiB limit')
      =/  next-id=@uv
        `@uv`(shas %git-github-push (cat 3 eny.bowl request-count))
      =.  request-count  +(request-count)
      =/  next=github-request  u.context(kind %push-send, refs refs.u.advertised)
      =.  github-in-flight  (~(put by github-in-flight) next-id next)
      =.  github-results
        (~(put by github-results) job.u.context [%.y %.n %push repository.u.context 'uploading Git object pack'])
      =/  request=request:http
        :*  %'POST'
            (git-url:git-github owner.u.context remote.u.context '/git-receive-pack')
            (receive-headers:git-github github-token `'application/x-git-receive-pack-request')
            `request-body
        ==
      :_  this
      :~  [%pass /github/(scot %uv next-id) %arvo %i %request request *outbound-config:iris]
      ==
    ?:  =(%push-send kind.u.context)
      =/  result=(unit [ok=? message=@t])
        (receive-result:git-github body head.u.context)
      ?~  result
        (fail 'GitHub returned an invalid receive-pack result')
      ?.  ok.u.result
        (fail ?:(=('' message.u.result) 'GitHub rejected the branch update' message.u.result))
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y %push repository.u.context 'GitHub branch synchronized'])
      `this
    ?:  ?|  =(%import kind.u.context)
            =(%update kind.u.context)
        ==
      ?:  =('' head.u.context)
        =/  advertised=(unit github-refs:git-github)
          (advertised-refs:git-github body)
        ?~  advertised
          (fail 'GitHub did not advertise a usable branch')
        =/  request-body=octs  (upload-request:git-github refs.u.advertised)
        =/  next-id=@uv
          `@uv`(shas %git-github-pack (cat 3 eny.bowl request-count))
        =.  request-count  +(request-count)
        =/  next=github-request
          u.context(head head.u.advertised, refs refs.u.advertised)
        =.  github-in-flight  (~(put by github-in-flight) next-id next)
        =.  github-results
          (~(put by github-results) job.u.context [%.y %.n kind.u.context repository.u.context 'downloading Git object pack'])
        =/  request=request:http
          :*  %'POST'
              (git-url:git-github owner.u.context remote.u.context '/git-upload-pack')
              (git-headers:git-github github-token `'application/x-git-upload-pack-request')
              `request-body
          ==
        :_  this
        :~  [%pass /github/(scot %uv next-id) %arvo %i %request request *outbound-config:iris]
        ==
      ?:  (gth p.body 67.108.864)
        (fail 'GitHub pack exceeds the 64 MiB import limit')
      =/  pack=(unit octs)  (upload-pack:git-github body)
      ?~  pack
        (fail 'GitHub upload-pack response did not contain a pack')
      =/  object-count=(unit @)  (uint-be-at:git-pack-decode u.pack 8 4)
      ?~  object-count
        (fail 'GitHub pack header is incomplete')
      ?:  (gth u.object-count 25.000)
        (fail 'GitHub pack exceeds the 25,000 object import limit')
      =/  existing=(unit repository:git)  (~(get by repositories) repository.u.context)
      =/  bases=(map oid:git object:git)  ?~(existing ~ objects.u.existing)
      =/  decoded=(unit decoded-pack:git-pack-decode)
        (decode-pack-with:git-pack-decode u.pack bases)
      ?~  decoded
        (fail 'GitHub pack failed checksum, compression, delta, or object validation')
      =/  combined=(map oid:git object:git)  bases
      =/  staged=(list [oid:git object:git])  ~(tap by objects.u.decoded)
      =.  combined
        |-
        ?~  staged  combined
        =.  combined  (~(put by combined) -.i.staged +.i.staged)
        $(staged t.staged)
      =/  refs-valid=?
        %+  levy  ~(tap by refs.u.context)
        |=  entry=[@t oid:git]
        =/  closure=(unit (set oid:git))
          (reachable:git-graph combined (silt ~[+.entry]))
        ?=(^ closure)
      ?.  refs-valid
        (fail 'GitHub pack did not contain a complete reachable object graph')
      =/  fast-forward=?
        ?~  existing  %.y
        %+  levy  ~(tap by refs.u.context)
        |=  entry=[@t oid:git]
        =/  old=(unit oid:git)  (~(get by refs.u.existing) -.entry)
        ?~  old  %.y
        ?:  =(u.old +.entry)  %.y
        =/  closure=(unit (set oid:git))
          (reachable:git-graph combined (silt ~[+.entry]))
        ?&  ?=(^ closure)
            (~(has in u.closure) u.old)
        ==
      ?.  fast-forward
        (fail 'GitHub and local branches have diverged; push or reconcile before pulling')
      =/  next-refs=(map @t oid:git)
        ?~  existing  refs.u.context
        =/  working=(map @t oid:git)  refs.u.existing
        =/  incoming=(list [@t oid:git])  ~(tap by refs.u.context)
        |-
        ?~  incoming  working
        =.  working  (~(put by working) -.i.incoming +.i.incoming)
        $(incoming t.incoming)
      =/  origin=github-origin:git  [owner.u.context remote.u.context]
      =/  repo=repository:git
        ?~  existing
          :*  our.bowl
              public-read.u.context
              ''
              head.u.context
              next-refs
              ~
              combined
              (silt ~[our.bowl])
              ~
              ~
              ~
              ~
              ~
              ~
              `origin
              ~
              ~
              ~
              ~
              ~
          ~
          ~
          ~
          ~
          default-notification-events
          ==
        u.existing(head head.u.context, refs next-refs, objects combined, github-origin `origin)
      =.  repositories  (~(put by repositories) repository.u.context repo)
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y kind.u.context repository.u.context 'GitHub repository synchronized'])
      `this
    ?:  ?|  =(%issues kind.u.context)
            =(%pulls kind.u.context)
        ==
      =/  jon=(unit json)  (de:json:html q.body)
      ?~  jon
        (fail 'GitHub returned invalid JSON')
      =/  items=(unit (list forge-item:git))
        (forge-items:git-github u.jon =(%pulls kind.u.context))
      ?~  items
        (fail 'GitHub returned an invalid issue or pull-request list')
      =/  found=(unit repository:git)  (~(get by repositories) repository.u.context)
      ?~  found
        (fail 'local repository disappeared during GitHub sync')
      =/  previous=(list forge-item:git)
        ?:(=(%issues kind.u.context) github-issues.u.found github-pulls.u.found)
      =/  merged-items=(list forge-item:git)
        ?:  =(1 metadata-page.u.context)  u.items
        =/  novel=(list forge-item:git)
          %+  skim  u.items
          |=  item=forge-item:git
          =/  duplicate=(list forge-item:git)
            (skim previous |=(prior=forge-item:git =(number.prior number.item)))
          ?=(~ duplicate)
        (scag 500 (weld previous novel))
      =/  repo=repository:git
        ?:  =(%issues kind.u.context)
          u.found(github-issues merged-items)
        u.found(github-pulls merged-items)
      =.  repositories  (~(put by repositories) repository.u.context repo)
      =/  received=@ud  ?:(?=([%a *] u.jon) (lent p.u.jon) 0)
      =/  label=@t
        %+  rap  3
        :~  ?:(=(%issues kind.u.context) 'GitHub issues synchronized · ' 'GitHub pull requests synchronized · ')
            (decimal received)
            ' received'
        ==
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.y kind.u.context repository.u.context label])
      `this
    =/  message=@t
      ?:  =(%fork kind.u.context)
        'GitHub fork requested'
      'GitHub pull request opened'
    =.  github-results
      (~(put by github-results) job.u.context [%.n %.y kind.u.context repository.u.context message])
    `this
  ::
      [%lfs-delete @ ~]
    =/  request-id=(unit @uv)  (slaw %uv i.t.wire)
    ?~  request-id  `this
    =/  context=(unit lfs-delete)  (~(get by lfs-deletes) u.request-id)
    ?~  context  `this
    =.  lfs-deletes  (~(del by lfs-deletes) u.request-id)
    ?.  ?=([%iris %http-response *] sign-arvo)  `this
    =/  response=client-response:iris  client-response.sign-arvo
    ?.  ?=(%finished -.response)  `this
    =/  status=@ud  status-code.response-header.response
    ?.  |(&((gte status 200) (lth status 300)) =(404 status))  `this
    =/  found=(unit repository:git)
      (~(get by repositories) repository.u.context)
    ?~  found  `this
    =/  updated=repository:git
      u.found(lfs-objects (~(del by lfs-objects.u.found) oid.u.context))
    `this(repositories (~(put by repositories) repository.u.context updated))
  ::
      [%iris @ ~]
    =/  request-id=(unit @uv)  (slaw %uv i.t.wire)
    ?~  request-id  `this
    =/  context=(unit lfs-request)  (~(get by in-flight) u.request-id)
    ?~  context  `this
    =.  in-flight  (~(del by in-flight) u.request-id)
    ?.  ?=([%iris %http-response *] sign-arvo)
      :_  this
      (error-cards eyre-id.u.context 502 'object storage request failed')
    =/  response=client-response:iris  client-response.sign-arvo
    ?.  ?=(%finished -.response)
      :_  this
      (error-cards eyre-id.u.context 502 'object storage response was incomplete')
    =/  status=@ud  status-code.response-header.response
    ?.  &((gte status 200) (lth status 300))
      :_  this
      (error-cards eyre-id.u.context 422 'uploaded object was not found in object storage')
    =/  content-length=(unit @ud)
      =/  raw=(unit @t)  (get-header:http 'content-length' headers.response-header.response)
      ?~(raw ~ (slaw %ud u.raw))
    ?:  ?&(?=(^ content-length) !=(u.content-length size.upload.u.context))
      :_  this
      (error-cards eyre-id.u.context 422 'stored object size does not match')
    =/  found=(unit repository:git)  (~(get by repositories) repository.u.context)
    ?~  found
      :_  this
      (error-cards eyre-id.u.context 404 'repository not found')
    =/  object=lfs-object:git  [size.upload.u.context object-key.upload.u.context]
    =/  repo=repository:git
      u.found(lfs-objects (~(put by lfs-objects.u.found) oid.u.context object))
    =.  repo  repo(lfs-uploads (~(del by lfs-uploads.repo) oid.u.context))
    =.  repositories  (~(put by repositories) repository.u.context repo)
    :_  this
    %+  give-simple-payload:app:server  eyre-id.u.context
    =/  jon=json  (pairs:enjs:format ~)
    [[200 ~[['content-type' 'application/vnd.git-lfs+json'] ['cache-control' 'no-store']]] `(json-to-octs:server jon)]
  ==
++  on-fail   on-fail:def
--
