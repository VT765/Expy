import { useSyncStore } from '../store/useSyncStore'

// 'local' | 'offline' | 'syncing' | 'pending' | 'error' | 'synced'
export function useSyncStatus() {
  const token = useSyncStore((s) => s.token)
  const online = useSyncStore((s) => s.online)
  const status = useSyncStore((s) => s.status)
  const pending = useSyncStore((s) => Object.keys(s.outbox).length)

  let state = 'synced'
  if (!token) state = 'local'
  else if (!online) state = 'offline'
  else if (status === 'syncing') state = 'syncing'
  else if (status === 'error') state = 'error'
  else if (pending > 0) state = 'pending'

  const label = {
    local: 'Local only',
    offline: pending ? `Offline · ${pending} pending` : 'Offline',
    syncing: 'Syncing…',
    error: 'Sync failed',
    pending: `${pending} pending`,
    synced: 'Synced',
  }[state]

  return { state, label, pending }
}
