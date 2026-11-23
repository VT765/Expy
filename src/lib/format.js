import { currencySymbol } from './currencies'

const nf0 = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 })
const nf2 = new Intl.NumberFormat('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

// 1829 → "1,829", 8687.17 → "8,687.17", 1234567 → "12,34,567"
export function formatNumber(value) {
  const n = Math.abs(Number(value) || 0)
  const rounded = Math.round(n * 100) / 100
  return Number.isInteger(rounded) ? nf0.format(rounded) : nf2.format(rounded)
}

// Signed money string; negative values get a leading minus: "-₹703".
export function formatMoney(value, currency = 'INR') {
  const n = Number(value) || 0
  const sign = n < 0 && Math.abs(n) >= 0.005 ? '-' : ''
  return `${sign}${currencySymbol(currency)}${formatNumber(n)}`
}

// Compact axis labels: 1.2K, 3.4L, 1.1Cr.
export function formatCompact(value) {
  const n = Math.abs(value)
  if (n >= 1e7) return `${+(n / 1e7).toFixed(1)}Cr`
  if (n >= 1e5) return `${+(n / 1e5).toFixed(1)}L`
  if (n >= 1e3) return `${+(n / 1e3).toFixed(1)}K`
  return `${Math.round(n)}`
}

const timeFmt = new Intl.DateTimeFormat('en-IN', { hour: 'numeric', minute: '2-digit', hour12: true })
export const formatTime = (ts) => timeFmt.format(ts).toUpperCase()

const dayFmt = new Intl.DateTimeFormat('en-US', { weekday: 'long', month: 'short', day: 'numeric' })
const dayYearFmt = new Intl.DateTimeFormat('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' })
export const formatDayLong = (ts) =>
  (new Date(ts).getFullYear() === new Date().getFullYear() ? dayFmt : dayYearFmt).format(ts)

const shortFmt = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' })
export const formatShortDate = (ts) => shortFmt.format(ts)

export const ordinal = (n) => {
  const s = ['th', 'st', 'nd', 'rd']
  const v = n % 100
  return n + (s[(v - 20) % 10] || s[v] || s[0])
}
