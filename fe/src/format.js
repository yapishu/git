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
