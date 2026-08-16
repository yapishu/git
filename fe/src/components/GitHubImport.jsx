import { useEffect, useRef, useState } from 'react'
import { api } from '../api'

const splitRepository = (value) => {
  const clean = value.trim().replace(/^https?:\/\/github\.com\//, '').replace(/\.git$/, '').replace(/^\/+|\/+$/g, '')
  const [owner = '', repository = ''] = clean.split('/')
  return { owner, repository }
}

export default function GitHubImport({ onComplete, onCancel }) {
  const [source, setSource] = useState('')
  const [name, setName] = useState('')
  const [publicRead, setPublicRead] = useState(true)
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const priorJobs = useRef(new Set())

  const parsed = splitRepository(source)

  useEffect(() => {
    if (parsed.repository && !name) setName(parsed.repository)
  }, [parsed.repository])

  useEffect(() => {
    if (!busy) return
    let stopped = false
    const poll = async () => {
      try {
        const status = await api.githubStatus()
        const jobs = status.jobs || []
        const relevant = jobs.filter((job) => !priorJobs.current.has(job.job) && ['import', 'update'].includes(job.kind) && job.repository === name)
        const active = relevant.find((job) => job.active)
        const latest = relevant[relevant.length - 1]
        if (active) setMessage(active.message)
        else if (latest) {
          if (!latest.ok) throw new Error(latest.message)
          setMessage(latest.message)
          setBusy(false)
          await onComplete(name)
          return
        }
      } catch (cause) {
        setError(cause.message)
        setBusy(false)
        return
      }
      if (!stopped) setTimeout(poll, 800)
    }
    poll()
    return () => { stopped = true }
  }, [busy, name, onComplete])

  async function submit(event) {
    event.preventDefault()
    setError('')
    setMessage('Contacting GitHub…')
    setBusy(true)
    try {
      const before = await api.githubStatus()
      priorJobs.current = new Set((before.jobs || []).map((job) => job.job))
      await api.githubImport(parsed.owner, parsed.repository, name.trim(), publicRead)
    } catch (cause) {
      setError(cause.message)
      setBusy(false)
    }
  }

  return (
    <main className="content centered">
      <form className="panel create-panel github-import" onSubmit={submit}>
        <h1>Import from GitHub</h1>
        <p>Fetch branches, tags, commits, trees, and blobs from GitHub.</p>
        {error && <div className="inline-error">{error}</div>}
        <label><span>Repository URL or owner/name</span><input autoFocus value={source} onChange={(event) => setSource(event.target.value)} placeholder="octocat/Hello-World" /></label>
        <label><span>Local name</span><input value={name} onChange={(event) => setName(event.target.value)} placeholder="Hello-World" /></label>
        <label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public on this ship</strong><small>Anyone can clone and fetch the imported repository.</small></span></label>
        <small className="field-note">Limits: 64 MiB and 25,000 objects. Import runs in the background.</small>
        {message && <div className="transfer-status"><span className={busy ? 'spinner' : ''} />{message}</div>}
        <div className="form-actions"><button type="button" className="button" onClick={onCancel}>Cancel</button><button className="button primary" disabled={busy || !parsed.owner || !parsed.repository || !name.trim()}>{busy ? 'Importing…' : 'Import repository'}</button></div>
      </form>
    </main>
  )
}
