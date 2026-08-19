import { parseDocument, stringify } from 'yaml'
import Markdown from './Markdown'
import '../frontmatter.css'

const frontmatterBlock = /^\uFEFF?---[ \t]*(?:\r?\n)([\s\S]*?)(?:\r?\n)---[ \t]*(?=\r?\n|$)(?:\r?\n)?/

function splitFrontmatter(source) {
  const match = source.match(frontmatterBlock)
  if (!match) return { body: source, metadata: null }

  try {
    const document = parseDocument(match[1])
    if (document.errors.length) return { body: source, metadata: null }
    const parsed = document.toJS({ mapAsMap: true, maxAliasCount: 100 })
    if (!(parsed instanceof Map)) return { body: source, metadata: null }

    return {
      body: source.slice(match[0].length),
      metadata: Array.from(parsed, ([key, value]) => [String(key), value]),
    }
  } catch {
    return { body: source, metadata: null }
  }
}

function FrontmatterValue({ value }) {
  if (value !== null && typeof value === 'object') {
    return <code className="markdown-frontmatter-complex">{stringify(value).trimEnd()}</code>
  }
  return String(value ?? 'null')
}

export default function MarkdownDocument({ children, className = '', loadAsset, onOpenPath }) {
  const source = String(children || '')
  const { body, metadata } = splitFrontmatter(source)
  if (!metadata) return <Markdown className={className} loadAsset={loadAsset} onOpenPath={onOpenPath}>{source}</Markdown>

  return <div className={`markdown-body ${className}`.trim()}>
    <table className="markdown-frontmatter">
      <tbody>{metadata.map(([key, value], index) => <tr key={`${index}-${key}`}>
        <th scope="row">{key}</th>
        <td><FrontmatterValue value={value} /></td>
      </tr>)}</tbody>
    </table>
    <Markdown loadAsset={loadAsset} onOpenPath={onOpenPath}>{body}</Markdown>
  </div>
}
