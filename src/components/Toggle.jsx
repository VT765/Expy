import { motion } from 'framer-motion'
import { cn } from '../lib/cn'

// iOS switch. The knob moves via transform; the "on" fill fades via opacity.
export default function Toggle({ checked, onChange, disabled, label }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={(e) => {
        e.stopPropagation()
        onChange(!checked)
      }}
      className={cn('relative h-[31px] w-[51px] shrink-0 overflow-hidden rounded-chip bg-well', disabled && 'opacity-40')}
    >
      <span
        className={cn('absolute inset-0 rounded-chip bg-ink transition-opacity duration-200', checked ? 'opacity-100' : 'opacity-0')}
      />
      <motion.span
        className={cn('absolute left-[2px] top-[2px] h-[27px] w-[27px] rounded-full shadow-md', checked ? 'bg-canvas' : 'bg-ink')}
        animate={{ x: checked ? 20 : 0 }}
        transition={{ type: 'spring', stiffness: 600, damping: 38 }}
      />
    </button>
  )
}
