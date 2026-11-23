import { memo, useRef } from 'react'
import { animate, motion, useMotionValue, useTransform } from 'framer-motion'
import EmojiCircle from './EmojiCircle'
import { formatMoney, formatTime } from '../lib/format'

const DELETE_AT = -110

// History row. Tap → edit; swipe left past the threshold → delete.
function TransactionRow({ tx, category, baseCurrency, onOpen, onDelete }) {
  const x = useMotionValue(0)
  const revealOpacity = useTransform(x, [-110, -24, 0], [1, 0.4, 0])
  const dragged = useRef(false)
  const signed = tx.type === 'credit' ? -tx.amountInBase : tx.amountInBase
  const foreign = tx.currency !== baseCurrency

  return (
    <div className="relative h-full overflow-hidden">
      <motion.div
        className="absolute inset-y-[6px] right-0 flex w-full items-center justify-end rounded-card bg-danger pr-6 text-body font-semibold"
        style={{ opacity: revealOpacity }}
        aria-hidden="true"
      >
        Delete
      </motion.div>
      <motion.div
        className="gpu relative flex h-full items-center gap-[14px] bg-canvas px-3"
        style={{ x }}
        drag="x"
        dragDirectionLock
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={{ left: 0.7, right: 0 }}
        onDragStart={() => (dragged.current = true)}
        onDragEnd={(_, info) => {
          if (info.offset.x < DELETE_AT || info.velocity.x < -800) {
            animate(x, -480, { duration: 0.2 }).then(() => onDelete(tx))
          } else {
            animate(x, 0, { type: 'spring', stiffness: 500, damping: 40 })
          }
          setTimeout(() => (dragged.current = false), 50)
        }}
        onTap={() => !dragged.current && onOpen(tx)}
      >
        <EmojiCircle emoji={category.emoji} color={category.color} />
        <div className="min-w-0 flex-1">
          <p className="truncate text-headline font-bold">{category.name}</p>
          <p className="truncate text-body text-sub">{tx.note || ' '}</p>
        </div>
        <div className="shrink-0 text-right">
          <p className="text-headline font-bold tabular-nums">{formatMoney(signed, baseCurrency)}</p>
          <p className="text-footnote tabular-nums text-sub">
            {foreign ? `${formatMoney(tx.amount, tx.currency)} · ` : ''}
            {formatTime(tx.date)}
          </p>
        </div>
      </motion.div>
    </div>
  )
}

export default memo(TransactionRow)
