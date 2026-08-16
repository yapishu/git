const BASE = '/apps/git/api'

const fileRoute = (name, path) => {
  const parts = path.split('/').filter(Boolean).map(encodeURIComponent)
  return `/repository/${encodeURIComponent(name)}/file/${parts.join('/')}`
}

const atRef = (path, ref) => ref ? `${path}?ref=${encodeURIComponent(ref)}` : path

async function request(path, options = {}) {
  const response = await fetch(`${BASE}${path}`, {
    credentials: 'same-origin',
    headers: options.body ? { 'content-type': 'application/json', ...options.headers } : options.headers,
    ...options,
  })
  const text = await response.text()
  let data = null
  try {
    data = text ? JSON.parse(text) : null
  } catch {
    data = { error: text || `HTTP ${response.status}` }
  }
  if (!response.ok) throw new Error(data?.error || data?.message || `HTTP ${response.status}`)
  return data
}

export const api = {
  repositories: () => request('/repositories'),
  desks: () => request('/desks'),
  peerTransfers: () => request('/peer/transfers'),
  peerDeleteTransfer: (transfer) => request(`/peer/transfers/${encodeURIComponent(transfer)}`, { method: 'DELETE' }),
  peerFork: (ship, repository, name, publicRead) =>
    request('/peer/fork', { method: 'POST', body: JSON.stringify({ ship, repository, name, publicRead }) }),
  peerPush: (name) => request('/peer/push', { method: 'POST', body: JSON.stringify({ name }) }),
  peerPullRequest: (name, title) => request('/peer/pull-request', { method: 'POST', body: JSON.stringify({ name, title }) }),
  githubStatus: () => request('/github/status'),
  setGithubToken: (token) => request('/github/token', { method: 'POST', body: JSON.stringify({ token }) }),
  clearGithubToken: () => request('/github/token', { method: 'DELETE' }),
  githubImport: (owner, repository, name, publicRead) =>
    request('/github/import', { method: 'POST', body: JSON.stringify({ owner, repository, name, publicRead }) }),
  githubMetadata: (name, kind) => request(`/repository/${encodeURIComponent(name)}/github/metadata`, { method: 'POST', body: JSON.stringify({ kind }) }),
  githubFork: (name) => request(`/repository/${encodeURIComponent(name)}/github/fork`, { method: 'POST', body: '{}' }),
  githubPull: (name, title, head, base, body) =>
    request(`/repository/${encodeURIComponent(name)}/github/pull`, {
      method: 'POST', body: JSON.stringify({ title, head, base, body }),
    }),
  repository: (name) => request(`/repository/${encodeURIComponent(name)}`),
  files: (name, ref) => request(atRef(`/repository/${encodeURIComponent(name)}/files`, ref)),
  file: (name, path, ref) => request(atRef(fileRoute(name, path), ref)),
  fileHistory: (name, path, ref) => request(atRef(fileRoute(name, path).replace('/file/', '/file-history/'), ref)),
  saveFile: (name, path, content, message) =>
    request(fileRoute(name, path), {
      method: 'POST',
      body: JSON.stringify({ content, message }),
    }),
  commits: (name) => request(`/repository/${encodeURIComponent(name)}/commits`),
  create: (name, publicRead) =>
    request('/repositories', { method: 'POST', body: JSON.stringify({ name, publicRead }) }),
  remove: (name) => request(`/repository/${encodeURIComponent(name)}`, { method: 'DELETE' }),
  setPublic: (name, publicRead) =>
    request(`/repository/${encodeURIComponent(name)}/public`, {
      method: 'POST',
      body: JSON.stringify({ publicRead }),
    }),
  setWriter: (name, ship, allowed) =>
    request(`/repository/${encodeURIComponent(name)}/writers`, {
      method: 'POST',
      body: JSON.stringify({ ship, allowed }),
    }),
  mergePull: (name, number) => request(`/repository/${encodeURIComponent(name)}/pulls/${number}/merge`, { method: 'POST', body: '{}' }),
  setToken: (name, token) =>
    request(`/repository/${encodeURIComponent(name)}/token`, {
      method: 'POST',
      body: JSON.stringify({ token }),
    }),
  clearToken: (name) =>
    request(`/repository/${encodeURIComponent(name)}/token`, { method: 'DELETE' }),
  bind: (name, desk, branch) =>
    request(`/repository/${encodeURIComponent(name)}/bind`, {
      method: 'POST',
      body: JSON.stringify({ desk, branch }),
    }),
  unbind: (name) =>
    request(`/repository/${encodeURIComponent(name)}/unbind`, { method: 'POST', body: '{}' }),
  publish: (name, message) =>
    request(`/repository/${encodeURIComponent(name)}/publish`, {
      method: 'POST',
      body: JSON.stringify({ message }),
    }),
}
