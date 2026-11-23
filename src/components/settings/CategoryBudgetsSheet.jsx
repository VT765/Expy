import { useState } from 'react'
import BottomSheet from '../BottomSheet'
import AmountSheet from './AmountSheet'
import { useDataStore } from '../../store/useDataStore'
import { useCategories } from '../../hooks/useCategories'
import { formatMoney } from '../../lib/format'

export default function CategoryBudgetsSheet({ open, onClose }) {
  const budgets = useDataStore((s) => s.budgets)
  const currency = useDataStore((s) => s.settings.baseCurrency)
  const setBudget = useDataStore((s) => s.setBudget)
  const { list } = useCategories()
  const [editing, setEditing] = useState(null)

  const amountFor = (id) => budgets.find((b) => b.categoryId === id && !b.deletedAt)?.amount ?? 0

  return (
    <BottomSheet open={open} onClose={onClose} title="Category budgets" tall>
      <p className="mb-4 text-center text-footnote text-sub">Monthly limits per category. Progress shows on Analytics.</p>
      <div className="overflow-hidden rounded-card bg-raised">
        {list.map((c) => {
          const amount = amountFor(c.id)
          return (
            <button key={c.id} type="button" onClick={() => setEditing(c)} className="group relative flex w-full items-center gap-3 pl-4 text-left">
              <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 group-active:opacity-100" />
              <span className="text-[20px]">{c.emoji}</span>
              <span className="flex min-h-[52px] flex-1 items-center border-b-[0.5px] border-well pr-4 group-last:border-b-0">
                <span className="flex-1 text-body">{c.name}</span>
                <span className="text-body tabular-nums text-sub">{amount ? formatMoney(amount, currency) : 'Not set'} ›</span>
              </span>
            </button>
          )
        })}
      </div>
      <AmountSheet
        open={editing != null}
        title={editing ? `${editing.emoji} ${editing.name}` : ''}
        currency={currency}
        value={editing ? amountFor(editing.id) : 0}
        onSave={(v) => setBudget(editing.id, v)}
        onClose={() => setEditing(null)}
      />
    </BottomSheet>
  )
}
