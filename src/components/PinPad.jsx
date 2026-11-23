import { useEffect, useRef, useState } from 'react'
import { motion, useAnimationControls } from 'framer-motion'
import { BackArrow } from './Icons'
import { cn } from '../lib/cn'

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'extra', '0', 'back']
export const PIN_LENGTH = 4

// Title + 4 dots + keypad (same key style as the Tap numpad). Calls
// onComplete(pin) once 4 digits are in; the parent resolves it to true
// (accepted) or false (shake and clear).
export default function PinPad({ title, subtitle, onComplete, disabled, extraKey, resetKey }) {
  const [pin, setPinState] = useState('')
  // The ref is the source of truth so very fast taps never read a stale value.
  const pinRef = useRef('')
  const busy = useRef(false)
  const shake = useAnimationControls()
  const setPin = (v) => {
    pinRef.current = v
    setPinState(v)
  }

  useEffect(() => setPin(''), [resetKey])

  const press = async (k) => {
    if (disabled || busy.current) return
    if (k === 'back') return setPin(pinRef.current.slice(0, -1))
    const next = (pinRef.current + k).slice(0, PIN_LENGTH)
    setPin(next)
    if (next.length === PIN_LENGTH) {
      busy.current = true
      const ok = await onComplete(next)
      if (ok === false) {
        await shake.start({ x: [0, -16, 16, -12, 12, -6, 6, 0], transition: { duration: 0.45 } })
      }
      setPin('')
      busy.current = false
    }
  }

  return (
    <div className="flex w-full flex-col items-center">
      <h1 className="text-title font-bold">{title}</h1>
      <p className="mt-1.5 h-5 text-footnote text-sub">{subtitle}</p>
      <motion.div animate={shake} className="mt-7 flex gap-5" aria-label={`${pin.length} of ${PIN_LENGTH} digits entered`}>
        {Array.from({ length: PIN_LENGTH }, (_, i) => (
          <span
            key={i}
            className={cn('h-3.5 w-3.5 rounded-full border-[1.5px] border-ink transition-transform duration-150', i < pin.length ? 'scale-110 bg-ink' : 'bg-transparent')}
          />
        ))}
      </motion.div>
      <div className={cn('mt-12 grid w-full max-w-[340px] grid-cols-3 gap-[10px] px-4', disabled && 'opacity-30')}>
        {KEYS.map((k) =>
          k === 'extra' ? (
            <div key={k} className="flex items-center justify-center">
              {extraKey}
            </div>
          ) : (
            <button
              key={k}
              type="button"
              onPointerDown={(e) => {
                e.preventDefault()
                press(k)
              }}
              aria-label={k === 'back' ? 'Delete digit' : k}
              className="group relative flex h-[68px] items-center justify-center overflow-hidden rounded-key bg-raised text-key font-medium"
            >
              <span className="pointer-events-none absolute inset-0 bg-white/[0.12] opacity-0 transition-opacity duration-200 group-active:opacity-100 group-active:duration-0" />
              {k === 'back' ? <BackArrow size={26} /> : k}
            </button>
          ),
        )}
      </div>
    </div>
  )
}
