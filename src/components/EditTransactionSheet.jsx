import { useEffect, useState } from 'react'
import BottomSheet from './BottomSheet'
import Button from './Button'
import CategoryChip from './CategoryChip'
import CurrencySheet from './CurrencySheet'
import Pills from './Pills'
import { useDataStore } from '../store/useDataStore'
import { useUIStore } from '../store/useUIStore'
import { useCategories } from '../hooks/useCategories'
import { currencySymbol } from '../lib/currencies'
import { toDateTimeInput } from '../lib/dates'
import { useDeleteWithUndo } from '../hooks/useDeleteWithUndo'

const inputCls = 'h-12 w-full rounded-[14px] bg-raised px-4 text-body text-ink outline-none placeholder:text-faint'

export default function EditTransactionSheet() {
  const id = useUIStore((s) => s.editingId)
  const close = () => useUIStore.getState().setEditingId(null)
  const tx = useDataStore((s) => (id ? s.transactions.find((t) => t.id === id) : null))
  const updateTransaction = useDataStore((s) => s.updateTransaction)
  const showError = useUIStore((s) => s.showError)
  const showToast = useUIStore((s) => s.showToast)
  const deleteWithUndo = useDeleteWithUndo()
  const { list: categories } = useCategories()

  const [form, setForm] = useState(null)
  const [currencyOpen, setCurrencyOpen] = useState(false)

  useEffect(() => {
    if (tx)
      setForm({
        amount: String(tx.amount),
        currency: tx.currency,
        type: tx.type,
        categoryId: tx.categoryId,
        date: toDateTimeInput(tx.date),
        note: tx.note,
      })
    // Only reset when a different transaction opens.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tx?.id])

  const set = (patch) => setForm((f) => ({ ...f, ...patch }))

  const save = () => {
    const amount = Math.round(parseFloat(form.amount) * 100) / 100
    if (!(amount > 0)) return showError('Enter an amount greater than 0')
    const date = new Date(form.date).getTime()
    if (!Number.isFinite(date)) return showError('Pick a valid date')
    updateTransaction(tx.id, { amount, currency: form.currency, type: form.type, categoryId: form.categoryId, date, note: form.note })
    showToast('Changes saved')
    close()
  }

  const open = Boolean(tx && form)

  return (
    <>
      <BottomSheet
        open={open}
        onClose={close}
        title="Edit entry"
        footer={
          <div className="flex gap-3">
            <Button
              variant="destructive"
              className="px-5"
              onClick={() => {
                deleteWithUndo(tx)
                close()
              }}
            >
              Delete
            </Button>
            <Button block onClick={save}>
              Save
            </Button>
          </div>
        }
      >
        {open && (
          <div className="space-y-5 pt-1">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCurrencyOpen(true)}
                className="h-12 shrink-0 rounded-[14px] bg-raised px-4 text-body font-semibold active:opacity-60"
              >
                {currencySymbol(form.currency)} {form.currency}
              </button>
              <input
                inputMode="decimal"
                aria-label="Amount"
                value={form.amount}
                onChange={(e) => set({ amount: e.target.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1') })}
                className={`${inputCls} text-[22px] font-bold`}
              />
            </div>

            <Pills
              value={form.type}
              onChange={(type) => set({ type })}
              options={[
                { value: 'expense', label: 'Expense' },
                { value: 'credit', label: 'Credit' },
              ]}
            />

            <div className="-mx-gutter scroll-area flex gap-2.5 overflow-x-auto px-gutter">
              {categories.map((c) => (
                <CategoryChip key={c.id} category={c} selected={c.id === form.categoryId} onClick={() => set({ categoryId: c.id })} />
              ))}
            </div>

            <label className="block">
              <span className="mb-1.5 block text-footnote text-sub">Date & time</span>
              <input type="datetime-local" value={form.date} onChange={(e) => set({ date: e.target.value })} className={inputCls} />
            </label>

            <label className="block">
              <span className="mb-1.5 block text-footnote text-sub">Note</span>
              <input
                value={form.note}
                maxLength={500}
                onChange={(e) => set({ note: e.target.value })}
                placeholder="Add a note"
                className={inputCls}
              />
            </label>
          </div>
        )}
      </BottomSheet>
      <CurrencySheet
        open={currencyOpen}
        value={form?.currency}
        onClose={() => setCurrencyOpen(false)}
        onSelect={(currency) => {
          set({ currency })
          setCurrencyOpen(false)
        }}
      />
    </>
  )
}
