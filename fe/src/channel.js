// Minimal Eyre channel client.
//
// Eyre's channel API is plain HTTP: a PUT of subscribe/ack/delete actions and
// a GET that streams the results back as server-sent events. That is all this
// needs, so it carries no dependency.

const randomSuffix = () => Math.random().toString(16).slice(2, 8)

export function channelUrl(base = '') {
  return `${base}/~/channel/${Math.floor(Date.now() / 1000)}-${randomSuffix()}`
}

export function subscribeAction(id, ship, app, path) {
  return { id, action: 'subscribe', ship: String(ship).replace(/^~/, ''), app, path }
}

export function ackAction(id, eventId) {
  return { id, action: 'ack', 'event-id': Number(eventId) }
}

// Returns { close }. onFact receives the fact body; onStatus receives
// 'open' | 'closed'. On any transport error the channel is torn down and a
// fresh one is opened after a backoff, so a reconnecting browser re-runs
// on-watch and gets current state without waiting for the next event.
export function watchAgent({
  ship,
  app,
  path,
  onFact,
  onStatus,
  base = '',
  minRetry = 1000,
  maxRetry = 15000,
  fetchImpl,
  EventSourceImpl,
  setTimeoutImpl,
  clearTimeoutImpl,
}) {
  const doFetch = fetchImpl || globalThis.fetch
  const Source = EventSourceImpl || globalThis.EventSource
  const later = setTimeoutImpl || globalThis.setTimeout
  const cancel = clearTimeoutImpl || globalThis.clearTimeout

  let stopped = false
  let source = null
  let url = ''
  let nextId = 1
  let retry = minRetry
  let timer = null

  const put = (actions) =>
    doFetch(url, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(actions),
    })

  function teardown() {
    if (source) {
      try { source.close() } catch { /* already closed */ }
      source = null
    }
  }

  function reconnect() {
    if (stopped) return
    teardown()
    onStatus?.('closed')
    timer = later(connect, retry)
    retry = Math.min(maxRetry, retry * 2)
  }

  async function connect() {
    if (stopped) return
    url = channelUrl(base)
    nextId = 1
    try {
      const response = await put([subscribeAction(nextId++, ship, app, path)])
      if (!response.ok) throw new Error(`channel PUT ${response.status}`)
    } catch {
      reconnect()
      return
    }
    if (stopped) return
    source = new Source(url, { withCredentials: true })
    source.onopen = () => { retry = minRetry; onStatus?.('open') }
    source.onmessage = (event) => {
      if (event.lastEventId) put([ackAction(nextId++, event.lastEventId)]).catch(() => {})
      let message = null
      try { message = JSON.parse(event.data) } catch { return }
      if (message?.response === 'diff') onFact?.(message.json)
      if (message?.response === 'subscribe' && message.err) reconnect()
      if (message?.response === 'quit') reconnect()
    }
    source.onerror = () => reconnect()
  }

  connect()

  return {
    close() {
      stopped = true
      if (timer) cancel(timer)
      teardown()
      if (url) put([{ id: nextId++, action: 'delete' }]).catch(() => {})
    },
  }
}
