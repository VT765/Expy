import { Row, Section } from '../SettingsRow'
import { useSyncStore } from '../../store/useSyncStore'
import { syncNow } from '../../lib/sync'
import { useSyncStatus } from '../../hooks/useSyncStatus'

const ago = (ts) => {
  if (!ts) return 'Never'
  const s = Math.round((Date.now() - ts) / 1000)
  if (s < 60) return 'Just now'
  if (s < 3600) return `${Math.round(s / 60)} min ago`
  return new Date(ts).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' })
}

export default function SyncSection() {
  const token = useSyncStore((s) => s.token)
  const lastSyncedAt = useSyncStore((s) => s.lastSyncedAt)
  const error = useSyncStore((s) => s.error)
  const { label, pending } = useSyncStatus()

  if (!token) {
    return (
      <Section title="Sync status">
        <Row title="Local only" subtitle="Data lives on this device. Sign in above to sync." chevron={false} />
      </Section>
    )
  }

  return (
    <Section title="Sync status">
      <Row title="Status" value={label} chevron={false} subtitle={error && label !== 'Synced' ? error : undefined} />
      <Row title="Last synced" value={ago(lastSyncedAt)} chevron={false} />
      {pending > 0 && <Row title="Pending changes" value={String(pending)} chevron={false} />}
      <Row title="Sync now" onClick={() => syncNow()} />
    </Section>
  )
}
