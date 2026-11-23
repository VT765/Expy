import { useEffect, useState } from 'react'
import BottomSheet from '../BottomSheet'
import Button from '../Button'
import { currencySymbol } from '../../lib/currencies'

// Single-amount editor (monthly budget, per-category budget, rate override).
export default function AmountSheet({ open, title, hint, currency, value, onSave, onClose, removeLabel = 'Remove' }) {
  const [text, setText] = useState('')
  useEffect(() => {
    if (open) setText(value ? String(value) : '')
  }, [open, value])
  const amount = parseFloat(text) || 0

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title={title}
      footer={
        <div className="flex gap-3">
          {value > 0 && (
            <Button
              variant="destructive"
              className="px-5"
              onClick={() => {
                onSave(0)
                onClose()
              }}
            >
              {removeLabel}
            </Button>
          )}
          <Button
            block
            disabled={!(amount > 0)}
            onClick={() => {
              onSave(Math.round(amount * 100) / 100)
              onClose()
            }}
          >
            Save
          </Button>
        </div>
      }
    >
      {hint && <p className="mb-4 text-center text-footnote text-sub">{hint}</p>}
      <div className="flex items-center justify-center gap-2 py-4">
        <span className="text-[34px] font-bold text-sub">{currencySymbol(currency)}</span>
        <input
          autoFocus
          inputMode="decimal"
          aria-label={title}
          value={text}
          placeholder="0"
          onChange={(e) => setText(e.target.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1'))}
          className="w-[60%] bg-transparent text-center text-[40px] font-bold text-ink outline-none placeholder:text-faint"
        />
      </div>
    </BottomSheet>
  )
}
