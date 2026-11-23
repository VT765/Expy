import { useEffect, useState } from 'react'
import { useLockStore } from '../store/useLockStore'

// Tracks background/foreground transitions and re-locks after the configured
// delay. Returns `obscured`: true while the app is hidden with lock enabled,
// so the iOS app-switcher snapshot shows a blank screen.
export function useAutoLock() {
  const [obscured, setObscured] = useState(false)
  useEffect(() => {
    const onChange = () => {
      const { enabled, markHidden, markVisible } = useLockStore.getState()
      if (document.visibilityState === 'hidden') {
        markHidden()
        if (enabled) setObscured(true)
      } else {
        markVisible()
        setObscured(false)
      }
    }
    document.addEventListener('visibilitychange', onChange)
    window.addEventListener('pagehide', onChange)
    return () => {
      document.removeEventListener('visibilitychange', onChange)
      window.removeEventListener('pagehide', onChange)
    }
  }, [])
  return obscured
}
