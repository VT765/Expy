import { useDataStore } from '../store/useDataStore'

const MAX_AGE = 12 * 3600 * 1000
let inflight = null

// Fetches latest rates for the base currency from Frankfurter (frankfurter.app
// now redirects to api.frankfurter.dev without CORS headers) and caches
// them as "units of base per 1 unit of X". Manual overrides in settings win.
export function ensureRates({ force = false } = {}) {
  const { settings, rates, setRates } = useDataStore.getState()
  const base = settings.baseCurrency
  const fresh = rates.base === base && Date.now() - rates.fetchedAt < MAX_AGE
  if ((fresh && !force) || !navigator.onLine) return Promise.resolve(rates)
  if (inflight) return inflight

  inflight = fetch(`https://api.frankfurter.dev/v1/latest?base=${base}`)
    .then((r) => {
      if (!r.ok) throw new Error(`Rates request failed (${r.status})`)
      return r.json()
    })
    .then((data) => {
      const perUnit = {}
      for (const [code, rate] of Object.entries(data.rates || {})) if (rate > 0) perUnit[code] = 1 / rate
      const next = { base, perUnit, fetchedAt: Date.now() }
      setRates(next)
      return next
    })
    .finally(() => {
      inflight = null
    })
  return inflight
}
