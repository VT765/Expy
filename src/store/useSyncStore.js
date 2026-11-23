import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { createIdbStorage } from '../lib/idbStorage'

// Auth token, sync cursor and the outbox of local changes waiting to be pushed.
// The outbox is keyed by collection + id, so repeated edits to one record
// collapse into a single pending write.
export const useSyncStore = create(
  persist(
    (set, get) => ({
      token: null,
      offlineMode: false,
      cursor: 0, // server time of the last successful pull
      lastSyncedAt: null,
      outbox: {},
      status: 'idle', // idle | syncing | error
      error: null,
      online: typeof navigator === 'undefined' ? true : navigator.onLine,

      enqueueMany: (collection, docs) =>
        set((s) => {
          const outbox = { ...s.outbox }
          for (const doc of docs) outbox[`${collection}:${doc.id}`] = { collection, doc }
          return { outbox }
        }),
      // Removes pushed entries unless they were modified again mid-flight.
      ack: (entries) =>
        set((s) => {
          const outbox = { ...s.outbox }
          for (const { collection, doc } of entries) {
            const key = `${collection}:${doc.id}`
            if (outbox[key]?.doc.updatedAt === doc.updatedAt) delete outbox[key]
          }
          return { outbox }
        }),
      pendingCount: () => Object.keys(get().outbox).length,

      login: (token) => set({ token, offlineMode: false, cursor: 0, error: null }),
      useOffline: () => set({ offlineMode: true }),
      logout: () => set({ token: null, offlineMode: false, cursor: 0, lastSyncedAt: null, outbox: {}, status: 'idle', error: null }),
    }),
    {
      name: 'expy-sync',
      version: 1,
      storage: createIdbStorage(),
      partialize: (s) => ({
        token: s.token,
        offlineMode: s.offlineMode,
        cursor: s.cursor,
        lastSyncedAt: s.lastSyncedAt,
        outbox: s.outbox,
      }),
    },
  ),
)
