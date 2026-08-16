::  A stock Git-generated non-delta pack fixture.
::
/-  git
/+  git-codec, git-inflate, git-pack-decode
:-  %say
|=  *
=/  source=octs  [760 0x3c5c.3f6f.65e0.db9f.af7c.10f3.8b01.e17a.27f3.5982.870f.63ea.007b.8647.f27b.a976.c13b.3e67.2373.abcb.02fe.f586.3bbf.b861.4dcb.d575.f174.7572.0851.3133.3030.3433.9c78.02a5.5407.6551.005c.d9c9.8905.d105.4e4d.4a28.554b.2cc9.2c4b.cb9c.7801.b485.1543.da2f.d4f4.2fe0.d71c.1316.e148.117f.eded.d419.7f53.ce55.547e.ba7d.e8a6.793b.527c.fabe.c7a9.a197.8328.7ed7.8e39.2498.2b30.5d7f.63b3.b535.cbc2.d865.2aed.209d.6463.2621.fa4c.d38e.f538.7e7b.8def.8b8e.bc9b.3cba.051a.efcf.b0d5.eb64.2ee1.3f04.e41c.4e11.ccf2.6a61.0cb0.b1cf.6fd5.e435.0724.dcbc.2a4c.6213.1251.2754.23b3.6f9c.c9ab.d34c.410d.9fb6.ac1d.795b.4796.ba8f.d9b6.cfdb.02b7.c377.f72b.7cdc.a355.7268.ceb2.8c9f.af73.6ead.77a4.9a97.ba2c.ba28.9134.ed87.772b.6d26.c028.596a.cff6.5bdb.d236.8b4e.de37.4a63.e68b.798e.63b1.73f4.7aea.f76e.a5ee.ad36.550a.a11b.76ea.e662.3b0e.e744.5de9.0a91.3b38.7b81.435c.316b.910e.3504.bceb.530d.49fe.f7e8.b0a2.d839.9fd9.8f16.494a.b3e5.ee13.5587.3758.c87c.095a.44f5.b19e.c31d.2a5c.6d62.0814.7293.6448.2d0e.5605.63ee.b1eb.6c5c.e3bd.ccee.553b.3379.2694.665f.60cc.343c.f69d.0f71.7556.3b5d.9aea.f9c8.ccc6.b16b.58e8.c367.de4e.cef4.daa7.3c3d.9aae.b5c7.9a87.a92d.e45e.5732.b12f.57f3.a907.1f90.2307.ae05.ce2a.53da.f6ad.2f2b.9038.5132.ec28.0fb4.2228.0a23.cb0a.6b27.66c3.b72c.44eb.6b95.7d8a.88bd.bec9.2c4f.6234.9b78.c467.83b5.3846.1233.1bae.a36c.e448.da72.c365.1a7f.5add.54c0.a737.fa7e.e2b4.524a.b4d0.f34a.1815.535a.629d.da34.83db.07b5.fb59.dcba.8774.4587.3e5e.bac0.cc94.2b55.1455.5be0.9f00.500a.727f.eb38.3f15.b416.7817.42e0.6cb4.3aa9.6fd7.c02e.278b.e8a4.abff.4109.834d.7695.34d3.cd17.c196.46e2.d320.9288.d80f.f671.ae31.db86.fa35.f4dc.7344.fdc7.c8be.4c0b.df01.27a3.e73f.0013.0486.0803.7652.2fc5.4ca2.6508.c518.a4e5.3925.a656.5861.2679.a328.364f.8169.4a10.e232.c71f.3cc4.0840.647d.1d2a.516a.9523.a4b7.7777.7744.9c7d.3f06.6dc6.4cc6.81a1.8ec3.6c06.c007.8343.0055.c948.ccc6.3fad.ef45.3cf7.8414.4a9b.cec9.92a5.9c78.369c.0300.0000.0200.0000.4b43.4150]
=/  header=(unit [kind=object-kind:git size=@ud next=@ud])
  (entry-header:git-pack-decode source 12)
=/  inflated=(unit inflated:git-inflate)
  ?~  header  ~
  (zlib-inflate:git-inflate (slice:git-codec source next.u.header (sub 740 next.u.header)) size.u.header)
=/  decoded=(unit decoded-pack:git-pack-decode)
  (decode-pack:git-pack-decode source)
=/  second-offset=@ud
  ?~  header  0
  ?~  inflated  0
  (add next.u.header consumed.u.inflated)
=/  second=(unit [kind=object-kind:git size=@ud next=@ud])
  (entry-header:git-pack-decode source second-offset)
=/  second-inflated=(unit inflated:git-inflate)
  ?~  second  ~
  (zlib-inflate:git-inflate (slice:git-codec source next.u.second (sub 740 next.u.second)) size.u.second)
=/  third-offset=@ud
  ?~  second  0
  ?~  second-inflated  0
  (add next.u.second consumed.u.second-inflated)
=/  third=(unit [kind=object-kind:git size=@ud next=@ud])
  (entry-header:git-pack-decode source third-offset)
=/  third-inflated=(unit inflated:git-inflate)
  ?~  third  ~
  (zlib-inflate:git-inflate (slice:git-codec source next.u.third (sub 740 next.u.third)) size.u.third)
:-  %stock-pack
:*  header=?=(^ header)
    first-inflated=?=(^ inflated)
    first-consumed=?:(?=(^ inflated) consumed.u.inflated 0)
    second-offset=second-offset
    second=?=(^ second)
    second-inflated=?=(^ second-inflated)
    second-consumed=?:(?=(^ second-inflated) consumed.u.second-inflated 0)
    third-offset=third-offset
    third=?=(^ third)
    third-inflated=?=(^ third-inflated)
    third-consumed=?:(?=(^ third-inflated) consumed.u.third-inflated 0)
    decoded=?=(^ decoded)
==
