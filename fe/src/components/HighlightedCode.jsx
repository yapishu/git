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

function escapeHtml(value) {
  return String(value ?? '').replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;')
}

function blameIdentity(source) {
  return source?.author?.name || source?.author?.email || 'Unknown'
}

function blameRevision(source) {
  return source?.kind === 'clay' ? `r${source.revision}` : String(source?.oid || '').slice(0, 8)
}

function blameMarker(source, line) {
  if (!source) return ''
  const identity = blameIdentity(source)
  const revision = blameRevision(source)
  const title = [source.subject, identity, source.timestampCase].filter(Boolean).join(' · ')
  return `<button type="button" class="blame-origin" data-blame-line="${line}" title="${escapeHtml(title)}"><span>${escapeHtml(identity)}</span><b>${escapeHtml(revision)}</b></button>`
}

function annotateLines(html, selectedStart, selectedEnd, blame) {
  let line = 0
  const annotated = html.replace(/<span class="line">/g, () => {
    line += 1
    const selected = isSelected(line, selectedStart, selectedEnd) ? ' selected-line' : ''
    return `<span class="line${selected}" id="L${line}" data-line="${line}">${blameMarker(blame?.[line - 1], line)}${lineAnchor(line)}`
  })
  // Shiki separates its line spans with literal newlines. Once the spans are
  // block-level those separators render as additional blank lines in <pre>.
  return annotated.replace(/<\/span>\r?\n(?=<span class="line(?: |"))/g, '</span>')
}

function PlainCode({ code, selectedStart, selectedEnd, lineEvents, blame }) {
  const lines = code.split('\n')
  return (
    <pre className={`code-view plain-code${blame ? ' with-blame' : ''}`} {...lineEvents}><code>{lines.map((content, index) => {
      const line = index + 1
      const source = blame?.[index]
      return <span className={`line${isSelected(line, selectedStart, selectedEnd) ? ' selected-line' : ''}`} id={`L${line}`} data-line={line} key={line}>{source && <button type="button" className="blame-origin" data-blame-line={line} title={[source.subject, blameIdentity(source), source.timestampCase].filter(Boolean).join(' · ')}><span>{blameIdentity(source)}</span><b>{blameRevision(source)}</b></button>}<a className="line-number" href={lineHref(line)} data-line-link={line} aria-label={`Link to line ${line}`} title="Click or drag to select; Shift-click to select a range">{line}</a>{content || ' '}</span>
    })}</code></pre>
  )
}

export function HighlightedCode({ code, path, selectedStart, selectedEnd, onSelectLine, blame, onSelectBlame }) {
  const html = useHighlight(code, path)
  const annotated = useMemo(() => html ? annotateLines(html, selectedStart, selectedEnd, blame) : null, [html, selectedStart, selectedEnd, blame])
  const dragAnchor = useRef(null)
  const dragging = useRef(false)

  useEffect(() => {
    if (!selectedStart) return
    const frame = requestAnimationFrame(() => document.getElementById(`L${selectedStart}`)?.scrollIntoView({ block: 'center' }))
    return () => cancelAnimationFrame(frame)
  }, [selectedStart, annotated])

  useEffect(() => {
    const finish = () => { dragAnchor.current = null; dragging.current = false }
    addEventListener('mouseup', finish)
    return () => removeEventListener('mouseup', finish)
  }, [])

  function lineFromEvent(event) {
    const anchor = event.target.closest('[data-line-link]')
    return anchor ? Number(anchor.dataset.lineLink) : null
  }

  function startLine(event) {
    if (event.target.closest('[data-blame-line]')) return
    const line = lineFromEvent(event)
    if (!line || event.button !== 0) return
    event.preventDefault()
    dragAnchor.current = event.shiftKey && selectedStart ? selectedStart : line
    dragging.current = true
    onSelectLine?.(line, event.shiftKey, dragAnchor.current)
  }

  function extendLine(event) {
    if (!dragging.current || dragAnchor.current === null || !(event.buttons & 1)) return
    const line = lineFromEvent(event)
    if (!line) return
    event.preventDefault()
    onSelectLine?.(line, true, dragAnchor.current)
  }

  function suppressLineClick(event) {
    const blameTarget = event.target.closest('[data-blame-line]')
    if (blameTarget) {
      event.preventDefault()
      onSelectBlame?.(blame?.[Number(blameTarget.dataset.blameLine) - 1])
      return
    }
    if (!lineFromEvent(event)) return
    event.preventDefault()
  }

  const lineEvents = { onMouseDown: startLine, onMouseOver: extendLine, onClick: suppressLineClick }

  if (!annotated) return <PlainCode code={code} selectedStart={selectedStart} selectedEnd={selectedEnd} lineEvents={lineEvents} blame={blame} />
  return <div className={`code-view highlighted-code${blame ? ' with-blame' : ''}`} {...lineEvents} dangerouslySetInnerHTML={{ __html: annotated }} />
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
