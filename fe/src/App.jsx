import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { api, publicApi, waitForPeerBrowse, waitForPeerTransfer } from './api'
import ForkPeer from './components/ForkPeer'
import GitHubImport from './components/GitHubImport'
import { ActivityIcon, RefreshIcon } from './components/Icons'
import PeerActivity from './components/PeerActivity'
import PublishDesk from './components/PublishDesk'
import RepositoryView from './components/RepositoryView'
import NewRepositoryModal from './components/NewRepositoryModal'
import RemoteRepositoryView from './components/RemoteRepositoryView'
import Settings from './components/Settings'
import Sidebar from './components/Sidebar'

function routeFromHash() {
  const raw = location.hash.replace(/^#\/?/, '').split('?')[0]
  const parts = raw.split('/').filter(Boolean)
  try {
    if (parts[0] === 'settings') return { kind: 'settings' }
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
  const remoteBrowseRef = useRef({ generation: 0, request: '' })
  const [remoteData, setRemoteData] = useState(null)
  const [remoteStatus, setRemoteStatus] = useState('')
  const [remoteProgress, setRemoteProgress] = useState(null)
  const [remoteError, setRemoteError] = useState('')
  const [creating, setCreating] = useState(false)
  const [publishingDesk, setPublishingDesk] = useState(false)
  const [forkingPeer, setForkingPeer] = useState(false)
  const [importingGitHub, setImportingGitHub] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [peerActivity, setPeerActivity] = useState([])
  const [activityOpen, setActivityOpen] = useState(false)
  const [theme, setTheme] = useState(() => localStorage.getItem('urgit-theme') || 'system')

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('urgit-theme', theme)
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
      setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setSettingsOpen(false)
      if (route.kind === 'settings') openSettings(false)
      else if (route.kind === 'peer') {
        const current = remoteSelectedRef.current
        if (!current || current.ship !== route.ship || current.name !== route.name) chooseRemote(route.ship, route.name, false)
      }
      else { setRemoteSelected(null); setRemoteData(null); setRemoteStatus(''); setRemoteProgress(null); setRemoteError(''); setSelected(route.name) }
    }
    addEventListener('popstate', pop)
    if (routeFromHash().kind !== 'repository') pop()
    return () => removeEventListener('popstate', pop)
  }, [])

  function choose(name) {
    remoteBrowseRef.current.generation += 1
    if (remoteBrowseRef.current.request) api.peerDeleteBrowse(remoteBrowseRef.current.request).catch(() => {})
    remoteBrowseRef.current.request = ''
    setCreating(false)
    setPublishingDesk(false)
    setForkingPeer(false)
    setImportingGitHub(false)
    setSettingsOpen(false)
    setRemoteSelected(null)
    setRemoteData(null)
    setRemoteStatus('')
    setRemoteProgress(null)
    setRemoteError('')
    setSelected(name)
    history.pushState({}, '', `#/${encodeURIComponent(name)}`)
  }

  async function chooseRemote(ship, name, pushHistory = true) {
    const current = remoteSelectedRef.current
    if (current?.ship === ship && current?.name === name && (remoteData || remoteBrowseRef.current.request)) return
    const previous = remoteBrowseRef.current.request
    const generation = remoteBrowseRef.current.generation + 1
    remoteBrowseRef.current = { generation, request: '' }
    if (previous) api.peerDeleteBrowse(previous).catch(() => {})
    const selection = { ship, name }
    remoteSelectedRef.current = selection
    setError(''); setRemoteSelected(selection); setRemoteData(null); setRemoteStatus('Contacting peer'); setRemoteProgress(null); setRemoteError(''); setSelected('')
    setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setSettingsOpen(false)
    if (pushHistory) history.pushState({}, '', `#/peer/${encodeURIComponent(ship)}/${encodeURIComponent(name)}`)
    try {
      for (let attempt = 0; attempt < 2; attempt += 1) {
        const started = await api.peerBrowse(ship, name)
        if (remoteBrowseRef.current.generation !== generation) {
          await api.peerDeleteBrowse(started.request).catch(() => {})
          return
        }
        remoteBrowseRef.current.request = started.request
        let found
        try {
          found = await waitForPeerBrowse(started.request, {
            onProgress: (browse) => {
              if (remoteBrowseRef.current.generation === generation) {
                setRemoteStatus(browse.message || 'Loading from peer')
                setRemoteProgress(browse.progress || null)
              }
            },
          })
        } catch (cause) {
          if (remoteBrowseRef.current.generation !== generation) return
          remoteBrowseRef.current.request = ''
          if (cause.code === 'PEER_BROWSE_MISSING' && attempt === 0) {
            setRemoteStatus('Restarting peer browse after agent reload')
            continue
          }
          if (cause.code === 'PEER_BROWSE_MISSING') {
            throw new Error('Peer browse was interrupted while the app reloaded. Retry when the ship is ready.')
          }
          throw cause
        }
        await api.peerDeleteBrowse(started.request).catch(() => {})
        if (remoteBrowseRef.current.generation !== generation) return
        remoteBrowseRef.current.request = ''
        if (!found.ok) throw new Error(found.message)
        if (found.ship !== ship || found.repository !== name || found.result?.repository?.name !== name) {
          throw new Error('peer browse returned a different repository')
        }
        setRemoteStatus('')
        setRemoteProgress(null)
        setRemoteData(found.result)
        return
      }
    } catch (cause) {
      if (remoteBrowseRef.current.generation === generation) {
        remoteBrowseRef.current.request = ''
        setRemoteStatus('')
        setRemoteProgress(null)
        setRemoteError(cause.message)
      }
    }
  }

  async function forkRemote(ship, repository, onProgress) {
    setError('')
    try {
      const started = await api.peerFork(ship, repository, repository, true)
      const result = await waitForPeerTransfer(started.transfer, { onProgress })
      await api.peerDeleteTransfer(started.transfer).catch(() => {})
      if (!result.ok) throw new Error(result.message)
      await refresh(repository); choose(repository); return true
    } catch (cause) { setError(cause.message); return false }
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

  function openSettings(pushHistory = true) {
    remoteBrowseRef.current.generation += 1
    if (remoteBrowseRef.current.request) api.peerDeleteBrowse(remoteBrowseRef.current.request).catch(() => {})
    remoteBrowseRef.current.request = ''
    remoteSelectedRef.current = null
    setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false)
    setRemoteSelected(null); setRemoteData(null); setRemoteStatus(''); setRemoteError('')
    setSettingsOpen(true)
    if (pushHistory) history.pushState({ urgitSettings: true }, '', '#/settings')
  }

  function closeSettings() {
    if (history.state?.urgitSettings) history.back()
    else choose(selected || repositories[0]?.name || '')
  }

  return (
    <div className="app-shell">
      <Sidebar repositories={repositories} peers={peers} selected={selected} remoteSelected={remoteSelected} onSelect={choose} onSelectRemote={chooseRemote} onCreate={() => setCreating(true)} onPeersChanged={refreshPeers} onSettings={openSettings} />
      <div className="workspace">
        <div className="topbar">
          <span className="topbar-label">{settingsOpen ? 'Settings' : repo ? repo.owner : 'Repositories'}</span>
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
        {settingsOpen ? (
          <Settings theme={theme} onThemeChange={setTheme} repositoryCount={repositories.length} peerCount={peers.length} onImport={() => { setSettingsOpen(false); setImportingGitHub(true) }} onBack={closeSettings} />
        ) : importingGitHub ? (
          <GitHubImport onComplete={published} onCancel={() => setImportingGitHub(false)} />
        ) : forkingPeer ? (
          <ForkPeer repositories={repositories} onComplete={published} onCancel={() => setForkingPeer(false)} />
        ) : publishingDesk ? (
          <PublishDesk repositories={repositories} onComplete={published} onCancel={() => setPublishingDesk(false)} />
        ) : remoteSelected ? (
          remoteData ? <RemoteRepositoryView key={`${remoteSelected.ship}/${remoteSelected.name}`} ship={remoteSelected.ship} repository={remoteSelected.name} data={remoteData} onFork={forkRemote} /> : remoteError ? <main className="content"><div className="empty remote-browse-failure"><strong>Could not load {remoteSelected.ship}/{remoteSelected.name}</strong><span>{remoteError}</span><button className="button primary" onClick={() => chooseRemote(remoteSelected.ship, remoteSelected.name, false)}>Retry</button></div></main> : <main className="content"><div className="empty remote-browse-loading"><span className="spinner" />Loading {remoteSelected.ship}/{remoteSelected.name} from peer…<small>{remoteStatus}</small><BrowseProgress progress={remoteProgress} /></div></main>
        ) : repo ? (
          <RepositoryView repo={repo} onRefresh={refresh} onOpenOrigin={chooseRemote} />
        ) : (
          <main className="content welcome">
            <h1>{loading ? 'Loading repositories…' : 'Repositories'}</h1>
            {!loading && <><p>No repositories.</p><button className="button primary" onClick={() => setCreating(true)}>New repository</button></>}
          </main>
        )}
      </div>
      {creating && <NewRepositoryModal onCreate={create} onClose={() => setCreating(false)} onPublishDesk={() => { setForkingPeer(false); setImportingGitHub(false); setSettingsOpen(false); setPublishingDesk(true) }} onForkPeer={() => { setPublishingDesk(false); setImportingGitHub(false); setSettingsOpen(false); setForkingPeer(true) }} onImportGitHub={() => { setPublishingDesk(false); setForkingPeer(false); setSettingsOpen(false); setImportingGitHub(true) }} />}
    </div>
  )
}

function BrowseProgress({ progress }) {
  const received = Number(progress?.received || 0)
  const expected = Number(progress?.expected || 0)
  if (expected > 0) {
    const percent = Math.min(100, Math.round((received / expected) * 100))
    return <div className="remote-browse-progress"><progress max={expected} value={received}>{percent}%</progress><span>{received} / {expected} pages · {percent}%</span></div>
  }
  return <div className="progress-track indeterminate remote-browse-progress"><i /></div>
}

function PublicApp({ name }) {
  const [repo, setRepo] = useState(null)
  const [error, setError] = useState('')
  const [theme, setTheme] = useState(() => localStorage.getItem('urgit-theme') || 'system')

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('urgit-theme', theme)
  }, [theme])
  useEffect(() => {
    publicApi.repository(name).then(setRepo).catch((cause) => setError(cause.message))
  }, [name])

  const nextTheme = { system: 'light', light: 'dark', dark: 'system' }[theme]
  return <div className="public-shell">
    <div className="workspace">
      <div className="topbar"><a className="public-brand" href="/apps/urgit/">urgit</a><div className="topbar-actions"><span className="public-read-label">read only</span><button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button></div></div>
      {error ? <main className="content"><div className="empty">{error}</div></main> : repo ? <RepositoryView repo={repo} publicMode client={publicApi} /> : <main className="content"><div className="empty">Loading repository…</div></main>}
    </div>
  </div>
}

export default function App() {
  const match = location.pathname.match(/^\/apps\/urgit\/public\/([^/]+)\/?$/)
  return match ? <PublicApp name={decodeURIComponent(match[1])} /> : <PrivateApp />
}
