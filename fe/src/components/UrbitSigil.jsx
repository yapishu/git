import { useMemo } from 'react'
import sigil from '@urbit/sigil-js/core'

export default function UrbitSigil({ ship, size = 88, foreground = '#ffffff', background = '#0969da', className = '' }) {
  const source = useMemo(() => {
    try {
      const point = String(ship || '')
      if (!point || point.length > 14) return ''
      const xml = sigil({ point, size, foreground, background, detail: 'default', space: 'default' })
      return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(xml)}`
    } catch {
      return ''
    }
  }, [ship, size, foreground, background])

  if (!source) return <span className={`${className} sigil-text-fallback`.trim()} aria-hidden="true">~</span>
  return <img className={className} src={source} width={size} height={size} alt={`${ship} sigil`} />
}
