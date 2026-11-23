import { del, get, set } from 'idb-keyval'

// Zustand persist storage backed by IndexedDB. Values go through structured
// clone (no JSON round-trip), and bursts of writes (e.g. a sync pulling 500
// rows) are coalesced into one put. Pending writes flush when the app is
// backgrounded, since iOS may kill a hidden PWA without warning.
export function createIdbStorage(wait = 200) {
  const timers = {}
  const pending = {}

  const flush = () => {
    for (const name of Object.keys(pending)) {
      clearTimeout(timers[name])
      set(name, pending[name])
      delete pending[name]
    }
  }
  if (typeof window !== 'undefined') {
    window.addEventListener('pagehide', flush)
    document.addEventListener('visibilitychange', () => document.visibilityState === 'hidden' && flush())
  }

  return {
    getItem: async (name) => (await get(name)) ?? null,
    setItem: (name, value) => {
      pending[name] = value
      clearTimeout(timers[name])
      timers[name] = setTimeout(() => {
        delete pending[name]
        set(name, value)
      }, wait)
    },
    removeItem: (name) => {
      clearTimeout(timers[name])
      delete pending[name]
      return del(name)
    },
  }
}
