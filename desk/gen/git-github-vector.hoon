::  GitHub receive-pack request and report-status conformance vector.
::
/-  git
/+  git-codec, git-github, git-pack-decode, git-protocol
:-  %say
|=  *
:-  %noun
=/  blob=object:git  [%blob (text:git-codec 'github push\0a')]
=/  oid=oid:git  (object-oid:git-codec kind.blob data.blob)
=/  ref=@t  'refs/heads/main'
=/  request=octs  (receive-request:git-github ~ oid ref ~[blob])
=/  parsed=(unit receive-request:git)  (parse-receive-request:git-protocol request)
?>  ?=(^ parsed)
=/  commands=(list receive-command:git)  commands.u.parsed
?>  =(1 (lent commands))
?>  ?=(^ commands)
=/  command=receive-command:git  i.commands
?>  ?=(~ old.command)
?>  ?&  ?=(^ new.command)
        =(oid u.new.command)
        =(ref ref.command)
    ==
=/  decoded=(unit decoded-pack:git-pack-decode)
  (decode-pack-with:git-pack-decode pack.u.parsed ~)
?>  ?=(^ decoded)
?>  (~(has by objects.u.decoded) oid)
=/  success=octs  (receive-status:git-protocol 'ok' ~[[%.y ref '']])
=/  accepted=(unit [ok=? message=@t])  (receive-result:git-github success ref)
?>  ?&  ?=(^ accepted)
        ok.u.accepted
    ==
=/  rejected-body=octs
  (receive-status:git-protocol 'ok' ~[[%.n ref 'non-fast-forward']])
=/  rejected=(unit [ok=? message=@t])
  (receive-result:git-github rejected-body ref)
?>  ?&  ?=(^ rejected)
        !ok.u.rejected
        =('non-fast-forward' message.u.rejected)
    ==
%.y
