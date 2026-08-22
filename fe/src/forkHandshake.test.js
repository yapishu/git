import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const backend = readFileSync(
  new URL('../../desk/app/urgit.hoon', import.meta.url),
  'utf8',
)

const schema = readFileSync(
  new URL('../../desk/sur/git.hoon', import.meta.url),
  'utf8',
)

function arm(name, next) {
  const start = backend.indexOf(`++  ${name}`)
  const end = backend.indexOf(`++  ${next}`, start)
  assert.notEqual(start, -1, `missing ++  ${name}`)
  assert.notEqual(end, -1, `missing ++  ${next} after ++  ${name}`)
  return backend.slice(start, end)
}

const onInit = arm('on-init', 'on-save')
const onSave = arm('on-save', 'on-load')
const onLoad = arm('on-load', 'on-poke')
const peerRequest = arm('peer-request', 'peer-accepted')
const peerRelease = arm('peer-release', 'peer-snapshot-fail')
const onArvo = backend.slice(backend.indexOf('++  on-arvo'))

test('the fork preparation queue is persisted, so a reload cannot strand a requester', () => {
  // It is a field of the saved state, not a transient =/ binding beside it.
  assert.doesNotMatch(backend, /=\/  peer-prepare-queue/)
  assert.match(schema, /peer-prepare-queue=\(map @uv peer-prepare-entry\)/)
  assert.equal(onSave.trimEnd(), '++  on-save\n  !>(state)\n::')

  // on-load keeps the queue and re-arms the ~s1 build timer for each entry.
  assert.doesNotMatch(onLoad, /peer-prepare-queue ~/)
  assert.match(onLoad, /~\(tap by peer-prepare-queue\.loaded\)/)
  assert.match(
    onLoad,
    /\/peer\/prepare-start\/\(scot %uv transfer\.entry\) %arvo %b %wait \(add now\.bowl ~s1\)/,
  )

  // The genuinely transient maps are still wiped.
  assert.match(onLoad, /peer-stream-jobs ~/)
  assert.match(onLoad, /peer-serving ~/)
  assert.match(onInit, /this\(peer-prepare-queue ~, peer-stream-jobs ~, peer-browse-prepare-queue ~\)/)
})

test('peer request acceptance never immediately starts synchronous pack preparation', () => {
  assert.doesNotMatch(
    peerRequest,
    /%agent \[our\.bowl %urgit\] %poke %git-peer !>\(\[%prepare/,
  )
})

test('new peer requests queue preparation and schedule it one second after acceptance', () => {
  assert.match(
    peerRequest,
    /\|\(\(~\(has by peer-serving\) transfer\.req\) \(~\(has by peer-prepare-queue\) transfer\.req\)\)/,
  )
  assert.match(
    peerRequest,
    /peer-prepare-queue\s+\(~\(put by peer-prepare-queue\) transfer\.req \[src\.bowl req\]\)/,
  )

  const accepted = peerRequest.indexOf(
    '(peer-card src.bowl /peer/accepted/(scot %uv transfer.req)',
  )
  const wake = peerRequest.indexOf(
    '[%pass /peer/prepare-start/(scot %uv transfer.req) %arvo %b %wait (add now.bowl ~s1)]',
  )
  assert.notEqual(accepted, -1, 'missing accepted response card')
  assert.notEqual(wake, -1, 'missing deferred prepare-start wake')
  assert.ok(accepted < wake, 'accepted response must precede prepare-start scheduling')
})

test('prepare-start wake consumes the queue before emitting a self prepare poke', () => {
  assert.match(onArvo, /\[%peer %prepare-start @ ~\]/)
  assert.match(
    onArvo,
    /queued=[\s\S]*?~\(get by peer-prepare-queue\) u\.transfer[\s\S]*peer-prepare-queue\s+\(~\(del by peer-prepare-queue\) u\.transfer\)/,
  )
  assert.match(
    onArvo,
    /%agent \[our\.bowl %urgit\] %poke %git-peer !>\(\[%prepare target\.u\.queued req\.u\.queued\]\)/,
  )
})

test('peer release authenticates and cancels queued preparation before serving lookup', () => {
  const queuedLookup = peerRelease.indexOf('~(get by peer-prepare-queue) transfer')
  const servingLookup = peerRelease.indexOf('~(get by peer-serving) transfer')
  assert.notEqual(queuedLookup, -1, 'missing queued preparation lookup')
  assert.notEqual(servingLookup, -1, 'missing serving transfer lookup')
  assert.ok(queuedLookup < servingLookup, 'queued cancellation must run before serving lookup')
  assert.match(peerRelease, /=\(src\.bowl target\.u\.queued\)/)
  assert.match(
    peerRelease,
    /peer-prepare-queue\s+\(~\(del by peer-prepare-queue\) transfer\)/,
  )
})
