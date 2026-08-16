const BASE = '/apps/git/api'

const fileRoute = (name, path) => {
  const parts = path.split('/').filter(Boolean).map(encodeURIComponent)
  return `/repository/${encodeURIComponent(name)}/file/${parts.join('/')}`
}

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
  repository: (name) => request(`/repository/${encodeURIComponent(name)}`),
  files: (name) => request(`/repository/${encodeURIComponent(name)}/files`),
  file: (name, path) => request(fileRoute(name, path)),
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
