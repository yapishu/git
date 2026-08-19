import test from 'node:test'
import assert from 'node:assert/strict'
import sigil from '@urbit/sigil-js/core'

test('renders an Urbit sigil SVG for profile fallbacks', () => {
  const xml = sigil({ point: '~zod', size: 88, foreground: '#fff', background: '#000' })
  assert.match(xml, /<svg/)
  assert.match(xml, /width="88"/)
})
