const SHIKI_VERSION = '4.4.3'
const SHIKI_BASE = `https://esm.sh/shiki@${SHIKI_VERSION}`
const SHIKI_PACKAGES = `https://esm.sh/@shikijs`
const HOON_GRAMMAR = 'https://raw.githubusercontent.com/famousj/hoon-vscode/e555c8f04d470d4763678ce8b081101603591346/syntaxes/hoon.tmLanguage'

const extensionLanguages = {
  c: 'c', h: 'c', cc: 'cpp', cpp: 'cpp', cxx: 'cpp', hpp: 'cpp',
  css: 'css', scss: 'scss', less: 'less',
  diff: 'diff', patch: 'diff',
  go: 'go', html: 'html', htm: 'html', java: 'java',
  js: 'javascript', mjs: 'javascript', cjs: 'javascript', jsx: 'jsx',
  json: 'json', jsonc: 'jsonc', kt: 'kotlin', kts: 'kotlin',
  lua: 'lua', md: 'markdown', markdown: 'markdown', nix: 'nix',
  php: 'php', py: 'python', rb: 'ruby', rs: 'rust',
  sh: 'shellscript', bash: 'shellscript', zsh: 'shellscript',
  sql: 'sql', svelte: 'svelte', toml: 'toml',
  ts: 'typescript', tsx: 'tsx', vue: 'vue',
  xml: 'xml', svg: 'xml', yaml: 'yaml', yml: 'yaml', zig: 'zig',
}

const filenameLanguages = {
  dockerfile: 'dockerfile', makefile: 'makefile',
  'docker-compose.yml': 'yaml', 'docker-compose.yaml': 'yaml',
}

let highlighterPromise
let highlighterUnavailable = false
const languagePromises = new Map()

const importRemote = (url) => import(/* @vite-ignore */ url)
const moduleDefault = (module) => module.default || module

export function languageForPath(path) {
  const filename = path.split('/').pop()?.toLowerCase() || ''
  if (filenameLanguages[filename]) return filenameLanguages[filename]
  const extension = filename.includes('.') ? filename.split('.').pop() : ''
  if (extension === 'hoon') return 'hoon'
  return extensionLanguages[extension] || null
}

async function getHighlighter() {
  if (highlighterUnavailable) throw new Error('highlighter unavailable')
  if (!highlighterPromise) {
    highlighterPromise = Promise.all([
      importRemote(`${SHIKI_BASE}/core`),
      importRemote(`${SHIKI_BASE}/engine/javascript`),
      importRemote(`${SHIKI_PACKAGES}/themes@${SHIKI_VERSION}/github-light`),
      importRemote(`${SHIKI_PACKAGES}/themes@${SHIKI_VERSION}/github-dark`),
    ]).then(([core, engine, light, dark]) => core.createHighlighterCore({
      themes: [moduleDefault(light), moduleDefault(dark)],
      langs: [],
      engine: engine.createJavaScriptRegexEngine(),
    })).catch((error) => {
      highlighterPromise = null
      highlighterUnavailable = true
      throw error
    })
  }
  return highlighterPromise
}

function parsePlistValue(element) {
  if (!element) return null
  if (element.tagName === 'dict') {
    const result = {}
    const children = [...element.children]
    for (let index = 0; index < children.length; index += 2) {
      result[children[index].textContent] = parsePlistValue(children[index + 1])
    }
    return result
  }
  if (element.tagName === 'array') return [...element.children].map(parsePlistValue)
  if (element.tagName === 'true') return true
  if (element.tagName === 'false') return false
  if (element.tagName === 'integer' || element.tagName === 'real') return Number(element.textContent)
  return element.textContent
}

async function loadHoonGrammar() {
  const response = await fetch(HOON_GRAMMAR)
  if (!response.ok) throw new Error(`Hoon grammar request failed (${response.status})`)
  const document = new DOMParser().parseFromString(await response.text(), 'application/xml')
  if (document.querySelector('parsererror')) throw new Error('Hoon grammar is not valid XML')
  const grammar = parsePlistValue(document.querySelector('plist')?.firstElementChild)
  return { ...grammar, name: 'hoon', scopeName: 'source.hoon' }
}

async function ensureLanguage(highlighter, language) {
  if (highlighter.getLoadedLanguages().includes(language)) return
  if (!languagePromises.has(language)) {
    const loading = (language === 'hoon'
      ? loadHoonGrammar()
      : importRemote(`${SHIKI_PACKAGES}/langs@${SHIKI_VERSION}/${language}`).then(moduleDefault)
    ).then((grammar) => highlighter.loadLanguage(grammar)).catch((error) => {
      languagePromises.delete(language)
      throw error
    })
    languagePromises.set(language, loading)
  }
  await languagePromises.get(language)
}

export async function highlightCode(code, path) {
  const language = languageForPath(path)
  if (!language || code.length > 500_000) return null
  try {
    const highlighter = await getHighlighter()
    await ensureLanguage(highlighter, language)
    return highlighter.codeToHtml(code, {
      lang: language,
      themes: { light: 'github-light', dark: 'github-dark' },
      defaultColor: 'light',
    })
  } catch {
    return null
  }
}
