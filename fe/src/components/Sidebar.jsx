import { useMemo, useState } from 'react'
import { api } from '../api'
import { GitIcon, PlusIcon } from './Icons'

export default function Sidebar({ repositories, peers, selected, remoteSelected, onSelect, onSelectRemote, onCreate, onPeersChanged, onGitHubSettings }) {
  const [query, setQuery] = useState('')
  const [addingPeer, setAddingPeer] = useState(false)
  const [peerName, setPeerName] = useState('')
  const [expanded, setExpanded] = useState({})
  const [catalogs, setCatalogs] = useState({})
  const [peerError, setPeerError] = useState('')
  const visible = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return needle ? repositories.filter((repo) => repo.name.toLowerCase().includes(needle)) : repositories
  }, [query, repositories])

  async function addPeer(event) {
    event.preventDefault(); setPeerError('')
    try { await api.addPeer(peerName.trim()); setPeerName(''); setAddingPeer(false); await onPeersChanged() } catch (cause) { setPeerError(cause.message) }
  }

  async function togglePeer(ship) {
    if (expanded[ship]) { setExpanded((value) => ({ ...value, [ship]: false })); return }
    setExpanded((value) => ({ ...value, [ship]: true }))
    setCatalogs((value) => ({ ...value, [ship]: { loading: true, repositories: [] } }))
    try {
      const started = await api.peerDiscover(ship)
      for (let attempt = 0; attempt < 60; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 500))
        const status = await api.peerDiscoveries()
        const found = status.discoveries?.find((item) => item.request === started.request)
        if (found && !found.active) {
          await api.peerDeleteDiscovery(started.request).catch(() => {})
          if (!found.ok) throw new Error(found.message)
          setCatalogs((value) => ({ ...value, [ship]: { loading: false, repositories: found.repositories || [] } }))
          return
        }
      }
      throw new Error('peer did not answer in time')
    } catch (cause) { setCatalogs((value) => ({ ...value, [ship]: { loading: false, error: cause.message, repositories: [] } })) }
  }

  async function removePeer(ship, event) {
    event.stopPropagation()
    await api.removePeer(ship); await onPeersChanged()
  }

  return (
    <aside className="sidebar">
      <div className="brand"><GitIcon size={20} /><span>urgit</span></div>
      <div className="sidebar-heading">
        <span>Repositories</span>
        <button className="icon-button" onClick={onCreate} title="New repository"><PlusIcon /></button>
      </div>
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
      <div className="sidebar-heading peer-heading"><span>Peers</span><button className="icon-button" onClick={() => setAddingPeer((value) => !value)} title="Add peer"><PlusIcon /></button></div>
      {addingPeer && <form className="peer-add" onSubmit={addPeer}><input autoFocus value={peerName} onChange={(event) => setPeerName(event.target.value)} placeholder="~sampel-palnet" /><button className="button" disabled={!peerName.trim()}>Add</button></form>}
      {peerError && <small className="field-error sidebar-peer-error">{peerError}</small>}
      <nav className="peer-tree">
        {peers.map((ship) => <div className="peer-node" key={ship}>
          <div className="peer-link-row"><button className="repo-link peer-link" onClick={() => togglePeer(ship)}><span className="peer-chevron">{expanded[ship] ? '⌄' : '›'}</span><code>{ship}</code></button><button className="peer-remove" onClick={(event) => removePeer(ship, event)} title="Remove peer">×</button></div>
          {expanded[ship] && <div className="peer-children">
            {catalogs[ship]?.loading && <small>Contacting peer…</small>}
            {catalogs[ship]?.error && <small className="field-error">{catalogs[ship].error}</small>}
            {catalogs[ship] && !catalogs[ship].loading && !catalogs[ship].repositories.length && !catalogs[ship].error && <small>No accessible repositories.</small>}
            {(catalogs[ship]?.repositories || []).map((repo) => <button key={repo.name} className={remoteSelected?.ship === ship && remoteSelected?.name === repo.name ? 'repo-link remote-repo-link active' : 'repo-link remote-repo-link'} onClick={() => onSelectRemote(ship, repo.name)}><span className="repo-mark" /><span className="truncate">{repo.name}</span>{repo.writable && <span className="write-badge">write</span>}</button>)}
          </div>}
        </div>)}
        {!peers.length && <small className="quiet peer-empty">Add a ship to browse its repositories.</small>}
      </nav>
      <div className="sidebar-footer"><button className="repo-link" onClick={onGitHubSettings}><span className="github-mark">GH</span><span>GitHub</span><span className="sidebar-arrow">›</span></button></div>
    </aside>
  )
}
