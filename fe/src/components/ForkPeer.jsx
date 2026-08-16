import { useEffect, useRef, useState } from 'react'
import { api } from '../api'

export default function ForkPeer({ repositories, onComplete, onCancel }) {
  const [ship, setShip] = useState('')
  const [repository, setRepository] = useState('')
  const [name, setName] = useState('')
  const [publicRead, setPublicRead] = useState(true)
  const [busy, setBusy] = useState(false)
  const [status, setStatus] = useState('')
  const [error, setError] = useState('')
  const poll = useRef(null)

  useEffect(() => () => clearInterval(poll.current), [])

  async function submit(event) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setStatus('Contacting peer…')
    try {
      const started = await api.peerFork(ship.trim(), repository.trim(), name.trim(), publicRead)
      poll.current = setInterval(async () => {
        try {
          const data = await api.peerTransfers()
          const transfer = data.transfers?.find((item) => item.transfer === started.transfer)
          if (!transfer || transfer.active) {
            setStatus('Receiving verified Git objects…')
            return
          }
          clearInterval(poll.current)
          if (!transfer.ok) throw new Error(transfer.message || 'Peer transfer failed')
          setStatus('Fork complete.')
          await onComplete(name.trim())
        } catch (cause) {
          clearInterval(poll.current)
          setError(cause.message)
          setBusy(false)
        }
      }, 750)
    } catch (cause) {
      setError(cause.message)
      setBusy(false)
      setStatus('')
    }
  }

  const collision = repositories.some((repo) => repo.name === name.trim())

  return (
    <main className="content centered">
      <form className="panel create-panel" onSubmit={submit}>
        <h1>Fork from a ship</h1>
        <p>Copy a public repository over Ames.</p>
        {error && <div className="inline-error">{error}</div>}
        {status && !error && <div className="transfer-status">{status}</div>}
        <label><span>Source ship</span><input value={ship} onChange={(event) => setShip(event.target.value)} placeholder="~sampel-palnet" autoFocus /></label>
        <label><span>Source repository</span><input value={repository} onChange={(event) => { setRepository(event.target.value); if (!name) setName(event.target.value) }} placeholder="project" /></label>
        <label><span>Local repository name</span><input value={name} onChange={(event) => setName(event.target.value)} placeholder="project" /></label>
        {collision && <small className="field-note">An existing peer fork with the same origin will be updated.</small>}
        <label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public local fork</strong><small>Allow other ships and Git clients to fetch this copy.</small></span></label>
        <div className="form-actions split"><button type="button" className="button ghost" onClick={onCancel}>Cancel</button><button className="button primary" disabled={busy || !ship.trim() || !repository.trim() || !name.trim()}>{busy ? 'Transferring…' : collision ? 'Update fork' : 'Fork repository'}</button></div>
      </form>
    </main>
  )
}
