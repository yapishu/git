function decodeText(content) {
  const raw = atob(content || '')
  const bytes = Uint8Array.from(raw, (char) => char.charCodeAt(0))
  try { return new TextDecoder('utf-8', { fatal: true }).decode(bytes) } catch { return null }
}

function patchFileName(path) {
  const clean = path.replace(/^\/+/, '')
  return /[\s"\\]/.test(clean) ? JSON.stringify(clean) : clean
}

function patchText(content) {
  const text = decodeText(content)
  if (text === null) return null
  const terminalNewline = text.endsWith('\n')
  const lines = text ? text.split('\n') : []
  if (terminalNewline) lines.pop()
  return { lines, terminalNewline }
}

function patchRange(start, count) {
  return count === 1 ? String(start) : `${start},${count}`
}

export function filePatch(change) {
  if (change.truncated) return null
  const oldFile = change.status === 'added' ? { lines: [], terminalNewline: true } : patchText(change.oldContent)
  const newFile = change.status === 'deleted' ? { lines: [], terminalNewline: true } : patchText(change.newContent)
  if (!oldFile || !newFile) return null
  const before = oldFile.lines, after = newFile.lines
  let prefix = 0
  while (prefix < before.length && prefix < after.length && before[prefix] === after[prefix]) prefix += 1
  let suffix = 0
  while (suffix < before.length - prefix && suffix < after.length - prefix && before[before.length - 1 - suffix] === after[after.length - 1 - suffix]) suffix += 1
  const contextStart = Math.max(0, prefix - 3)
  const suffixContext = Math.min(3, suffix)
  const oldChangedEnd = before.length - suffix
  const newChangedEnd = after.length - suffix
  const oldEnd = oldChangedEnd + suffixContext
  const newEnd = newChangedEnd + suffixContext
  const oldCount = oldEnd - contextStart
  const newCount = newEnd - contextStart
  const oldStart = oldCount ? contextStart + 1 : contextStart
  const newStart = newCount ? contextStart + 1 : contextStart
  const clean = change.path.replace(/^\/+/, '')
  const aPath = patchFileName(`a/${clean}`)
  const bPath = patchFileName(`b/${clean}`)
  const oldPath = change.status === 'added' ? '/dev/null' : aPath
  const newPath = change.status === 'deleted' ? '/dev/null' : bPath
  const body = [`diff --git ${aPath} ${bPath}`]
  if (change.status === 'added') body.push('new file mode 100644')
  if (change.status === 'deleted') body.push('deleted file mode 100644')
  body.push(`--- ${oldPath}`, `+++ ${newPath}`, `@@ -${patchRange(oldStart, oldCount)} +${patchRange(newStart, newCount)} @@`)
  const addLine = (prefixChar, line, missingNewline) => {
    body.push(`${prefixChar}${line}`)
    if (missingNewline) body.push('\\ No newline at end of file')
  }
  for (let index = contextStart; index < prefix; index += 1) addLine(' ', before[index], !oldFile.terminalNewline && index === before.length - 1)
  for (let index = prefix; index < oldChangedEnd; index += 1) addLine('-', before[index], !oldFile.terminalNewline && index === before.length - 1)
  for (let index = prefix; index < newChangedEnd; index += 1) addLine('+', after[index], !newFile.terminalNewline && index === after.length - 1)
  for (let offset = 0; offset < suffixContext; offset += 1) {
    const oldIndex = oldChangedEnd + offset
    const newIndex = newChangedEnd + offset
    addLine(' ', after[newIndex], (!oldFile.terminalNewline && oldIndex === before.length - 1) || (!newFile.terminalNewline && newIndex === after.length - 1))
  }
  return `${body.join('\n')}\n`
}

export function comparisonPatch(diff) {
  if (diff?.changesTruncated) return null
  const patches = (diff?.changes || []).map(filePatch)
  return patches.some((patch) => patch === null) ? null : patches.join('')
}
