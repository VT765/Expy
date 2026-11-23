import { motion } from 'framer-motion'
import { cn } from '../lib/cn'

const variants = {
  primary: 'bg-ink text-canvas',
  secondary: 'bg-raised text-ink',
  ghost: 'bg-transparent text-ink',
  destructive: 'bg-raised text-danger',
}

const sizes = {
  lg: 'h-14 px-6 text-[18px] font-bold rounded-btn',
  md: 'h-12 px-5 text-body font-semibold rounded-[16px]',
  sm: 'h-9 px-4 text-footnote font-semibold rounded-chip',
}

export default function Button({
  variant = 'primary',
  size = 'lg',
  block = false,
  disabled = false,
  loading = false,
  className,
  children,
  ...rest
}) {
  const inactive = disabled || loading
  return (
    <motion.button
      type="button"
      whileTap={inactive ? undefined : { scale: 0.97 }}
      transition={{ duration: 0.12 }}
      disabled={inactive}
      className={cn(
        'relative inline-flex select-none items-center justify-center gap-2 outline-none',
        disabled ? 'bg-well text-faint' : variants[variant],
        sizes[size],
        block && 'w-full',
        className,
      )}
      {...rest}
    >
      <span className={cn('inline-flex items-center gap-2 transition-opacity', loading && 'opacity-0')}>{children}</span>
      {loading && <Spinner className="absolute" />}
    </motion.button>
  )
}

export function Spinner({ className, size = 20 }) {
  return (
    <svg className={cn('animate-spin', className)} width={size} height={size} viewBox="0 0 24 24" aria-label="Loading">
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeOpacity="0.25" strokeWidth="3" />
      <path d="M21 12a9 9 0 0 0-9-9" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
  )
}
