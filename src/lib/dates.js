import { formatDayLong } from './format'

export const DAY = 86400000

export const startOfDay = (ts) => {
  const d = new Date(ts)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}
export const addDays = (ts, n) => {
  const d = new Date(ts)
  d.setDate(d.getDate() + n)
  return d.getTime()
}
export const addMonths = (ts, n) => {
  const d = new Date(ts)
  d.setMonth(d.getMonth() + n)
  return d.getTime()
}

// Monday-start week.
export const startOfWeek = (ts) => {
  const d = new Date(startOfDay(ts))
  const diff = (d.getDay() + 6) % 7
  return addDays(d.getTime(), -diff)
}

// Budget cycle month: starts on `cycleDay` (1–28) and runs until the same day next month.
export const startOfCycle = (ts, cycleDay = 1) => {
  const d = new Date(startOfDay(ts))
  if (d.getDate() < cycleDay) d.setMonth(d.getMonth() - 1)
  d.setDate(cycleDay)
  return d.getTime()
}

export const startOfYear = (ts) => new Date(new Date(ts).getFullYear(), 0, 1).getTime()

export const daysBetween = (start, end) => Math.max(1, Math.round((startOfDay(end) - startOfDay(start)) / DAY))

export function dayHeader(ts) {
  const today = startOfDay(Date.now())
  const day = startOfDay(ts)
  if (day === today) return 'Today'
  if (day === addDays(today, -1)) return 'Yesterday'
  return formatDayLong(ts)
}

// <input type="date"> helpers (local time).
export const toDateInput = (ts) => {
  const d = new Date(ts)
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}
export const toDateTimeInput = (ts) => {
  const d = new Date(ts)
  const p = (n) => String(n).padStart(2, '0')
  return `${toDateInput(ts)}T${p(d.getHours())}:${p(d.getMinutes())}`
}
export const fromDateInput = (value) => {
  const [y, m, d] = value.split('-').map(Number)
  return new Date(y, m - 1, d).getTime()
}

// Keeps the time of `timeSource` while moving to the calendar day of `dayTs`.
export const withTimeOf = (dayTs, timeSource = Date.now()) => {
  const t = new Date(timeSource)
  const d = new Date(dayTs)
  d.setHours(t.getHours(), t.getMinutes(), t.getSeconds(), 0)
  return d.getTime()
}
