export function formatBytes(value) {
  const bytes = Number(value)
  if (!Number.isFinite(bytes) || bytes < 0) return '—'
  if (bytes < 1024) return `${bytes.toLocaleString()} B`
  const units = ['KB', 'MB', 'GB', 'TB']
  let size = bytes
  let unit = -1
  do {
    size /= 1024
    unit += 1
  } while (size >= 1024 && unit < units.length - 1)
  const digits = size < 10 ? 1 : 0
  return `${size.toLocaleString(undefined, { minimumFractionDigits: digits, maximumFractionDigits: 1 })} ${units[unit]}`
}

export function exactBytes(value) {
  const bytes = Number(value)
  return Number.isFinite(bytes) && bytes >= 0 ? `${bytes.toLocaleString()} bytes` : ''
}

export function relativeTime(timestamp, nowSeconds = Date.now() / 1000) {
  const then = Number(timestamp)
  const now = Number(nowSeconds)
  if (!Number.isFinite(then) || then <= 0 || !Number.isFinite(now)) return ''
  const elapsed = Math.max(0, now - then)
  if (elapsed < 60) return 'just now'

  const ranges = [
    [60, 'minute'],
    [3_600, 'hour'],
    [86_400, 'day'],
    [604_800, 'week'],
    [2_629_746, 'month'],
    [31_556_952, 'year'],
  ]
  let divisor = ranges[0][0]
  let unit = ranges[0][1]
  for (const [candidate, candidateUnit] of ranges) {
    if (elapsed < candidate) break
    divisor = candidate
    unit = candidateUnit
  }
  return new Intl.RelativeTimeFormat(undefined, { numeric: 'always' }).format(-Math.max(1, Math.floor(elapsed / divisor)), unit)
}

export function exactTime(timestamp) {
  const value = Number(timestamp) * 1000
  return Number.isFinite(value) && value > 0 ? new Date(value).toLocaleString() : ''
}

export function newestRepositoriesFirst(repositories = []) {
  return [...repositories].sort((left, right) => Number(right.updatedAt || 0) - Number(left.updatedAt || 0))
}
