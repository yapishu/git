import test from 'node:test'
import assert from 'node:assert/strict'
import { relativeTime } from './format.js'

test('formats commit timestamps as compact relative times', () => {
  const now = 2_000_000_000
  assert.equal(relativeTime(now - 20, now), 'just now')
  assert.equal(relativeTime(now - 120, now), '2 minutes ago')
  assert.equal(relativeTime(now - 10_800, now), '3 hours ago')
  assert.equal(relativeTime(now - 172_800, now), '2 days ago')
})

test('does not render invalid commit timestamps', () => {
  assert.equal(relativeTime('', 2_000_000_000), '')
  assert.equal(relativeTime('not-a-time', 2_000_000_000), '')
})
