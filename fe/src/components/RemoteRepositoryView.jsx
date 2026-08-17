import { useState } from 'react'
import FileTree from './FileTree'

const shortOid = (oid) => oid ? oid.slice(0, 8) : '—'
const formatDate = (timestamp) => {
  const value = Number(timestamp) * 1000
  return Number.isFinite(value) && value > 0 ? new Date(value).toLocaleString() : ''
}

export default function RemoteRepositoryView({ ship, data, onFork }) {
  const [tab, setTab] = useState('code')
  const repo = data?.repository
  if (!repo) return <main className="content"><div className="empty">Repository data is unavailable.</div></main>
  const commits = data.commits?.commits || []
  const pulls = repo.pullRequests || []
  return <main className="content">
    <header className="repo-header"><div><div className="repo-breadcrumb"><span>{ship}</span><b>/</b><h1>{repo.name}</h1><span className="visibility-badge">Peer</span></div>{repo.description && <p className="repo-description">{repo.description}</p>}</div><button className="button primary" onClick={() => onFork(ship, repo.name)}>Fork repository</button></header>
    <div className="repo-meta"><span><b>{repo.fileCount || 0}</b> files</span><span><b>{repo.commitCount || 0}</b> commits</span><span><b>{repo.branchCount || 0}</b> branches</span><span><b>{repo.tagCount || 0}</b> tags</span></div>
    <nav className="tabs"><button className={tab === 'code' ? 'active' : ''} onClick={() => setTab('code')}>Code</button><button className={tab === 'pulls' ? 'active' : ''} onClick={() => setTab('pulls')}>Pull requests <span className="tab-count">{pulls.length}</span></button><button className={tab === 'commits' ? 'active' : ''} onClick={() => setTab('commits')}>Commits <span className="tab-count">{commits.length}</span></button><button className={tab === 'branches' ? 'active' : ''} onClick={() => setTab('branches')}>Branches <span className="tab-count">{repo.branchCount || 0}</span></button></nav>
    <section className="repo-body">
      {tab === 'code' && <FileTree files={data.files?.files || []} />}
      {tab === 'commits' && <div className="commit-list">{commits.map((commit) => { const date = formatDate(commit.committer?.timestamp); return <div className="commit-row" key={commit.oid}><span className="commit-avatar">{(commit.author?.name || '?').slice(0, 1).toUpperCase()}</span><div><strong>{commit.subject || 'Untitled commit'}</strong><small>{commit.author?.name || commit.author?.email || 'Unknown author'}{date ? ` committed ${date}` : ''}</small></div><code title={commit.oid}>{shortOid(commit.oid)}</code></div> })}</div>}
      {tab === 'pulls' && (!pulls.length ? <div className="empty compact">No native pull requests.</div> : <div className="pull-list">{pulls.map((pull) => <article className="pull-row" key={pull.number}><div><span className={`status ${pull.state === 'open' ? 'good' : ''}`}>{pull.state}</span><h3>#{pull.number} {pull.title}</h3><p><code>{pull.sourceShip}/{pull.sourceRepository}</code> proposes <code>{shortOid(pull.head)}</code> into <code>{shortOid(pull.base)}</code></p></div></article>)}</div>)}
      {tab === 'branches' && <div className="table"><div className="table-head"><span>Branch</span><span>Commit</span></div>{(repo.refs || []).filter((ref) => ref.name.startsWith('refs/heads/')).map((ref) => <div className="table-row" key={ref.name}><strong>{ref.name.replace('refs/heads/', '')}</strong><code>{shortOid(ref.oid)}</code></div>)}</div>}
    </section>
  </main>
}
