import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { api, publicApi, waitForPeerBrowse, waitForPeerTransfer } from './api'
import ForkPeer from './components/ForkPeer'
import { ConfirmProvider } from './components/ConfirmDialog'
import GitHubImport from './components/GitHubImport'
import { ActivityIcon, BackIcon, ForwardIcon, SettingsIcon } from './components/Icons'
import PeerActivity from './components/PeerActivity'
import PublishDesk from './components/PublishDesk'
import RepositoryView from './components/RepositoryView'
import NewRepositoryModal from './components/NewRepositoryModal'
import RemoteRepositoryView from './components/RemoteRepositoryView'
import Settings from './components/Settings'
import Sidebar from './components/Sidebar'
import UrbitSigil from './components/UrbitSigil'
import { exactTime, newestRepositoriesFirst, relativeTime } from './format'
import { readRemoteCache, remoteCacheIsUsable, writeRemoteCache } from './remoteCache'
import { watchAgent } from './channel'
import { emptyFeed, mergeFeed } from './transferFeed'

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
  const [remoteError, setRemoteError] = useState('')
  const [remoteCacheState, setRemoteCacheState] = useState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: 0 })
  const [creating, setCreating] = useState(false)
  const [publishingDesk, setPublishingDesk] = useState(false)
  const [forkingPeer, setForkingPeer] = useState(false)
  const [importingGitHub, setImportingGitHub] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [transferFeed, setTransferFeed] = useState(emptyFeed)
  const [transfersSubscribed, setTransfersSubscribed] = useState(false)
  const peerActivity = transferFeed.activity
  const urgitNotifications = transferFeed.notifications
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
      setTransferFeed((previous) => mergeFeed(previous, data))
    } catch {
      // Repository use remains available if the activity endpoint is reloading.
    }
  }, [])
  // The ship pushes transfer state on /peer/activity. Polling stays as the
  // fallback and runs only while the subscription is down.
  useEffect(() => {
    let channel = null
    let live = true
    ;(async () => {
      let ship = ''
      try { ship = (await publicApi.profile()).ship } catch { return }
      if (!live || !ship) return
      channel = watchAgent({
        ship,
        app: 'urgit',
        path: '/peer/activity',
        onFact: (json) => setTransferFeed((previous) => mergeFeed(previous, json)),
        onStatus: (status) => setTransfersSubscribed(status === 'open'),
      })
    })()
    return () => { live = false; setTransfersSubscribed(false); channel?.close() }
  }, [])
  useEffect(() => {
    refreshActivity()
    if (transfersSubscribed) return undefined
    const timer = setInterval(refreshActivity, 4000)
    return () => clearInterval(timer)
  }, [refreshActivity, transfersSubscribed])
  useEffect(() => {
    const pop = () => {
      const route = routeFromHash()
      setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setSettingsOpen(false)
      if (route.kind === 'settings') openSettings(false)
      else if (route.kind === 'peer') {
        const current = remoteSelectedRef.current
        if (!current || current.ship !== route.ship || current.name !== route.name) chooseRemote(route.ship, route.name, false)
      }
      else { setRemoteSelected(null); setRemoteData(null); setRemoteStatus(''); setRemoteError(''); setRemoteCacheState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: 0 }); setSelected(route.name) }
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
    setRemoteError('')
    setRemoteCacheState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: 0 })
    setSelected(name)
    history.pushState({}, '', `#/${encodeURIComponent(name)}`)
  }

  async function chooseRemote(ship, name, pushHistory = true, force = false) {
    const current = remoteSelectedRef.current
    if (!force && current?.ship === ship && current?.name === name && (remoteData || remoteBrowseRef.current.request)) return
    const previous = remoteBrowseRef.current.request
    const generation = remoteBrowseRef.current.generation + 1
    remoteBrowseRef.current = { generation, request: '' }
    if (previous) await api.peerDeleteBrowse(previous).catch(() => {})
    const selection = { ship, name }
    remoteSelectedRef.current = selection
    setError(''); setRemoteSelected(selection); setRemoteData(null); setRemoteStatus('Checking local cache'); setRemoteError(''); setRemoteCacheState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: 0 }); setSelected('')
    setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setSettingsOpen(false)
    if (pushHistory) history.pushState({}, '', `#/peer/${encodeURIComponent(ship)}/${encodeURIComponent(name)}`)
    try {
      if (!force) {
        const cached = await readRemoteCache(ship, name)
        if (remoteBrowseRef.current.generation !== generation) return
        if (remoteCacheIsUsable(cached)) {
          setRemoteData(cached.data)
          setRemoteStatus('')
          setRemoteCacheState({ cached: true, checking: true, newer: false, checkFailed: false, cachedAt: cached.cachedAt })
          try {
            const started = await api.peerStamp(ship, name)
            if (remoteBrowseRef.current.generation !== generation) {
              await api.peerDeleteBrowse(started.request).catch(() => {})
              return
            }
            remoteBrowseRef.current.request = started.request
            const found = await waitForPeerBrowse(started.request)
            await api.peerDeleteBrowse(started.request).catch(() => {})
            if (remoteBrowseRef.current.generation !== generation) return
            remoteBrowseRef.current.request = ''
            const revision = found.result?.revision
            const valid = found.ok && found.ship === ship && found.repository === name && found.result?.repository?.name === name && revision
            setRemoteCacheState({ cached: true, checking: false, newer: Boolean(valid && revision !== cached.revision), checkFailed: !valid, cachedAt: cached.cachedAt })
          } catch {
            if (remoteBrowseRef.current.generation === generation) {
              remoteBrowseRef.current.request = ''
              setRemoteCacheState({ cached: true, checking: false, newer: false, checkFailed: true, cachedAt: cached.cachedAt })
            }
          }
          return
        }
      }
      setRemoteStatus(force ? 'Refreshing from peer' : 'Contacting peer')
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
              }
            },
          })
        } catch (cause) {
          if (remoteBrowseRef.current.generation !== generation) return
          await api.peerDeleteBrowse(started.request).catch(() => {})
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
        setRemoteData(found.result)
        setRemoteCacheState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: Date.now() })
        await writeRemoteCache(ship, name, found.result.revision, found.result)
        return
      }
    } catch (cause) {
      if (remoteBrowseRef.current.generation === generation) {
        remoteBrowseRef.current.request = ''
        setRemoteStatus('')
        setRemoteError(cause.message)
      }
    }
  }

  async function forkRemote(ship, repository, localName, publicRead, onProgress, onStarted) {
    setError('')
    try {
      const started = await api.peerFork(ship, repository, localName, publicRead)
      onStarted?.(started.transfer)
      const result = await waitForPeerTransfer(started.transfer, { onProgress })
      await api.peerDeleteTransfer(started.transfer).catch(() => {})
      if (!result.ok) throw new Error(result.message)
      await refresh(localName); choose(localName); return true
    } catch (cause) {
      if (cause.message !== 'transfer cancelled') setError(cause.message)
      return false
    }
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
  const activityCount = peerActivity.filter((item) => item.status === 'active').length + urgitNotifications.length

  async function clearActivity() {
    try {
      await api.clearPeerActivity()
      setTransferFeed((previous) => mergeFeed(previous, { activity: [], notifications: [] }))
    } catch (cause) {
      setError(cause.message)
    }
  }

  async function cancelTransfer(transfer) {
    try {
      await api.peerDeleteTransfer(transfer)
      await refreshActivity()
    } catch (cause) {
      if (!/not found/i.test(cause.message)) setError(cause.message)
    }
  }

  function openSettings(pushHistory = true) {
    remoteBrowseRef.current.generation += 1
    if (remoteBrowseRef.current.request) api.peerDeleteBrowse(remoteBrowseRef.current.request).catch(() => {})
    remoteBrowseRef.current.request = ''
    remoteSelectedRef.current = null
    setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false)
    setRemoteSelected(null); setRemoteData(null); setRemoteStatus(''); setRemoteError(''); setRemoteCacheState({ cached: false, checking: false, newer: false, checkFailed: false, cachedAt: 0 })
    setSettingsOpen(true)
    if (pushHistory) history.pushState({ urgitSettings: true }, '', '#/settings')
  }

  function closeSettings() {
    if (history.state?.urgitSettings) history.back()
    else choose(selected || repositories[0]?.name || '')
  }

  return (
    <div className="app-shell">
      <Sidebar repositories={repositories} peers={peers} selected={selected} remoteSelected={remoteSelected} onSelect={choose} onSelectRemote={chooseRemote} onCreate={() => setCreating(true)} onPeersChanged={refreshPeers} />
      <div className="workspace">
        <div className="topbar">
          <div className="topbar-navigation">
            <button className="icon-button" onClick={() => history.back()} title="Back" aria-label="Back"><BackIcon /></button>
            <button className="icon-button" onClick={() => history.forward()} title="Forward" aria-label="Forward"><ForwardIcon /></button>
            <span className="topbar-label">{settingsOpen ? 'Settings' : repo ? repo.owner : 'Repositories'}</span>
          </div>
          <div className="topbar-actions">
            <div className="activity-anchor">
              <button className="icon-button activity-button" onClick={() => { setActivityOpen((open) => !open); refreshActivity() }} title="Activity"><ActivityIcon />{activityCount > 0 && <span className="activity-badge">{activityCount}</span>}</button>
              {activityOpen && <PeerActivity activity={peerActivity} notifications={urgitNotifications} onClear={clearActivity} onCancel={cancelTransfer} />}
            </div>
            <button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button>
            <button className={`icon-button${settingsOpen ? ' active' : ''}`} onClick={() => settingsOpen ? closeSettings() : openSettings()} title="Settings" aria-label="Settings"><SettingsIcon /></button>
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
          remoteData ? <RemoteRepositoryView key={`${remoteSelected.ship}/${remoteSelected.name}`} ship={remoteSelected.ship} repository={remoteSelected.name} repositories={repositories} data={remoteData} cacheState={remoteCacheState} onRefresh={() => chooseRemote(remoteSelected.ship, remoteSelected.name, false, true)} onFork={forkRemote} onCancelTransfer={cancelTransfer} /> : remoteError ? <main className="content"><div className="empty remote-browse-failure"><strong>Could not load {remoteSelected.ship}/{remoteSelected.name}</strong><span>{remoteError}</span><button className="button primary" onClick={() => chooseRemote(remoteSelected.ship, remoteSelected.name, false, true)}>Retry</button></div></main> : <main className="content"><div className="empty remote-browse-loading"><span className="spinner" />Loading {remoteSelected.ship}/{remoteSelected.name} from peer…<small>{remoteStatus}</small><div className="progress-track indeterminate remote-browse-progress"><i /></div></div></main>
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
      <div className="topbar"><div className="topbar-navigation"><button className="icon-button" onClick={() => history.back()} title="Back" aria-label="Back"><BackIcon /></button><button className="icon-button" onClick={() => history.forward()} title="Forward" aria-label="Forward"><ForwardIcon /></button><a className="public-brand" href="/urgit">urgit</a></div><div className="topbar-actions"><a className="fork-urgit-link" href="https://matwet.subject.network/apps/urgit/public/urgit">Fork me on %urgit!</a><button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button></div></div>
      {error ? <main className="content"><div className="empty">{error}</div></main> : repo ? <RepositoryView repo={repo} publicMode client={publicApi} /> : <main className="content"><div className="empty">Loading repository…</div></main>}
    </div>
  </div>
}

const profileColor = (value) => {
  const raw = String(value || '').replace(/^0x/, '')
  return /^[0-9a-f]+$/i.test(raw) ? `#${raw.padStart(6, '0').slice(-6)}` : ''
}

function ProfileAvatar({ ship, name, src, accent }) {
  const [failed, setFailed] = useState(false)
  useEffect(() => setFailed(false), [src])
  if (src && !failed) return <img className="profile-avatar" src={src} alt={`${name} avatar`} onError={() => setFailed(true)} />
  return <UrbitSigil className="profile-avatar sigil-avatar" ship={ship} size={88} background={accent || '#0969da'} />
}

function PublicProfileApp() {
  const [data, setData] = useState(null)
  const [error, setError] = useState('')
  const [theme, setTheme] = useState(() => localStorage.getItem('urgit-theme') || 'system')

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('urgit-theme', theme)
  }, [theme])
  useEffect(() => {
    publicApi.profile().then((profile) => {
      setData(profile)
      document.title = `${profile.profile?.nickname || profile.ship} · urgit`
    }).catch((cause) => setError(cause.message))
  }, [])

  const nextTheme = { system: 'light', light: 'dark', dark: 'system' }[theme]
  const profile = data?.profile || null
  const name = profile?.nickname || data?.ship || ''
  const repositories = newestRepositoriesFirst(data?.repositories)
  const accent = profileColor(profile?.color)

  return <div className="public-shell profile-shell">
    <div className="workspace">
      <div className="topbar profile-topbar"><a className="public-brand" href="/urgit">urgit</a><div className="topbar-actions"><button className="theme-button" onClick={() => setTheme(nextTheme)} title={`Theme: ${theme}`}>{theme === 'dark' ? '◐' : theme === 'light' ? '◑' : '◒'}</button></div></div>
      {error ? <main className="profile-page"><div className="empty">{error}</div></main> : !data ? <main className="profile-page"><div className="empty">Loading profile…</div></main> : <main className="profile-page">
        <section className={`profile-hero${profile?.cover ? ' with-cover' : ''}`} style={accent ? { '--profile-accent': accent } : undefined}>
          {profile?.cover && <img className="profile-cover" src={profile.cover} alt="" onError={(event) => { event.currentTarget.hidden = true }} />}
          <div className="profile-identity">
            <ProfileAvatar ship={data.ship} name={name} src={profile?.avatar} accent={accent} />
            <div><h1>{name}</h1>{profile?.nickname && <code>{data.ship}</code>}{profile?.status && <span className="profile-status">{profile.status}</span>}</div>
          </div>
          {profile?.bio && <p className="profile-bio">{profile.bio}</p>}
        </section>

        <section className="profile-repositories">
          <header><div><h2>My repos</h2><p>{repositories.length} public {repositories.length === 1 ? 'repository' : 'repositories'}</p></div></header>
          {!repositories.length ? <div className="empty compact">No public repositories.</div> : <div className="profile-repo-list">{repositories.map((repository) => {
            const updated = relativeTime(repository.updatedAt)
            return <a className="profile-repo-row" href={`/apps/urgit/public/${encodeURIComponent(repository.name)}`} key={repository.name}>
              <div className="profile-repo-main"><h3>{repository.name}</h3>{repository.description && <p>{repository.description}</p>}</div>
              <div className="profile-repo-meta">{updated && <time title={exactTime(repository.updatedAt)}>Updated {updated}</time>}<span>{repository.branchCount} {Number(repository.branchCount) === 1 ? 'branch' : 'branches'}</span>{Number(repository.tagCount) > 0 && <span>{repository.tagCount} {Number(repository.tagCount) === 1 ? 'tag' : 'tags'}</span>}</div>
            </a>
          })}</div>}
        </section>
        <footer className="profile-footer"><a className="powered-by-urgit" href="https://matwet.subject.network/apps/urgit/public/urgit"><img src="/apps/urgit/git.svg" alt="" />Powered by urgit</a></footer>
      </main>}
    </div>
  </div>
}

export default function App() {
  const match = location.pathname.match(/^\/apps\/urgit\/public\/([^/]+)\/?$/)
  const profile = /^\/urgit\/?$/.test(location.pathname)
  return <ConfirmProvider>{profile ? <PublicProfileApp /> : match ? <PublicApp name={decodeURIComponent(match[1])} /> : <PrivateApp />}</ConfirmProvider>
}
