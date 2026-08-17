export function GitIcon({ size = 18 }) {
  return <img src="/apps/urgit/git.svg" width={size} height={size} alt="" aria-hidden="true" />
}

export function RefreshIcon() {
  return <svg viewBox="0 0 24 24"><path d="M20 11a8 8 0 1 0-2.3 6M20 5v6h-6" /></svg>
}

export function PlusIcon() {
  return <svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" /></svg>
}

export function CopyIcon() {
  return <svg viewBox="0 0 24 24"><rect x="8" y="8" width="11" height="11" rx="2" /><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" /></svg>
}

export function ActivityIcon() {
  return <svg viewBox="0 0 24 24"><path d="M4 12h3l2-6 4 12 2-6h5" /></svg>
}

export function SettingsIcon() {
  return <svg viewBox="0 0 24 24"><path d="M4 7h7M15 7h5M4 17h3M11 17h9M11 4v6M7 14v6" /></svg>
}
