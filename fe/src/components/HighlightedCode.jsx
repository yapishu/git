import { useEffect, useMemo, useRef, useState } from 'react'
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

function lineHref(line) {
  const [rawPath, rawQuery = ''] = location.hash.replace(/^#/, '').split('?')
  const params = new URLSearchParams(rawQuery)
  params.set('line', String(line))
  return `#${rawPath}?${params.toString()}`
}

function lineAnchor(line) {
  const href = lineHref(line).replaceAll('&', '&amp;').replaceAll('"', '&quot;')
  return `<a class="line-number" href="${href}" data-line-link="${line}" aria-label="Link to line ${line}">${line}</a>`
}

function isSelected(line, selectedStart, selectedEnd) {
  return selectedStart && line >= selectedStart && line <= (selectedEnd || selectedStart)
}

function annotateLines(html, selectedStart, selectedEnd) {
  let line = 0
  const annotated = html.replace(/<span class="line">/g, () => {
    line += 1
    const selected = isSelected(line, selectedStart, selectedEnd) ? ' selected-line' : ''
    return `<span class="line${selected}" id="L${line}" data-line="${line}">${lineAnchor(line)}`
  })
  // Shiki separates its line spans with literal newlines. Once the spans are
  // block-level those separators render as additional blank lines in <pre>.
  return annotated.replace(/<\/span>\r?\n(?=<span class="line(?: |"))/g, '</span>')
}

function PlainCode({ code, selectedStart, selectedEnd, onSelectLine }) {
  const lines = code.split('\n')
  return (
    <pre className="code-view plain-code"><code>{lines.map((content, index) => {
      const line = index + 1
      return <span className={`line${isSelected(line, selectedStart, selectedEnd) ? ' selected-line' : ''}`} id={`L${line}`} data-line={line} key={line}><a className="line-number" href={lineHref(line)} onClick={(event) => { event.preventDefault(); onSelectLine?.(line, event.shiftKey) }} aria-label={`Link to line ${line}`} title="Click to select; Shift-click to select a range">{line}</a>{content || ' '}</span>
    })}</code></pre>
  )
}

export function HighlightedCode({ code, path, selectedStart, selectedEnd, onSelectLine }) {
  const html = useHighlight(code, path)
  const annotated = useMemo(() => html ? annotateLines(html, selectedStart, selectedEnd) : null, [html, selectedStart, selectedEnd])

  useEffect(() => {
    if (!selectedStart) return
    const frame = requestAnimationFrame(() => document.getElementById(`L${selectedStart}`)?.scrollIntoView({ block: 'center' }))
    return () => cancelAnimationFrame(frame)
  }, [selectedStart, annotated])

  function chooseLine(event) {
    const anchor = event.target.closest('[data-line-link]')
    if (!anchor) return
    event.preventDefault()
    onSelectLine?.(Number(anchor.dataset.lineLink), event.shiftKey)
  }

  if (!annotated) return <PlainCode code={code} selectedStart={selectedStart} selectedEnd={selectedEnd} onSelectLine={onSelectLine} />
  return <div className="code-view highlighted-code" onClick={chooseLine} dangerouslySetInnerHTML={{ __html: annotated }} />
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
