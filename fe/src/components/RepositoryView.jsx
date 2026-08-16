import { useEffect, useMemo, useState } from 'react'
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

function Files({ data, commit, loading, onOpen }) {
  if (loading) return <div className="empty">Loading tree…</div>
  if (!data?.files?.length) return <div className="empty">This repository has no files yet.</div>
  return (
    <div className="table">
      {commit && <div className="latest-commit"><span className="commit-dot" /><strong>{commit.subject || 'Untitled commit'}</strong><code title={commit.oid}>{shortOid(commit.oid)}</code></div>}
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

function FileView({ repository, path, branch, editable, onBack, onSaved }) {
  const [file, setFile] = useState(null)
  const [history, setHistory] = useState(null)
  const [view, setView] = useState('file')
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
    api.file(repository, path, branch).then((data) => {
      if (!active) return
      const decoded = decodeBase64(data.content)
      setFile({ ...data, ...decoded })
      setText(decoded.text ?? '')
      setOriginal(decoded.text ?? '')
    }).catch((cause) => active && setError(cause.message)).finally(() => active && setBusy(false))
    return () => { active = false }
  }, [repository, path, branch])

  useEffect(() => {
    if (view !== 'history' || history) return
    api.fileHistory(repository, path, branch).then(setHistory).catch((cause) => setError(cause.message))
  }, [view, history, repository, path, branch])

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
          <button className={view === 'history' ? 'button active' : 'button'} onClick={() => setView(view === 'history' ? 'file' : 'history')}>{view === 'history' ? 'View file' : 'History'}</button>
          {editable && file && file.text !== null && !editing && view === 'file' && <button className="button" onClick={() => setEditing(true)}>Edit</button>}
        </div>
      </div>
      {error && <div className="inline-error">{error}</div>}
      {view === 'history' ? (
        !history ? <div className="empty">Loading file history…</div> : !history.commits?.length ? <div className="empty">No changes found for this file.</div> : <Commits data={history} loading={false} />
      ) : busy && !file ? <div className="empty">Loading file…</div> : editing ? (
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

function Branches({ repo, selected, onBrowse }) {
  const branches = (repo.refs || []).filter((ref) => ref.name.startsWith('refs/heads/'))
  if (!branches.length) return <div className="empty">No branches yet.</div>
  return (
    <div className="table branch-table">
      <div className="table-head"><span>Branch</span><span>Commit</span></div>
      {branches.map((branch) => (
        <button className="table-row file-row" key={branch.name} onClick={() => onBrowse(branch.name)}>
          <span><strong>{branch.name.replace('refs/heads/', '')}</strong>{branch.name === repo.head && <small className="default-label">default</small>}</span>
          <code title={branch.oid}>{shortOid(branch.oid)}</code>
        </button>
      ))}
    </div>
  )
}

function PullRequests({ repo, onMutate }) {
  const [busy, setBusy] = useState(0)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('open')
  const [query, setQuery] = useState('')
  const pulls = repo.pullRequests || []
  async function merge(number) {
    setBusy(number)
    setError('')
    try { await api.mergePull(repo.name, number); await onMutate() } catch (cause) { setError(cause.message) } finally { setBusy(0) }
  }
  const githubPulls = repo.githubPulls || []
  const entries = useMemo(() => [
    ...pulls.map((pull) => ({ ...pull, native: true })),
    ...githubPulls.map((pull) => ({ ...pull, native: false })),
  ], [pulls, githubPulls])
  const visible = entries.filter((pull) => (filter === 'all' || pull.state === filter) && (!query.trim() || pull.title.toLowerCase().includes(query.trim().toLowerCase())))
  if (!entries.length) return <div className="empty">No pull requests.</div>
  return <>
    <div className="forge-toolbar"><div className="segmented"><button className={filter === 'open' ? 'active' : ''} onClick={() => setFilter('open')}>Open</button><button className={filter === 'closed' ? 'active' : ''} onClick={() => setFilter('closed')}>Closed</button><button className={filter === 'all' ? 'active' : ''} onClick={() => setFilter('all')}>All</button></div><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Filter pull requests…" /></div>
    {!visible.length ? <div className="empty compact">No pull requests match this filter.</div> : <div className="pull-list">
    {error && <div className="inline-error">{error}</div>}
    {visible.map((pull) => pull.native ? <article className="pull-row" key={`native-${pull.number}`}>
      <div><span className={`status ${pull.state === 'open' ? 'good' : ''}`}>{pull.state}</span><h3>#{pull.number} {pull.title}</h3><p><code>{pull.sourceShip}/{pull.sourceRepository}</code> proposes <code>{shortOid(pull.head)}</code></p></div>
      {pull.state === 'open' && <button className="button primary" disabled={busy} onClick={() => merge(pull.number)}>{busy === pull.number ? 'Validating…' : 'Merge'}</button>}
    </article> : <a className="pull-row forge-link" key={`github-${pull.number}`} href={pull.url} target="_blank" rel="noreferrer">
      <div><span className={`status ${pull.state === 'open' ? 'good' : ''}`}>{pull.draft ? 'draft' : pull.state}</span><h3>#{pull.number} {pull.title}</h3><p>opened by <strong>{pull.author}</strong> on GitHub</p></div><span className="external-arrow">↗</span>
    </a>)}
    </div>}
  </>
}

function Issues({ repo }) {
  const [filter, setFilter] = useState('open')
  const [query, setQuery] = useState('')
  const issues = repo.githubIssues || []
  if (!repo.githubOrigin) return <div className="empty">Connect a GitHub origin to synchronize issues.</div>
  if (!issues.length) return <div className="empty">No synchronized GitHub issues.</div>
  const visible = issues.filter((issue) => (filter === 'all' || issue.state === filter) && (!query.trim() || issue.title.toLowerCase().includes(query.trim().toLowerCase())))
  return <><div className="forge-toolbar"><div className="segmented"><button className={filter === 'open' ? 'active' : ''} onClick={() => setFilter('open')}>Open</button><button className={filter === 'closed' ? 'active' : ''} onClick={() => setFilter('closed')}>Closed</button><button className={filter === 'all' ? 'active' : ''} onClick={() => setFilter('all')}>All</button></div><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Filter issues…" /></div>{!visible.length ? <div className="empty compact">No issues match this filter.</div> : <div className="issue-list">{visible.map((issue) => <a className="issue-row forge-link" key={issue.number} href={issue.url} target="_blank" rel="noreferrer"><span className={`issue-icon ${issue.state}`}>◉</span><div><h3>{issue.title}</h3><p>#{issue.number} · {issue.state} · {issue.author}</p></div><span className="external-arrow">↗</span></a>)}</div>}</>
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
  const [writer, setWriter] = useState('')
  const [busy, setBusy] = useState('')
  const [error, setError] = useState('')
  const [syncResult, setSyncResult] = useState('')
  const [pullTitle, setPullTitle] = useState('')
  const [githubTitle, setGithubTitle] = useState('')
  const [githubHead, setGithubHead] = useState('')
  const [githubBase, setGithubBase] = useState((repo.head || 'refs/heads/main').replace('refs/heads/', ''))

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

  async function pushToOrigin() {
    setBusy('peer-push')
    setError('')
    setSyncResult('Offering update to origin…')
    try {
      const started = await api.peerPush(repo.name)
      for (let attempt = 0; attempt < 60; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 500))
        const status = await api.peerTransfers()
        const transfer = status.transfers?.find((item) => item.transfer === started.transfer)
        if (transfer && !transfer.active && transfer.message !== 'offering update') {
          await api.peerDeleteTransfer(started.transfer).catch(() => {})
          if (!transfer.ok) throw new Error(transfer.message)
          setSyncResult(transfer.message)
          await onMutate()
          return
        }
      }
      throw new Error('origin did not finish the update in time')
    } catch (cause) {
      setError(cause.message)
      setSyncResult('')
    } finally {
      setBusy('')
    }
  }

  async function openPullRequest() {
    setBusy('peer-pull')
    setError('')
    setSyncResult('Transferring pull request objects…')
    try {
      const started = await api.peerPullRequest(repo.name, pullTitle.trim())
      for (let attempt = 0; attempt < 60; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 500))
        const status = await api.peerTransfers()
        const transfer = status.transfers?.find((item) => item.transfer === started.transfer)
        if (transfer && transfer.message !== 'opening pull request') {
          await api.peerDeleteTransfer(started.transfer).catch(() => {})
          if (!transfer.ok) throw new Error(transfer.message)
          setSyncResult(transfer.message)
          setPullTitle('')
          return
        }
      }
      throw new Error('origin did not finish the pull request in time')
    } catch (cause) {
      setError(cause.message)
      setSyncResult('')
    } finally { setBusy('') }
  }

  async function githubAction(label, start, kinds) {
    setBusy(label); setError(''); setSyncResult('Starting GitHub request…')
    try {
      const before = await api.githubStatus()
      const prior = new Set((before.jobs || []).map((job) => job.job))
      await start()
      for (let attempt = 0; attempt < 90; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 800))
        const status = await api.githubStatus()
        const matching = (status.jobs || []).filter((job) => !prior.has(job.job) && job.repository === repo.name && kinds.includes(job.kind))
        if (matching.some((job) => job.active)) { setSyncResult(matching.find((job) => job.active)?.message || 'Working…'); continue }
        const failed = matching.find((job) => !job.ok)
        if (failed) throw new Error(failed.message)
        if (matching.length) { setSyncResult(matching.map((job) => job.message).join(' · ')); await onMutate(); return }
      }
      throw new Error('GitHub operation did not finish in time')
    } catch (cause) { setError(cause.message); setSyncResult('') } finally { setBusy('') }
  }

  return (
    <div className="settings-grid">
      {error && <div className="inline-error">{error}</div>}
      {repo.peerOrigin && <section className="panel">
        <div className="section-title"><div><h2>Native origin</h2><p>Forked from <code>{repo.peerOrigin.ship}/{repo.peerOrigin.repository}</code>. Ames coordinates updates and Fine carries the verified object snapshot.</p></div></div>
        <div className="form-actions split"><small className="quiet">{syncResult || 'The origin must grant this ship write access.'}</small><button className="button primary" disabled={busy} onClick={pushToOrigin}>{busy === 'peer-push' ? 'Syncing…' : 'Push to origin'}</button></div>
        <div className="subsection"><label><span>Pull request title</span><div className="inline-field"><input value={pullTitle} onChange={(e) => setPullTitle(e.target.value)} placeholder="Describe the change" /><button className="button" disabled={busy || !pullTitle.trim()} onClick={openPullRequest}>{busy === 'peer-pull' ? 'Opening…' : 'Open PR'}</button></div></label></div>
      </section>}
      {repo.githubOrigin && <section className="panel github-panel">
        <div className="section-title"><div><h2>GitHub origin</h2><p>Linked to <a href={`https://github.com/${repo.githubOrigin.owner}/${repo.githubOrigin.repository}`} target="_blank" rel="noreferrer">{repo.githubOrigin.owner}/{repo.githubOrigin.repository}</a>. Code is fetched with Git Smart HTTP; forge data uses GitHub’s API.</p></div><span className="status good">linked</span></div>
        <div className="github-action-grid">
          <button className="button" disabled={busy} onClick={() => githubAction('github-code', () => api.githubImport(repo.githubOrigin.owner, repo.githubOrigin.repository, repo.name, repo.publicRead), ['import', 'update'])}>{busy === 'github-code' ? 'Updating…' : 'Update code'}</button>
          <button className="button" disabled={busy} onClick={() => githubAction('github-meta', () => Promise.all([api.githubMetadata(repo.name, 'issues'), api.githubMetadata(repo.name, 'pulls')]), ['issues', 'pulls'])}>{busy === 'github-meta' ? 'Syncing…' : 'Sync issues & PRs'}</button>
          <button className="button" disabled={busy} onClick={() => githubAction('github-fork', () => api.githubFork(repo.name), ['fork'])}>{busy === 'github-fork' ? 'Requesting…' : 'Fork on GitHub'}</button>
        </div>
        <div className="subsection"><div className="section-title"><div><h3>Open GitHub pull request</h3><p>The head must already exist on GitHub, such as <code>your-name:branch</code>.</p></div></div>
          <div className="three-fields"><label><span>Title</span><input value={githubTitle} onChange={(event) => setGithubTitle(event.target.value)} /></label><label><span>Head</span><input value={githubHead} onChange={(event) => setGithubHead(event.target.value)} placeholder="you:feature" /></label><label><span>Base</span><input value={githubBase} onChange={(event) => setGithubBase(event.target.value)} /></label></div>
          <div className="form-actions"><button className="button primary" disabled={busy || !githubTitle.trim() || !githubHead.trim() || !githubBase.trim()} onClick={() => githubAction('github-pr', () => api.githubPull(repo.name, githubTitle.trim(), githubHead.trim(), githubBase.trim(), ''), ['open-pull'])}>{busy === 'github-pr' ? 'Opening…' : 'Open on GitHub'}</button></div>
        </div>
        {syncResult && <div className="transfer-status">{syncResult}</div>}
      </section>}
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
        <div className="subsection">
          <div className="section-title"><div><h3>Ship writers</h3><p>Authorized ships can send verified, fast-forward updates from native forks.</p></div></div>
          <div className="inline-field"><input value={writer} onChange={(e) => setWriter(e.target.value)} placeholder="~sampel-palnet" /><button className="button" disabled={busy || !writer.trim()} onClick={() => act('writer', async () => { await api.setWriter(repo.name, writer.trim(), true); setWriter('') })}>Grant</button></div>
          <div className="writer-list">
            {(repo.writers || []).map((ship) => <div key={ship}><code>{ship}</code><button className="text-button danger-text" onClick={() => act(`writer-${ship}`, () => api.setWriter(repo.name, ship, false))}>Revoke</button></div>)}
            {!repo.writers?.length && <small className="quiet">No remote writers.</small>}
          </div>
        </div>
      </section>
      <section className="panel danger-zone">
        <div><h2>Delete repository</h2><p>Remove refs, Git objects, binding metadata, and LFS pointers held by this repository.</p></div>
        <button className="button danger" onClick={() => { if (window.confirm(`Delete ${repo.name}? This cannot be undone.`)) act('delete', () => api.remove(repo.name)) }}>Delete</button>
      </section>
    </div>
  )
}

export default function RepositoryView({ repo, onRefresh }) {
  const [tab, setTab] = useState('code')
  const [filePath, setFilePath] = useState('')
  const [branch, setBranch] = useState(repo.head)
  const [detail, setDetail] = useState(null)
  const [loading, setLoading] = useState(true)
  const cloneUrl = `${window.location.origin}/git/${repo.name}.git`

  useEffect(() => {
    let active = true
    setLoading(true)
    const load = tab === 'commits' ? api.commits(repo.name) : tab === 'code' ? Promise.all([api.files(repo.name, branch), api.commits(repo.name)]).then(([files, commits]) => ({ files, commits })) : Promise.resolve(null)
    load.then((data) => active && setDetail(data)).finally(() => active && setLoading(false))
    return () => { active = false }
  }, [repo.name, repo.refs, tab, branch])

  useEffect(() => { setFilePath(''); setBranch(repo.head) }, [repo.name, repo.head])

  function browseBranch(ref) {
    setBranch(ref)
    setFilePath('')
    setTab('code')
  }

  async function mutate() {
    await onRefresh(repo.name)
  }

  return (
    <main className="content">
      <header className="repo-header">
        <div><div className="repo-breadcrumb"><span>{repo.owner}</span><b>/</b><h1>{repo.name}</h1><span className="visibility-badge">{repo.publicRead ? 'Public' : 'Private'}</span></div>{repo.githubOrigin && <a className="origin-link" href={`https://github.com/${repo.githubOrigin.owner}/${repo.githubOrigin.repository}`} target="_blank" rel="noreferrer">GitHub · {repo.githubOrigin.owner}/{repo.githubOrigin.repository} ↗</a>}</div>
        <div className="clone-box"><code>{cloneUrl}</code><button className="icon-button" title="Copy clone URL" onClick={() => navigator.clipboard.writeText(cloneUrl)}><CopyIcon /></button></div>
      </header>
      <div className="repo-meta">
        <span title="Branches, tags, and other named Git pointers"><b>{repo.refs?.length || 0}</b> Git refs</span><span title="Internal Git commits, directory trees, and file blobs"><b>{repo.objectCount || 0}</b> stored Git objects</span><span title="Large file payloads in ship object storage"><b>{repo.lfsObjectCount || 0}</b> LFS files</span>
        {repo.binding?.bound && <span className="clay-chip">Clay · {repo.binding.desk}</span>}
      </div>
      <nav className="tabs">
        {[['code', 'Code'], ['issues', 'Issues', repo.githubIssues?.length], ['pulls', 'Pull requests', (repo.pullRequests?.length || 0) + (repo.githubPulls?.length || 0)], ['branches', 'Branches', (repo.refs || []).filter((ref) => ref.name.startsWith('refs/heads/')).length], ['commits', 'Commits'], ['settings', 'Settings']].map(([name, label, count]) => <button key={name} className={tab === name ? 'active' : ''} onClick={() => setTab(name)}><span>{label}</span>{count > 0 && <b className="tab-count">{count}</b>}</button>)}
      </nav>
      <section className="repo-body">
        {tab === 'code' && <div className="branch-context"><select value={branch} onChange={(event) => browseBranch(event.target.value)}>{(repo.refs || []).filter((ref) => ref.name.startsWith('refs/heads/')).map((ref) => <option key={ref.name} value={ref.name}>{ref.name.replace('refs/heads/', '')}</option>)}</select><span>{detail?.files?.files?.length || 0} files</span>{branch !== repo.head && <button className="text-button" onClick={() => browseBranch(repo.head)}>Default branch</button>}</div>}
        {tab === 'code' && (filePath
          ? <FileView repository={repo.name} path={filePath} branch={branch} editable={branch === repo.head} onBack={() => setFilePath('')} onSaved={mutate} />
          : <Files data={detail?.files} commit={branch === repo.head ? detail?.commits?.commits?.[0] : null} loading={loading} onOpen={setFilePath} />)}
        {tab === 'issues' && <Issues repo={repo} />}
        {tab === 'branches' && <Branches repo={repo} selected={branch} onBrowse={browseBranch} />}
        {tab === 'commits' && <Commits data={detail} loading={loading} />}
        {tab === 'pulls' && <PullRequests repo={repo} onMutate={mutate} />}
        {tab === 'settings' && <Settings repo={repo} onMutate={mutate} />}
      </section>
    </main>
  )
}
