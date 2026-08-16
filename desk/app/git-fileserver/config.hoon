|%
++  web-root  ^-  (list @t)
  /apps/git
++  file-root  ^-  path
  /web
++  index  ^-  $@(~ [~ path])
  `/index/html
++  extension  ^-  ?(%need %path %fall)
  %fall
++  auth  ^-  $@(? [? (list [path ?])])
  &
--
