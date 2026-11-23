import { AnimatePresence, motion } from 'framer-motion'
import { useUIStore } from '../store/useUIStore'
import { spring } from '../lib/motion'
import { cn } from '../lib/cn'

// iOS-style alert driven by useUIStore().confirm(); resolves true/false.
export default function ConfirmDialog() {
  const dialog = useUIStore((s) => s.dialog)
  const resolve = useUIStore((s) => s.resolveDialog)

  return (
    <AnimatePresence>
      {dialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center px-10">
          <motion.div
            className="absolute inset-0 bg-black/70"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={() => resolve(false)}
          />
          <motion.div
            role="alertdialog"
            aria-modal="true"
            className="gpu relative w-full max-w-[300px] overflow-hidden rounded-card bg-raised text-center"
            initial={{ opacity: 0, scale: 1.08 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.96 }}
            transition={spring}
          >
            <div className="px-5 pb-4 pt-5">
              <h2 className="text-headline font-semibold">{dialog.title}</h2>
              {dialog.message && <p className="mt-1.5 text-footnote text-sub">{dialog.message}</p>}
            </div>
            <div className="grid grid-cols-2 border-t-[0.5px] border-well">
              <button type="button" onClick={() => resolve(false)} className="h-12 text-body text-sub active:bg-white/5">
                {dialog.cancelLabel ?? 'Cancel'}
              </button>
              <button
                type="button"
                onClick={() => resolve(true)}
                className={cn(
                  'h-12 border-l-[0.5px] border-well text-body font-semibold active:bg-white/5',
                  dialog.destructive ? 'text-danger' : 'text-ink',
                )}
              >
                {dialog.confirmLabel ?? 'OK'}
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}
