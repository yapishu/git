import { useEffect, useState } from 'react'
import { api } from '../api'

export default function PublishDesk({ repositories, onComplete, onCancel }) {
  const [desks, setDesks] = useState([])
  const [desk, setDesk] = useState('')
  const [name, setName] = useState('')
  const [message, setMessage] = useState('Publish Clay desk')
  const [publicRead, setPublicRead] = useState(true)
  const [busy, setBusy] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    api.desks().then((data) => {
      if (!active) return
      setDesks(data.desks || [])
      setDesk(data.desks?.[0] || '')
      setName(data.desks?.[0] || '')
    }).catch((cause) => active && setError(cause.message)).finally(() => active && setBusy(false))
    return () => { active = false }
  }, [])

  function chooseDesk(value) {
    setDesk(value)
    if (!name || desks.includes(name)) setName(value)
  }

  async function submit(event) {
    event.preventDefault()
    setBusy(true)
    setError('')
    let created = false
    try {
      await api.create(name.trim(), publicRead)
      created = true
      await api.bind(name.trim(), desk, 'refs/heads/main')
      await api.publish(name.trim(), message.trim())
      await onComplete(name.trim())
    } catch (cause) {
      if (created) {
        try { await api.remove(name.trim()) } catch { /* preserve the original error */ }
      }
      setError(cause.message)
    } finally {
      setBusy(false)
    }
  }

  const collision = repositories.some((repo) => repo.name === name.trim())

  return (
    <main className="content centered">
      <form className="panel create-panel" onSubmit={submit}>
        <h1>Publish a desk</h1>
        <p>Create or update a repository from a mounted Clay desk.</p>
        {error && <div className="inline-error">{error}</div>}
        <label><span>Clay desk</span>
          <select value={desk} onChange={(event) => chooseDesk(event.target.value)} disabled={busy && !desks.length}>
            {!desks.length && <option value="">No desks found</option>}
            {desks.map((item) => <option key={item} value={item}>{item}</option>)}
          </select>
        </label>
        <label><span>Repository name</span><input value={name} onChange={(event) => setName(event.target.value)} placeholder="my-desk" autoFocus /></label>
        {collision && <small className="field-error">That repository already exists.</small>}
        <label><span>Initial commit message</span><input value={message} onChange={(event) => setMessage(event.target.value)} /></label>
        <label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public repository</strong><small>Anyone who knows the URL can clone and fetch it.</small></span></label>
        <div className="form-actions split"><button type="button" className="button ghost" onClick={onCancel}>Cancel</button><button className="button primary" disabled={busy || !desk || !name.trim() || !message.trim() || collision}>{busy ? 'Publishing…' : 'Publish desk'}</button></div>
      </form>
    </main>
  )
}
