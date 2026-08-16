import { GitIcon, PlusIcon } from './Icons'

export default function Sidebar({ repositories, selected, onSelect, onCreate, onPublishDesk }) {
  return (
    <aside className="sidebar">
      <div className="brand"><GitIcon size={20} /><span>git</span></div>
      <div className="sidebar-heading">
        <span>Repositories</span>
        <button className="icon-button" onClick={onCreate} title="New repository"><PlusIcon /></button>
      </div>
      <button className="publish-desk-button" onClick={onPublishDesk}><span>↗</span> Publish desk</button>
      <nav className="repo-list">
        {repositories.map((repo) => (
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
      </nav>
    </aside>
  )
}
