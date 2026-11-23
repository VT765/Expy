import { useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import PinPad from './PinPad'
import { XIcon } from './Icons'
import { useLockStore } from '../store/useLockStore'
import { useUIStore } from '../store/useUIStore'
import { spring } from '../lib/motion'

// Full-screen PIN flow: [verify current] → new → confirm.
// mode: 'create' | 'change' | 'verify' (verify just checks, e.g. before disabling).
export default function PinSetupSheet({ open, mode = 'create', onDone, onClose }) {
  const [step, setStep] = useState('new')
  const [first, setFirst] = useState('')
  const [error, setError] = useState(' ')

  useEffect(() => {
    if (!open) return
    setStep(mode === 'create' ? 'new' : 'current')
    setFirst('')
    setError(' ')
  }, [open, mode])

  const titles = {
    current: mode === 'verify' ? 'Enter your PIN' : 'Enter current PIN',
    new: 'Create a 4-digit PIN',
    confirm: 'Enter it again',
  }

  const handle = async (pin) => {
    const lock = useLockStore.getState()
    if (step === 'current') {
      if (!(await lock.checkPin(pin))) {
        setError('Wrong PIN')
        return false
      }
      if (mode === 'verify') {
        onDone?.()
        onClose()
        return true
      }
      setError(' ')
      setStep('new')
      return true
    }
    if (step === 'new') {
      setFirst(pin)
      setError(' ')
      setStep('confirm')
      return true
    }
    if (pin !== first) {
      setError("PINs didn't match. Try again.")
      setStep('new')
      return false
    }
    await lock.setPin(pin)
    useUIStore.getState().showToast(mode === 'change' ? 'PIN changed' : 'App Lock is on')
    onDone?.()
    onClose()
    return true
  }

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          className="gpu fixed inset-0 z-[55] flex flex-col bg-canvas pb-safe-b pt-safe-t"
          initial={{ y: '100%' }}
          animate={{ y: 0 }}
          exit={{ y: '100%' }}
          transition={spring}
        >
          <div className="flex h-14 items-center px-3">
            <button type="button" onClick={onClose} aria-label="Cancel" className="flex h-11 w-11 items-center justify-center active:opacity-50">
              <XIcon size={24} />
            </button>
          </div>
          <div className="flex flex-1 items-center justify-center pb-16">
            <PinPad key={step} title={titles[step]} subtitle={error} onComplete={handle} />
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
