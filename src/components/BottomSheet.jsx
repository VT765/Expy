import { useEffect } from 'react'
import { createPortal } from 'react-dom'
import { AnimatePresence, motion, useDragControls } from 'framer-motion'
import { spring } from '../lib/motion'

const DISMISS_OFFSET = 120
const DISMISS_VELOCITY = 600

// Modal sheet that slides up from the bottom. Drag the grabber/header down to
// dismiss; the body scrolls independently so dragging never fights scrolling.
// Portaled to <body> so transformed ancestors (tab transitions) can't trap it.
export default function BottomSheet({ open, onClose, title, headerAction, footer, tall = false, children }) {
  const controls = useDragControls()

  useEffect(() => {
    if (!open) return
    const onKey = (e) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  return createPortal(
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-40">
          <motion.div
            className="absolute inset-0 bg-black/70"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.25 }}
            onClick={onClose}
          />
          <motion.div
            role="dialog"
            aria-modal="true"
            aria-label={title}
            className="gpu absolute inset-x-0 bottom-0 flex flex-col rounded-t-sheet bg-card"
            style={{ maxHeight: 'calc(100% - env(safe-area-inset-top) - 12px)', height: tall ? 'calc(100% - env(safe-area-inset-top) - 12px)' : undefined }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={spring}
            drag="y"
            dragListener={false}
            dragControls={controls}
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0.04, bottom: 0.9 }}
            onDragEnd={(_, info) => {
              if (info.offset.y > DISMISS_OFFSET || info.velocity.y > DISMISS_VELOCITY) onClose()
            }}
          >
            <div className="shrink-0 touch-none pb-3 pt-2.5" onPointerDown={(e) => controls.start(e)}>
              <div className="mx-auto h-[5px] w-9 rounded-full bg-well" />
              {(title || headerAction) && (
                <div className="relative mt-3 flex min-h-[28px] items-center justify-center px-gutter">
                  {title && <h2 className="text-headline font-bold">{title}</h2>}
                  {headerAction && <div className="absolute right-gutter">{headerAction}</div>}
                </div>
              )}
            </div>
            <div className="scroll-area min-h-0 flex-1 px-gutter pb-5">{children}</div>
            {footer && <div className="shrink-0 px-gutter pb-[calc(env(safe-area-inset-bottom)+12px)] pt-2">{footer}</div>}
            {!footer && <div className="shrink-0 pb-safe-b" />}
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  )
}
