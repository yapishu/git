import { useEffect, useState } from 'react'

const prefix = 'urgit:draft:'

function read(key, fallback) {
  if (!key) return fallback
  try {
    const saved = localStorage.getItem(prefix + key)
    return saved === null ? fallback : saved
  } catch {
    return fallback
  }
}

export const readLocalDraft = (key, fallback = '') => read(key, fallback)

export function saveLocalDraft(key, value) {
  if (!key) return
  try {
    if (value) localStorage.setItem(prefix + key, value)
    else localStorage.removeItem(prefix + key)
  } catch { /* storage may be disabled or full */ }
}

export function clearLocalDraft(key) {
  if (!key) return
  try { localStorage.removeItem(prefix + key) } catch { /* storage may be disabled */ }
}

export function useLocalDraft(key, fallback = '') {
  const [value, setValue] = useState(() => read(key, fallback))

  useEffect(() => { setValue(read(key, fallback)) }, [key, fallback])

  function update(next) {
    const resolved = typeof next === 'function' ? next(value) : next
    setValue(resolved)
    if (!key) return
    saveLocalDraft(key, resolved)
  }

  function clear() {
    setValue(fallback)
    if (!key) return
    clearLocalDraft(key)
  }

  return [value, update, clear]
}
