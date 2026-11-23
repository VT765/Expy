import { addDays, addMonths, fromDateInput, startOfCycle, startOfDay, startOfWeek, startOfYear } from './dates'
import { formatShortDate } from './format'

const monthFmt = new Intl.DateTimeFormat('en-US', { month: 'long', year: 'numeric' })

// Returns { start, end } (end exclusive) and a label for a period.
// kind: today | week | month | year | all | custom; offset: 0 = current, -1 = previous…
// "month" follows the budget cycle start day.
export function periodRange({ kind, offset = 0, from, to }, cycleDay = 1, now = Date.now()) {
  switch (kind) {
    case 'today': {
      const start = addDays(startOfDay(now), offset)
      return { start, end: addDays(start, 1), label: formatShortDate(start) }
    }
    case 'week': {
      const start = addDays(startOfWeek(now), offset * 7)
      const end = addDays(start, 7)
      const label = offset === 0 ? 'This week' : `${formatShortDate(start)} – ${formatShortDate(addDays(end, -1))}`
      return { start, end, label }
    }
    case 'month': {
      const start = addMonths(startOfCycle(now, cycleDay), offset)
      const end = addMonths(start, 1)
      const label =
        cycleDay === 1 ? monthFmt.format(start) : `${formatShortDate(start)} – ${formatShortDate(addDays(end, -1))}`
      return { start, end, label }
    }
    case 'year': {
      const start = new Date(new Date(startOfYear(now)).getFullYear() + offset, 0, 1).getTime()
      return { start, end: new Date(new Date(start).getFullYear() + 1, 0, 1).getTime(), label: String(new Date(start).getFullYear()) }
    }
    case 'custom': {
      const start = from ? fromDateInput(from) : startOfDay(addDays(now, -29))
      const end = to ? addDays(fromDateInput(to), 1) : addDays(startOfDay(now), 1)
      return { start, end: Math.max(end, start + 1), label: `${formatShortDate(start)} – ${formatShortDate(addDays(end, -1))}` }
    }
    default:
      return { start: 0, end: Infinity, label: 'All time' }
  }
}

// The period immediately before `range` with the same length (for % change).
export function previousRange(period, cycleDay) {
  if (period.kind === 'custom') {
    const { start, end } = periodRange(period, cycleDay)
    return { start: start - (end - start), end: start }
  }
  return periodRange({ ...period, offset: (period.offset ?? 0) - 1 }, cycleDay)
}

export const inRange = (tx, { start, end }) => tx.date >= start && tx.date < end
