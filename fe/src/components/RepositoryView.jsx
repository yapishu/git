import { useEffect, useState } from 'react'
import { api } from '../api'
import { CopyIcon } from './Icons'

const shortOid = (oid) => oid ? oid.slice(0, 8) : '—'

const decodeBase64 = (content) => {
  const raw = atob(content)
  const bytes = Uint8Array.from(raw, (char) => char.charCodeAt(0))
  let text = null
  try { text = new TextDecoder('utf-8', { fatal: true }).decode(bytes) } catch { /* binary */ }
  return { bytes, text }
}

const encodeBase64 = (text) => {
  const bytes = new TextEncoder().encode(text)
  let raw = ''
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    raw += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000))
  }
  return btoa(raw)
}

const imageType = (path) => {
  const leaf = path.split('/').filter(Boolean).pop() || ''
  const extension = (leaf.includes('.') ? leaf.split('.').pop() : leaf).toLowerCase()
  return ({ png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', webp: 'image/webp', svg: 'image/svg+xml' })[extension]
}

function Files({ data, loading, onOpen }) {
  if (loading) return <div className="empty">Loading tree…</div>
  if (!data?.files?.length) return <div className="empty">This repository has no files yet.</div>
  return (
    <div className="table">
      <div className="table-head"><span>Path</span><span>Size</span></div>
      {data.files.map((file) => (
        <button className="table-row file-row" key={file.path} onClick={() => onOpen(file.path)}>
          <span className="file-path"><i />{file.path}</span>
          <span className="quiet">{Number(file.size).toLocaleString()} B</span>
        </button>
      ))}
    </div>
  )
}

function FileView({ repository, path, onBack, onSaved }) {
  const [file, setFile] = useState(null)
  const [text, setText] = useState('')
  const [original, setOriginal] = useState('')
  const [message, setMessage] = useState(`Edit ${path}`)
  const [editing, setEditing] = useState(false)
  const [busy, setBusy] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    setBusy(true)
    setError('')
    api.file(repository, path).then((data) => {
      if (!active) return
      const decoded = decodeBase64(data.content)
      setFile({ ...data, ...decoded })
      setText(decoded.text ?? '')
      setOriginal(decoded.text ?? '')
    }).catch((cause) => active && setError(cause.message)).finally(() => active && setBusy(false))
    return () => { active = false }
  }, [repository, path])

  async function save() {
    setBusy(true)
    setError('')
    try {
      await api.saveFile(repository, path, encodeBase64(text), message.trim())
      setOriginal(text)
      setEditing(false)
      await onSaved()
    } catch (cause) {
      setError(cause.message)
    } finally {
      setBusy(false)
    }
  }

  const mime = imageType(path)
  const objectUrl = file && mime ? `data:${mime};base64,${file.content}` : null
  const downloadUrl = file ? `data:application/octet-stream;base64,${file.content}` : null

  return (
    <div className="file-view">
      <div className="file-toolbar">
        <button className="text-button file-back" onClick={onBack}>← Files</button>
        <code>{path}</code>
        <div className="file-actions">
          {downloadUrl && <a className="button link-button" href={downloadUrl} download={path.split('/').pop()}>Download</a>}
          {file && file.text !== null && !editing && <button className="button" onClick={() => setEditing(true)}>Edit</button>}
        </div>
      </div>
      {error && <div className="inline-error">{error}</div>}
      {busy && !file ? <div className="empty">Loading file…</div> : editing ? (
        <div className="editor-panel">
          <textarea className="code-editor" value={text} onChange={(event) => setText(event.target.value)} spellCheck="false" />
          <div className="editor-footer">
            <input value={message} onChange={(event) => setMessage(event.target.value)} aria-label="Commit message" />
            <button className="button" onClick={() => { setText(original); setEditing(false) }}>Cancel</button>
            <button className="button primary" disabled={busy || !message.trim() || text === original} onClick={save}>{busy ? 'Committing…' : 'Commit changes'}</button>
          </div>
        </div>
      ) : objectUrl ? (
        <div className="image-view"><img src={objectUrl} alt={path} /></div>
      ) : file?.text !== null ? (
        <pre className="code-view"><code>{file?.text}</code></pre>
      ) : file ? (
        <div className="empty">Binary file · {Number(file.size).toLocaleString()} bytes</div>
      ) : null}
    </div>
  )
}

function Commits({ data, loading }) {
  if (loading) return <div className="empty">Loading history…</div>
  if (!data?.commits?.length) return <div className="empty">No commits yet.</div>
  return (
    <div className="commit-list">
      {data.commits.map((commit) => (
        <div className="commit-row" key={commit.oid}>
          <span className="commit-dot" />
          <div><strong>{commit.subject || 'Untitled commit'}</strong><small>{commit.parent ? `parent ${shortOid(commit.parent)}` : 'root commit'}</small></div>
          <code title={commit.oid}>{shortOid(commit.oid)}</code>
        </div>
      ))}
    </div>
  )
}

function Settings({ repo, onMutate }) {
  const [desk, setDesk] = useState(repo.binding?.desk || '')
  const [branch, setBranch] = useState(repo.binding?.branch || repo.head || 'refs/heads/main')
  const [message, setMessage] = useState('Publish Clay desk')
  const [token, setToken] = useState('')
  const [busy, setBusy] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    setDesk(repo.binding?.desk || '')
    setBranch(repo.binding?.branch || repo.head || 'refs/heads/main')
  }, [repo])

  async function act(label, fn) {
    setBusy(label)
    setError('')
    try {
      await fn()
      await onMutate()
    } catch (cause) {
      setError(cause.message)
    } finally {
      setBusy('')
    }
  }

  return (
    <div className="settings-grid">
      {error && <div className="inline-error">{error}</div>}
      <section className="panel">
        <div className="section-title"><div><h2>Clay bridge</h2><p>Publish a desk as this repository, and apply accepted pushes back into Clay.</p></div><span className={repo.binding?.bound ? 'status good' : 'status'}>{repo.binding?.bound ? 'bound' : 'unbound'}</span></div>
        {repo.binding?.bound ? (
          <>
            <div className="binding-card"><span>Desk</span><code>{repo.binding.desk}</code><span>Branch</span><code>{repo.binding.branch}</code></div>
            <label><span>Commit message</span><input value={message} onChange={(e) => setMessage(e.target.value)} /></label>
            <div className="form-actions split">
              <button className="button ghost danger-text" onClick={() => act('unbind', () => api.unbind(repo.name))}>Unbind</button>
              <button className="button primary" disabled={busy || !message.trim()} onClick={() => act('publish', () => api.publish(repo.name, message.trim()))}>{busy === 'publish' ? 'Publishing…' : 'Publish desk'}</button>
            </div>
          </>
        ) : (
          <>
            <div className="two-fields">
              <label><span>Desk</span><input value={desk} onChange={(e) => setDesk(e.target.value)} placeholder="my-desk" /></label>
              <label><span>Branch ref</span><input value={branch} onChange={(e) => setBranch(e.target.value)} /></label>
            </div>
            <div className="form-actions"><button className="button primary" disabled={busy || !desk.trim() || !branch.trim()} onClick={() => act('bind', () => api.bind(repo.name, desk.trim(), branch.trim()))}>{busy === 'bind' ? 'Binding…' : 'Bind desk'}</button></div>
          </>
        )}
      </section>
      <section className="panel">
        <div className="section-title"><div><h2>Access</h2><p>Public controls clone/fetch. A token permits authenticated pushes over Smart HTTP.</p></div></div>
        <label className="check-row">
          <input type="checkbox" checked={repo.publicRead} onChange={(e) => act('public', () => api.setPublic(repo.name, e.target.checked))} />
          <span><strong>Public read access</strong><small>{repo.publicRead ? 'Clone and fetch are open.' : 'Urbit authentication is required.'}</small></span>
        </label>
        <label><span>Write token</span><div className="inline-field"><input type="password" value={token} onChange={(e) => setToken(e.target.value)} placeholder={repo.writeTokenSet ? 'Token is set' : 'Set a Git password'} /><button className="button" disabled={busy || !token} onClick={() => act('token', async () => { await api.setToken(repo.name, token); setToken('') })}>Save</button></div></label>
        {repo.writeTokenSet && <button className="text-button danger-text" onClick={() => act('clear-token', () => api.clearToken(repo.name))}>Clear write token</button>}
      </section>
      <section className="panel danger-zone">
        <div><h2>Delete repository</h2><p>Remove refs, Git objects, binding metadata, and LFS pointers held by this repository.</p></div>
        <button className="button danger" onClick={() => { if (window.confirm(`Delete ${repo.name}? This cannot be undone.`)) act('delete', () => api.remove(repo.name)) }}>Delete</button>
      </section>
    </div>
  )
}

export default function RepositoryView({ repo, onRefresh }) {
  const [tab, setTab] = useState('files')
  const [filePath, setFilePath] = useState('')
  const [detail, setDetail] = useState(null)
  const [loading, setLoading] = useState(true)
  const cloneUrl = `${window.location.origin}/git/${repo.name}.git`

  useEffect(() => {
    let active = true
    setLoading(true)
    const load = tab === 'commits' ? api.commits(repo.name) : tab === 'files' ? api.files(repo.name) : Promise.resolve(null)
    load.then((data) => active && setDetail(data)).finally(() => active && setLoading(false))
    return () => { active = false }
  }, [repo.name, repo.refs, tab])

  useEffect(() => { setFilePath('') }, [repo.name])

  async function mutate() {
    await onRefresh(repo.name)
  }

  return (
    <main className="content">
      <header className="repo-header">
        <div><div className="eyebrow">{repo.publicRead ? 'Public repository' : 'Private repository'}</div><h1>{repo.name}</h1></div>
        <div className="clone-box"><code>{cloneUrl}</code><button className="icon-button" title="Copy clone URL" onClick={() => navigator.clipboard.writeText(cloneUrl)}><CopyIcon /></button></div>
      </header>
      <div className="repo-meta">
        <span title="Branches, tags, and other named Git pointers"><b>{repo.refs?.length || 0}</b> Git refs</span><span title="Internal Git commits, directory trees, and file blobs"><b>{repo.objectCount || 0}</b> stored Git objects</span><span title="Large file payloads in ship object storage"><b>{repo.lfsObjectCount || 0}</b> LFS files</span>
        {repo.binding?.bound && <span className="clay-chip">Clay · {repo.binding.desk}</span>}
      </div>
      <nav className="tabs">
        {['files', 'commits', 'settings'].map((name) => <button key={name} className={tab === name ? 'active' : ''} onClick={() => setTab(name)}>{name[0].toUpperCase() + name.slice(1)}</button>)}
      </nav>
      <section className="repo-body">
        {tab === 'files' && (filePath
          ? <FileView repository={repo.name} path={filePath} onBack={() => setFilePath('')} onSaved={mutate} />
          : <Files data={detail} loading={loading} onOpen={setFilePath} />)}
        {tab === 'commits' && <Commits data={detail} loading={loading} />}
        {tab === 'settings' && <Settings repo={repo} onMutate={mutate} />}
      </section>
    </main>
  )
}
