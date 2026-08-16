import { useMemo, useState } from 'react'
import { GitIcon, PlusIcon } from './Icons'

export default function Sidebar({ repositories, selected, onSelect, onCreate, onPublishDesk, onForkPeer, onImportGitHub, onGitHubSettings }) {
  const [query, setQuery] = useState('')
  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return needle ? repositories.filter((repo) => repo.name.toLowerCase().includes(needle)) : repositories
  }, [query, repositories])

  return (
    <aside className="sidebar">
      <div className="brand"><GitIcon size={20} /><span>git</span></div>
      <div className="sidebar-heading">
        <span>Repositories</span>
        <button className="icon-button" onClick={onCreate} title="New repository"><PlusIcon /></button>
      </div>
      <button className="publish-desk-button" onClick={onPublishDesk}><span>↗</span> Publish desk</button>
      <button className="publish-desk-button" onClick={onForkPeer}><span>⇣</span> Fork from ship</button>
      <button className="publish-desk-button" onClick={onImportGitHub}><span>⌁</span> Import from GitHub</button>
      {repositories.length > 5 && <input className="repo-search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Find a repository…" aria-label="Find a repository" />}
      <nav className="repo-list">
        {visible.map((repo) => (
          <button
            key={repo.name}
            className={repo.name === selected ? 'repo-link active' : 'repo-link'}
            onClick={() => onSelect(repo.name)}
          >
            <span className="repo-mark" />
            <span className="truncate">{repo.name}</span>
            {!repo.publicRead && <span className="lock" title="Private">private</span>}
          </button>
        ))}
        {!repositories.length && <p className="quiet sidebar-empty">No repositories yet.</p>}
        {repositories.length > 0 && !visible.length && <p className="quiet sidebar-empty">No matching repositories.</p>}
      </nav>
      <div className="sidebar-footer"><button className="repo-link" onClick={onGitHubSettings}><span className="github-mark">GH</span><span>GitHub</span><span className="sidebar-arrow">›</span></button></div>
    </aside>
  )
}
