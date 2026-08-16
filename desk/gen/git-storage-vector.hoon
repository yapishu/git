/+  git-storage
:-  %say
|=  *
:-  %noun
=/  credentials=credentials:git-storage
  ['https://objects.example' 'EXAMPLEKEY' 'example-secret']
=/  configuration=configuration:git-storage  ['git-data' 'local-1']
=/  request=signed-request:git-storage
  %:  sign-hash:git-storage
    'PUT'
    'application/octet-stream'
    'ae85361c4307a95c463c809a426a2bc2b69f7c8db52c5a4122cfb2d4b9d5f205'
    credentials
    configuration
    'git-lfs/~zod/sample/ae85361c4307a95c463c809a426a2bc2b69f7c8db52c5a4122cfb2d4b9d5f205'
    ~2026.8.16..12.34.56
  ==
[ url=url.request
  has-authorization=?=(^ (get-header:http 'authorization' headers.request))
  has-payload-hash=?=(^ (get-header:http 'x-amz-content-sha256' headers.request))
  has-date=?=(^ (get-header:http 'x-amz-date' headers.request))
]
