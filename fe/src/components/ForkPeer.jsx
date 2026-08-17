import { useEffect, useRef, useState } from 'react'
import { api } from '../api'

export default function ForkPeer({ repositories, onComplete, onCancel }) {
  const [ship, setShip] = useState('')
  const [repository, setRepository] = useState('')
  const [name, setName] = useState('')
  const [publicRead, setPublicRead] = useState(true)
  const [busy, setBusy] = useState(false)
  const [discovering, setDiscovering] = useState(false)
  const [catalog, setCatalog] = useState([])
  const [status, setStatus] = useState('')
  const [progress, setProgress] = useState(null)
  const [error, setError] = useState('')
  const transferPoll = useRef(null)
  const discoveryPoll = useRef(null)
  const activeTransfer = useRef('')
  const activeDiscovery = useRef('')

  useEffect(() => () => {
    clearInterval(transferPoll.current)
    clearInterval(discoveryPoll.current)
    if (activeTransfer.current) api.peerDeleteTransfer(activeTransfer.current).catch(() => {})
    if (activeDiscovery.current) api.peerDeleteDiscovery(activeDiscovery.current).catch(() => {})
  }, [])

  async function discover() {
    setDiscovering(true)
    setCatalog([])
    setError('')
    setStatus('Reading public repositories…')
    try {
      const started = await api.peerDiscover(ship.trim())
      activeDiscovery.current = started.request
      discoveryPoll.current = setInterval(async () => {
        try {
          const data = await api.peerDiscoveries()
          const result = data.discoveries?.find((item) => item.request === started.request)
          if (!result || result.active) return
          clearInterval(discoveryPoll.current)
          activeDiscovery.current = ''
          await api.peerDeleteDiscovery(started.request).catch(() => {})
          if (!result.ok) throw new Error(result.message || 'Peer discovery failed')
          setCatalog(result.repositories || [])
          setStatus(result.repositories?.length ? `${result.repositories.length} public repositories found.` : 'No public repositories found.')
          setDiscovering(false)
        } catch (cause) {
          clearInterval(discoveryPoll.current)
          setError(cause.message)
          setStatus('')
          setDiscovering(false)
        }
      }, 600)
    } catch (cause) {
      setError(cause.message)
      setStatus('')
      setDiscovering(false)
    }
  }

  function selectRemote(repo) {
    setRepository(repo.name)
    if (!name || catalog.some((item) => item.name === name)) setName(repo.name)
  }

  async function submit(event) {
    event.preventDefault()
    setBusy(true)
    setError('')
    setStatus('Contacting peer…')
    setProgress(null)
    try {
      const started = await api.peerFork(ship.trim(), repository.trim(), name.trim(), publicRead)
      activeTransfer.current = started.transfer
      transferPoll.current = setInterval(async () => {
        try {
          const data = await api.peerTransfers()
          const transfer = data.transfers?.find((item) => item.transfer === started.transfer)
          if (!transfer || transfer.active) {
            if (transfer) {
              setProgress(transfer)
              const received = Number(transfer.received || 0)
              const expected = Number(transfer.expected || 0)
              setStatus(expected > 0 ? `Receiving verified Git objects · ${received} / ${expected}` : 'Preparing repository snapshot…')
            } else setStatus('Contacting peer…')
            return
          }
          clearInterval(transferPoll.current)
          activeTransfer.current = ''
          await api.peerDeleteTransfer(started.transfer).catch(() => {})
          if (!transfer.ok) throw new Error(transfer.message || 'Peer transfer failed')
          setStatus('Fork complete.')
          await onComplete(name.trim())
        } catch (cause) {
          clearInterval(transferPoll.current)
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

  async function cancel() {
    clearInterval(transferPoll.current)
    clearInterval(discoveryPoll.current)
    const transfer = activeTransfer.current
    const discovery = activeDiscovery.current
    activeTransfer.current = ''
    activeDiscovery.current = ''
    if (transfer) await api.peerDeleteTransfer(transfer).catch(() => {})
    if (discovery) await api.peerDeleteDiscovery(discovery).catch(() => {})
    setBusy(false)
    onCancel()
  }

  const collision = repositories.some((repo) => repo.name === name.trim())

  return (
    <main className="content centered">
      <form className="panel create-panel" onSubmit={submit}>
        <h1>Fork from a ship</h1>
        <p>Copy a public repository through Ames and Fine.</p>
        {error && <div className="inline-error">{error}</div>}
        {status && !error && <div className="transfer-status"><span className={busy ? 'spinner' : ''} />{status}{busy && progress && Number(progress.expected || 0) > 0 && <progress max={Number(progress.expected)} value={Number(progress.received || 0)} />}</div>}
        <label><span>Source ship</span><div className="inline-field"><input value={ship} onChange={(event) => { setShip(event.target.value); setCatalog([]) }} placeholder="~sampel-palnet" autoFocus /><button type="button" className="button" disabled={busy || discovering || !ship.trim()} onClick={discover}>{discovering ? 'Scanning…' : 'Discover'}</button></div></label>
        {!!catalog.length && <div className="peer-catalog">{catalog.map((repo) => <button type="button" key={repo.name} className={repository === repo.name ? 'peer-repo selected' : 'peer-repo'} onClick={() => selectRemote(repo)}><span><strong>{repo.name}</strong><small>{repo.head}</small></span><span className="peer-repo-meta">{repo.refs} refs · {repo.objects} objects{repo.writable ? ' · write' : ''}</span></button>)}</div>}
        <label><span>Source repository</span><input value={repository} onChange={(event) => { setRepository(event.target.value); if (!name) setName(event.target.value) }} placeholder="project" /></label>
        <label><span>Local repository name</span><input value={name} onChange={(event) => setName(event.target.value)} placeholder="project" /></label>
        {collision && <small className="field-note">An existing peer fork with the same origin will be updated.</small>}
        <label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public local fork</strong><small>Allow other ships and Git clients to fetch this copy.</small></span></label>
        <div className="form-actions split"><button type="button" className="button ghost" onClick={cancel}>Cancel</button><button className="button primary" disabled={busy || !ship.trim() || !repository.trim() || !name.trim()}>{busy ? 'Transferring…' : collision ? 'Update fork' : 'Fork repository'}</button></div>
      </form>
    </main>
  )
}
