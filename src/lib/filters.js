import { addDays, fromDateInput } from './dates'

export const hasActiveFilters = (f) =>
  f.categoryIds.length > 0 || f.type !== 'all' || f.minAmount !== '' || f.maxAmount !== '' || f.from || f.to || f.query.trim()

export function applyFilters(list, f, getCategory) {
  if (!hasActiveFilters(f)) return list
  const cats = f.categoryIds.length ? new Set(f.categoryIds) : null
  const min = f.minAmount === '' ? -Infinity : Number(f.minAmount)
  const max = f.maxAmount === '' ? Infinity : Number(f.maxAmount)
  const from = f.from ? fromDateInput(f.from) : -Infinity
  const to = f.to ? addDays(fromDateInput(f.to), 1) : Infinity
  const q = f.query.trim().toLowerCase()
  return list.filter(
    (t) =>
      (!cats || cats.has(t.categoryId)) &&
      (f.type === 'all' || t.type === f.type) &&
      t.amountInBase >= min &&
      t.amountInBase <= max &&
      t.date >= from &&
      t.date < to &&
      (!q || t.note.toLowerCase().includes(q) || getCategory(t.categoryId).name.toLowerCase().includes(q)),
  )
}
