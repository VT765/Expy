import { AnimatePresence, motion } from 'framer-motion'
import { useUIStore } from '../store/useUIStore'
import { spring } from '../lib/motion'
import { cn } from '../lib/cn'

// Single global toast, dropped in from under the status bar. Swipe up or tap
// to dismiss; an optional action button (e.g. Undo) sits on the right.
export default function Toast() {
  const toast = useUIStore((s) => s.toast)
  const hide = useUIStore((s) => s.hideToast)

  return (
    <div className="pointer-events-none fixed inset-x-0 top-0 z-[70] flex justify-center px-gutter pt-safe-t">
      <AnimatePresence>
        {toast && (
          <motion.div
            key={toast.id}
            role={toast.tone === 'error' ? 'alert' : 'status'}
            onClick={toast.action ? undefined : hide}
            className={cn(
              'gpu pointer-events-auto mt-2 flex max-w-full items-center gap-2 rounded-chip py-2.5 pl-4 text-footnote font-semibold shadow-[0_8px_30px_rgba(0,0,0,0.6)]',
              toast.action ? 'pr-1.5' : 'pr-4',
              toast.tone === 'error' ? 'bg-danger text-ink' : 'bg-ink text-canvas',
            )}
            initial={{ y: -72, opacity: 0, scale: 0.96 }}
            animate={{ y: 0, opacity: 1, scale: 1 }}
            exit={{ y: -72, opacity: 0, scale: 0.96 }}
            transition={spring}
            drag="y"
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0.8, bottom: 0.1 }}
            onDragEnd={(_, info) => info.offset.y < -20 && hide()}
          >
            {toast.icon}
            <span className="truncate">{toast.message}</span>
            {toast.action && (
              <button
                type="button"
                onClick={() => {
                  toast.action.onClick()
                  hide()
                }}
                className="ml-1 shrink-0 rounded-chip bg-canvas px-3.5 py-1 text-ink active:opacity-70"
              >
                {toast.action.label}
              </button>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
