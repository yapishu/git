::  Native Git object database and Smart HTTP endpoint.
::
/-  git
/+  dbug, default-agent, git-clay, git-codec, git-graph, git-pack, git-pack-decode, git-protocol, git-storage, server
|%
+$  card  card:agent:gall
+$  lfs-spec  [oid=@t size=@ud]
+$  lfs-request  [eyre-id=@ta repository=@t oid=@t upload=lfs-upload:git]
+$  clay-push
  $:  eyre-id=@ta
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
--
::
%-  agent:dbug
=|  state-0:git
=*  state  -
=/  in-flight  *(map @uv lfs-request)
=/  request-count=@ud  0
=/  pending-clay  *(unit clay-push)
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %git]
  ==
::
++  on-save
  !>(state)
::
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =/  loaded=state-0:git  !<(state-0:git old)
  :_  this(state loaded, in-flight ~, request-count 0, pending-clay ~)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /git] %git]
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
  ==
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
    =/  binding=desk-binding:git  [desk-name.act branch.act ~ ~]
    `this(repositories (~(put by repositories) repository.act u.found(binding `binding)))
  ::
      %unbind-desk
    =/  found=(unit repository:git)  (~(get by repositories) repository.act)
    ?~  found  `this
    `this(repositories (~(put by repositories) repository.act u.found(binding ~)))
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
++  on-peek   on-peek:def
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
    %+  give-simple-payload:app:server  eyre-id.pending
    (receive-payload 'ok' (receive-results commands.pending ok.result message.result))
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
