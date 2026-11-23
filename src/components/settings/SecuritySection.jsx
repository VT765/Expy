import { useEffect, useState } from 'react'
import { Row, Section } from '../SettingsRow'
import Toggle from '../Toggle'
import PinSetupSheet from '../PinSetupSheet'
import OptionSheet from './OptionSheet'
import { useLockStore } from '../../store/useLockStore'
import { useUIStore } from '../../store/useUIStore'
import { isFaceIdAvailable, registerFaceId } from '../../lib/webauthn'

const AUTO_LOCK_OPTIONS = [
  { value: 'immediate', label: 'Immediately' },
  { value: '1m', label: 'After 1 minute' },
  { value: '5m', label: 'After 5 minutes' },
]

export default function SecuritySection() {
  const enabled = useLockStore((s) => s.enabled)
  const faceId = useLockStore((s) => s.faceIdCredential)
  const autoLock = useLockStore((s) => s.autoLock)
  const [pinFlow, setPinFlow] = useState(null) // { mode, onDone }
  const [autoOpen, setAutoOpen] = useState(false)
  const [faceSupported, setFaceSupported] = useState(false)

  useEffect(() => {
    isFaceIdAvailable().then(setFaceSupported)
  }, [])

  const toggleLock = (on) => {
    if (on) setPinFlow({ mode: 'create' })
    else setPinFlow({ mode: 'verify', onDone: () => useLockStore.getState().disable() })
  }

  const toggleFaceId = async (on) => {
    const { setFaceId } = useLockStore.getState()
    if (!on) return setFaceId(null)
    try {
      setFaceId(await registerFaceId())
      useUIStore.getState().showToast('Face ID enabled')
    } catch (err) {
      if (err?.name !== 'NotAllowedError') useUIStore.getState().showError('Could not set up Face ID')
    }
  }

  return (
    <Section title="Security">
      <Row title="App Lock" subtitle="Require a PIN to open Expy" chevron={false} trailing={<Toggle checked={enabled} onChange={toggleLock} label="App Lock" />} />
      {enabled && (
        <>
          <Row title="Change PIN" onClick={() => setPinFlow({ mode: 'change' })} />
          {faceSupported && (
            <Row title="Face ID" subtitle="Unlock with Face ID, PIN as fallback" chevron={false} trailing={<Toggle checked={Boolean(faceId)} onChange={toggleFaceId} label="Face ID" />} />
          )}
          <Row title="Auto-lock" value={AUTO_LOCK_OPTIONS.find((o) => o.value === autoLock)?.label} onClick={() => setAutoOpen(true)} />
        </>
      )}
      <PinSetupSheet open={pinFlow != null} mode={pinFlow?.mode} onDone={pinFlow?.onDone} onClose={() => setPinFlow(null)} />
      <OptionSheet
        open={autoOpen}
        title="Auto-lock"
        options={AUTO_LOCK_OPTIONS}
        value={autoLock}
        onSelect={(v) => useLockStore.getState().setAutoLock(v)}
        onClose={() => setAutoOpen(false)}
      />
    </Section>
  )
}
