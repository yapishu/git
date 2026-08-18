import { useEffect, useState } from 'react'
import FileTree from './FileTree'

const shortOid = (oid) => oid ? oid.slice(0, 8) : '—'
const formatDate = (timestamp) => {
  const value = Number(timestamp) * 1000
  return Number.isFinite(value) && value > 0 ? new Date(value).toLocaleString() : ''
}

export default function RemoteRepositoryView({ ship, repository, repositories, data, onFork, onCancelTransfer }) {
  const repo = data?.repository
  const routeTab = () => {
    const query = location.hash.split('?')[1] || ''
    const requested = new URLSearchParams(query).get('tab')
    return ['code', 'pulls', 'commits', 'branches'].includes(requested) ? requested : 'code'
  }
  const [tab, setTab] = useState(routeTab)
  const [forking, setForking] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [transfer, setTransfer] = useState('')
  const [progress, setProgress] = useState(null)
  const [forkDialog, setForkDialog] = useState(false)
  const [localName, setLocalName] = useState(repository)
  const [forkTarget, setForkTarget] = useState(repository)
  const [publicRead, setPublicRead] = useState(true)
  useEffect(() => {
    const restore = () => setTab(routeTab())
    addEventListener('popstate', restore)
    return () => removeEventListener('popstate', restore)
  }, [ship, repo?.name])
  function chooseTab(next) {
    const query = next === 'code' ? '' : `?tab=${encodeURIComponent(next)}`
    history.pushState({}, '', `#/peer/${encodeURIComponent(ship)}/${encodeURIComponent(repo.name)}${query}`)
    setTab(next)
  }
  const existing = repositories.find((item) => item.name === localName.trim())
  const sameOrigin = existing?.peerOrigin?.ship === ship && existing?.peerOrigin?.repository === repository && !existing?.binding?.bound
  const blockedCollision = Boolean(existing && !sameOrigin)
  async function fork(event) {
    event.preventDefault()
    if (forking) return
    const target = localName.trim()
    setForkDialog(false)
    setForking(true)
    setForkTarget(target)
    setProgress({ received: 0, expected: 0, message: 'Contacting peer' })
    const complete = await onFork(ship, repository, target, publicRead, setProgress, setTransfer)
    if (!complete) { setForking(false); setCancelling(false); setTransfer(''); setProgress(null) }
  }
  async function cancelFork() {
    if (!transfer || cancelling) return
    setCancelling(true)
    await onCancelTransfer(transfer)
  }
  if (!repo) return <main className="content"><div className="empty">Repository data is unavailable.</div></main>
  const commits = data.commits?.commits || []
  const pulls = repo.pullRequests || []
  return <main className="content">
    <header className="repo-header"><div><div className="repo-breadcrumb"><span>{ship}</span><b>/</b><h1>{repository}</h1><span className="visibility-badge">Peer</span></div>{repo.description && <p className="repo-description">{repo.description}</p>}</div><button className={`button primary ${forking ? 'is-busy' : ''}`} disabled={forking} onClick={() => { setLocalName(repository); setForkDialog(true) }}>{forking && <span className="spinner" />}{forking ? 'Forking to my ship…' : 'Fork to my ship'}</button></header>
    {forking && <TransferProgress ship={ship} repository={repository} localName={forkTarget} progress={progress} cancelling={cancelling} onCancel={cancelFork} />}
    <div className="repo-meta"><span><b>{repo.fileCount || 0}</b> files</span><span><b>{repo.commitCount || 0}</b> commits</span><span><b>{repo.branchCount || 0}</b> branches</span><span><b>{repo.tagCount || 0}</b> tags</span></div>
    <nav className="tabs"><button className={tab === 'code' ? 'active' : ''} onClick={() => chooseTab('code')}>Code</button><button className={tab === 'pulls' ? 'active' : ''} onClick={() => chooseTab('pulls')}>Pull requests <span className="tab-count">{pulls.length}</span></button><button className={tab === 'commits' ? 'active' : ''} onClick={() => chooseTab('commits')}>Commits <span className="tab-count">{repo.commitCount || commits.length}</span></button><button className={tab === 'branches' ? 'active' : ''} onClick={() => chooseTab('branches')}>Branches <span className="tab-count">{repo.branchCount || 0}</span></button></nav>
    <section className="repo-body">
      {tab === 'code' && <FileTree files={data.files?.files || []} />}
      {tab === 'commits' && <div className="commit-list">{commits.map((commit) => { const date = formatDate(commit.committer?.timestamp); return <div className="commit-row" key={commit.oid}><span className="commit-avatar">{(commit.author?.name || '?').slice(0, 1).toUpperCase()}</span><div><strong>{commit.subject || 'Untitled commit'}</strong><small>{commit.author?.name || commit.author?.email || 'Unknown author'}{date ? ` committed ${date}` : ''}</small></div><code title={commit.oid}>{shortOid(commit.oid)}</code></div> })}</div>}
      {tab === 'pulls' && (!pulls.length ? <div className="empty compact">No native pull requests.</div> : <div className="pull-list">{pulls.map((pull) => <article className="pull-row" key={pull.number}><div><span className={`status ${pull.state === 'open' ? 'good' : ''}`}>{pull.state}</span><h3>#{pull.number} {pull.title}</h3><p><code>{pull.sourceShip}/{pull.sourceRepository}</code> proposes <code>{shortOid(pull.head)}</code> into <code>{shortOid(pull.base)}</code></p></div></article>)}</div>)}
      {tab === 'branches' && <div className="table"><div className="table-head"><span>Branch</span><span>Commit</span></div>{(repo.refs || []).filter((ref) => ref.name.startsWith('refs/heads/')).map((ref) => <div className="table-row" key={ref.name}><strong>{ref.name.replace('refs/heads/', '')}</strong><code>{shortOid(ref.oid)}</code></div>)}</div>}
    </section>
    {forkDialog && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && setForkDialog(false)}><section className="modal-card" role="dialog" aria-modal="true" aria-label="Fork repository"><header><div><span className="eyebrow">Fork</span><h1>{ship}/{repository}</h1></div><button type="button" className="icon-button" onClick={() => setForkDialog(false)} aria-label="Close">×</button></header><form onSubmit={fork}><label><span>Local repository name</span><input autoFocus required pattern="[A-Za-z0-9._-]+" maxLength="100" value={localName} onChange={(event) => setLocalName(event.target.value)} /></label>{sameOrigin && <small className="field-note">This updates the existing fork from the same origin.</small>}{blockedCollision && <small className="field-error">That name belongs to another repository. Choose a different local name.</small>}<label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public local fork</strong><small>Allow other ships and Git clients to fetch this copy.</small></span></label><div className="form-actions"><button type="button" className="button ghost" onClick={() => setForkDialog(false)}>Cancel</button><button className="button primary" disabled={blockedCollision || !localName.trim()}>{sameOrigin ? 'Update fork' : 'Fork repository'}</button></div></form></section></div>}
  </main>
}

function TransferProgress({ ship, repository, localName, progress, cancelling, onCancel }) {
  const received = Number(progress?.received || 0)
  const expected = Number(progress?.expected || 0)
  const percent = expected > 0 ? Math.min(100, Math.round((received / expected) * 100)) : 0
  return <div className="peer-transfer-progress" role="status" aria-live="polite">
    <div><strong>Forking {ship}/{repository} → {localName}</strong><span>{expected > 0 ? `${received} / ${expected} objects · ${percent}%` : progress?.message || 'Preparing repository snapshot…'}</span></div>
    {expected > 0 ? <progress max="100" value={percent}>{percent}%</progress> : <div className="progress-track indeterminate"><i /></div>}
    <div className="peer-transfer-footer"><small>You can leave this view and follow the transfer from peer activity.</small><button className="text-button" disabled={cancelling} onClick={onCancel}>{cancelling ? 'Cancelling…' : 'Cancel transfer'}</button></div>
  </div>
}
