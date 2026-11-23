import { useEffect, useState } from 'react'
import { useDataStore } from '../store/useDataStore'
import { useSyncStore } from '../store/useSyncStore'

const stores = [useDataStore, useSyncStore]

// True once every persisted store has loaded from IndexedDB.
export function useHydrated(extra = []) {
  const all = [...stores, ...extra]
  const check = () => all.every((s) => s.persist.hasHydrated())
  const [ready, setReady] = useState(check)
  useEffect(() => {
    if (ready) return
    const unsubs = all.map((s) => s.persist.onFinishHydration(() => check() && setReady(true)))
    if (check()) setReady(true)
    return () => unsubs.forEach((u) => u())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  return ready
}
