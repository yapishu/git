::  Stored, fixed-Huffman, and dynamic-Huffman zlib vectors.
::
/+  git-codec, git-inflate, git-pack
:-  %say
|=  *
:-  %noun
=/  fixed-line=octs
  (text:git-codec 'The quick brown fox jumps over the lazy dog. ')
=/  fixed-raw=octs
  (join-all:git-codec (turn (gulf 1 20) |=(* fixed-line)))
=/  fixed-zlib=octs
  [61 0x1c.43a5.4701.8ada.98aa.3c55.1e2a.8c84.29eb.a7e4.a42a.5556.24e7.4a01.2852.2d4b.2fc8.5628.2dcd.2ac8.50af.cb48.53cf.2fca.2a48.56ce.4ccd.2c28.5548.c90b.0178]
=/  dynamic-line=octs
  (text:git-codec 'alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega\0a')
=/  dynamic-raw=octs
  (join-all:git-codec (turn (gulf 1 40) |=(* dynamic-line)))
=/  dynamic-zlib=octs
  [126 0x5bf9.412a.0bfb.73fe.cb65.b2d9.6cb6.5b2d.96cb.65b2.d96c.b65b.2d96.cb65.17cc.a72c.6d11.1ec3.1795.efe6.2706.cf1c.b6e3.a55c.370b.8afd.b37a.18f1.39c4.da20.edb6.544e.e9bd.23d6.caca.3158.359f.13f6.adbf.2751.aa47.11ad.9910.696c.42f5.63cf.a121.2166.144b.d0ca.fa7a.10d8.9163.b516.c624.9b57.314f.7dd0.040c.30c3.0a4b.cded.9c78]
=/  stored-zlib=octs  (zlib-store:git-pack dynamic-raw)
=/  fixed=(unit inflated:git-inflate)  (zlib-inflate:git-inflate fixed-zlib p.fixed-raw)
=/  dynamic=(unit inflated:git-inflate)  (zlib-inflate:git-inflate dynamic-zlib p.dynamic-raw)
=/  stored=(unit inflated:git-inflate)  (zlib-inflate:git-inflate stored-zlib p.dynamic-raw)
[ fixed=?&(?=(^ fixed) =(data.u.fixed fixed-raw) =(consumed.u.fixed p.fixed-zlib))
  dynamic=?&(?=(^ dynamic) =(data.u.dynamic dynamic-raw) =(consumed.u.dynamic p.dynamic-zlib))
  stored=?&(?=(^ stored) =(data.u.stored dynamic-raw) =(consumed.u.stored p.stored-zlib))
]
