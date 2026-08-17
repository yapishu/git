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

const publicFileRoute = (name, path) => {
  const parts = path.split('/').filter(Boolean).map(encodeURIComponent)
  return `/public/repository/${encodeURIComponent(name)}/file/${parts.join('/')}`
}

export const publicApi = {
  repository: (name) => request(`/public/repository/${encodeURIComponent(name)}`),
  issue: (name, number) => request(`/public/repository/${encodeURIComponent(name)}/issues/${number}`),
  files: (name, ref) => request(atRef(`/public/repository/${encodeURIComponent(name)}/files`, ref)),
  file: (name, path, ref) => request(atRef(publicFileRoute(name, path), ref)),
  fileHistory: (name, path, ref) => request(atRef(publicFileRoute(name, path).replace('/file/', '/file-history/'), ref)),
  fileBlame: (name, path, ref) => request(atRef(publicFileRoute(name, path).replace('/file/', '/file-blame/'), ref)),
  commits: (name, ref) => request(atRef(`/public/repository/${encodeURIComponent(name)}/commits`, ref)),
  compare: (name, base, head) => request(`/public/repository/${encodeURIComponent(name)}/compare?base=${encodeURIComponent(base)}&head=${encodeURIComponent(head)}`),
  commit: (name, oid) => request(`/public/repository/${encodeURIComponent(name)}/commit/${encodeURIComponent(oid)}`),
  search: (name, query, ref) => request(`/public/repository/${encodeURIComponent(name)}/search?q=${encodeURIComponent(query)}${ref ? `&ref=${encodeURIComponent(ref)}` : ''}`),
  release: (name, tag) => request(`/public/repository/${encodeURIComponent(name)}/releases?tag=${encodeURIComponent(tag)}`),
  archiveUrl: (name, ref) => `${BASE}/public/repository/${encodeURIComponent(name)}/archive?ref=${encodeURIComponent(ref)}`,
}

export const api = {
  repositories: () => request('/repositories'),
  desks: () => request('/desks'),
  peerActivity: () => request('/peer/activity'),
  peers: () => request('/peer/peers'),
  addPeer: (ship) => request('/peer/peers', { method: 'POST', body: JSON.stringify({ ship }) }),
  removePeer: (ship) => request('/peer/peers', { method: 'DELETE', body: JSON.stringify({ ship }) }),
  peerBrowse: (ship, repository) => request(`/peer/browse/${encodeURIComponent(ship)}/${encodeURIComponent(repository)}`, { method: 'POST', body: '{}' }),
  peerBrowses: () => request('/peer/browses'),
  peerDeleteBrowse: (requestId) => request('/peer/browses', { method: 'DELETE', body: JSON.stringify({ request: requestId }) }),
  clearPeerActivity: () => request('/peer/activity', { method: 'DELETE' }),
  peerDiscover: (ship) => request('/peer/discover', { method: 'POST', body: JSON.stringify({ ship }) }),
  peerDiscoveries: () => request('/peer/discoveries'),
  peerDeleteDiscovery: (requestId) => request('/peer/discoveries', { method: 'DELETE', body: JSON.stringify({ request: requestId }) }),
  peerTransfers: () => request('/peer/transfers'),
  peerDeleteTransfer: (transfer) => request('/peer/transfers', { method: 'DELETE', body: JSON.stringify({ transfer }) }),
  peerFork: (ship, repository, name, publicRead) =>
    request('/peer/fork', { method: 'POST', body: JSON.stringify({ ship, repository, name, publicRead }) }),
  peerPush: (name) => request('/peer/push', { method: 'POST', body: JSON.stringify({ name }) }),
  peerPullRequest: (name, title) => request('/peer/pull-request', { method: 'POST', body: JSON.stringify({ name, title }) }),
  githubStatus: () => request('/github/status'),
  setGithubToken: (token) => request('/github/token', { method: 'POST', body: JSON.stringify({ token }) }),
  clearGithubToken: () => request('/github/token', { method: 'DELETE' }),
  githubImport: (owner, repository, name, publicRead) =>
    request('/github/import', { method: 'POST', body: JSON.stringify({ owner, repository, name, publicRead }) }),
  githubPush: (name, branch) => request(`/repository/${encodeURIComponent(name)}/github/push`, {
    method: 'POST', body: JSON.stringify({ branch }),
  }),
  githubMetadata: (name, kind, page = 1) => request(`/repository/${encodeURIComponent(name)}/github/metadata`, { method: 'POST', body: JSON.stringify({ kind, page }) }),
  githubIssue: (name, number) => request(`/repository/${encodeURIComponent(name)}/github/issues/${number}`),
  githubPullDetail: (name, number) => request(`/repository/${encodeURIComponent(name)}/github/pulls/${number}`),
  githubFile: (name, path, ref) => request(atRef(fileRoute(name, path).replace('/file/', '/github/file/'), ref)),
  githubFork: (name) => request(`/repository/${encodeURIComponent(name)}/github/fork`, { method: 'POST', body: '{}' }),
  githubPull: (name, title, head, base, body) =>
    request(`/repository/${encodeURIComponent(name)}/github/pull`, {
      method: 'POST', body: JSON.stringify({ title, head, base, body }),
    }),
  repository: (name) => request(`/repository/${encodeURIComponent(name)}`),
  files: (name, ref) => request(atRef(`/repository/${encodeURIComponent(name)}/files`, ref)),
  file: (name, path, ref) => request(atRef(fileRoute(name, path), ref)),
  fileHistory: (name, path, ref) => request(atRef(fileRoute(name, path).replace('/file/', '/file-history/'), ref)),
  fileBlame: (name, path, ref) => request(atRef(fileRoute(name, path).replace('/file/', '/file-blame/'), ref)),
  saveFile: (name, path, content, message, ref = '') =>
    request(fileRoute(name, path), {
      method: 'POST',
      body: JSON.stringify({ content, message, ...(ref ? { ref } : {}) }),
    }),
  deleteFile: (name, path, message, ref = '') =>
    request(fileRoute(name, path), {
      method: 'DELETE',
      body: JSON.stringify({ message, ...(ref ? { ref } : {}) }),
    }),
  commits: (name, ref) => request(atRef(`/repository/${encodeURIComponent(name)}/commits`, ref)),
  compare: (name, base, head) => request(`/repository/${encodeURIComponent(name)}/compare?base=${encodeURIComponent(base)}&head=${encodeURIComponent(head)}`),
  commit: (name, oid) => request(`/repository/${encodeURIComponent(name)}/commit/${encodeURIComponent(oid)}`),
  search: (name, query, ref) => request(`/repository/${encodeURIComponent(name)}/search?q=${encodeURIComponent(query)}${ref ? `&ref=${encodeURIComponent(ref)}` : ''}`),
  create: (name, publicRead) =>
    request('/repositories', { method: 'POST', body: JSON.stringify({ name, publicRead }) }),
  remove: (name) => request(`/repository/${encodeURIComponent(name)}`, { method: 'DELETE' }),
  setPublic: (name, publicRead) =>
    request(`/repository/${encodeURIComponent(name)}/public`, {
      method: 'POST',
      body: JSON.stringify({ publicRead }),
    }),
  setDescription: (name, description) =>
    request(`/repository/${encodeURIComponent(name)}/description`, {
      method: 'POST',
      body: JSON.stringify({ description }),
    }),
  createBranch: (name, branch, source) =>
    request(`/repository/${encodeURIComponent(name)}/branches`, {
      method: 'POST',
      body: JSON.stringify({ name: branch, source }),
    }),
  deleteBranch: (name, branch) =>
    request(`/repository/${encodeURIComponent(name)}/branches`, {
      method: 'DELETE',
      body: JSON.stringify({ name: branch }),
    }),
  setDefaultBranch: (name, branch) =>
    request(`/repository/${encodeURIComponent(name)}/branches/default`, {
      method: 'POST',
      body: JSON.stringify({ name: branch }),
    }),
  setWriter: (name, ship, allowed) =>
    request(`/repository/${encodeURIComponent(name)}/writers`, {
      method: 'POST',
      body: JSON.stringify({ ship, allowed }),
    }),
  setProtected: (name, ref, protectedBranch) =>
    request(`/repository/${encodeURIComponent(name)}/protected`, {
      method: 'POST',
      body: JSON.stringify({ ref, protected: protectedBranch }),
    }),
  createTag: (name, tag, target, message) =>
    request(`/repository/${encodeURIComponent(name)}/tags`, {
      method: 'POST',
      body: JSON.stringify({ name: tag, target, message }),
    }),
  deleteTag: (name, tag) =>
    request(`/repository/${encodeURIComponent(name)}/tags`, {
      method: 'DELETE',
      body: JSON.stringify({ name: tag }),
    }),
  createRelease: (name, tag, title, notes) =>
    request(`/repository/${encodeURIComponent(name)}/releases`, {
      method: 'POST', body: JSON.stringify({ tag, title, notes }),
    }),
  release: (name, tag) => request(`/repository/${encodeURIComponent(name)}/releases?tag=${encodeURIComponent(tag)}`),
  deleteRelease: (name, tag) =>
    request(`/repository/${encodeURIComponent(name)}/releases`, {
      method: 'DELETE', body: JSON.stringify({ tag }),
    }),
  archiveUrl: (name, ref) => `${BASE}/repository/${encodeURIComponent(name)}/archive?ref=${encodeURIComponent(ref)}`,
  createWebhook: (name, url, secret, events) =>
    request(`/repository/${encodeURIComponent(name)}/webhooks`, {
      method: 'POST', body: JSON.stringify({ url, secret, events }),
    }),
  deleteWebhook: (name, id) =>
    request(`/repository/${encodeURIComponent(name)}/webhooks`, {
      method: 'DELETE', body: JSON.stringify({ id }),
    }),
  testWebhook: (name, id) =>
    request(`/repository/${encodeURIComponent(name)}/webhooks/${id}/test`, { method: 'POST', body: '{}' }),
  setIncomingHook: (name, secret) =>
    request(`/repository/${encodeURIComponent(name)}/incoming-hook`, {
      method: 'POST', body: JSON.stringify({ secret }),
    }),
  clearIncomingHook: (name) =>
    request(`/repository/${encodeURIComponent(name)}/incoming-hook`, { method: 'DELETE', body: '{}' }),
  dismissUpstreamUpdate: (name, id) =>
    request(`/repository/${encodeURIComponent(name)}/upstream-updates`, {
      method: 'DELETE', body: JSON.stringify({ id }),
    }),
  createPull: (name, title, branch) =>
    request(`/repository/${encodeURIComponent(name)}/pulls`, {
      method: 'POST', body: JSON.stringify({ title, branch }),
    }),
  pull: (name, number) => request(`/repository/${encodeURIComponent(name)}/pulls/${number}`),
  addPullComment: (name, number, body, path = '', line = 0, side = '') =>
    request(`/repository/${encodeURIComponent(name)}/pulls/${number}/comments`, {
      method: 'POST', body: JSON.stringify({ body, path, line, side }),
    }),
  resolvePullComment: (name, number, comment, resolved) =>
    request(`/repository/${encodeURIComponent(name)}/pulls/${number}/comments/${comment}/resolve`, {
      method: 'POST', body: JSON.stringify({ resolved }),
    }),
  setPullState: (name, number, state) =>
    request(`/repository/${encodeURIComponent(name)}/pulls/${number}/state`, {
      method: 'POST', body: JSON.stringify({ state }),
    }),
  mergePull: (name, number) => request(`/repository/${encodeURIComponent(name)}/pulls/${number}/merge`, { method: 'POST', body: '{}' }),
  createIssue: (name, title, body) =>
    request(`/repository/${encodeURIComponent(name)}/issues`, {
      method: 'POST', body: JSON.stringify({ title, body }),
    }),
  issue: (name, number) => request(`/repository/${encodeURIComponent(name)}/issues/${number}`),
  addIssueComment: (name, number, body) =>
    request(`/repository/${encodeURIComponent(name)}/issues/${number}/comments`, {
      method: 'POST', body: JSON.stringify({ body }),
    }),
  setIssueState: (name, number, state) =>
    request(`/repository/${encodeURIComponent(name)}/issues/${number}/state`, {
      method: 'POST', body: JSON.stringify({ state }),
    }),
  setIssueLabels: (name, number, labels) =>
    request(`/repository/${encodeURIComponent(name)}/issues/${number}/labels`, {
      method: 'POST', body: JSON.stringify({ labels }),
    }),
  setIssueAssignees: (name, number, assignees) =>
    request(`/repository/${encodeURIComponent(name)}/issues/${number}/assignees`, {
      method: 'POST', body: JSON.stringify({ assignees }),
    }),
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
  clayStatus: (name) =>
    request(`/repository/${encodeURIComponent(name)}/clay/status`),
  lfsGcPreview: (name) => request(`/repository/${encodeURIComponent(name)}/lfs/gc`),
  lfsGc: (name) => request(`/repository/${encodeURIComponent(name)}/lfs/gc`, {
    method: 'POST', body: '{}',
  }),
  applyToClay: (name) =>
    request(`/repository/${encodeURIComponent(name)}/clay/apply`, {
      method: 'POST',
      body: '{}',
    }),
}
