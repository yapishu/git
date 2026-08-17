import { useState } from 'react'

export default function NewRepositoryModal({ onCreate, onPublishDesk, onForkPeer, onImportGitHub, onClose }) {
  const [mode, setMode] = useState('choose')
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [publicRead, setPublicRead] = useState(false)
  const [busy, setBusy] = useState(false)

  async function submit(event) {
    event.preventDefault()
    setBusy(true)
    try { await onCreate(name.trim(), publicRead, description.trim()); onClose() } finally { setBusy(false) }
  }

  return <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
    <section className="modal-card" role="dialog" aria-modal="true" aria-label="New repository">
      <header><div><span className="eyebrow">Create</span><h1>New repository</h1></div><button className="icon-button" onClick={onClose} aria-label="Close">×</button></header>
      {mode === 'choose' ? <div className="source-options">
        <button onClick={() => setMode('blank')}><b>Blank repository</b><span>Start with an empty main branch.</span><i>›</i></button>
        <button onClick={() => { onPublishDesk(); onClose() }}><b>Publish a Clay desk</b><span>Snapshot an existing desk and keep its revisions mapped to commits.</span><i>›</i></button>
        <button onClick={() => { onForkPeer(); onClose() }}><b>Fork from a ship</b><span>Copy a repository over Ames and Fine, with an upstream for pushes and PRs.</span><i>›</i></button>
        <button onClick={() => { onImportGitHub(); onClose() }}><b>Import from GitHub</b><span>Fetch Git objects and optionally synchronize issues and pull requests.</span><i>›</i></button>
      </div> : <form onSubmit={submit}>
        <button type="button" className="text-button modal-back" onClick={() => setMode('choose')}>← Sources</button>
        <label><span>Name</span><input autoFocus required pattern="[A-Za-z0-9._-]+" maxLength="100" value={name} onChange={(event) => setName(event.target.value)} placeholder="my-project" /></label>
        <label><span>Description</span><input maxLength="500" value={description} onChange={(event) => setDescription(event.target.value)} placeholder="What is this repository for?" /></label>
        <label className="check-row"><input type="checkbox" checked={publicRead} onChange={(event) => setPublicRead(event.target.checked)} /><span><strong>Public read access</strong><small>Other ships and Git clients can browse, clone, and fetch.</small></span></label>
        <div className="form-actions"><button type="button" className="button ghost" onClick={onClose}>Cancel</button><button className="button primary" disabled={busy || !name.trim()}>{busy ? 'Creating…' : 'Create repository'}</button></div>
      </form>}
    </section>
  </div>
}
