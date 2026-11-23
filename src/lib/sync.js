import { api } from './api'
import { useDataStore } from '../store/useDataStore'
import { useSyncStore } from '../store/useSyncStore'

// Offline-first sync. Every local write lands in IndexedDB and the outbox;
// this module pushes the outbox, then pulls everything changed on the server
// since the last cursor. Conflicts resolve last-write-wins on updatedAt.

const BATCH = 500
let running = null
let again = false
let debounceTimer

export function syncNow() {
  if (running) {
    again = true
    return running
  }
  running = run().finally(() => {
    running = null
    if (again) {
      again = false
      syncNow()
    }
  })
  return running
}

async function run() {
  const sync = useSyncStore.getState()
  if (!sync.token) return
  if (!navigator.onLine) {
    useSyncStore.setState({ online: false })
    return
  }
  useSyncStore.setState({ status: 'syncing', online: true })
  try {
    // Push in batches.
    let entries = Object.values(useSyncStore.getState().outbox)
    while (entries.length) {
      const batch = entries.slice(0, BATCH)
      const changes = {}
      for (const { collection, doc } of batch) (changes[collection] ??= []).push(doc)
      await api('sync', { method: 'POST', body: { changes } })
      useSyncStore.getState().ack(batch)
      entries = entries.slice(BATCH)
    }
    // Pull.
    const { serverTime, ...remote } = await api(`sync?since=${useSyncStore.getState().cursor || 0}`)
    useDataStore.getState().applyRemote(remote)
    useSyncStore.setState({ cursor: serverTime, lastSyncedAt: Date.now(), status: 'idle', error: null })
  } catch (err) {
    useSyncStore.setState({ status: 'error', error: err.message, online: err.status !== 0 && navigator.onLine })
  }
}

// Wires sync to app lifecycle: open, reconnect, foreground, and local writes.
export function startSync() {
  const onOnline = () => {
    useSyncStore.setState({ online: true })
    syncNow()
  }
  const onOffline = () => useSyncStore.setState({ online: false })
  const onVisible = () => document.visibilityState === 'visible' && syncNow()
  window.addEventListener('online', onOnline)
  window.addEventListener('offline', onOffline)
  document.addEventListener('visibilitychange', onVisible)

  // Debounced push after each local write (outbox grows).
  const unsub = useSyncStore.subscribe((s, prev) => {
    if (s.outbox !== prev.outbox && Object.keys(s.outbox).length > Object.keys(prev.outbox).length) {
      clearTimeout(debounceTimer)
      debounceTimer = setTimeout(syncNow, 800)
    }
    if (s.token && !prev.token) syncNow() // just signed in
  })
  const interval = setInterval(() => document.visibilityState === 'visible' && syncNow(), 5 * 60_000)

  syncNow()
  return () => {
    window.removeEventListener('online', onOnline)
    window.removeEventListener('offline', onOffline)
    document.removeEventListener('visibilitychange', onVisible)
    clearInterval(interval)
    unsub()
  }
}

// Best-effort push before signing out, so nothing unsynced is lost.
export async function flushOutbox(timeoutMs = 6000) {
  if (!Object.keys(useSyncStore.getState().outbox).length) return true
  await Promise.race([syncNow(), new Promise((r) => setTimeout(r, timeoutMs))])
  return !Object.keys(useSyncStore.getState().outbox).length
}
