import { useDataStore } from '../store/useDataStore'
import { useSyncStore } from '../store/useSyncStore'
import { useLockStore } from '../store/useLockStore'
import { useUIStore } from '../store/useUIStore'
import { flushOutbox } from './sync'

// Clears this device: data, sync state and App Lock. Used by sign-out and
// "Forgot PIN" (after which the password is required to get back in).
export function wipeDevice() {
  useDataStore.getState().resetLocal()
  useSyncStore.getState().logout()
  useLockStore.getState().disable()
  useUIStore.setState({ settingsOpen: false, editingId: null, tab: 'tap' })
}

// Pushes pending changes, then wipes. Returns false if the user backed out
// because changes couldn't be synced.
export async function signOut() {
  const { confirm, showToast } = useUIStore.getState()
  const flushed = await flushOutbox()
  if (!flushed) {
    const pending = Object.keys(useSyncStore.getState().outbox).length
    const ok = await confirm({
      title: `${pending} unsynced ${pending === 1 ? 'change' : 'changes'}`,
      message: "They couldn't be uploaded and will be lost if you sign out now.",
      confirmLabel: 'Sign out anyway',
      destructive: true,
    })
    if (!ok) return false
  }
  wipeDevice()
  showToast('Signed out')
  return true
}

export const forgotPin = {
  prompt: () =>
    useSyncStore.getState().token
      ? {
          title: 'Forgot PIN?',
          message: "You'll be signed out. Sign in with your password to get back in. Your data is safe on the server.",
          confirmLabel: 'Sign out',
          destructive: true,
        }
      : {
          title: 'Forgot PIN?',
          message: 'This device is not signed in, so the only way back in is to erase the data on this device.',
          confirmLabel: 'Erase & reset',
          destructive: true,
        },
  run: async () => {
    if (useSyncStore.getState().token) await flushOutbox()
    wipeDevice()
  },
}
