::  Webhook signature and GitHub push parsing conformance vector.
::
/-  git
/+  git-webhook
:-  %say
|=  *
:-  %noun
=/  body=@t  'The quick brown fox jumps over the lazy dog'
=/  bytes=octs  [(met 3 body) body]
=/  expected=@t
  'sha256=f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8'
?>  =((signature:git-webhook 'key' bytes) expected)
?>  (verify:git-webhook 'key' bytes expected)
?>  !(verify:git-webhook 'wrong-key' bytes expected)
=/  repository=json
  [%o (my ~[['full_name' [%s 'example/project']]])]
=/  payload=json
  :-  %o
  %-  my
  :~  ['ref' [%s 'refs/heads/main']]
      ['before' [%s '0000000000000000000000000000000000000000']]
      ['after' [%s '1111111111111111111111111111111111111111']]
      ['repository' repository]
  ==
=/  notice=(unit push-notice:git-webhook)
  (github-push:git-webhook payload)
?>  ?=(^ notice)
?>  =('example/project' source.u.notice)
?>  =('refs/heads/main' ref.u.notice)
?>  =('0000000000000000000000000000000000000000' before.u.notice)
?>  =('1111111111111111111111111111111111111111' after.u.notice)
%.y
