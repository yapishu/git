::  Structural editing and three-way merge conformance.
::
/-  git
/+  git-codec, git-tree
:-  %say
|=  *
:-  %noun
=/  base=(unit [commit=oid:git objects=(map oid:git object:git)])
  (initial-commit:git-tree ~ /shared/txt (text:git-codec 'base\0a') ~zod ~2026.1.1 'base')
?>  ?=(^ base)
=/  ours=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.base commit.u.base /ours/txt (text:git-codec 'ours\0a') ~zod ~2026.1.1 'ours')
?>  ?=(^ ours)
=/  theirs=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.base commit.u.base /theirs/txt (text:git-codec 'theirs\0a') ~zod ~2026.1.1 'theirs')
?>  ?=(^ theirs)
=/  combined=(map oid:git object:git)
  (~(gas by objects.u.ours) ~(tap by objects.u.theirs))
=/  clean=(unit [commit=oid:git objects=(map oid:git object:git)])
  (merge-commit:git-tree combined commit.u.base commit.u.ours commit.u.theirs ~zod ~2026.1.1 'merge')
?>  ?=(^ clean)
=/  files=(unit (map path octs))
  (flatten-commit:git-tree objects.u.clean commit.u.clean)
=/  clean-ok=?
  ?&  ?=(^ files)
      (~(has by u.files) /shared/txt)
      (~(has by u.files) /ours/txt)
      (~(has by u.files) /theirs/txt)
  ==
=/  left=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.base commit.u.base /shared/txt (text:git-codec 'left\0a') ~zod ~2026.1.1 'left')
?>  ?=(^ left)
=/  right=(unit [commit=oid:git objects=(map oid:git object:git)])
  (edit-commit:git-tree objects.u.base commit.u.base /shared/txt (text:git-codec 'right\0a') ~zod ~2026.1.1 'right')
?>  ?=(^ right)
=/  conflict-objects=(map oid:git object:git)
  (~(gas by objects.u.left) ~(tap by objects.u.right))
=/  conflicted=(unit [commit=oid:git objects=(map oid:git object:git)])
  (merge-commit:git-tree conflict-objects commit.u.base commit.u.left commit.u.right ~zod ~2026.1.1 'conflict')
[(oid-text:git-codec commit.u.clean) clean-ok ?=(~ conflicted)]
