import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { api } from './api.js'

const repositoryView = readFileSync(
  new URL('./components/RepositoryView.jsx', import.meta.url),
  'utf8',
)
const peerActivityView = readFileSync(
  new URL('./components/PeerActivity.jsx', import.meta.url),
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
const peerError = backend.slice(
  backend.indexOf('++  peer-error'),
  backend.indexOf('++  handle-peer'),
)
const peerResultReceived = backend.slice(
  backend.indexOf('++  peer-result-received'),
  backend.indexOf('++  peer-request'),
)
const peerPrepare = backend.slice(
  backend.indexOf('++  peer-prepare'),
  backend.indexOf('++  peer-ready'),
)
const peerRelease = backend.slice(
  backend.indexOf('++  peer-release'),
  backend.indexOf('++  peer-snapshot-fail'),
)
const peerResultsJson = backend.slice(
  backend.indexOf('++  peer-results-json'),
  backend.indexOf('++  peer-discoveries-json'),
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

test('early peer errors finish tracked outgoing offers', () => {
  assert.match(peerError, /outgoing=.*~\(get by peer-outgoing\) transfer/)
  assert.match(peerError, /=\(src\.bowl peer\.u\.outgoing\)/)
  assert.match(peerError, /peer-outgoing-finish transfer %.n message/)
  assert.doesNotMatch(peerError, /skim\s+peer-activities/)
})

test('snapshot service activity does not replace its outgoing offer', () => {
  assert.match(peerPrepare, /peer-serve-activity-id transfer\.req/)
  assert.match(peerRelease, /peer-serve-activity-id transfer/)
})

test('outgoing offers remain active until authoritative state is consumed', () => {
  assert.match(backend, /\+\$  peer-offer-flight/)
  assert.match(backend, /=\/  peer-outgoing\s+\*\(map @uv peer-offer-flight\)/)
  assert.match(peerResultsJson, /outgoing=\(unit peer-offer-flight\).*~\(get by peer-outgoing\) transfer/)
  assert.match(peerResultsJson, /\['active' b\+\|\(\?=\(\^ flight\) \?=\(\^ outgoing\)\)\]/)
})

test('peer results authenticate and consume one active outgoing offer', () => {
  assert.match(peerResultReceived, /outgoing=.*~\(get by peer-outgoing\) transfer/)
  assert.match(peerResultReceived, /=\(src\.bowl peer\.u\.outgoing\)/)
  assert.match(peerResultReceived, /peer-outgoing-finish transfer ok message/)
})

test('outgoing offers have a terminal timeout independent of activity history', () => {
  assert.equal([...backend.matchAll(/\/peer\/offer-timeout\/\(scot %uv transfer\)/g)].length, 2)
  assert.match(backend, /\[%peer %offer-timeout @ ~\]/)
  assert.match(backend, /peer-outgoing\s+\(~\(del by peer-outgoing\) u\.transfer\)/)
  assert.match(backend, /peer-results\s+[\s\S]*\[%.n message repository\.u\.outgoing\]/)
  const clearActivity = backend.slice(
    backend.indexOf("?=([%apps %urgit %api %peer %activity ~] site)"),
    backend.indexOf("?=([%apps %urgit %api %peer %transfers ~] site)"),
  )
  assert.doesNotMatch(clearActivity, /peer-outgoing/)
})

test('only cancellable fork transfers show a cancel action', () => {
  assert.match(peerActivityView, /event\.status === 'active' && event\.kind === 'fork'/)
})
