::  Signature Version 4 client for the ship-configured object store.
|%
+$  credentials
  $:  endpoint=@t
      access-key-id=@t
      secret-access-key=@t
  ==
+$  configuration
  $:  current-bucket=@t
      region=@t
  ==
+$  signed-request
  $:  url=@t
      headers=(list [@t @t])
  ==
::
++  hmac-sha256
  |=  [key=octs message=octs]
  ^-  @
  =/  block-size=@ud  64
  =/  material=octs
    ?:  (gth p.key block-size)  [32 (shay key)]  key
  =/  padded=@  q.material
  =/  inner-key=@  (mix padded (fil 3 block-size 0x36))
  =/  outer-key=@  (mix padded (fil 3 block-size 0x5c))
  =/  inner=@  (shay [(add block-size p.message) (cat 3 inner-key q.message)])
  (shay [(add block-size 32) (cat 3 outer-key inner)])
::
++  hmac-text
  |=  [key=octs message=@t]
  ^-  @
  (hmac-sha256 key [(met 3 message) message])
::
++  signing-key
  |=  [secret=@t date=@t region=@t]
  ^-  @
  =/  first=@t  (rap 3 ~['AWS4' secret])
  =/  date-key=@  (hmac-text [(met 3 first) first] date)
  =/  region-key=@  (hmac-text [32 date-key] region)
  =/  service-key=@  (hmac-text [32 region-key] 's3')
  (hmac-text [32 service-key] 'aws4_request')
::
++  hex-32
  |=  value=@
  ^-  @t
  =/  alphabet=@t  '0123456789abcdef'
  =/  index=@ud  0
  =/  out=tape  ~
  |-
  ?:  =(index 32)  (crip out)
  =/  byte=@ud  (cut 3 [index 1] value)
  =/  high=@tD  (cut 3 [(div byte 16) 1] alphabet)
  =/  low=@tD   (cut 3 [(mod byte 16) 1] alphabet)
  $(index +(index), out (snoc (snoc out high) low))
::
++  two-digits
  |=  value=@ud
  ^-  tape
  ?:  (lth value 10)
    (weld "0" (a-co:co value))
  (a-co:co value)
::
++  date-stamp
  |=  now=@da
  ^-  @t
  =/  date  (yore now)
  (crip (weld (a-co:co y.date) (weld (two-digits m.date) (two-digits d.t.date))))
::
++  amz-date
  |=  now=@da
  ^-  @t
  =/  date  (yore now)
  %-  crip
  %+  weld  (a-co:co y.date)
  %+  weld  (two-digits m.date)
  %+  weld  (two-digits d.t.date)
  %+  weld  "T"
  %+  weld  (two-digits h.t.date)
  %+  weld  (two-digits m.t.date)
  (weld (two-digits s.t.date) "Z")
::
++  strip-prefix
  |=  [prefix=tape value=tape]
  ^-  tape
  ?:  =(prefix (scag (lent prefix) value))
    (slag (lent prefix) value)
  value
::
++  endpoint-host
  |=  endpoint=@t
  ^-  @t
  =/  value=tape  (trip endpoint)
  =.  value  (strip-prefix "https://" value)
  =.  value  (strip-prefix "http://" value)
  =/  slash=(unit @ud)  (find "/" value)
  (crip ?~(slash value (scag u.slash value)))
::
++  endpoint-scheme
  |=  endpoint=@t
  ^-  @t
  ?:  =("http://" (scag 7 (trip endpoint)))  'http://'
  'https://'
::
++  uri-encode
  |=  text=@t
  ^-  @t
  =/  input=tape  (trip text)
  =/  output=tape  ~
  |-
  ?~  input  (crip output)
  =/  char=@tD  i.input
  =/  unreserved=?
    ?|  &((gte char 'A') (lte char 'Z'))
        &((gte char 'a') (lte char 'z'))
        &((gte char '0') (lte char '9'))
        =(char '-')  =(char '_')  =(char '.')  =(char '~')  =(char '/')
    ==
  ?:  unreserved
    $(input t.input, output (snoc output char))
  =/  digit=$-(@ud @tD)
    |=  value=@ud
    ?:  (lth value 10)  (add '0' value)
    (add 'A' (sub value 10))
  $(input t.input, output (weld output ~['%' (digit (div char 16)) (digit (mod char 16))]))
::
++  sign-hash
  |=  $:  method=@t
          content-type=@t
          payload-hash=@t
          =credentials
          =configuration
          object-key=@t
          now=@da
      ==
  ^-  signed-request
  =/  host=@t  (endpoint-host endpoint.credentials)
  =/  path=@t  (rap 3 ~['/' current-bucket.configuration '/' object-key])
  =/  canonical-uri=@t  (uri-encode path)
  =/  url=@t  (rap 3 ~[(endpoint-scheme endpoint.credentials) host canonical-uri])
  =/  timestamp=@t  (amz-date now)
  =/  date=@t  (date-stamp now)
  =/  signed-headers=@t  'host;x-amz-content-sha256;x-amz-date'
  =/  canonical-headers=@t
    %+  rap  3
    :~  'host:'  host  '\0a'
        'x-amz-content-sha256:'  payload-hash  '\0a'
        'x-amz-date:'  timestamp  '\0a'
    ==
  =/  canonical-request=@t
    %+  rap  3
    :~  method  '\0a'  canonical-uri  '\0a\0a'
        canonical-headers  '\0a'  signed-headers  '\0a'  payload-hash
    ==
  =/  scope=@t  (rap 3 ~[date '/' region.configuration '/s3/aws4_request'])
  =/  string-to-sign=@t
    %+  rap  3
    :~  'AWS4-HMAC-SHA256\0a'  timestamp  '\0a'  scope  '\0a'
        (hex-32 (shay [(met 3 canonical-request) canonical-request]))
    ==
  =/  key=@  (signing-key secret-access-key.credentials date region.configuration)
  =/  signature=@t  (hex-32 (hmac-text [32 key] string-to-sign))
  =/  authorization=@t
    %+  rap  3
    :~  'AWS4-HMAC-SHA256 Credential='  access-key-id.credentials  '/'  scope
        ', SignedHeaders='  signed-headers  ', Signature='  signature
    ==
  :_  :~  ['content-type' content-type]
          ['x-amz-content-sha256' payload-hash]
          ['x-amz-date' timestamp]
          ['authorization' authorization]
      ==
  url
::
++  sign
  |=  $:  method=@t
          content-type=@t
          body=octs
          =credentials
          =configuration
          object-key=@t
          now=@da
      ==
  (sign-hash method content-type (hex-32 (shay body)) credentials configuration object-key now)
--
