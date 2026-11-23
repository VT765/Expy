import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import Button from '../components/Button'
import { api } from '../lib/api'
import { useSyncStore } from '../store/useSyncStore'
import { useUIStore } from '../store/useUIStore'

const inputCls = 'h-14 w-full rounded-[16px] bg-raised px-4 text-body text-ink outline-none placeholder:text-faint'

// Sign in (or first-time setup) in the app's design language.
export default function LoginScreen() {
  const [status, setStatus] = useState('loading') // loading | setup | login | unreachable
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [setupKey, setSetupKey] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const check = () => {
    setStatus('loading')
    api('auth/status', { auth: false })
      .then((r) => setStatus(r.configured ? 'login' : 'setup'))
      .catch(() => setStatus('unreachable'))
  }
  useEffect(check, [])

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    if (status === 'setup' && password !== confirm) return setError("Passwords don't match")
    setBusy(true)
    try {
      const { token } =
        status === 'setup'
          ? await api('auth/setup', { method: 'POST', auth: false, body: { password, setupKey } })
          : await api('auth/login', { method: 'POST', auth: false, body: { password } })
      useSyncStore.getState().login(token)
      useUIStore.getState().showToast(status === 'setup' ? 'Account created' : 'Signed in')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <motion.div
      className="fixed inset-0 z-[75] flex flex-col bg-canvas px-gutter pb-safe-b pt-safe-t"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <form onSubmit={submit} className="mx-auto flex w-full max-w-sm flex-1 flex-col justify-center">
        <img src="/icons/icon-192.png" alt="" className="mx-auto h-16 w-16 rounded-[18px]" />
        <h1 className="mt-6 text-center text-large font-bold tracking-tight">
          {status === 'setup' ? 'Set up Expy' : 'Welcome back'}
        </h1>
        <p className="mt-1.5 text-center text-body text-sub">
          {status === 'setup'
            ? 'Create a password to sync your expenses.'
            : status === 'unreachable'
              ? "Can't reach the server right now."
              : 'Sign in to sync your expenses.'}
        </p>

        {status === 'loading' && <div className="mx-auto mt-10 h-14 w-full animate-pulse rounded-[16px] bg-raised" />}

        {(status === 'login' || status === 'setup') && (
          <div className="mt-10 space-y-3">
            <input
              type="password"
              autoComplete={status === 'setup' ? 'new-password' : 'current-password'}
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={inputCls}
              autoFocus
            />
            {status === 'setup' && (
              <>
                <input type="password" autoComplete="new-password" placeholder="Confirm password" value={confirm} onChange={(e) => setConfirm(e.target.value)} className={inputCls} />
                <input
                  type="password"
                  autoComplete="off"
                  placeholder="Setup key (API_KEY from Vercel)"
                  value={setupKey}
                  onChange={(e) => setSetupKey(e.target.value)}
                  className={inputCls}
                />
              </>
            )}
            <p className="min-h-5 px-1 text-footnote text-danger" role="alert">
              {error}
            </p>
            <Button type="submit" block loading={busy} disabled={!password || (status === 'setup' && (!confirm || !setupKey))}>
              {status === 'setup' ? 'Create account' : 'Sign in'}
            </Button>
          </div>
        )}

        {status === 'unreachable' && (
          <Button variant="secondary" block className="mt-10" onClick={check}>
            Try again
          </Button>
        )}
      </form>

      <button type="button" onClick={() => useSyncStore.getState().useOffline()} className="mb-6 text-footnote text-sub active:opacity-50">
        Use without sync on this device
      </button>
    </motion.div>
  )
}
