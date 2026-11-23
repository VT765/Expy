import { useMemo, useState } from 'react'
import BottomSheet from '../BottomSheet'
import AmountSheet from './AmountSheet'
import { CURRENCIES, currencySymbol } from '../../lib/currencies'
import { ensureRates } from '../../lib/rates'
import { useDataStore, rateFor } from '../../store/useDataStore'
import { useUIStore } from '../../store/useUIStore'

const ago = (ts) => {
  if (!ts) return 'never'
  const m = Math.round((Date.now() - ts) / 60000)
  if (m < 1) return 'just now'
  if (m < 60) return `${m} min ago`
  const h = Math.round(m / 60)
  return h < 48 ? `${h} h ago` : `${Math.round(h / 24)} days ago`
}

// Live rates from frankfurter.app with per-currency manual overrides.
export default function ExchangeRatesSheet({ open, onClose }) {
  const state = useDataStore()
  const { settings, rates, updateSettings, rebaseTransactions } = state
  const [editing, setEditing] = useState(null)
  const [refreshing, setRefreshing] = useState(false)
  const base = settings.baseCurrency
  const list = useMemo(() => CURRENCIES.filter((c) => c.code !== base), [base])

  const refresh = async () => {
    setRefreshing(true)
    try {
      await ensureRates({ force: true })
      useUIStore.getState().showToast('Rates updated')
    } catch {
      useUIStore.getState().showError('Could not fetch rates')
    } finally {
      setRefreshing(false)
    }
  }

  const setOverride = (code, value) => {
    const next = { ...settings.rateOverrides }
    if (value > 0) next[code] = value
    else delete next[code]
    updateSettings({ rateOverrides: next })
    rebaseTransactions()
  }

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title="Exchange rates"
      tall
      headerAction={
        <button type="button" onClick={refresh} disabled={refreshing} className="text-body text-sub active:opacity-50 disabled:opacity-40">
          {refreshing ? 'Updating…' : 'Refresh'}
        </button>
      }
    >
      <p className="mb-4 text-center text-footnote text-sub">
        From frankfurter.app · updated {ago(rates.base === base ? rates.fetchedAt : 0)}. Tap a rate to override it.
      </p>
      <div className="overflow-hidden rounded-card bg-raised">
        {list.map((c) => {
          const rate = rateFor(state, c.code)
          const overridden = settings.rateOverrides?.[c.code]
          return (
            <button key={c.code} type="button" onClick={() => setEditing(c)} className="group relative flex w-full items-center pl-4 text-left">
              <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 group-active:opacity-100" />
              <span className="flex min-h-[52px] flex-1 items-center border-b-[0.5px] border-well pr-4 group-last:border-b-0">
                <span className="flex-1 text-body">
                  1 {c.code} <span className="text-sub">· {c.name}</span>
                </span>
                <span className="text-body tabular-nums text-sub">
                  {rate ? `${currencySymbol(base)}${rate < 0.1 ? rate.toFixed(4) : rate.toFixed(2)}` : '—'}
                  {overridden && <span className="ml-1.5 rounded bg-well px-1.5 py-0.5 text-caption text-ink">manual</span>}
                </span>
              </span>
            </button>
          )
        })}
      </div>
      <AmountSheet
        open={editing != null}
        title={editing ? `1 ${editing.code} in ${base}` : ''}
        hint="Manual rates override the live rate for new and existing entries."
        currency={base}
        value={editing ? settings.rateOverrides?.[editing.code] : 0}
        removeLabel="Use live"
        onSave={(v) => setOverride(editing.code, v)}
        onClose={() => setEditing(null)}
      />
    </BottomSheet>
  )
}
