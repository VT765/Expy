import { useEffect, useState } from 'react'
import BottomSheet from './BottomSheet'
import Button from './Button'
import Pills from './Pills'
import { CheckIcon, SearchIcon } from './Icons'
import { EMPTY_FILTERS, useUIStore } from '../store/useUIStore'
import { useCategories } from '../hooks/useCategories'
import { tint } from '../lib/colors'
import { cn } from '../lib/cn'

const inputCls = 'h-12 w-full min-w-0 rounded-[14px] bg-raised px-4 text-body text-ink outline-none placeholder:text-faint'
const label = 'mb-2.5 block text-footnote font-semibold uppercase tracking-label text-faint'

export default function FilterSheet({ open, onClose }) {
  const filters = useUIStore((s) => s.filters)
  const setFilters = useUIStore((s) => s.setFilters)
  const { list: categories } = useCategories()
  const [draft, setDraft] = useState(filters)

  useEffect(() => {
    if (open) setDraft(filters)
  }, [open, filters])

  const set = (patch) => setDraft((d) => ({ ...d, ...patch }))
  const toggleCat = (id) =>
    set({ categoryIds: draft.categoryIds.includes(id) ? draft.categoryIds.filter((c) => c !== id) : [...draft.categoryIds, id] })
  const numeric = (v) => v.replace(/[^0-9.]/g, '')

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title="Filters"
      tall
      headerAction={
        <button type="button" onClick={() => setDraft(EMPTY_FILTERS)} className="text-body text-sub active:opacity-50">
          Reset
        </button>
      }
      footer={
        <Button
          block
          onClick={() => {
            setFilters(draft)
            onClose()
          }}
        >
          Apply
        </Button>
      }
    >
      <div className="space-y-7 pt-1">
        <div className="relative">
          <SearchIcon size={18} className="pointer-events-none absolute left-4 top-[15px] text-faint" />
          <input
            type="search"
            value={draft.query}
            onChange={(e) => set({ query: e.target.value })}
            placeholder="Search notes"
            className={`${inputCls} pl-11`}
          />
        </div>

        <div>
          <span className={label}>Type</span>
          <Pills
            value={draft.type}
            onChange={(type) => set({ type })}
            options={[
              { value: 'all', label: 'All' },
              { value: 'expense', label: 'Expenses' },
              { value: 'credit', label: 'Credits' },
            ]}
          />
        </div>

        <div>
          <span className={label}>Categories</span>
          <div className="flex flex-wrap gap-2">
            {categories.map((c) => {
              const on = draft.categoryIds.includes(c.id)
              return (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => toggleCat(c.id)}
                  className={cn('flex h-10 items-center gap-1.5 rounded-chip px-3.5 text-footnote font-semibold', !on && 'bg-raised text-sub')}
                  style={on ? { background: tint(c.color), color: c.color, boxShadow: `inset 0 0 0 2px ${c.color}` } : undefined}
                >
                  <span>{c.emoji}</span>
                  {c.name}
                  {on && <CheckIcon size={14} />}
                </button>
              )
            })}
          </div>
        </div>

        <div>
          <span className={label}>Amount range</span>
          <div className="flex items-center gap-3">
            <input inputMode="decimal" placeholder="Min" value={draft.minAmount} onChange={(e) => set({ minAmount: numeric(e.target.value) })} className={inputCls} />
            <span className="text-sub">–</span>
            <input inputMode="decimal" placeholder="Max" value={draft.maxAmount} onChange={(e) => set({ maxAmount: numeric(e.target.value) })} className={inputCls} />
          </div>
        </div>

        <div>
          <span className={label}>Date range</span>
          <div className="flex items-center gap-3">
            <input type="date" aria-label="From" value={draft.from} onChange={(e) => set({ from: e.target.value })} className={inputCls} />
            <span className="text-sub">–</span>
            <input type="date" aria-label="To" value={draft.to} onChange={(e) => set({ to: e.target.value })} className={inputCls} />
          </div>
        </div>
      </div>
    </BottomSheet>
  )
}
