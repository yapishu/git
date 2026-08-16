::  Clay desk to Git commit and back again.
::
/-  git
/+  git-clay, git-codec
:-  %say
|=  *
:-  %noun
=/  files=(map path octs)
  %-  malt
  :~  [`path`/app/demo/hoon (text:git-codec ':: demo\0a[%zuse 409]\0a')]
      [`path`/sys/kelvin (text:git-codec '[%zuse 409]\0a')]
      [`path`/web/index/html (text:git-codec '<h1>demo</h1>\0a')]
  ==
=/  snap=(unit [commit=oid:git objects=(map oid:git object:git)])
  (snapshot:git-clay files ~ ~ ~zod ~2026.1.1 'Publish %demo from Clay')
?>  ?=(^ snap)
=/  round-trip=(unit (map path octs))
  (flatten-commit:git-clay objects.u.snap commit.u.snap)
[(oid-text:git-codec commit.u.snap) =(round-trip `files)]
