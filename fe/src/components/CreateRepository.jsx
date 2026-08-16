import { useState } from 'react'

export default function CreateRepository({ onCreate, onCancel }) {
  const [name, setName] = useState('')
  const [publicRead, setPublicRead] = useState(false)
  const [busy, setBusy] = useState(false)

  async function submit(event) {
    event.preventDefault()
    setBusy(true)
    try {
      await onCreate(name.trim(), publicRead)
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="content centered">
      <form className="panel create-panel" onSubmit={submit}>
        <div className="eyebrow">New repository</div>
        <h1>Create a place for your code.</h1>
        <label>
          <span>Name</span>
          <input autoFocus required pattern="[A-Za-z0-9._-]+" maxLength="100" value={name} onChange={(e) => setName(e.target.value)} placeholder="my-project" />
        </label>
        <label className="check-row">
          <input type="checkbox" checked={publicRead} onChange={(e) => setPublicRead(e.target.checked)} />
          <span><strong>Public read access</strong><small>Anyone who knows the URL can clone and fetch.</small></span>
        </label>
        <div className="form-actions">
          <button type="button" className="button ghost" onClick={onCancel}>Cancel</button>
          <button className="button primary" disabled={busy || !name.trim()}>{busy ? 'Creating…' : 'Create repository'}</button>
        </div>
      </form>
    </main>
  )
}
