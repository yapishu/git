import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const css = readFileSync(new URL('./style.css', import.meta.url), 'utf8')

function declarations(selector) {
  const escaped = selector.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  return [...css.matchAll(new RegExp(`${escaped}\\s*\\{([^}]+)\\}`, 'g'))]
    .map((match) => match[1].replace(/\s+/g, ' ').trim())
}

test('keeps upstream update text and actions in explicit desktop grid tracks', () => {
  const [row] = declarations('.upstream-update-item')
  const [actions] = declarations('.upstream-update-item > .row-actions')

  assert.match(row, /display:\s*grid/)
  assert.match(row, /grid-template-columns:\s*minmax\(0,\s*1fr\)\s+max-content/)
  assert.doesNotMatch(row, /flex-wrap/)
  assert.match(actions, /justify-self:\s*end/)
  assert.doesNotMatch(actions, /margin-left:\s*auto/)
})

test('stacks upstream update actions below text on narrow screens', () => {
  const rows = declarations('.upstream-update-item')
  const actions = declarations('.upstream-update-item > .row-actions')

  assert.ok(rows.some((rule) => /grid-template-columns:\s*minmax\(0,\s*1fr\)/.test(rule)))
  assert.ok(actions.some((rule) => /justify-self:\s*start/.test(rule)))
})
