::  Persisted repository %1 to %2 migration vector.
::
/-  git
/+  git-migrate
:-  %say
|=  *
:-  %noun
=/  oid=oid:git  0x1234
=/  when=@da  ~2026.8.19
=/  refs=(map @t oid:git)
  (my ~[['refs/heads/main' oid]])
=/  protected-refs=(set @t)
  (silt ~['refs/heads/main'])
=/  objects=(map oid:git object:git)
  (my ~[[oid [%blob [4 0x7473.6574]]]])
=/  writers=(set @p)
  (silt ~[~zod ~nec])
=/  lfs-objects=(map @t lfs-object:git)
  (my ~[['sha256:fixture' [4 'objects/fixture']]])
=/  lfs-uploads=(map @t lfs-upload:git)
  (my ~[['sha256:upload' [8 'uploads/fixture' when]]])
=/  lfs-locks=(map @ud lfs-lock:git)
  (my ~[[7 [7 'src/main.hoon' '~zod' when]]])
=/  binding=(unit desk-binding:git)
  `[%urgit 'refs/heads/main' `12 `oid ~[[12 oid %git-to-clay when]]]
=/  peer-origin=(unit peer-origin:git)
  `[~nec 'upstream']
=/  github-origin=(unit github-origin:git)
  `['nousresearch' 'urgit']
=/  github-issues=(list forge-item:git)
  ~[[1 'Migration issue' 'open' 'https://example.test/issues/1' 'zod' %.n]]
=/  github-pulls=(list forge-item:git)
  ~[[2 'Migration pull' 'open' 'https://example.test/pulls/2' 'nec' %.y]]
=/  native-pulls=(list native-pull-1:git)
  :~  :-  3
      :*  ~nec
          'fork'
          'Native pull'
          %open
          oid
          oid
          ~[[1 ~zod 'review' when `'src/main.hoon' `7 `%head %.n]]
      ==
  ==
=/  native-issues=(list native-issue:git)
  :~  :-  4
      :*  ~nec
          'Native issue'
          'body'
          %open
          (silt ~['migration'])
          (silt ~[~zod])
          when
          when
          ~[[1 ~zod 'issue reply' when]]
      ==
  ==
=/  releases=(map @t release:git)
  (my ~[['v2' ['v2' 'Migration release' 'notes' ~zod when]]])
=/  webhooks=(map @ud webhook:git)
  (my ~[[1 [1 'https://example.test/hook' 'secret' (silt ~[`webhook-event:git`%push `webhook-event:git`%issue]) %.y]]])
=/  incoming-hook=(unit incoming-hook:git)
  `['incoming-secret' %.y]
=/  webhook-deliveries=(list webhook-delivery:git)
  ~[[`@uv`10 1 %push %success 204 'delivered' when]]
=/  upstream-updates=(list upstream-update:git)
  ~[[`@uv`11 'github' 'refs/heads/main' 'before' 'after' when]]
=/  notification-events=(set notification-event:git)
  (silt ~[`notification-event:git`%issue `notification-event:git`%pull-request])
=/  old=repository-1:git
  :*  ~zod
      %.n
      'migration fixture'
      'refs/heads/main'
      refs
      protected-refs
      objects
      writers
      `0xdead.beef
      lfs-objects
      lfs-uploads
      lfs-locks
      binding
      peer-origin
      github-origin
      github-issues
      github-pulls
      native-pulls
      native-issues
      releases
      webhooks
      incoming-hook
      webhook-deliveries
      upstream-updates
      notification-events
  ==
=/  migrated=repository:git
  (repository-1-to-2:git-migrate old)
=/  old-pull=native-pull-1:git  (snag 0 native-pulls.old)
=/  migrated-pull=native-pull:git  (snag 0 native-pulls.migrated)
=/  expected=repository:git
  :*  owner.old
      public-read.old
      description.old
      head.old
      refs.old
      protected-refs.old
      objects.old
      writers.old
      ~
      write-token-hash.old
      lfs-objects.old
      lfs-uploads.old
      lfs-locks.old
      binding.old
      peer-origin.old
      github-origin.old
      github-issues.old
      github-pulls.old
      :~  :*  number.old-pull
              source-ship.old-pull
              source-repository.old-pull
              ''
              head.old
              title.old-pull
              state.old-pull
              head.old-pull
              base.old-pull
              comments.old-pull
          ==
      ==
      native-issues.old
      releases.old
      webhooks.old
      incoming-hook.old
      webhook-deliveries.old
      upstream-updates.old
      notification-events.old
  ==
?>  =(expected migrated)
?>  =(~ readers.migrated)
?>  =('' source-ref.migrated-pull)
?>  =(head.old target-ref.migrated-pull)
?>  =(number.old-pull number.migrated-pull)
?>  =(source-ship.old-pull source-ship.migrated-pull)
?>  =(source-repository.old-pull source-repository.migrated-pull)
?>  =(title.old-pull title.migrated-pull)
?>  =(state.old-pull state.migrated-pull)
?>  =(head.old-pull head.migrated-pull)
?>  =(base.old-pull base.migrated-pull)
?>  =(comments.old-pull comments.migrated-pull)
%.y
