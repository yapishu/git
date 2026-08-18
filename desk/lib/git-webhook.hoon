::  Signed webhook payloads and GitHub-compatible push parsing.
::
/-  git
/+  git-storage
|%
+$  push-notice
  $:  source=@t
      ref=@t
      before=@t
      after=@t
  ==
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
++  signature
  |=  [secret=@t body=octs]
  ^-  @t
  =/  digest=@
    (hmac-sha256:git-storage [(met 3 secret) secret] body)
  (rap 3 ~['sha256=' (hex-32:git-storage digest)])
::
++  verify
  |=  [secret=@t body=octs supplied=@t]
  ^-  ?
  =((signature secret body) supplied)
::
++  github-push
  |=  jon=json
  ^-  (unit push-notice)
  =/  ref=(unit @t)  (string-at 'ref' jon)
  =/  before=(unit @t)  (string-at 'before' jon)
  =/  after=(unit @t)  (string-at 'after' jon)
  ?.  ?&(?=(^ ref) ?=(^ before) ?=(^ after))  ~
  =/  source=@t
    =/  repository=(unit json)  (json-at 'repository' jon)
    ?~  repository  'github'
    =/  full-name=(unit @t)  (string-at 'full_name' u.repository)
    ?~(full-name 'github' u.full-name)
  `[source u.ref u.before u.after]
--
