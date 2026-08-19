::  Pure persisted-repository migrations.
::
/-  git
|%
++  repository-1-to-2
  |=  repo=repository-1:git
  ^-  repository:git
  =/  native-pulls=(list native-pull:git)
    %+  turn  native-pulls.repo
    |=  pull=native-pull-1:git
    =/  source-ref=@t  ''
    =/  target-ref=@t  head.repo
    :*  number.pull
        source-ship.pull
        source-repository.pull
        source-ref
        target-ref
        title.pull
        state.pull
        head.pull
        base.pull
        comments.pull
    ==
  :*  owner.repo
      public-read.repo
      description.repo
      head.repo
      refs.repo
      protected-refs.repo
      objects.repo
      writers.repo
      ~
      write-token-hash.repo
      lfs-objects.repo
      lfs-uploads.repo
      lfs-locks.repo
      binding.repo
      peer-origin.repo
      github-origin.repo
      github-issues.repo
      github-pulls.repo
      native-pulls
      native-issues.repo
      releases.repo
      webhooks.repo
      incoming-hook.repo
      webhook-deliveries.repo
      upstream-updates.repo
      notification-events.repo
  ==
--
