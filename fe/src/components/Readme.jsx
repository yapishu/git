import { useCallback, useEffect, useMemo, useState } from 'react'
import MarkdownDocument from './MarkdownDocument'

function decode(content) {
  const raw = atob(content)
  const bytes = Uint8Array.from(raw, (char) => char.charCodeAt(0))
  try { return new TextDecoder('utf-8', { fatal: true }).decode(bytes) } catch { return null }
}

export function readmePath(files) {
  return (files || []).find((file) => {
    const path = file.path.replace(/^\/+/, '')
    return !path.includes('/') && /^readme(?:\.md|\.markdown)$/i.test(path)
  })?.path || ''
}

function repositoryPath(value) {
  const clean = value.split(/[?#]/, 1)[0]
  const parts = []
  for (const part of clean.split('/')) {
    if (!part || part === '.') continue
    if (part === '..') { parts.pop(); continue }
    parts.push(part)
  }
  return `/${parts.join('/')}`
}

export default function Readme({ files, loadFile, onOpen }) {
  const path = useMemo(() => readmePath(files), [files])
  const [text, setText] = useState(null)
  const [error, setError] = useState('')
  const loadAsset = useCallback((target) => loadFile(repositoryPath(target)), [loadFile])
  const openPath = useCallback((target) => onOpen?.(repositoryPath(target)), [onOpen])

  useEffect(() => {
    let active = true
    setText(null); setError('')
    if (!path) return () => { active = false }
    loadFile(path).then((file) => {
      if (!active) return
      const decoded = decode(file.content)
      if (decoded !== null) setText(decoded)
    }).catch((cause) => active && setError(cause.message))
    return () => { active = false }
  }, [path, loadFile])

  if (!path || (!text && !error)) return null
  return <section className="readme-panel">
    <header><button type="button" className="text-button" onClick={() => onOpen?.(path)}>{path.replace(/^\/+/, '')}</button></header>
    {error ? <div className="inline-error">{error}</div> : <MarkdownDocument loadAsset={loadAsset} onOpenPath={openPath}>{text}</MarkdownDocument>}
  </section>
}
