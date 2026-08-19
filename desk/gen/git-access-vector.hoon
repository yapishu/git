::  Native repository read-access policy vectors.
::
/+  git-access
:-  %say
|=  *
:-  %noun
=/  owner=@p  ~zod
=/  reader=@p  ~nec
=/  writer=@p  ~bud
=/  stranger=@p  ~wes
=/  readers=(set @p)  (silt ~[reader])
=/  writers=(set @p)  (silt ~[writer])
?>  (can-read:git-access %.y owner readers writers stranger)
?>  (can-read:git-access %.n owner readers writers owner)
?>  (can-read:git-access %.n owner readers writers reader)
?>  (can-read:git-access %.n owner readers writers writer)
?>  !(can-read:git-access %.n owner readers writers stranger)
%.y
