import { useEffect, useState } from 'react'
import { Section } from '../SettingsRow'
import Button from '../Button'
import Skeleton from '../Skeleton'
import { CopyIcon } from '../Icons'
import { useSyncStore } from '../../store/useSyncStore'
import { useUIStore } from '../../store/useUIStore'
import { api } from '../../lib/api'
import { syncNow } from '../../lib/sync'

async function copy(text, label) {
  try {
    await navigator.clipboard.writeText(text)
    useUIStore.getState().showToast(`${label} copied`)
  } catch {
    useUIStore.getState().showError('Copy failed; long-press to select instead')
  }
}

function CopyField({ label, value, secret }) {
  const [revealed, setRevealed] = useState(!secret)
  return (
    <div className="rounded-card bg-card px-4 py-3">
      <p className="text-footnote text-sub">{label}</p>
      <div className="mt-1 flex items-center gap-2">
        <button
          type="button"
          onClick={() => secret && setRevealed((r) => !r)}
          className="min-w-0 flex-1 select-text truncate text-left font-mono text-footnote text-ink"
        >
          {value ? (revealed ? value : '•'.repeat(24)) : <Skeleton className="h-4 w-48" />}
        </button>
        <button type="button" aria-label={`Copy ${label}`} disabled={!value} onClick={() => copy(value, label)} className="flex h-9 w-9 items-center justify-center rounded-full bg-raised active:opacity-60 disabled:opacity-30">
          <CopyIcon size={16} />
        </button>
      </div>
    </div>
  )
}

// API URLs + key for iOS Shortcuts, key rotation and an end-to-end test.
export default function QuickLoggingSection() {
  const token = useSyncStore((s) => s.token)
  const [apiKey, setApiKey] = useState(null)
  const [error, setError] = useState(null)
  const [testing, setTesting] = useState(false)
  const origin = window.location.origin

  useEffect(() => {
    if (!token) return
    api('shortcut/key')
      .then((r) => setApiKey(r.apiKey))
      .catch((e) => setError(e.message))
  }, [token])

  if (!token) {
    return (
      <Section title="Quick Logging" hint="Sign in to log expenses from iOS Shortcuts, Back Tap and Siri.">
        {null}
      </Section>
    )
  }

  const regenerate = async () => {
    const ok = await useUIStore.getState().confirm({
      title: 'Regenerate API key?',
      message: 'Your existing Shortcuts stop working until you paste the new key into them.',
      confirmLabel: 'Regenerate',
      destructive: true,
    })
    if (!ok) return
    try {
      setApiKey((await api('shortcut/key/regenerate', { method: 'POST' })).apiKey)
      useUIStore.getState().showToast('New key generated')
    } catch (e) {
      useUIStore.getState().showError(e.message)
    }
  }

  // Creates an entry through the Shortcut endpoint, then deletes it.
  const test = async () => {
    setTesting(true)
    const { showToast, showError } = useUIStore.getState()
    try {
      const res = await api('quick-add', {
        method: 'POST',
        auth: false,
        raw: true,
        headers: { 'x-api-key': apiKey },
        body: { amount: 1, category: 'Other', note: 'Expy connection test' },
      })
      const text = await res.text()
      if (!res.ok) throw new Error(text.replace(/^Error:\s*/, ''))
      const id = res.headers.get('X-Entry-Id')
      if (id) await api(`transactions/${id}`, { method: 'DELETE' })
      await syncNow()
      showToast(`Test passed · ${text.replace(/^Saved /, '')} added & removed`, { duration: 3500 })
    } catch (e) {
      showError(`Test failed: ${e.message}`)
    } finally {
      setTesting(false)
    }
  }

  return (
    <Section title="Quick Logging" hint="Use these in the “Log Expense” Shortcut. See the README for the step-by-step.">
      <CopyField label="Quick-add URL (POST)" value={`${origin}/api/quick-add`} />
      <CopyField label="Categories URL (GET)" value={`${origin}/api/shortcut/categories`} />
      <CopyField label="API key (x-api-key header) · tap to reveal" value={apiKey} secret />
      {error && <p className="px-1 text-footnote text-danger">{error}</p>}
      <div className="grid grid-cols-2 gap-[6px] pt-1">
        <Button variant="secondary" size="md" onClick={test} loading={testing} disabled={!apiKey}>
          Test
        </Button>
        <Button variant="destructive" size="md" onClick={regenerate} disabled={!apiKey}>
          Regenerate key
        </Button>
      </div>
    </Section>
  )
}
