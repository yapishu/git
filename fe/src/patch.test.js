import test from 'node:test'
import assert from 'node:assert/strict'
import { comparisonPatch, filePatch } from './patch.js'

const encoded = (text) => btoa(text)

test('emits an applicable modified-file hunk', () => {
  assert.equal(filePatch({
    path: '/README.md', status: 'modified', truncated: false,
    oldContent: encoded('hello\n'), newContent: encoded('hello\nreview me\n'),
  }), [
    'diff --git a/README.md b/README.md',
    '--- a/README.md',
    '+++ b/README.md',
    '@@ -1 +1,2 @@',
    ' hello',
    '+review me',
    '',
  ].join('\n'))
})

test('emits additions and deletions against dev-null', () => {
  assert.match(filePatch({ path: '/new.txt', status: 'added', truncated: false, oldContent: '', newContent: encoded('new\n') }), /new file mode 100644\n--- \/dev\/null\n\+\+\+ b\/new\.txt\n@@ -0,0 \+1 @@\n\+new\n$/)
  assert.match(filePatch({ path: '/old.txt', status: 'deleted', truncated: false, oldContent: encoded('old\n'), newContent: '' }), /deleted file mode 100644\n--- a\/old\.txt\n\+\+\+ \/dev\/null\n@@ -1 \+0,0 @@\n-old\n$/)
})

test('marks missing terminal newlines', () => {
  const patch = filePatch({ path: '/note', status: 'modified', truncated: false, oldContent: encoded('old'), newContent: encoded('new') })
  assert.match(patch, /-old\n\\ No newline at end of file\n\+new\n\\ No newline at end of file\n$/)
})

test('declines binary and truncated bodies', () => {
  assert.equal(filePatch({ path: '/bin', status: 'modified', truncated: false, oldContent: '//4=', newContent: '//4=' }), null)
  assert.equal(filePatch({ path: '/large', status: 'modified', truncated: true, oldContent: '', newContent: '' }), null)
  assert.equal(comparisonPatch({ changesTruncated: true, changes: [] }), null)
})
