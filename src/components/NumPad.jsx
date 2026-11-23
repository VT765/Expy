import { useRef } from 'react'
import { BackArrow } from './Icons'

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back']
const LONG_PRESS_MS = 450

// 3×4 keypad. Keys fire on pointerdown for zero-latency input; holding
// backspace calls onClear. Press feedback is an opacity overlay.
export default function NumPad({ onKey, onBackspace, onClear, className = '' }) {
  const holdTimer = useRef()
  const cleared = useRef(false)

  const down = (key) => (e) => {
    e.preventDefault()
    if (key === 'back') {
      cleared.current = false
      holdTimer.current = setTimeout(() => {
        cleared.current = true
        onClear()
      }, LONG_PRESS_MS)
      return
    }
    onKey(key)
  }
  const up = (key) => () => {
    if (key !== 'back') return
    clearTimeout(holdTimer.current)
    if (!cleared.current) onBackspace()
    cleared.current = true
  }
  const cancel = () => {
    clearTimeout(holdTimer.current)
    cleared.current = true
  }

  return (
    <div className={`grid grid-cols-3 gap-[6px] ${className}`}>
      {KEYS.map((k) => (
        <button
          key={k}
          type="button"
          aria-label={k === 'back' ? 'Backspace (hold to clear)' : k === '.' ? 'Decimal point' : k}
          onPointerDown={down(k)}
          onPointerUp={up(k)}
          onPointerLeave={cancel}
          onPointerCancel={cancel}
          onContextMenu={(e) => e.preventDefault()}
          className="group relative flex h-[63px] items-center justify-center overflow-hidden rounded-key bg-raised text-key font-medium text-ink"
        >
          <span className="pointer-events-none absolute inset-0 bg-white/[0.12] opacity-0 transition-opacity duration-200 group-active:opacity-100 group-active:duration-0" />
          {k === 'back' ? <BackArrow size={28} /> : k === '.' ? <span className="-mt-3 text-[34px]">.</span> : k}
        </button>
      ))}
    </div>
  )
}
