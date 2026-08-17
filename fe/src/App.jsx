import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { api, publicApi } from './api'
import ForkPeer from './components/ForkPeer'
import GitHubImport from './components/GitHubImport'
import GitHubSettings from './components/GitHubSettings'
import { ActivityIcon, RefreshIcon } from './components/Icons'
import PeerActivity from './components/PeerActivity'
import PublishDesk from './components/PublishDesk'
import RepositoryView from './components/RepositoryView'
import NewRepositoryModal from './components/NewRepositoryModal'
import RemoteRepositoryView from './components/RemoteRepositoryView'
import Sidebar from './components/Sidebar'

function routeFromHash() {
  const raw = location.hash.replace(/^#\/?/, '').split('?')[0]
  const parts = raw.split('/').filter(Boolean)
  try {
    if (parts[0] === 'peer' && parts.length >= 3) return { kind: 'peer', ship: decodeURIComponent(parts[1]), name: decodeURIComponent(parts[2]) }
    return { kind: 'repository', name: parts[0] ? decodeURIComponent(parts[0]) : '' }
  } catch {
    return { kind: 'repository', name: '' }
  }
}

const repoFromHash = () => {
  const route = routeFromHash()
  return route.kind === 'repository' ? route.name : ''
}

function PrivateApp() {
  const [repositories, setRepositories] = useState([])
  const [peers, setPeers] = useState([])
  const [selected, setSelected] = useState(repoFromHash())
  const [remoteSelected, setRemoteSelected] = useState(null)
  const remoteSelectedRef = useRef(null)
  const [remoteData, setRemoteData] = useState(null)
  const [creating, setCreating] = useState(false)
  const [publishingDesk, setPublishingDesk] = useState(false)
  const [forkingPeer, setForkingPeer] = useState(false)
  const [importingGitHub, setImportingGitHub] = useState(false)
  const [githubSettings, setGithubSettings] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [peerActivity, setPeerActivity] = useState([])
  const [activityOpen, setActivityOpen] = useState(false)
  const [theme, setTheme] = useState(() => localStorage.getItem('git-theme') || 'system')

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('git-theme', theme)
  }, [theme])
  useEffect(() => { remoteSelectedRef.current = remoteSelected }, [remoteSelected])

  const refresh = useCallback(async (preferred) => {
    setError('')
    try {
      const data = await api.repositories()
      const repos = data.repositories || []
      setRepositories(repos)
      const target = preferred || selected
      if (target && repos.some((repo) => repo.name === target)) {
        setSelected(target)
        return true
      }
      const fallback = repos[0]?.name || ''
      setSelected(fallback)
      const route = routeFromHash()
      if (fallback && route.kind === 'repository') history.replaceState({}, '', `#/${encodeURIComponent(fallback)}`)
      return false
    } catch (cause) {
      setError(cause.message)
      return false
    } finally {
      setLoading(false)
    }
  }, [selected])

  useEffect(() => { refresh() }, [])
  const refreshPeers = useCallback(async () => {
    try { const data = await api.peers(); setPeers(data.peers || []) } catch (cause) { setError(cause.message) }
  }, [])
  useEffect(() => { refreshPeers() }, [refreshPeers])
  const refreshActivity = useCallback(async () => {
    try {
      const data = await api.peerActivity()
      setPeerActivity(data.activity || [])
    } catch {
      // Repository use remains available if the activity endpoint is reloading.
    }
  }, [])
  useEffect(() => {
    refreshActivity()
    const timer = setInterval(refreshActivity, 4000)
    return () => clearInterval(timer)
  }, [refreshActivity])
  useEffect(() => {
    const pop = () => {
      const route = routeFromHash()
      setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false)
      if (route.kind === 'peer') {
        const current = remoteSelectedRef.current
        if (!current || current.ship !== route.ship || current.name !== route.name) chooseRemote(route.ship, route.name, false)
      }
      else { setRemoteSelected(null); setRemoteData(null); setSelected(route.name) }
    }
    addEventListener('popstate', pop)
    if (routeFromHash().kind === 'peer') pop()
    return () => removeEventListener('popstate', pop)
  }, [])

  function choose(name) {
    setCreating(false)
    setPublishingDesk(false)
    setForkingPeer(false)
    setImportingGitHub(false)
    setGithubSettings(false)
    setRemoteSelected(null)
    setRemoteData(null)
    setSelected(name)
    history.pushState({}, '', `#/${encodeURIComponent(name)}`)
  }

  async function chooseRemote(ship, name, pushHistory = true) {
    setError(''); setRemoteSelected({ ship, name }); setRemoteData(null); setSelected('')
    setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false)
    if (pushHistory) history.pushState({}, '', `#/peer/${encodeURIComponent(ship)}/${encodeURIComponent(name)}`)
    try {
      const started = await api.peerBrowse(ship, name)
      for (let attempt = 0; attempt < 60; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 500))
        const status = await api.peerBrowses()
        const found = status.browses?.find((item) => item.request === started.request)
        if (found && !found.active) {
          await api.peerDeleteBrowse(started.request).catch(() => {})
          if (!found.ok) throw new Error(found.message)
          setRemoteData(found.result); return
        }
      }
      throw new Error('peer repository did not load in time')
    } catch (cause) { setError(cause.message) }
  }

  async function forkRemote(ship, repository) {
    setError('')
    try {
      const started = await api.peerFork(ship, repository, repository, true)
      for (let attempt = 0; attempt < 120; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 500))
        const status = await api.peerTransfers()
        const found = status.transfers?.find((item) => item.transfer === started.transfer)
        if (found && !found.active && found.message !== 'transferring') {
          await api.peerDeleteTransfer(started.transfer).catch(() => {})
          if (!found.ok) throw new Error(found.message)
          await refresh(repository); choose(repository); return
        }
      }
      throw new Error('fork did not complete in time')
    } catch (cause) { setError(cause.message) }
  }

  async function published(name) {
    await refresh(name)
    choose(name)
    setTimeout(() => refresh(name), 1200)
  }

  async function create(name, publicRead, description = '') {
    try {
      await api.create(name, publicRead)
      if (description) await api.setDescription(name, description)
      await refresh(name)
      choose(name)
    } catch (cause) {
      setError(cause.message)
    }
  }

  const repo = useMemo(() => repositories.find((item) => item.name === selected), [repositories, selected])
  const nextTheme = { system: 'light', light: 'dark', dark: 'system' }[theme]
  const activePeers = peerActivity.filter((item) => item.status === 'active').length

  async function clearActivity() {
    try {
      await api.clearPeerActivity()
      setPeerActivity([])
    } catch (cause) {
      setError(cause.message)
    }
  }

  return (
    <div className="app-shell">
      <Sidebar repositories={repositories} peers={peers} selected={selected} remoteSelected={remoteSelected} onSelect={choose} onSelectRemote={chooseRemote} onCreate={() => setCreating(true)} onPeersChanged={refreshPeers} onGitHubSettings={() => { setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setRemoteSelected(null); setGithubSettings(true) }} />
      <div className="workspace">
        <div className="topbar">
          <span className="topbar-label">{repo ? repo.owner : 'Repositories'}</span>
          <div className="topbar-actions">
            <div className="activity-anchor">
              <button className="icon-button activity-button" onClick={() => { setActivityOpen((open) => !open); refreshActivity() }} title="Peer activity"><ActivityIcon />{activePeers > 0 && <span className="activity-badge">{activePeers}</span>}</button>
              {activityOpen && <PeerActivity activity={peerActivity} onClear={clearActivity} />}
            </div>
            <button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button>
            <button className="icon-button" onClick={() => refresh(selected)} title="Refresh"><RefreshIcon /></button>
          </div>
        </div>
        {error && <div className="error-banner"><span>{error}</span><button onClick={() => setError('')}>×</button></div>}
        {githubSettings ? (
          <GitHubSettings onImport={() => { setGithubSettings(false); setImportingGitHub(true) }} onBack={() => setGithubSettings(false)} />
        ) : importingGitHub ? (
          <GitHubImport onComplete={published} onCancel={() => setImportingGitHub(false)} />
        ) : forkingPeer ? (
          <ForkPeer repositories={repositories} onComplete={published} onCancel={() => setForkingPeer(false)} />
        ) : publishingDesk ? (
          <PublishDesk repositories={repositories} onComplete={published} onCancel={() => setPublishingDesk(false)} />
        ) : remoteSelected ? (
          remoteData ? <RemoteRepositoryView ship={remoteSelected.ship} data={remoteData} onFork={forkRemote} /> : <main className="content"><div className="empty">Remotely scrying {remoteSelected.ship}/{remoteSelected.name}...</div></main>
        ) : repo ? (
          <RepositoryView repo={repo} onRefresh={refresh} onOpenOrigin={chooseRemote} />
        ) : (
          <main className="content welcome">
            <h1>{loading ? 'Loading repositories…' : 'Repositories'}</h1>
            {!loading && <><p>No repositories.</p><button className="button primary" onClick={() => setCreating(true)}>New repository</button></>}
          </main>
        )}
      </div>
      {creating && <NewRepositoryModal onCreate={create} onClose={() => setCreating(false)} onPublishDesk={() => { setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false); setPublishingDesk(true) }} onForkPeer={() => { setPublishingDesk(false); setImportingGitHub(false); setGithubSettings(false); setForkingPeer(true) }} onImportGitHub={() => { setPublishingDesk(false); setForkingPeer(false); setGithubSettings(false); setImportingGitHub(true) }} />}
    </div>
  )
}

function PublicApp({ name }) {
  const [repo, setRepo] = useState(null)
  const [error, setError] = useState('')
  const [theme, setTheme] = useState(() => localStorage.getItem('git-theme') || 'system')

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('git-theme', theme)
  }, [theme])
  useEffect(() => {
    publicApi.repository(name).then(setRepo).catch((cause) => setError(cause.message))
  }, [name])

  const nextTheme = { system: 'light', light: 'dark', dark: 'system' }[theme]
  return <div className="public-shell">
    <div className="workspace">
      <div className="topbar"><a className="public-brand" href="/apps/git/">git</a><div className="topbar-actions"><span className="public-read-label">read only</span><button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button></div></div>
      {error ? <main className="content"><div className="empty">{error}</div></main> : repo ? <RepositoryView repo={repo} publicMode client={publicApi} /> : <main className="content"><div className="empty">Loading repository…</div></main>}
    </div>
  </div>
}

export default function App() {
  const match = location.pathname.match(/^\/apps\/git\/public\/([^/]+)\/?$/)
  return match ? <PublicApp name={decodeURIComponent(match[1])} /> : <PrivateApp />
}
