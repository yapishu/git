import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const source = readFileSync(
  new URL('../../desk/app/urgit-fileserver.hoon', import.meta.url),
  'utf8',
)

test('does not put extensionless SPA shells in the Eyre response cache', () => {
  const routeStart = source.indexOf('=/  request-root=(unit path)')
  const assetStart = source.indexOf('=/  =path', routeStart)
  assert.notEqual(routeStart, -1)
  assert.notEqual(assetStart, -1)

  const fallback = source.slice(routeStart, assetStart)
  assert.match(fallback, /:-\s+\?=\(\^ ext\)\s+\?~\s+ext/)
  assert.doesNotMatch(fallback, /:-\s+&\s+\?~\s+ext/)
})

test('evicts known SPA shell entries on init and upgrade', () => {
  const onInitStart = source.indexOf('++  on-init')
  const onLoadStart = source.indexOf('++  on-load', onInitStart)
  const onPokeStart = source.indexOf('++  on-poke', onLoadStart)
  assert.notEqual(onInitStart, -1)
  assert.notEqual(onLoadStart, -1)
  assert.notEqual(onPokeStart, -1)

  const onInit = source.slice(onInitStart, onLoadStart)
  const onLoad = source.slice(onLoadStart, onPokeStart)
  for (const lifecycle of [onInit, onLoad]) {
    assert.match(lifecycle, /\(store '\/apps\/urgit' ~\)/)
    assert.match(lifecycle, /\(store '\/apps\/urgit\/' ~\)/)
    assert.match(lifecycle, /\(store '\/urgit' ~\)/)
    assert.match(lifecycle, /\(store '\/urgit\/' ~\)/)
  }
})

test('binds the public profile shell at /urgit on init and upgrade', () => {
  const onInitStart = source.indexOf('++  on-init')
  const onLoadStart = source.indexOf('++  on-load', onInitStart)
  const onPokeStart = source.indexOf('++  on-poke', onLoadStart)
  const onInit = source.slice(onInitStart, onLoadStart)
  const onLoad = source.slice(onLoadStart, onPokeStart)
  for (const lifecycle of [onInit, onLoad]) {
    assert.match(lifecycle, /%connect \[~ \/urgit\]/)
  }
})

test('treats dotted public repository names as SPA routes', () => {
  const parseStart = source.indexOf('(rush url.request')
  const routeStart = source.indexOf('=/  request-root=(unit path)', parseStart)
  assert.notEqual(parseStart, -1)
  assert.notEqual(routeStart, -1)

  const routing = source.slice(parseStart, routeStart)
  assert.match(routing, /=\.\s+ext\s+\?:\s+\(starts-with '\/apps\/urgit\/public\/' url\.request\)\s+~\s+ext/)
})
