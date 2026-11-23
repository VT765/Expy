import { useEffect } from 'react'

// Blocks pinch-zoom, which iOS still allows despite user-scalable=no.
// Double-tap zoom is handled by `touch-action: manipulation` in CSS, so fast
// repeated taps (e.g. on a keypad) still register.
export function useIOSGuards() {
  useEffect(() => {
    const stop = (e) => e.preventDefault()
    const opts = { passive: false }
    document.addEventListener('gesturestart', stop, opts)
    document.addEventListener('gesturechange', stop, opts)
    return () => {
      document.removeEventListener('gesturestart', stop, opts)
      document.removeEventListener('gesturechange', stop, opts)
    }
  }, [])
}
