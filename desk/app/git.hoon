::  Native Git object database and Smart HTTP endpoint.
::
/-  git, git-peer
/+  dbug, default-agent, git-clay, git-codec, git-github, git-graph, git-pack, git-pack-decode, git-protocol, git-storage, server
|%
+$  card  card:agent:gall
+$  lfs-spec  [oid=@t size=@ud]
+$  lfs-request  [eyre-id=@ta repository=@t oid=@t upload=lfs-upload:git]
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
      message=@t
      paths=(list path)
      files=(map path octs)
  ==
+$  peer-serve
  $:  target=ship
      transfer=@uv
      objects=(list [oid:git object:git])
  ==
+$  peer-receive
  $:  purpose=?(%fork %push %pull)
      source=ship
      source-repository=@t
      local-repository=@t
      title=@t
      public-read=?
      head=@t
      refs=(map @t oid:git)
      expected=@ud
      received=@ud
      objects=(map oid:git object:git)
  ==
+$  peer-result  [status=? message=@t repository=@t]
+$  github-kind  ?(%import %update %issues %pulls %fork %open-pull)
+$  github-request
  $:  job=@uv
      kind=github-kind
      repository=@t
      owner=@t
      remote=@t
      public-read=?
      head=@t
      refs=(map @t oid:git)
  ==
+$  github-result
  $:  active=?
      ok=?
      kind=github-kind
      repository=@t
      message=@t
  ==
::
++  update-binding-success
  |=  [repo=repository:git new-oid=oid:git riot=riot:clay]
  ^-  repository:git
  ?~  binding.repo  repo
  =/  clay-revision=(unit @ud)
    ?~  riot  ~
    ?.  ?=([%ud @] q.p.u.riot)  ~
    `p.q.p.u.riot
  =/  linked=desk-binding:git
    u.binding.repo(last-clay clay-revision, last-git `new-oid)
  repo(binding `linked)
::
++  receive-results
  |=  [commands=(list receive-command:git) ok=? message=@t]
  ^-  (list [ok=? ref=@t message=@t])
  (turn commands |=(command=receive-command:git [ok ref.command message]))
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
  =/  linked=desk-binding:git
    u.binding.repo(last-git `commit.u.snapped)
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
  ==
::
++  decimal
  |=  value=@ud
  ^-  @t
  (crip ((d-co:co 1) value))
::
++  repository-json
  |=  [name=@t repo=repository:git]
  ^-  json
  =/  refs-json=(list json)
    %+  turn  ~(tap by refs.repo)
    |=  [ref=@t oid=oid:git]
    %-  pairs:enjs:format
    ~[['name' s+ref] ['oid' s+(oid-text:git-codec oid)]]
  =/  writers-json=(list json)
    (turn ~(tap in writers.repo) |=(writer=@p s+(scot %p writer)))
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
  %-  pairs:enjs:format
  :~  ['name' s+name]
      ['owner' s+(scot %p owner.repo)]
      ['publicRead' b+public-read.repo]
      ['head' s+head.repo]
      ['refs' [%a refs-json]]
      ['objectCount' n+(decimal (lent ~(tap by objects.repo)))]
      ['lfsObjectCount' n+(decimal (lent ~(tap by lfs-objects.repo)))]
      ['writeTokenSet' b+?=(^ write-token-hash.repo)]
      ['writers' [%a writers-json]]
      ['pullRequests' [%a pulls-json]]
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
++  repository-files-at-json
  |=  [name=@t repo=repository:git ref=@t]
  ^-  json
  =/  commit=(unit oid:git)  (~(get by refs.repo) ref)
  =/  files=(unit (map path octs))
    ?~  commit  `*(map path octs)
    (flatten-commit:git-clay objects.repo u.commit)
  =/  file-json=(list json)
    ?~  files  ~
    %+  turn  ~(tap by u.files)
    |=  [file-path=path data=octs]
    %-  pairs:enjs:format
    ~[['path' s+(spat file-path)] ['size' n+(decimal p.data)]]
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
++  file-at-commit
  |=  [repo=repository:git commit=oid:git file-path=path]
  ^-  (unit octs)
  =/  files=(unit (map path octs))
    (flatten-commit:git-clay objects.repo commit)
  ?~  files  ~
  (~(get by u.files) file-path)
::
++  repository-file-at
  |=  [repo=repository:git ref=@t file-path=path]
  ^-  (unit octs)
  =/  commit=(unit oid:git)  (~(get by refs.repo) ref)
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
  =/  current=(unit oid:git)  (~(get by refs.repo) ref)
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
++  commit-parent
  |=  data=octs
  ^-  (unit oid:git)
  ?:  (lte p.data 53)  ~
  =/  tail=octs  (slice:git-codec data 46 (sub p.data 46))
  ?.  (starts-with:git-protocol tail 'parent ')  ~
  (oid-at:git-protocol data 53)
::
++  commit-subject
  |=  data=octs
  ^-  @t
  =/  start=(unit @ud)  (double-newline data 0)
  ?~  start  ''
  =/  message=octs  (slice:git-codec data u.start (sub p.data u.start))
  =/  end=(unit @ud)  (find-byte:git-clay message 0 10)
  =/  width=@ud  ?~(end p.message u.end)
  =/  subject=octs  (slice:git-codec message 0 width)
  `@t`q.subject
::
++  repository-commits-json
  |=  [name=@t repo=repository:git]
  ^-  json
  =/  current=(unit oid:git)  (~(get by refs.repo) head.repo)
  =/  entries=(list json)  ~
  =/  count=@ud  0
  |-
  ?:  |(?=(~ current) (gte count 100))
    %-  pairs:enjs:format
    ~[['repository' s+name] ['head' s+head.repo] ['commits' [%a (flop entries)]]]
  =/  found=(unit object:git)  (~(get by objects.repo) u.current)
  ?~  found
    %-  pairs:enjs:format
    ~[['repository' s+name] ['head' s+head.repo] ['commits' [%a (flop entries)]]]
  ?.  =(%commit kind.u.found)
    %-  pairs:enjs:format
    ~[['repository' s+name] ['head' s+head.repo] ['commits' [%a (flop entries)]]]
  =/  parent=(unit oid:git)  (commit-parent data.u.found)
  =/  entry=json
    %-  pairs:enjs:format
    :~  ['oid' s+(oid-text:git-codec u.current)]
        ['parent' s+?~(parent '' (oid-text:git-codec u.parent))]
        ['subject' s+(commit-subject data.u.found)]
    ==
  $(current parent, entries [entry entries], count +(count))
--
::
%-  agent:dbug
=|  state-0:git
=*  state  -
=/  in-flight  *(map @uv lfs-request)
=/  request-count=@ud  0
=/  pending-clay  *(unit clay-push)
=/  pending-publish  *(unit publish-job)
=/  peer-serving  *(map @uv peer-serve)
=/  peer-receiving  *(map @uv peer-receive)
=/  peer-results  *(map @uv peer-result)
=/  github-in-flight  *(map @uv github-request)
=/  github-results  *(map @uv github-result)
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %git]
      [%pass /eyre/api-connect %arvo %e %connect [~ /apps/git/api] %git]
  ==
::
++  on-save
  !>(state)
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  loaded=state-0:git  !<(state-0:git old)
  :_  this(state loaded, in-flight ~, request-count 0, pending-clay ~, pending-publish ~, peer-serving ~, peer-receiving ~, peer-results ~, github-in-flight ~, github-results ~)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %git]
      [%pass /eyre/api-connect %arvo %e %connect [~ /apps/git/api] %git]
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
  ==
::
++  peer-card
  |=  [target=ship wire=wire packet=packet:git-peer]
  ^-  card
  [%pass wire %agent [target %git] %poke %git-peer !>(packet)]
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
      [number source.flight source-repository.flight title.flight %open incoming-oid base-oid]
    =/  updated=repository:git
      u.existing(objects objects.flight, native-pulls [pull native-pulls.u.existing])
    =.  repositories  (~(put by repositories) local-repository.flight updated)
    (peer-push-finish flight transfer %.y (rap 3 ~['pull request #' (decimal number) ' opened']))
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
          head.flight
          refs.flight
          objects.flight
          (silt ~[our.bowl])
          ~
          ~
          ~
          ~
          `[[source.flight source-repository.flight]]
          ~
          ~
          ~
          ~
      ==
    u.existing(head head.flight, refs refs.flight, objects objects.flight, peer-origin `[[source.flight source-repository.flight]])
  =.  repositories  (~(put by repositories) local-repository.flight repo)
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-results  (~(put by peer-results) transfer [%.y 'complete' local-repository.flight])
  `this
::
++  peer-push-finish
  |=  [flight=peer-receive transfer=@uv ok=? message=@t]
  ^-  (quip card _this)
  =.  peer-receiving  (~(del by peer-receiving) transfer)
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
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =.  peer-results  (~(put by peer-results) transfer [%.n message local-repository.u.found])
  `this
::
++  handle-peer
  |=  packet=packet:git-peer
  ^-  (quip card _this)
  ?-  -.packet
      %request
    (peer-request request.packet)
  ::
      %begin
    (peer-begin begin.packet)
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
++  peer-offer
  |=  offer=offer:git-peer
  ^-  (quip card _this)
  =/  found=(unit repository:git)  (~(get by repositories) repository.offer)
  ?~  found  (peer-fail src.bowl transfer.offer 'destination repository not found')
  ?.  |(pull-request.offer (~(has in writers.u.found) src.bowl))
    (peer-fail src.bowl transfer.offer 'ship is not authorized to update this repository')
  ?:  (~(has by peer-receiving) transfer.offer)
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
        ''
        ~
        0
        0
        objects.u.found
    ==
  =.  peer-receiving  (~(put by peer-receiving) transfer.offer flight)
  :_  this
  :~  (peer-card src.bowl /peer/request/(scot %uv transfer.offer) [%request transfer.offer source-repository.offer haves])
  ==
::
++  peer-result-received
  |=  [transfer=@uv ok=? message=@t]
  ^-  (quip card _this)
  =/  found=(unit peer-result)  (~(get by peer-results) transfer)
  ?~  found  `this
  =.  peer-results  (~(put by peer-results) transfer [ok message repository.u.found])
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
    (peer-fail src.bowl transfer.req 'transfer identifier is already active')
  =/  objects=(list [oid:git object:git])
    %+  murn  ~(tap by objects.u.found)
    |=  entry=[oid:git object:git]
    ?:  (~(has in haves.req) -.entry)  ~
    `entry
  =/  flight=peer-serve  [src.bowl transfer.req objects]
  =.  peer-serving  (~(put by peer-serving) transfer.req flight)
  :_  this
  :~  (peer-card src.bowl /peer/begin/(scot %uv transfer.req) [%begin transfer.req repository.req head.u.found refs.u.found (lent objects)])
      [%pass /peer/serve-timeout/(scot %uv transfer.req) %arvo %b %wait (add now.bowl ~m2)]
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
  =/  next=peer-receive
    u.found(head head.msg, refs refs.msg, expected objects.msg)
  =.  peer-receiving  (~(put by peer-receiving) transfer.msg next)
  ?:  =(src.bowl our.bowl)
    =/  serving=(unit peer-serve)  (~(get by peer-serving) transfer.msg)
    ?~  serving
      (peer-snapshot-fail transfer.msg 'local repository snapshot is unavailable')
    (peer-snapshot transfer.msg (silt objects.u.serving))
  :_  this
  =/  scry-path=path
    /g/x/1/git//fine/(scot %uv transfer.msg)/noun
  :~  [%pass /peer/fine/(scot %uv transfer.msg) %keen %.n src.bowl scry-path]
      [%pass /peer/timeout/(scot %uv transfer.msg) %arvo %b %wait (add now.bowl ~s30)]
  ==
::
++  peer-release
  |=  transfer=@uv
  ^-  (quip card _this)
  =/  found=(unit peer-serve)  (~(get by peer-serving) transfer)
  ?~  found  `this
  ?.  =(src.bowl target.u.found)  `this
  `this(peer-serving (~(del by peer-serving) transfer))
::
++  peer-snapshot-fail
  |=  [transfer=@uv message=@t]
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  =/  flight=peer-receive  u.found
  =.  peer-receiving  (~(del by peer-receiving) transfer)
  =/  release=card
    (peer-card source.flight /peer/release/(scot %uv transfer) [%release transfer])
  ?:  =(%fork purpose.flight)
    =.  peer-results
      (~(put by peer-results) transfer [%.n message local-repository.flight])
    [[release ~] this]
  :_  this
  :~  release
      (peer-card source.flight /peer/result/(scot %uv transfer) [%result transfer %.n message])
  ==
::
++  peer-snapshot
  |=  [transfer=@uv incoming=(map oid:git object:git)]
  ^-  (quip card _this)
  ?.  =(src.bowl our.bowl)  `this
  =/  found=(unit peer-receive)  (~(get by peer-receiving) transfer)
  ?~  found  `this
  =/  flight=peer-receive  u.found
  =/  count=@ud  (lent ~(tap by incoming))
  ?.  =(count expected.flight)
    (peer-snapshot-fail transfer 'Fine repository snapshot has the wrong object count')
  =/  valid=?
    %+  levy  ~(tap by incoming)
    |=  entry=[oid:git object:git]
    =/  object=object:git  +.entry
    =(-.entry (object-oid:git-codec kind.object data.object))
  ?.  valid
    (peer-snapshot-fail transfer 'Fine repository object failed content-address validation')
  =/  next=peer-receive
    flight(objects (merge-objects objects.flight incoming), received count)
  =.  peer-receiving  (~(put by peer-receiving) transfer next)
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
          'refs/heads/main'
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
    =/  repo=repository:git  u.found(refs (~(put by refs.u.found) ref.act oid.act))
    `this(repositories (~(put by repositories) repository.act repo))
  ::
      %delete-ref
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    =/  repo=repository:git  u.found(refs (~(del by refs.u.found) ref.act))
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
    =/  binding=desk-binding:git  [desk-name.act branch.act ~ ~]
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
  ?.  ?=(%o -.jon)  ~
  (~(get by p.jon) key)
::
++  string-at
  |=  [key=@t jon=json]
  ^-  (unit @t)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=(%s -.u.value)  ~
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
  ?.  ?=(%n -.u.value)  ~
  (parse-decimal p.u.value)
::
++  bool-at
  |=  [key=@t jon=json]
  ^-  (unit ?)
  =/  value=(unit json)  (json-at key jon)
  ?~  value  ~
  ?.  ?=(%b -.u.value)  ~
  `p.u.value
::
++  valid-lfs-oid
  |=  oid=@t
  ^-  ?
  =/  chars=tape  (trip oid)
  ?.  =(64 (lent chars))  %.n
  (levy chars |=(char=@tD ?|(&((gte char '0') (lte char '9')) &((gte char 'a') (lte char 'f')))))
::
++  parse-lfs-specs
  |=  jon=json
  ^-  (unit (list lfs-spec))
  =/  value=(unit json)  (json-at 'objects' jon)
  ?~  value  ~
  ?.  ?=(%a -.u.value)  ~
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
++  api-file-path
  |=  segments=(list @t)
  ^-  (unit path)
  ?~  segments  ~
  =/  parse
    |=  [remaining=(list @t) out=path]
    ^-  (unit path)
    ?~  remaining  `(flop out)
    =/  segment=(unit @tas)  (slaw %tas i.remaining)
    ?~  segment  ~
    $(remaining t.remaining, out [u.segment out])
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
    %-  pairs:enjs:format
    :~  ['transfer' s+(scot %uv transfer)]
        ['active' b+(~(has by peer-receiving) transfer)]
        ['ok' b+status.result]
        ['message' s+message.result]
        ['repository' s+repository.result]
    ==
  (pairs:enjs:format ~[['transfers' [%a entries]]])
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
++  handle-api
  |=  [eyre-id=@ta req=inbound-request:eyre line=request-line:server]
  ^-  (quip card _this)
  ?.  authenticated.req
    :_  this
    (api-error eyre-id 401 'Urbit login required')
  =/  site=(list @t)  site.line
  =/  method=@tas  method.request.req
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %github %status ~] site)
      ==
    :_  this
    (api-json eyre-id 200 github-results-json)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %github %token ~] site)
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
          ?=([%apps %git %api %github %token ~] site)
      ==
    =.  github-token  ~
    :_  this
    (api-ok eyre-id 200)
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %github %import ~] site)
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
    =/  ctx=github-request  [0v0 kind u.local u.owner u.remote u.public '' ~]
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
          ?=([%apps %git %api %repository @ %github %metadata ~] site)
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
    ?.  ?&  ?=(^ requested)
            ?|  =('issues' u.requested)
                =('pulls' u.requested)
            ==
        ==
      :_  this
      (api-error eyre-id 422 'kind must be issues or pulls')
    =/  owner=@t  owner.u.github-origin.u.found
    =/  remote=@t  repository.u.github-origin.u.found
    =/  kind=github-kind  ?:(=('issues' u.requested) %issues %pulls)
    =/  ctx=github-request  [0v0 kind name owner remote public-read.u.found '' ~]
    =/  suffix=@t
      ?:(=(%issues kind) '/issues?state=all&per_page=100' '/pulls?state=all&per_page=100')
    =/  request=request:http
      [%'GET' (api-url:git-github owner remote suffix) (api-headers:git-github github-token) ~]
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %github %fork ~] site)
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
    =/  ctx=github-request  [0v0 %fork name owner remote public-read.u.found '' ~]
    =/  headers=(list [@t @t])
      [['content-type' 'application/json'] (api-headers:git-github github-token)]
    =/  request=request:http
      [%'POST' (api-url:git-github owner remote '/forks') headers `(as-octs:mimes:html '{}')]
    =/  result  (github-start ctx request)
    :_  +.result
    (weld -.result (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y]])))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %github %pull ~] site)
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
    =/  ctx=github-request  [0v0 %open-pull name owner remote public-read.u.found '' ~]
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
          ?=([%apps %git %api %peer %transfers ~] site)
      ==
    :_  this
    (api-json eyre-id 200 peer-results-json)
  ?:  ?&  =(%'DELETE' method)
          ?=([%apps %git %api %peer %transfers @ ~] site)
      ==
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.t.t.t.site)
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
      =/  next=_this  +.canceled
      =/  cleaned=_this
        next(peer-results (~(del by peer-results.next) u.transfer))
      :_  cleaned
      (weld -.canceled (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]])))
    =.  peer-results  (~(del by peer-results) u.transfer)
    :_  this
    (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %peer %fork ~] site)
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
          ''
          ~
          0
          0
          base-objects
      ==
    =.  peer-receiving  (~(put by peer-receiving) transfer flight)
    =.  peer-results  (~(put by peer-results) transfer [%.n 'transferring' u.local-repository])
    :_  this
    %+  weld
      :~  (peer-card u.source /peer/request/(scot %uv transfer) [%request transfer u.source-repository haves])
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %peer %push ~] site)
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
    :_  this
    %+  weld
      :~  (peer-card ship.u.peer-origin.u.found /peer/offer/(scot %uv transfer) [%offer transfer repository.u.peer-origin.u.found u.name %.n ''])
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %peer %pull-request ~] site)
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
    :_  this
    %+  weld
      :~  (peer-card ship.u.peer-origin.u.found /peer/offer/(scot %uv transfer) [%offer transfer repository.u.peer-origin.u.found u.name %.y u.title])
      ==
    (api-json eyre-id 202 (pairs:enjs:format ~[['ok' b+%.y] ['transfer' s+(scot %uv transfer)]]))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %repositories ~] site)
      ==
    :_  this
    (api-json eyre-id 200 (repositories-json repositories))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %desks ~] site)
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
          ?=([%apps %git %api %repository @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    :_  this
    (api-json eyre-id 200 (repository-json name u.found))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %repository @ %files ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?.  (~(has by refs.u.found) ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-files-at-json name u.found ref))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %repository @ %commits ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    :_  this
    (api-json eyre-id 200 (repository-commits-json name u.found))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %repository @ %file-history *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?.  (~(has by refs.u.found) ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    :_  this
    (api-json eyre-id 200 (repository-file-history-json name u.found ref u.file-path))
  ?:  ?&  =(%'GET' method)
          ?=([%apps %git %api %repository @ %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  requested=(unit @t)  (query-value 'ref' args.line)
    =/  ref=@t  ?~(requested head.u.found u.requested)
    ?.  (~(has by refs.u.found) ref)
      :_  this
      (api-error eyre-id 404 'ref not found')
    =/  data=(unit octs)  (repository-file-at u.found ref u.file-path)
    ?~  data
      :_  this
      (api-error eyre-id 404 'file not found')
    :_  this
    (api-json eyre-id 200 (repository-file-json name u.found ref u.file-path u.data))
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %file *] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found
      :_  this
      (api-error eyre-id 404 'repository not found')
    =/  file-path=(unit path)  (api-file-path t.t.t.t.t.t.site)
    ?~  file-path
      :_  this
      (api-error eyre-id 422 'valid file path required')
    =/  jon=(unit json)  (api-body req)
    ?~  jon
      :_  this
      (api-error eyre-id 400 'valid JSON body required')
    =/  encoded=(unit @t)  (string-at 'content' u.jon)
    =/  message=(unit @t)  (string-at 'message' u.jon)
    ?.  ?&(?=(^ encoded) ?=(^ message) !=('' u.message))
      :_  this
      (api-error eyre-id 422 'base64 content and a non-empty commit message are required')
    =/  data=(unit octs)  (de:base64:mimes:html u.encoded)
    ?~  data
      :_  this
      (api-error eyre-id 422 'content is not valid base64')
    =/  parent=(unit oid:git)  (~(get by refs.u.found) head.u.found)
    ?~  parent
      :_  this
      (api-error eyre-id 409 'repository has no branch head to edit')
    =/  files=(unit (map path octs))
      (flatten-commit:git-clay objects.u.found u.parent)
    ?~  files
      :_  this
      (api-error eyre-id 409 'repository head is not a valid file tree')
    ?.  (~(has by u.files) u.file-path)
      :_  this
      (api-error eyre-id 404 'file not found')
    =/  updated-files=(map path octs)  (~(put by u.files) u.file-path u.data)
    =/  snapped=(unit [commit=oid:git objects=(map oid:git object:git)])
      (snapshot:git-clay updated-files objects.u.found `u.parent our.bowl now.bowl u.message)
    ?~  snapped
      :_  this
      (api-error eyre-id 422 'file tree cannot be represented as a Git commit')
    =/  applied=repository:git
      u.found(objects objects.u.snapped, refs (~(put by refs.u.found) head.u.found commit.u.snapped))
    ?~  binding.applied
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?.  =(head.applied branch.u.binding.applied)
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec commit.u.snapped)]]))
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  delta=(unit nori:clay)
      (clay-delta desk-name.u.binding.applied updated-files)
    ?~  delta
      :_  this
      (api-error eyre-id 409 'unable to read linked Clay desk')
    ?>  ?=(%& -.u.delta)
    ?:  =(~ p.u.delta)
      =/  linked-binding=desk-binding:git
        u.binding.applied(last-git `commit.u.snapped)
      =/  linked=repository:git
        applied(binding `linked-binding)
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
          ?=([%apps %git %api %repositories ~] site)
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
          ?=([%apps %git %api %repository @ ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%delete name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %public ~] site)
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
          ?=([%apps %git %api %repository @ %pulls @ %merge ~] site)
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
    =/  reachable=(unit (set oid:git))
      (reachable:git-graph objects.u.found (silt ~[head.pull]))
    ?.  ?&(?=(^ reachable) (~(has in u.reachable) u.current))
      :_  this
      (api-error eyre-id 409 'pull request cannot be fast-forwarded; update the fork and open a new request')
    =/  pulls=(list native-pull:git)
      %+  turn  native-pulls.u.found
      |=  candidate=native-pull:git
      ?:  =(number.candidate number.pull)
        candidate(state %merged)
      candidate
    =/  applied=repository:git
      u.found(refs (~(put by refs.u.found) head.u.found head.pull), native-pulls pulls)
    =/  clay-linked=?
      ?~  binding.applied  %.n
      =(head.applied branch.u.binding.applied)
    ?.  clay-linked
      =.  repositories  (~(put by repositories) name applied)
      :_  this
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec head.pull)]]))
    ?>  ?=(^ binding.applied)
    ?:  ?|(=(^ pending-clay) =(^ pending-publish))
      :_  this
      (api-error eyre-id 409 'another Clay operation is in progress')
    =/  files=(unit (map path octs))
      (flatten-commit:git-clay objects.applied head.pull)
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
      (api-json eyre-id 200 (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec head.pull)]]))
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
          head.pull
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
          ?=([%apps %git %api %repository @ %writers ~] site)
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
          ?=([%apps %git %api %repository @ %token ~] site)
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
          ?=([%apps %git %api %repository @ %token ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%clear-write-token name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %bind ~] site)
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
          ?=([%apps %git %api %repository @ %unbind ~] site)
      ==
    =/  name=@t  i.t.t.t.t.site
    ?.  (~(has by repositories) name)
      :_  this
      (api-error eyre-id 404 'repository not found')
    (api-with-action eyre-id 200 [%unbind-desk name])
  ?:  ?&  =(%'POST' method)
          ?=([%apps %git %api %repository @ %publish ~] site)
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
  =/  changes=(list [p=path q=miso:clay])
    %+  turn  ~(tap by files)
    |=  [file-path=path data=octs]
    =/  =mime  [/ data]
    =/  change=miso:clay
      ?:  (~(has in old-set) file-path)
        [%mut %mime !>(mime)]
      [%ins %mime !>(mime)]
    [file-path change]
  =/  deletes=(list [p=path q=miso:clay])
    %+  murn  u.old-files
    |=  file-path=spur
    ^-  (unit [p=path q=miso:clay])
    ?:  (~(has by files) file-path)  ~
    `[file-path %del ~]
  `[%& (weld changes deletes)]
::
++  update-binding-success
  |=  [repo=repository:git branch=@t new-oid=oid:git riot=riot:clay]
  ^-  repository:git
  ?~  binding.repo  repo
  =/  clay-revision=(unit @ud)
    ?~  riot  ~
    ?.  ?=([%ud @] q.p.u.riot)  ~
    `p.q.p.u.riot
  =/  linked=desk-binding:git
    u.binding.repo(last-clay clay-revision, last-git `new-oid)
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
  ?:  (starts-with '/apps/git/api' url.request.req)
    (handle-api eyre-id req line)
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
      |(public-read.u.found authenticated.req)
    (write-authorized u.found req)
  ?.  authorized
    :_  this
    %-  give-http
    :*  eyre-id
        401
        ~[['content-type' 'text/plain'] ['www-authenticate' 'Basic realm="git"']]
        `(text:git-codec 'repository authentication required\0a')
    ==
  =/  body=octs  (smart-advertisement:git-protocol u.found u.service)
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
  ?.  |(public-read.u.found authenticated.req)
    :_  this
    (give-http eyre-id 403 ~[['content-type' 'text/plain']] `(text:git-codec 'repository is private\0a'))
  ?~  body.request.req
    :_  this
    (give-http eyre-id 400 ~[['content-type' 'text/plain']] `(text:git-codec 'missing upload-pack request\0a'))
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
  =/  closure=(unit (set oid:git))
    (reachable:git-graph objects.u.found wants.u.parsed)
  ?~  closure
    :_  this
    (give-http eyre-id 500 ~[['content-type' 'text/plain']] `(text:git-codec 'repository graph is incomplete\0a'))
  =/  objects=(list object:git)
    %+  turn  ~(tap in u.closure)
    |=(oid=oid:git (need (~(get by objects.u.found) oid)))
  =/  pack=octs  (encode-pack:git-pack objects)
  =/  nak=octs
    (en-pkt:git-codec [%data (text:git-codec 'NAK\0a')])
  =/  response=octs  (join:git-codec nak pack)
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
      =.  repositories  (~(put by repositories) repo-name u.applied)
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.y ''))
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
      =.  repositories  (~(put by repositories) repo-name u.applied)
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (receive-payload 'ok' (receive-results commands.u.parsed %.y ''))
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
  =.  repositories  (~(put by repositories) repo-name u.applied)
  :_  this
  %+  give-simple-payload:app:server  eyre-id
  (receive-payload 'ok' (receive-results commands.u.parsed %.y ''))
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
      [%x %repositories ~]
    ``json+!>((repositories-json repositories))
  ::
      [%x %repository @ ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ``json+!>((repository-json name u.found))
  ::
      [%x %repository @ %files ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ``json+!>((repository-files-json name u.found))
  ::
      [%x %repository @ %commits ~]
    =/  name=@t  i.t.t.path
    =/  found=(unit repository:git)  (~(get by repositories) name)
    ?~  found  [~ ~]
    ``json+!>((repository-commits-json name u.found))
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
    =/  applied=repository:git
      (update-binding-success applied.pending new-oid.pending ~)
    =.  repositories  (~(put by repositories) repository.pending applied)
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
      [%peer %fine @ ~]
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  fail
      |=  message=@t
      ^-  packet:git-peer
      [%snapshot-error u.transfer message]
    =/  packet=packet:git-peer
      ?.  ?=([%ames %sage *] sign-arvo)
        (fail 'Fine repository read failed')
      =/  found=(unit peer-receive)
        (~(get by peer-receiving) u.transfer)
      ?~  found
        (fail 'Fine repository transfer is no longer active')
      =/  =sage:mess:ames  sage.sign-arvo
      ?.  =(ship.p.sage source.u.found)
        (fail 'Fine response came from the wrong ship')
      ?~  q.sage
        (fail 'Fine repository snapshot is unavailable')
      ?.  =(%noun p.q.sage)
        (fail 'Fine repository snapshot has the wrong mark')
      =/  decoded=(unit (map oid:git object:git))
        %-  mole
        |.(;;((map oid:git object:git) q.q.sage))
      ?~  decoded
        (fail 'Fine repository snapshot is malformed')
      [%snapshot u.transfer u.decoded]
    :_  this
    :~  [%pass /peer/snapshot/(scot %uv u.transfer) %agent [our.bowl %git] %poke %git-peer !>(packet)]
    ==
  ::
      [%peer %timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    =/  packet=packet:git-peer
      [%snapshot-error u.transfer 'Fine repository read timed out']
    :_  this
    :~  [%pass /peer/timeout-result/(scot %uv u.transfer) %agent [our.bowl %git] %poke %git-peer !>(packet)]
    ==
  ::
      [%peer %serve-timeout @ ~]
    ?.  ?=([%behn %wake *] sign-arvo)
      (on-arvo:def wire sign-arvo)
    ?^  error.sign-arvo  `this
    =/  transfer=(unit @uv)  (slaw %uv i.t.t.wire)
    ?~  transfer  `this
    `this(peer-serving (~(del by peer-serving) u.transfer))
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
      :*  repository.job
          desk-name.job
          branch.job
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
    :~  [%pass /clay-push %agent [our.bowl %git-clay] %poke %git-clay-action !>([desk-name.pending delta.pending])]
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
    =.  pending-clay  ~
    :_  this
    ?^  peer-response.pending
      =/  packet=packet:git-peer
        [%result transfer.u.peer-response.pending ok.result message.result]
      :~  [%pass /peer/result/(scot %uv transfer.u.peer-response.pending) %agent [ship.u.peer-response.pending %git] %poke %git-peer !>(packet)]
      ==
    ?:  api-response.pending
      =/  jon=json
        ?:  ok.result
          (pairs:enjs:format ~[['ok' b+%.y] ['commit' s+(oid-text:git-codec new-oid.pending)]])
        (pairs:enjs:format ~[['error' s+message.result]])
      %+  give-simple-payload:app:server  eyre-id.pending
      [[?:(ok.result 200 422) ~[['content-type' 'application/json; charset=utf-8'] ['cache-control' 'no-store']]] `(json-to-octs:server jon)]
    %+  give-simple-payload:app:server  eyre-id.pending
    (receive-payload 'ok' (receive-results commands.pending ok.result message.result))
  ::
      [%github @ ~]
    =/  request-id=(unit @uv)  (slaw %uv i.t.wire)
    ?~  request-id  `this
    =/  context=(unit github-request)  (~(get by github-in-flight) u.request-id)
    ?~  context  `this
    =.  github-in-flight  (~(del by github-in-flight) u.request-id)
    =/  fail
      |=  message=@t
      ^-  (quip card _this)
      =.  github-results
        (~(put by github-results) job.u.context [%.n %.n kind.u.context repository.u.context message])
      `this
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
      =/  origin=github-origin:git  [owner.u.context remote.u.context]
      =/  repo=repository:git
        ?~  existing
          :*  our.bowl
              public-read.u.context
              head.u.context
              refs.u.context
              combined
              (silt ~[our.bowl])
              ~
              ~
              ~
              ~
              ~
              `origin
              ~
              ~
              ~
          ==
        u.existing(head head.u.context, refs refs.u.context, objects combined, github-origin `origin)
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
      =/  repo=repository:git
        ?:  =(%issues kind.u.context)
          u.found(github-issues u.items)
        u.found(github-pulls u.items)
      =.  repositories  (~(put by repositories) repository.u.context repo)
      =/  label=@t  ?:(=(%issues kind.u.context) 'GitHub issues synchronized' 'GitHub pull requests synchronized')
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
