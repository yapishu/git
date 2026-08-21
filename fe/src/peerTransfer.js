import { formatBytes } from './format'

export function peerTransferPresentation(transfer) {
  if (!transfer) return { label: 'Contacting peer…', determinate: false }

  const stage = transfer.stage || ''
  const expectedBytes = Number(transfer.expectedBytes || 0)
  const archive = stage === 'archive' || expectedBytes > 0
  if (archive) {
    const size = expectedBytes > 0 ? ` · ${formatBytes(expectedBytes)}` : ''
    return { label: `Transferring repository archive${size}…`, determinate: false }
  }

  if (stage === 'prepare') return { label: 'Peer is preparing repository archive…', determinate: false }
  if (stage === 'request') return { label: 'Waiting for peer…', determinate: false }
  return { label: 'Transferring repository…', determinate: false }
}
