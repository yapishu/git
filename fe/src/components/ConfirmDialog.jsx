import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react'

const ConfirmContext = createContext(null)

export function ConfirmProvider({ children }) {
  const [dialog, setDialog] = useState(null)
  const resolver = useRef(null)

  const close = useCallback((accepted) => {
    resolver.current?.(accepted)
    resolver.current = null
    setDialog(null)
  }, [])

  const confirm = useCallback((options) => new Promise((resolve) => {
    resolver.current?.(false)
    resolver.current = resolve
    setDialog(typeof options === 'string' ? { message: options } : options)
  }), [])

  useEffect(() => {
    if (!dialog) return undefined
    const onKeyDown = (event) => { if (event.key === 'Escape') close(false) }
    addEventListener('keydown', onKeyDown)
    return () => removeEventListener('keydown', onKeyDown)
  }, [dialog, close])

  return <ConfirmContext.Provider value={confirm}>
    {children}
    {dialog && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && close(false)}>
      <section className="modal-card confirm-card" role="alertdialog" aria-modal="true" aria-labelledby="confirm-title" aria-describedby="confirm-message">
        <header><div><span className="eyebrow">Confirm</span><h1 id="confirm-title">{dialog.title || 'Are you sure?'}</h1></div><button type="button" className="icon-button" onClick={() => close(false)} aria-label="Close">×</button></header>
        <div className="modal-body">
          <p id="confirm-message">{dialog.message}</p>
          {dialog.detail && <small>{dialog.detail}</small>}
          <div className="form-actions"><button type="button" className="button ghost" onClick={() => close(false)}>{dialog.cancelLabel || 'Cancel'}</button><button type="button" className={`button ${dialog.danger === false ? 'primary' : 'danger'}`} autoFocus onClick={() => close(true)}>{dialog.confirmLabel || 'Continue'}</button></div>
        </div>
      </section>
    </div>}
  </ConfirmContext.Provider>
}

export function useConfirm() {
  const confirm = useContext(ConfirmContext)
  if (!confirm) throw new Error('useConfirm must be used inside ConfirmProvider')
  return confirm
}
