import { useEffect, useState } from 'react'
import { api } from '../api'

export default function GitHubSettings({ onImport, onBack }) {
  const [status, setStatus] = useState(null)
  const [token, setToken] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const load = () => api.githubStatus().then(setStatus).catch((cause) => setError(cause.message))
  useEffect(() => { load() }, [])

  async function save() {
    setBusy(true); setError('')
    try { await api.setGithubToken(token); setToken(''); await load() } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  async function clear() {
    setBusy(true); setError('')
    try { await api.clearGithubToken(); await load() } catch (cause) { setError(cause.message) } finally { setBusy(false) }
  }

  const jobs = [...(status?.jobs || [])].reverse().slice(0, 12)
  return (
    <main className="content settings-page">
      <button className="text-button back-link" onClick={onBack}>← Repositories</button>
      <header className="page-header"><div><h1>GitHub</h1></div><button className="button primary" onClick={onImport}>Import repository</button></header>
      {error && <div className="inline-error">{error}</div>}
      <div className="settings-columns">
        <section className="panel">
          <div className="section-title"><div><h2>Personal access token</h2><p>The token stays in Gall state and is never returned to the browser. Public imports work without one; private repositories and write operations require it.</p></div><span className={status?.tokenSet ? 'status good' : 'status'}>{status?.tokenSet ? 'connected' : 'optional'}</span></div>
          <label><span>GitHub token</span><div className="inline-field"><input type="password" value={token} onChange={(event) => setToken(event.target.value)} placeholder={status?.tokenSet ? 'Token is stored' : 'github_pat_…'} /><button className="button" disabled={busy || !token} onClick={save}>Save</button></div></label>
          {status?.tokenSet && <button className="text-button danger-text" disabled={busy} onClick={clear}>Disconnect GitHub</button>}
        </section>
        <section className="panel jobs-panel">
          <div className="section-title"><div><h2>Recent activity</h2><p>Imports and API synchronization run in the background.</p></div><button className="text-button" onClick={load}>Refresh</button></div>
          {!jobs.length ? <div className="compact-empty">No GitHub activity yet.</div> : <div className="job-list">{jobs.map((job) => <div className="job-row" key={job.job}><span className={`job-dot ${job.active ? 'active' : job.ok ? 'ok' : 'failed'}`} /><div><strong>{job.repository}</strong><small>{job.message}</small></div><span className="quiet">{job.kind}</span></div>)}</div>}
        </section>
      </div>
    </main>
  )
}
