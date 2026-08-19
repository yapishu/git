import test from 'node:test'
import assert from 'node:assert/strict'
import { remoteCacheIsUsable, remoteCacheKey } from './remoteCache.js'

test('keys remote repository cache entries by ship and repository', () => {
  assert.equal(remoteCacheKey('~sampel-palnet', 'docs'), '~sampel-palnet/docs')
})

test('keeps complete remote repository cache entries without automatic expiry', () => {
  const entry = { cachedAt: 1, revision: '0v1', data: { repository: { name: 'docs' } } }

  assert.equal(remoteCacheIsUsable(entry), true)
  assert.equal(remoteCacheIsUsable({ ...entry, cachedAt: 0 }), true)
  assert.equal(remoteCacheIsUsable({ ...entry, revision: '' }), false)
})
