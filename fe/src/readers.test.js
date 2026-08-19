import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { api } from './api.js'

const repositoryView = readFileSync(
  new URL('./components/RepositoryView.jsx', import.meta.url),
  'utf8',
)
const backend = readFileSync(
  new URL('../../desk/app/urgit.hoon', import.meta.url),
  'utf8',
)
const settings = repositoryView.slice(
  repositoryView.indexOf('function Settings'),
  repositoryView.indexOf('export default function RepositoryView'),
)
const peerBrowse = backend.slice(
  backend.indexOf('++  peer-browse-request'),
  backend.indexOf('++  peer-browse-ready'),
)
const peerBrowseJson = backend.slice(
  backend.indexOf('++  peer-repository-browse-json'),
  backend.indexOf('++  repository-revision'),
)
const publicScries = backend.slice(
  backend.indexOf('++  on-peek'),
  backend.indexOf('++  on-watch'),
)

test('setReader posts the ship reader permission to the encoded repository route', async () => {
  const originalFetch = globalThis.fetch
  let request
  globalThis.fetch = async (url, options) => {
    request = { url, options }
    return { ok: true, status: 200, text: async () => '{}' }
  }

  try {
    await api.setReader('private repo', '~sampel-palnet', true)
  } finally {
    globalThis.fetch = originalFetch
  }

  assert.equal(request.url, '/apps/urgit/api/repository/private%20repo/readers')
  assert.equal(request.options.method, 'POST')
  assert.deepEqual(JSON.parse(request.options.body), {
    ship: '~sampel-palnet',
    allowed: true,
  })
})

test('repository access settings manage readers separately from writers', () => {
  assert.match(settings, /const \[reader, setReader\] = useState\(''\)/)
  assert.match(settings, /<h3>Ship readers<\/h3>/)
  assert.match(settings, /Readers can discover, browse, and fork this private repository through Urgit, but cannot send updates\. Writers already have read access\./)
  assert.match(settings, /value=\{reader\}/)
  assert.match(settings, /api\.setReader\(repo\.name, reader\.trim\(\), true\)/)
  assert.match(settings, /\(repo\.readers \|\| \[\]\)\.map/)
  assert.match(settings, /api\.setReader\(repo\.name, ship, false\)/)
})

test('native peer browse responses hide repository administration fields', () => {
  assert.match(peerBrowseJson, /\['repository' \(public-repository-json name repo\)\]/)
  assert.doesNotMatch(peerBrowse, /\(repository-json repository u\.found\)/)
  assert.equal(
    [...peerBrowse.matchAll(/\(public-repository-json repository u\.found\)/g)].length,
    3,
  )
})

test('public repository scries hide repository administration fields', () => {
  assert.match(publicScries, /\(public-repositories-json visible\)/)
  assert.match(publicScries, /\(public-repository-json name u\.found\)/)
  assert.match(publicScries, /\(peer-repository-browse-json name u\.found\)/)
  assert.doesNotMatch(publicScries, /\(repositories-json visible\)/)
  assert.doesNotMatch(publicScries, /\(repository-json name u\.found\)/)
  assert.doesNotMatch(publicScries, /\(repository-browse-json name u\.found\)/)
})
