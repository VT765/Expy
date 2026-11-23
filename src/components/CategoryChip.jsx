import { forwardRef } from 'react'
import { motion } from 'framer-motion'
import { tint } from '../lib/colors'

// Emoji + name pill. Selected: tinted fill, 2px accent border, accent label.
const CategoryChip = forwardRef(function CategoryChip({ category, selected, onClick }, ref) {
  const color = category.color ?? '#9DB0C4'
  return (
    <motion.button
      ref={ref}
      type="button"
      onClick={onClick}
      whileTap={{ scale: 0.95 }}
      transition={{ duration: 0.12 }}
      aria-pressed={selected}
      className="relative flex h-[43px] shrink-0 items-center gap-2 rounded-chip bg-raised pl-4 pr-[18px] text-body font-semibold"
      style={selected ? { background: tint(color, 0.14), color, boxShadow: `inset 0 0 0 2px ${color}` } : { color: '#58585C' }}
    >
      <span className="text-[18px] leading-none">{category.emoji}</span>
      <span className="whitespace-nowrap">{category.name}</span>
    </motion.button>
  )
})

export default CategoryChip
