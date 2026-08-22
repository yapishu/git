// Projection of the transfer visibility payloads into one shape.
//
// Three sources produce the same keys: the /peer/activity poll
// ({activity, notifications}), the /peer/transfers poll ({transfers}), and
// the /peer/activity subscription fact, which carries all three. A payload
// that omits a key leaves the previous value alone, so a partial poll never
// blanks a panel that the subscription had already filled.

export const emptyFeed = () => ({ activity: [], notifications: [], transfers: [] })

export function mergeFeed(previous, payload) {
  const base = previous || emptyFeed()
  if (!payload || typeof payload !== 'object') return base
  return {
    activity: Array.isArray(payload.activity) ? payload.activity : base.activity,
    notifications: Array.isArray(payload.notifications) ? payload.notifications : base.notifications,
    transfers: Array.isArray(payload.transfers) ? payload.transfers : base.transfers,
  }
}

export const findTransfer = (feed, id) =>
  (feed?.transfers || []).find((item) => item.transfer === id) || null

export const activeActivity = (feed) =>
  (feed?.activity || []).filter((item) => item.status === 'active')

const ratio = (part, whole) => {
  const top = Number(part) || 0
  const bottom = Number(whole) || 0
  if (bottom <= 0) return null
  return Math.max(0, Math.min(1, top / bottom))
}

// Fraction complete, or null when the ship reports no denominator. Every
// branch is a count the ship measured; nothing here is an estimate.
export function transferFraction(transfer) {
  if (!transfer) return null
  const fragments = ratio(transfer.fineFragmentsReceived, transfer.fineFragmentsTotal)
  if (fragments !== null) return fragments
  const pages = ratio(transfer.completedPages, transfer.pages)
  if (pages !== null) return pages
  return ratio(transfer.received, transfer.expected)
}

// What the fraction is measured in, so a caller can label it honestly.
export function transferBasis(transfer) {
  if (!transfer) return null
  if (ratio(transfer.fineFragmentsReceived, transfer.fineFragmentsTotal) !== null) return 'fragments'
  if (ratio(transfer.completedPages, transfer.pages) !== null) return 'pages'
  if (ratio(transfer.received, transfer.expected) !== null) return 'objects'
  return null
}
