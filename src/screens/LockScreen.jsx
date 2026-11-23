import { useCallback, useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import PinPad from '../components/PinPad'
import Button from '../components/Button'
import { FaceIdIcon, LockIcon } from '../components/Icons'
import { useLockStore } from '../store/useLockStore'
import { useUIStore } from '../store/useUIStore'
import { verifyFaceId } from '../lib/webauthn'
import { forgotPin } from '../lib/session'

export default function LockScreen() {
  const faceId = useLockStore((s) => s.faceIdCredential)
  const cooldownUntil = useLockStore((s) => s.cooldownUntil)
  const failures = useLockStore((s) => s.failures)
  const attempt = useLockStore((s) => s.attempt)
  const unlock = useLockStore((s) => s.unlock)
  const [mode, setMode] = useState(faceId ? 'face' : 'pin')
  const [now, setNow] = useState(Date.now())
  const [prompting, setPrompting] = useState(false)

  const cooling = cooldownUntil > now
  useEffect(() => {
    if (!cooling) return
    const t = setInterval(() => setNow(Date.now()), 250)
    return () => clearInterval(t)
  }, [cooling])

  const tryFaceId = useCallback(async () => {
    if (!faceId || prompting) return
    setPrompting(true)
    try {
      if (await verifyFaceId(faceId)) unlock()
    } catch {
      // Cancelled, or Safari wants a tap first: stay on this screen.
    } finally {
      setPrompting(false)
    }
  }, [faceId, prompting, unlock])

  // Auto-prompt once on show.
  useEffect(() => {
    if (faceId) tryFaceId()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const subtitle = cooling
    ? `Too many attempts. Try again in ${Math.ceil((cooldownUntil - now) / 1000)}s`
    : failures > 0
      ? `Wrong PIN · ${5 - failures} ${5 - failures === 1 ? 'try' : 'tries'} left`
      : ' '

  return (
    <motion.div
      className="fixed inset-0 z-[80] flex flex-col items-center bg-canvas pb-safe-b pt-safe-t"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
    >
      <div className="flex w-full flex-1 flex-col items-center justify-center">
        {mode === 'face' ? (
          <div className="flex flex-col items-center px-gutter">
            <LockIcon size={34} className="text-sub" />
            <h1 className="mt-4 text-title font-bold">Expy is locked</h1>
            <button type="button" onClick={tryFaceId} className="mt-10 flex flex-col items-center gap-3 active:opacity-60" aria-label="Unlock with Face ID">
              <FaceIdIcon size={64} strokeWidth={1.4} />
              <span className="text-body text-sub">{prompting ? 'Looking for you…' : 'Tap to unlock with Face ID'}</span>
            </button>
            <Button variant="secondary" size="md" className="mt-12 w-40" onClick={() => setMode('pin')}>
              Use PIN
            </Button>
          </div>
        ) : (
          <PinPad
            title="Enter PIN"
            subtitle={subtitle}
            disabled={cooling}
            onComplete={async (pin) => {
              const r = await attempt(pin)
              if (r === 'cooldown') setNow(Date.now())
              return r === 'ok'
            }}
            extraKey={
              faceId ? (
                <button type="button" aria-label="Use Face ID" onClick={tryFaceId} className="flex h-[68px] w-full items-center justify-center text-ink active:opacity-50">
                  <FaceIdIcon size={30} />
                </button>
              ) : null
            }
          />
        )}
      </div>
      <button
        type="button"
        onClick={async () => {
          const ok = await useUIStore.getState().confirm(forgotPin.prompt())
          if (ok) forgotPin.run()
        }}
        className="mb-6 text-footnote text-sub active:opacity-50"
      >
        Forgot PIN?
      </button>
    </motion.div>
  )
}
