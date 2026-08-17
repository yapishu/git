import { useEffect, useRef, useState } from 'react'
import { highlightCode } from '../highlight'

function useHighlight(code, path, delay = 0) {
  const [html, setHtml] = useState(null)

  useEffect(() => {
    let active = true
    let timer
    setHtml(null)
    timer = setTimeout(() => {
      highlightCode(code, path).then((result) => {
        if (active) setHtml(result)
      })
    }, delay)
    return () => { active = false; clearTimeout(timer) }
  }, [code, path, delay])

  return html
}

export function HighlightedCode({ code, path }) {
  const html = useHighlight(code, path)
  if (!html) return <pre className="code-view"><code>{code}</code></pre>
  return <div className="code-view highlighted-code" dangerouslySetInnerHTML={{ __html: html }} />
}

export function HighlightedEditor({ value, path, onChange }) {
  const html = useHighlight(value, path, 100)
  const overlay = useRef(null)

  function synchronizeScroll(event) {
    if (!overlay.current) return
    overlay.current.scrollTop = event.currentTarget.scrollTop
    overlay.current.scrollLeft = event.currentTarget.scrollLeft
  }

  return (
    <div className={`highlight-editor${html ? ' ready' : ''}`}>
      {html && <div ref={overlay} className="editor-highlight" aria-hidden="true" dangerouslySetInnerHTML={{ __html: html }} />}
      <textarea
        className="code-editor"
        value={value}
        onChange={onChange}
        onScroll={synchronizeScroll}
        wrap="off"
        spellCheck="false"
        aria-label={`Edit ${path}`}
      />
    </div>
  )
}
