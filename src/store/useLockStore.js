import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { createIdbStorage } from '../lib/idbStorage'
import { createPinRecord, hashPin, safeEqual } from '../lib/crypto'

const MAX_ATTEMPTS = 5
const COOLDOWN_MS = 30_000
export const AUTO_LOCK = { immediate: 0, '1m': 60_000, '5m': 300_000 }

// Device-local security settings (never synced) plus the runtime lock state.
export const useLockStore = create(
  persist(
    (set, get) => ({
      enabled: false,
      pinHash: null,
      salt: null,
      iterations: 0,
      faceIdCredential: null,
      autoLock: 'immediate',
      failures: 0,
      cooldownUntil: 0,

      locked: false,
      hiddenAt: null,

      setPin: async (pin) => {
        const record = await createPinRecord(pin)
        set({ ...record, enabled: true, failures: 0, cooldownUntil: 0 })
      },
      checkPin: async (pin) => {
        const { pinHash, salt, iterations } = get()
        if (!pinHash) return false
        return safeEqual(await hashPin(pin, salt, iterations), pinHash)
      },
      // Returns 'ok' | 'wrong' | 'cooldown'.
      attempt: async (pin) => {
        if (Date.now() < get().cooldownUntil) return 'cooldown'
        if (await get().checkPin(pin)) {
          set({ locked: false, failures: 0, cooldownUntil: 0 })
          return 'ok'
        }
        const failures = get().failures + 1
        if (failures >= MAX_ATTEMPTS) {
          set({ failures: 0, cooldownUntil: Date.now() + COOLDOWN_MS })
          return 'cooldown'
        }
        set({ failures })
        return 'wrong'
      },
      unlock: () => set({ locked: false, failures: 0 }),
      lock: () => get().enabled && set({ locked: true }),
      disable: () => set({ enabled: false, pinHash: null, salt: null, iterations: 0, faceIdCredential: null, locked: false, failures: 0, cooldownUntil: 0 }),
      setFaceId: (faceIdCredential) => set({ faceIdCredential }),
      setAutoLock: (autoLock) => set({ autoLock }),
      markHidden: () => set({ hiddenAt: Date.now() }),
      markVisible: () => {
        const { enabled, hiddenAt, autoLock } = get()
        if (enabled && hiddenAt != null && Date.now() - hiddenAt >= (AUTO_LOCK[autoLock] ?? 0)) set({ locked: true })
        set({ hiddenAt: null })
      },
    }),
    {
      name: 'expy-lock',
      version: 1,
      storage: createIdbStorage(0),
      partialize: (s) => ({
        enabled: s.enabled,
        pinHash: s.pinHash,
        salt: s.salt,
        iterations: s.iterations,
        faceIdCredential: s.faceIdCredential,
        autoLock: s.autoLock,
        failures: s.failures,
        cooldownUntil: s.cooldownUntil,
      }),
      // Always start locked when a PIN is set.
      onRehydrateStorage: () => (state) => {
        if (state?.enabled) useLockStore.setState({ locked: true })
      },
    },
  ),
)
