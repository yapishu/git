const DATABASE = 'urgit-remote-cache'
const STORE = 'repositories'
const memory = new Map()

export const remoteCacheKey = (ship, repository) => `${ship}/${repository}`

export function remoteCacheIsUsable(entry) {
  return Boolean(entry?.data && entry?.revision)
}

function openDatabase() {
  if (typeof indexedDB === 'undefined') return Promise.resolve(null)
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DATABASE, 1)
    request.onupgradeneeded = () => {
      if (!request.result.objectStoreNames.contains(STORE)) request.result.createObjectStore(STORE, { keyPath: 'key' })
    }
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}

export async function readRemoteCache(ship, repository) {
  const key = remoteCacheKey(ship, repository)
  try {
    const database = await openDatabase()
    if (!database) return memory.get(key) || null
    return await new Promise((resolve, reject) => {
      const transaction = database.transaction(STORE, 'readonly')
      const request = transaction.objectStore(STORE).get(key)
      request.onsuccess = () => resolve(request.result || null)
      request.onerror = () => reject(request.error)
      transaction.oncomplete = () => database.close()
    })
  } catch {
    return memory.get(key) || null
  }
}

export async function writeRemoteCache(ship, repository, revision, data, cachedAt = Date.now()) {
  if (!revision || !data) return
  const entry = { key: remoteCacheKey(ship, repository), ship, repository, revision, cachedAt, data }
  memory.set(entry.key, entry)
  try {
    const database = await openDatabase()
    if (!database) return
    await new Promise((resolve, reject) => {
      const transaction = database.transaction(STORE, 'readwrite')
      transaction.objectStore(STORE).put(entry)
      transaction.oncomplete = () => { database.close(); resolve() }
      transaction.onerror = () => { database.close(); reject(transaction.error) }
      transaction.onabort = () => { database.close(); reject(transaction.error) }
    })
  } catch {
    // The in-memory entry remains usable when IndexedDB is unavailable.
  }
}
