import { useEffect, useState } from 'react'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'

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

export default function Markdown({ children, className = '', loadAsset, onOpenPath }) {
  return <div className={`markdown-body ${className}`.trim()}>
    <ReactMarkdown
      remarkPlugins={[remarkGfm]}
      urlTransform={safeUrl}
      components={{
        a: ({ node: _node, href = '', children: content, ...props }) => {
          const repositoryPath = relativeUrl(href) && onOpenPath
          const external = /^https?:/i.test(href)
          return <a
            {...props}
            href={href}
            target={external ? '_blank' : undefined}
            rel={external ? 'noreferrer' : undefined}
            onClick={repositoryPath ? (event) => { event.preventDefault(); onOpenPath(href) } : undefined}
          >{content}</a>
        },
        img: ({ node: _node, src = '', alt = '' }) => <MarkdownImage src={src} alt={alt} loadAsset={loadAsset} />,
      }}
    >{String(children || '')}</ReactMarkdown>
  </div>
}
