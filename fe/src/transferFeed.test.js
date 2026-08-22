import test from 'node:test'
import assert from 'node:assert/strict'
import { emptyFeed, mergeFeed, findTransfer, activeActivity, transferFraction, transferBasis } from './transferFeed.js'
import { channelUrl, subscribeAction, ackAction } from './channel.js'

test('an empty feed carries all three arrays', () => {
  assert.deepEqual(emptyFeed(), { activity: [], notifications: [], transfers: [] })
})

test('the activity poll shape fills activity and notifications only', () => {
  const feed = mergeFeed(emptyFeed(), { activity: [{ id: 'a' }], notifications: [{ id: 'n' }] })
  assert.deepEqual(feed.activity, [{ id: 'a' }])
  assert.deepEqual(feed.notifications, [{ id: 'n' }])
  assert.deepEqual(feed.transfers, [])
})

test('a partial payload keeps the keys it omits', () => {
  const first = mergeFeed(emptyFeed(), { activity: [{ id: 'a' }], notifications: [], transfers: [{ transfer: 't' }] })
  const second = mergeFeed(first, { activity: [{ id: 'b' }], notifications: [] })
  assert.deepEqual(second.transfers, [{ transfer: 't' }])
  assert.deepEqual(second.activity, [{ id: 'b' }])
})

test('the subscription fact shape fills all three at once', () => {
  const fact = { activity: [{ id: 'a', status: 'active' }], notifications: [], transfers: [{ transfer: 't' }] }
  const feed = mergeFeed(emptyFeed(), fact)
  assert.equal(activeActivity(feed).length, 1)
  assert.deepEqual(findTransfer(feed, 't'), { transfer: 't' })
  assert.equal(findTransfer(feed, 'missing'), null)
})

test('a junk payload leaves the feed untouched', () => {
  const feed = mergeFeed(emptyFeed(), { activity: [{ id: 'a' }] })
  assert.deepEqual(mergeFeed(feed, null), feed)
  assert.deepEqual(mergeFeed(feed, 'nonsense'), feed)
  assert.deepEqual(mergeFeed(feed, { activity: 'nonsense' }), feed)
})

test('progress prefers fragments, then pages, then objects', () => {
  assert.equal(transferFraction({ fineFragmentsReceived: 3, fineFragmentsTotal: 12, completedPages: 1, pages: 2 }), 0.25)
  assert.equal(transferBasis({ fineFragmentsReceived: 3, fineFragmentsTotal: 12 }), 'fragments')
  assert.equal(transferFraction({ fineFragmentsTotal: 0, completedPages: 1, pages: 4 }), 0.25)
  assert.equal(transferBasis({ completedPages: 1, pages: 4 }), 'pages')
  assert.equal(transferFraction({ pages: 0, received: 9, expected: 18 }), 0.5)
  assert.equal(transferBasis({ received: 9, expected: 18 }), 'objects')
})

test('progress is null rather than invented when nothing is measured', () => {
  assert.equal(transferFraction({ pages: 0, expected: 0, fineFragmentsTotal: 0 }), null)
  assert.equal(transferBasis({ pages: 0, expected: 0, fineFragmentsTotal: 0 }), null)
  assert.equal(transferFraction(null), null)
})

test('progress is clamped to the unit interval', () => {
  assert.equal(transferFraction({ received: 20, expected: 10 }), 1)
  assert.equal(transferFraction({ received: -5, expected: 10 }), 0)
})

test('the channel actions are the shapes Eyre accepts', () => {
  assert.match(channelUrl(), /^\/~\/channel\/\d+-[0-9a-f]+$/)
  assert.match(channelUrl('/base'), /^\/base\/~\/channel\//)
  assert.deepEqual(subscribeAction(1, '~bud', 'urgit', '/peer/activity'), {
    id: 1, action: 'subscribe', ship: 'bud', app: 'urgit', path: '/peer/activity',
  })
  assert.deepEqual(ackAction(4, '7'), { id: 4, action: 'ack', 'event-id': 7 })
})
