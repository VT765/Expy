import { addDays, addMonths, startOfDay, daysBetween } from './dates'
import { inRange } from './periods'

const dayLabel = new Intl.DateTimeFormat('en-US', { weekday: 'narrow' })
const monthLabel = new Intl.DateTimeFormat('en-US', { month: 'narrow' })
const monthLong = new Intl.DateTimeFormat('en-US', { month: 'short', year: 'numeric' })
const dayLong = new Intl.DateTimeFormat('en-US', { weekday: 'short', month: 'short', day: 'numeric' })

// Splits a range into chart buckets: days (≤ 45 days), weeks (≤ 180), else months.
export function bucketsFor({ start, end }, kind) {
  const days = daysBetween(start, end)
  const out = []
  if (kind === 'year' || days > 180) {
    for (let t = start; t < end; t = addMonths(t, 1))
      out.push({ start: t, end: Math.min(addMonths(t, 1), end), short: monthLabel.format(t), long: monthLong.format(t) })
  } else if (days > 45) {
    for (let t = start; t < end; t = addDays(t, 7))
      out.push({ start: t, end: Math.min(addDays(t, 7), end), short: '', long: `Week of ${dayLong.format(t)}` })
  } else {
    for (let t = start; t < end; t = addDays(t, 1))
      out.push({
        start: t,
        end: addDays(t, 1),
        short: kind === 'week' ? dayLabel.format(t) : String(new Date(t).getDate()),
        long: dayLong.format(t),
      })
  }
  return out
}

export function computeStats(transactions, range, kind, now = Date.now()) {
  const list = transactions.filter((t) => !t.deletedAt && inRange(t, range))
  let spent = 0
  let credit = 0
  const byCat = new Map()
  for (const t of list) {
    if (t.type === 'credit') credit += t.amountInBase
    else {
      spent += t.amountInBase
      byCat.set(t.categoryId, (byCat.get(t.categoryId) ?? 0) + t.amountInBase)
    }
  }

  // Average over days elapsed so far for the current period, else the full length.
  const effectiveEnd = Math.min(range.end, addDays(startOfDay(now), 1))
  const days = Number.isFinite(range.end) ? daysBetween(range.start, Math.max(effectiveEnd, range.start + 1)) : 1

  const buckets = Number.isFinite(range.end) ? bucketsFor(range, kind) : []
  const bucketTotals = buckets.map(() => 0)
  if (buckets.length) {
    for (const t of list) {
      if (t.type === 'credit') continue
      // Buckets are contiguous and sorted; binary search the bucket.
      let lo = 0
      let hi = buckets.length - 1
      while (lo < hi) {
        const mid = (lo + hi + 1) >> 1
        if (buckets[mid].start <= t.date) lo = mid
        else hi = mid - 1
      }
      bucketTotals[lo] += t.amountInBase
    }
  }

  const categories = [...byCat.entries()]
    .map(([categoryId, total]) => ({ categoryId, total, pct: spent ? total / spent : 0 }))
    .sort((a, b) => b.total - a.total)

  const top = list
    .filter((t) => t.type === 'expense')
    .sort((a, b) => b.amountInBase - a.amountInBase)
    .slice(0, 5)

  return {
    count: list.length,
    spent,
    credit,
    net: spent - credit,
    days,
    avgPerDay: spent / days,
    categories,
    buckets: buckets.map((b, i) => ({ ...b, total: bucketTotals[i] })),
    top,
  }
}

// Spending by category against budgets for one cycle.
export function budgetStatus({ budgets, stats, range, now = Date.now() }) {
  const active = budgets.filter((b) => !b.deletedAt && b.amount > 0)
  const daysLeft = Math.max(1, daysBetween(Math.max(startOfDay(now), range.start), range.end))
  const spentByCat = new Map(stats.categories.map((c) => [c.categoryId, c.total]))
  const make = (b, spent) => {
    const remaining = b.amount - spent
    return { ...b, spent, remaining, pct: spent / b.amount, over: remaining < 0, perDay: Math.max(0, remaining) / daysLeft }
  }
  const total = active.find((b) => b.categoryId == null)
  return {
    total: total ? make(total, stats.spent) : null,
    categories: active.filter((b) => b.categoryId != null).map((b) => make(b, spentByCat.get(b.categoryId) ?? 0)),
    daysLeft,
  }
}
