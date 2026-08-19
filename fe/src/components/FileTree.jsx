import { useEffect, useMemo, useState } from 'react'
import { exactBytes, exactTime, formatBytes, relativeTime } from '../format'

function makeTree(files) {
  const root = { name: '', path: '', directories: new Map(), files: [] }
  for (const file of files || []) {
    const parts = file.path.split('/').filter(Boolean)
    if (!parts.length) continue
    let node = root
    for (const part of parts.slice(0, -1)) {
      if (!node.directories.has(part)) {
        const path = `${node.path}/${part}`
        node.directories.set(part, { name: part, path, directories: new Map(), files: [] })
      }
      node = node.directories.get(part)
    }
    node.files.push({ ...file, name: parts.at(-1) })
  }
  return root
}

function childCount(node) {
  let count = node.files.length
  for (const child of node.directories.values()) count += childCount(child)
  return count
}

function TreeRows({ node, depth, expanded, toggle, onOpen, onOpenCommit, showHistory }) {
  const directories = [...node.directories.values()].sort((a, b) => a.name.localeCompare(b.name))
  const files = [...node.files].sort((a, b) => a.name.localeCompare(b.name))
  return <>
    {directories.map((directory) => {
      const open = expanded.has(directory.path)
      return <div key={directory.path} className="tree-group">
        <button className="table-row file-row tree-row directory-row" style={{ '--tree-depth': depth }} onClick={() => toggle(directory.path)} aria-expanded={open}>
          <span className="file-path"><span className="tree-chevron">{open ? '⌄' : '›'}</span><i className="folder-icon" />{directory.name}</span>
          {showHistory ? <><span /><span className="quiet file-size">{childCount(directory)} items</span><span /></> : <span className="quiet">{childCount(directory)} items</span>}
        </button>
        {open && <TreeRows node={directory} depth={depth + 1} expanded={expanded} toggle={toggle} onOpen={onOpen} onOpenCommit={onOpenCommit} showHistory={showHistory} />}
      </div>
    })}
    {files.map((file) => {
      const path = <span className="file-path"><span className="tree-spacer" /><i />{file.name}</span>
      const commit = file.lastCommit
      const contents = <>
        {onOpen ? <button className="file-open" onClick={() => onOpen(file.path)}>{path}</button> : path}
        {showHistory && <>
          {commit ? <button className="file-commit-link" title={`View ${commit.oid}`} onClick={() => onOpenCommit?.(commit)}>{commit.subject || 'Untitled commit'}</button> : <span className="quiet">—</span>}
          <span className="quiet file-size" title={exactBytes(file.size)}>{formatBytes(file.size)}</span>
          {commit ? <button className="file-time-link" title={exactTime(commit.committer?.timestamp || commit.author?.timestamp)} onClick={() => onOpenCommit?.(commit)}>{relativeTime(commit.committer?.timestamp || commit.author?.timestamp)}</button> : <span className="quiet">—</span>}
        </>}
        {!showHistory && <span className="quiet file-size" title={exactBytes(file.size)}>{formatBytes(file.size)}</span>}
      </>
      return onOpen
        ? <div className="table-row file-row tree-row" style={{ '--tree-depth': depth }} key={file.path}>{contents}</div>
        : <div className="table-row tree-row static-file-row" style={{ '--tree-depth': depth }} key={file.path}>{contents}</div>
    })}
  </>
}

export default function FileTree({ files, header, onOpen, onOpenCommit }) {
  const tree = useMemo(() => makeTree(files), [files])
  const [expanded, setExpanded] = useState(new Set())
  const showHistory = Boolean(onOpenCommit) && (files || []).some((file) => Object.hasOwn(file, 'lastCommit'))

  useEffect(() => { setExpanded(new Set()) }, [files])

  function toggle(path) {
    setExpanded((current) => {
      const next = new Set(current)
      if (next.has(path)) next.delete(path)
      else next.add(path)
      return next
    })
  }

  return <div className={`table file-tree${showHistory ? ' with-history' : ''}`}>
    {header}
    <div className="table-head"><span>Path</span>{showHistory && <span>Last commit</span>}<span>Size</span>{showHistory && <span>Updated</span>}</div>
    <TreeRows node={tree} depth={0} expanded={expanded} toggle={toggle} onOpen={onOpen} onOpenCommit={onOpenCommit} showHistory={showHistory} />
  </div>
}
