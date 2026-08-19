import React, { useEffect, useState } from 'react'

function safeUrl(value) {
  const url = value.trim()
  if (/^(https?:|mailto:|#|\/)/i.test(url) || (!/^[a-z][a-z0-9+.-]*:/i.test(url) && !url.startsWith('//'))) return url
  return '#'
}

const relativeUrl = (value) => !/^(?:[a-z][a-z0-9+.-]*:|\/|#)/i.test(value)
const assetType = (path) => ({ png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', webp: 'image/webp', svg: 'image/svg+xml' })[(path.split('.').pop() || '').toLowerCase()]

function MarkdownImage({ src, alt, loadAsset }) {
  const [resolved, setResolved] = useState(relativeUrl(src) && loadAsset ? '' : safeUrl(src))
  useEffect(() => {
    let active = true
    if (!relativeUrl(src) || !loadAsset) { setResolved(safeUrl(src)); return () => { active = false } }
    loadAsset(src).then((file) => {
      if (active) setResolved(`data:${assetType(src) || 'application/octet-stream'};base64,${file.content}`)
    }).catch(() => active && setResolved('#'))
    return () => { active = false }
  }, [src, loadAsset])
  if (!resolved) return <span className="markdown-image-loading">{alt}</span>
  if (resolved === '#') return alt
  return <img src={resolved} alt={alt} loading="lazy" />
}

function inline(text, key = 'inline', options = {}) {
  const pattern = /(!\[[^\]]*\]\([^)]+\)|`[^`]+`|\*\*[^*]+\*\*|__[^_]+__|\[[^\]]+\]\([^)]+\)|\*[^*]+\*|_[^_]+_)/g
  const nodes = []
  let offset = 0
  let match
  while ((match = pattern.exec(text))) {
    if (match.index > offset) nodes.push(text.slice(offset, match.index))
    const token = match[0]
    const tokenKey = `${key}-${match.index}`
    if (token.startsWith('![')) {
      const split = token.lastIndexOf('](')
      const alt = token.slice(2, split)
      const src = safeUrl(token.slice(split + 2, -1))
      nodes.push(src === '#' ? alt : <MarkdownImage key={tokenKey} src={src} alt={alt} loadAsset={options.loadAsset} />)
    } else if (token.startsWith('`')) nodes.push(<code key={tokenKey}>{token.slice(1, -1)}</code>)
    else if (token.startsWith('**') || token.startsWith('__')) nodes.push(<strong key={tokenKey}>{inline(token.slice(2, -2), tokenKey, options)}</strong>)
    else if (token.startsWith('[')) {
      const split = token.lastIndexOf('](')
      const label = token.slice(1, split)
      const href = safeUrl(token.slice(split + 2, -1))
      const repositoryPath = relativeUrl(href) && options.onOpenPath
      nodes.push(<a key={tokenKey} href={href} target={href.startsWith('http') ? '_blank' : undefined} rel={href.startsWith('http') ? 'noreferrer' : undefined} onClick={repositoryPath ? (event) => { event.preventDefault(); options.onOpenPath(href) } : undefined}>{inline(label, tokenKey, options)}</a>)
    } else nodes.push(<em key={tokenKey}>{inline(token.slice(1, -1), tokenKey, options)}</em>)
    offset = pattern.lastIndex
  }
  if (offset < text.length) nodes.push(text.slice(offset))
  return nodes
}

function blocks(markdown, options) {
  const lines = markdown.replace(/\r\n?/g, '\n').split('\n')
  const output = []
  let index = 0
  while (index < lines.length) {
    const line = lines[index]
    if (!line.trim()) { index += 1; continue }
    const fence = /^\s*```([^`]*)$/.exec(line)
    if (fence) {
      const code = []
      index += 1
      while (index < lines.length && !/^\s*```/.test(lines[index])) code.push(lines[index++])
      if (index < lines.length) index += 1
      output.push(<pre key={`code-${index}`}><code className={fence[1].trim() ? `language-${fence[1].trim()}` : undefined}>{code.join('\n')}</code></pre>)
      continue
    }
    const heading = /^(#{1,6})\s+(.+)$/.exec(line)
    if (heading) {
      const level = heading[1].length
      output.push(React.createElement(`h${level}`, { key: `heading-${index}` }, inline(heading[2], `heading-${index}`, options)))
      index += 1
      continue
    }
    if (/^\s*(?:---+|___+|\*\*\*+)\s*$/.test(line)) { output.push(<hr key={`hr-${index}`} />); index += 1; continue }
    if (/^\s*>/.test(line)) {
      const quote = []
      while (index < lines.length && /^\s*>/.test(lines[index])) quote.push(lines[index++].replace(/^\s*>\s?/, ''))
      output.push(<blockquote key={`quote-${index}`}>{blocks(quote.join('\n'), options)}</blockquote>)
      continue
    }
    const list = /^\s*(?:([-+*])|(\d+)\.)\s+(.+)$/.exec(line)
    if (list) {
      const ordered = Boolean(list[2])
      const items = []
      while (index < lines.length) {
        const item = /^\s*(?:([-+*])|(\d+)\.)\s+(.+)$/.exec(lines[index])
        if (!item || Boolean(item[2]) !== ordered) break
        items.push(<li key={`item-${index}`}>{inline(item[3], `item-${index}`, options)}</li>)
        index += 1
      }
      output.push(ordered ? <ol key={`list-${index}`}>{items}</ol> : <ul key={`list-${index}`}>{items}</ul>)
      continue
    }
    const paragraph = [line.trim()]
    index += 1
    while (index < lines.length && lines[index].trim() && !/^\s*```|^#{1,6}\s|^\s*>|^\s*(?:[-+*]|\d+\.)\s+/.test(lines[index])) paragraph.push(lines[index++].trim())
    output.push(<p key={`paragraph-${index}`}>{inline(paragraph.join(' '), `paragraph-${index}`, options)}</p>)
  }
  return output
}

export default function Markdown({ children, className = '', loadAsset, onOpenPath }) {
  return <div className={`markdown-body ${className}`.trim()}>{blocks(String(children || ''), { loadAsset, onOpenPath })}</div>
}
