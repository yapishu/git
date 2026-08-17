import { useCallback, useEffect, useMemo, useState } from 'react'
import { api } from './api'
import CreateRepository from './components/CreateRepository'
import ForkPeer from './components/ForkPeer'
import GitHubImport from './components/GitHubImport'
import GitHubSettings from './components/GitHubSettings'
import { ActivityIcon, RefreshIcon } from './components/Icons'
import PeerActivity from './components/PeerActivity'
import PublishDesk from './components/PublishDesk'
import RepositoryView from './components/RepositoryView'
import Sidebar from './components/Sidebar'

const repoFromHash = () => decodeURIComponent(location.hash.replace(/^#\/?/, ''))

export default function App() {
  const [repositories, setRepositories] = useState([])
  const [selected, setSelected] = useState(repoFromHash())
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
      setSelected(repos[0]?.name || '')
      return false
    } catch (cause) {
      setError(cause.message)
      return false
    } finally {
      setLoading(false)
    }
  }, [selected])

  useEffect(() => { refresh() }, [])
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
    const pop = () => { setSelected(repoFromHash()); setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false) }
    addEventListener('popstate', pop)
    return () => removeEventListener('popstate', pop)
  }, [])

  function choose(name) {
    setCreating(false)
    setPublishingDesk(false)
    setForkingPeer(false)
    setImportingGitHub(false)
    setGithubSettings(false)
    setSelected(name)
    history.pushState({}, '', `#/${encodeURIComponent(name)}`)
  }

  async function published(name) {
    await refresh(name)
    choose(name)
    setTimeout(() => refresh(name), 1200)
  }

  async function create(name, publicRead) {
    try {
      await api.create(name, publicRead)
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
      <Sidebar repositories={repositories} selected={selected} onSelect={choose} onCreate={() => { setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false); setCreating(true) }} onPublishDesk={() => { setCreating(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(false); setPublishingDesk(true) }} onForkPeer={() => { setCreating(false); setPublishingDesk(false); setImportingGitHub(false); setGithubSettings(false); setForkingPeer(true) }} onImportGitHub={() => { setCreating(false); setPublishingDesk(false); setForkingPeer(false); setGithubSettings(false); setImportingGitHub(true) }} onGitHubSettings={() => { setCreating(false); setPublishingDesk(false); setForkingPeer(false); setImportingGitHub(false); setGithubSettings(true) }} />
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
        ) : creating ? (
          <CreateRepository onCreate={create} onCancel={() => setCreating(false)} />
        ) : repo ? (
          <RepositoryView repo={repo} onRefresh={refresh} />
        ) : (
          <main className="content welcome">
            <h1>{loading ? 'Loading repositories…' : 'Repositories'}</h1>
            {!loading && <><p>No repositories.</p><button className="button primary" onClick={() => setCreating(true)}>New repository</button></>}
          </main>
        )}
      </div>
    </div>
  )
}
