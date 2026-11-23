import { useState } from 'react'
import { Row, Section } from '../SettingsRow'
import BottomSheet from '../BottomSheet'
import Button from '../Button'
import { useSyncStore } from '../../store/useSyncStore'
import { useUIStore } from '../../store/useUIStore'
import { api } from '../../lib/api'
import { signOut } from '../../lib/session'

const inputCls = 'h-12 w-full rounded-[14px] bg-raised px-4 text-body text-ink outline-none placeholder:text-faint'

export default function AccountSection() {
  const token = useSyncStore((s) => s.token)
  const [pwOpen, setPwOpen] = useState(false)

  if (!token) {
    return (
      <Section title="Account">
        <Row
          title="Sign in to sync"
          subtitle="Back up to your server and use Shortcuts"
          onClick={() => useSyncStore.setState({ offlineMode: false })}
        />
      </Section>
    )
  }

  return (
    <Section title="Account">
      <Row title="Change password" onClick={() => setPwOpen(true)} />
      <Row
        title="Sign out"
        subtitle="Removes data from this device after syncing"
        destructive
        chevron={false}
        onClick={async () => {
          const ok = await useUIStore.getState().confirm({
            title: 'Sign out?',
            message: 'Pending changes sync first, then this device is cleared. Sign in again to get your data back.',
            confirmLabel: 'Sign out',
            destructive: true,
          })
          if (ok) signOut()
        }}
      />
      <ChangePasswordSheet open={pwOpen} onClose={() => setPwOpen(false)} />
    </Section>
  )
}

function ChangePasswordSheet({ open, onClose }) {
  const [form, setForm] = useState({ current: '', next: '', confirm: '' })
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value.replace(/\D/g, '') }))

  const save = async () => {
    setError('')
    if (form.next !== form.confirm) return setError("New passwords don't match")
    setBusy(true)
    try {
      const { token } = await api('auth/password', { method: 'POST', body: { current: form.current, next: form.next } })
      useSyncStore.setState({ token })
      useUIStore.getState().showToast('Password changed · other devices signed out')
      setForm({ current: '', next: '', confirm: '' })
      onClose()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title="Change password"
      footer={
        <Button block loading={busy} disabled={!form.current || form.next.length < 8} onClick={save}>
          Update password
        </Button>
      }
    >
      <div className="space-y-3 pt-1">
        <input type="password" autoComplete="current-password" placeholder="Current password" inputMode="numeric" pattern="[0-9]*" value={form.current} onChange={set('current')} className={inputCls} />
        <input type="password" autoComplete="new-password" placeholder="New password (8+ digits)" inputMode="numeric" pattern="[0-9]*" value={form.next} onChange={set('next')} className={inputCls} />
        <input type="password" autoComplete="new-password" placeholder="Confirm new password" inputMode="numeric" pattern="[0-9]*" value={form.confirm} onChange={set('confirm')} className={inputCls} />
        <p className="min-h-5 px-1 text-footnote text-danger">{error}</p>
      </div>
    </BottomSheet>
  )
}
