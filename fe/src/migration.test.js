import test from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, readFileSync } from 'node:fs'

const surface = readFileSync(
  new URL('../../desk/sur/git.hoon', import.meta.url),
  'utf8',
)
const agent = readFileSync(
  new URL('../../desk/app/urgit.hoon', import.meta.url),
  'utf8',
)
const migrationUrl = new URL('../../desk/lib/git-migrate.hoon', import.meta.url)
const vectorUrl = new URL('../../desk/gen/git-migration-vector.hoon', import.meta.url)

function sourceBlock(source, start, end) {
  const startAt = source.indexOf(start)
  assert.notEqual(startAt, -1, `missing ${start}`)
  const endAt = source.indexOf(end, startAt + start.length)
  assert.notEqual(endAt, -1, `missing ${end} after ${start}`)
  return source.slice(startAt, endAt)
}

function moldFields(block) {
  return [...block.matchAll(/^\s+(?:\$:\s+)?([a-z][a-z0-9-]*)=/gm)].map(
    ([, field]) => field,
  )
}

test('published repository-1 remains reader-free and state-2 owns the current repository mold', () => {
  const repository1 = sourceBlock(surface, '+$  repository-1', '+$  state-1')
  assert.deepEqual(moldFields(repository1), [
    'owner',
    'public-read',
    'description',
    'head',
    'refs',
    'protected-refs',
    'objects',
    'writers',
    'write-token-hash',
    'lfs-objects',
    'lfs-uploads',
    'lfs-locks',
    'binding',
    'peer-origin',
    'github-origin',
    'github-issues',
    'github-pulls',
    'native-pulls',
    'native-issues',
    'releases',
    'webhooks',
    'incoming-hook',
    'webhook-deliveries',
    'upstream-updates',
    'notification-events',
  ])

  const state1 = sourceBlock(surface, '+$  state-1', '+$  state-2')
  assert.match(state1, /\$:\s+%1/)
  assert.match(state1, /repositories=\(map @t repository-1\)/)

  const state2 = sourceBlock(surface, '+$  state-2', '+$  action')
  assert.match(state2, /\$:\s+%2/)
  assert.match(state2, /repositories=\(map @t repository\)/)
})

test('published pull mold is preserved while current pulls pin source and target refs', () => {
  const publishedPull = sourceBlock(surface, '+$  native-pull-1\n', '+$  native-pull\n')
  assert.deepEqual(moldFields(publishedPull), [
    'number',
    'source-ship',
    'source-repository',
    'title',
    'state',
    'head',
    'base',
    'comments',
  ])

  const currentPull = sourceBlock(surface, '+$  native-pull\n', '+$  issue-comment')
  assert.deepEqual(moldFields(currentPull), [
    'number',
    'source-ship',
    'source-repository',
    'source-ref',
    'target-ref',
    'title',
    'state',
    'head',
    'base',
    'comments',
  ])

  const repository0 = sourceBlock(surface, '+$  repository-0', '+$  repository-1')
  const repository1 = sourceBlock(surface, '+$  repository-1', '+$  state-1')
  const currentRepository = sourceBlock(surface, '+$  repository', '+$  state-0')
  assert.match(repository0, /native-pulls=\(list native-pull-1\)/)
  assert.match(repository1, /native-pulls=\(list native-pull-1\)/)
  assert.match(currentRepository, /native-pulls=\(list native-pull\)/)
})

test('on-load explicitly migrates zero and one while accepting two', () => {
  assert.match(agent, /=\|  state-2:git/)
  const onLoad = sourceBlock(agent, '++  on-load', '++  on-poke')
  assert.match(onLoad, /\?\+\s+-\.q\.old\s+!!/)
  assert.ok(
    onLoad.includes(
      '%0  (migrate-state-1 (migrate-state-0 !<(state-0:git old)))',
    ),
  )
  assert.ok(onLoad.includes('%1  (migrate-state-1 !<(state-1:git old))'))
  assert.ok(onLoad.includes('%2  !<(state-2:git old)'))
})

test('pure repository migration seam and non-empty Hoon vector are present', () => {
  assert.ok(existsSync(migrationUrl), 'missing desk/lib/git-migrate.hoon')
  assert.ok(existsSync(vectorUrl), 'missing desk/gen/git-migration-vector.hoon')
  if (!existsSync(migrationUrl) || !existsSync(vectorUrl)) return

  const migration = readFileSync(migrationUrl, 'utf8')
  const vector = readFileSync(vectorUrl, 'utf8')
  assert.match(migration, /\+\+  repository-1-to-2/)
  assert.match(migration, /repo=repository-1:git/)
  assert.match(migration, /\^-  repository:git/)
  assert.match(vector, /repository-1-to-2:git-migrate/)
  assert.match(vector, /old=repository-1:git/)
  assert.match(vector, /refs=\(map @t oid:git\)/)
  assert.match(vector, /objects=\(map oid:git object:git\)/)
  assert.match(vector, /notification-events=\(set notification-event:git\)/)
  assert.match(vector, /\?>(?:\s+)?=\(~ readers\.migrated\)/)
  assert.match(migration, /turn\s+native-pulls\.repo/)
  assert.match(migration, /source-ref=@t\s+''/)
  assert.match(migration, /target-ref=@t\s+head\.repo/)
  assert.match(vector, /native-pulls=\(list native-pull-1:git\)/)
  assert.match(vector, /=\('' source-ref\.migrated-pull\)/)
  assert.match(vector, /=\(head\.old target-ref\.migrated-pull\)/)
  assert.match(vector, /=\(comments\.old-pull comments\.migrated-pull\)/)
})
