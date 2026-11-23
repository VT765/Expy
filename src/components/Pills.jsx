import { motion } from 'framer-motion'
import { cn } from '../lib/cn'

// Row of range pills (History "Today / This Week…", Analytics periods).
// variant "solid": white selected pill, grey unselected; "quiet": only the
// selected pill gets a background (Tap screen date pills).
export default function Pills({ options, value, onChange, variant = 'solid', className }) {
  return (
    <div className={cn('flex', variant === 'solid' ? 'gap-2' : 'gap-2.5', className)} role="tablist">
      {options.map((o) => {
        const active = o.value === value
        return (
          <motion.button
            key={o.value}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(o.value)}
            whileTap={{ scale: 0.95 }}
            transition={{ duration: 0.12 }}
            className={cn(
              'shrink-0 rounded-chip font-semibold',
              variant === 'solid'
                ? cn('h-[43px] px-[14px] text-body', active ? 'bg-ink text-canvas' : 'bg-raised text-faint')
                : cn('h-[32px] px-[14px] text-body', active ? 'bg-raised text-ink' : 'text-faint'),
            )}
          >
            {o.label}
          </motion.button>
        )
      })}
    </div>
  )
}
