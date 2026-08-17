::  Shallow upload-pack parsing and depth-limited graph traversal.
::
/-  git
/+  git-codec, git-graph, git-protocol, git-tree
:-  %say
|=  *
:-  %noun
=/  first=(unit [commit=oid:git objects=(map oid:git object:git)])
  (initial-commit:git-tree ~ /readme/txt (text:git-codec 'one\0a') ~zod ~2026.1.1 'one')
?>  ?=(^ first)
=/  second=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.first commit.u.first /readme/txt (text:git-codec 'two\0a') ~zod ~2026.1.2 'two')
?>  ?=(^ second)
=/  third=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.second commit.u.second /readme/txt (text:git-codec 'three\0a') ~zod ~2026.1.3 'three')
?>  ?=(^ third)
=/  limited=(unit shallow-result:git-graph)
  (reachable-depth:git-graph objects.u.third (silt ~[commit.u.third]) 2)
?>  ?=(^ limited)
=/  request=octs
  %-  join-all:git-codec
  :~  (en-pkt:git-codec [%data (text:git-codec 'command=fetch\0a')])
      (en-pkt:git-codec [%delim ~])
      (en-pkt:git-codec [%data (text:git-codec (rap 3 ~['want ' (oid-text:git-codec commit.u.third) ' shallow\0a']))])
      (en-pkt:git-codec [%data (text:git-codec (rap 3 ~['shallow ' (oid-text:git-codec commit.u.second) '\0a']))])
      (en-pkt:git-codec [%data (text:git-codec 'deepen 2\0a')])
      (en-pkt:git-codec [%data (text:git-codec 'deepen-relative\0a')])
      (en-pkt:git-codec [%data (text:git-codec 'filter blob:limit=12\0a')])
      (en-pkt:git-codec [%data (text:git-codec 'done\0a')])
      (en-pkt:git-codec [%flush ~])
  ==
=/  parsed=(unit upload-request:git)  (parse-upload-request:git-protocol request)
?>  ?=(^ parsed)
?>  ?=(^ depth.u.parsed)
=/  command=(unit @tas)  (v2-command:git-protocol request)
?>  ?=(^ command)
=/  filter=(unit upload-filter:git)  filter.u.parsed
?>  ?=(^ filter)
?>  ?=(%blob-limit -.u.filter)
=/  parsed-depth=@ud  u.depth.u.parsed
:~  (~(has in reachable.u.limited) commit.u.third)
    (~(has in reachable.u.limited) commit.u.second)
    !(~(has in reachable.u.limited) commit.u.first)
    (~(has in boundaries.u.limited) commit.u.second)
    =(2 parsed-depth)
    deepen-relative.u.parsed
    done.u.parsed
    (~(has in shallow.u.parsed) commit.u.second)
    =(12 limit.u.filter)
    =(%fetch u.command)
==
