::  Native peer repository read-access policy.
::
|%
++  can-read
  |=  [public=? owner=@p readers=(set @p) writers=(set @p) requester=@p]
  ^-  ?
  ?|  public
      =(requester owner)
      (~(has in readers) requester)
      (~(has in writers) requester)
  ==
--
