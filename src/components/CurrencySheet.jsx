import BottomSheet from './BottomSheet'
import { CheckIcon } from './Icons'
import { CURRENCIES } from '../lib/currencies'

export default function CurrencySheet({ open, value, onSelect, onClose, title = 'Currency' }) {
  return (
    <BottomSheet open={open} onClose={onClose} title={title}>
      <div className="overflow-hidden rounded-card bg-raised">
        {CURRENCIES.map((c) => (
          <button
            key={c.code}
            type="button"
            onClick={() => onSelect(c.code)}
            className="group relative flex w-full items-center gap-3 pl-4 text-left"
          >
            <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 group-active:opacity-100" />
            <span className="w-9 shrink-0 text-center text-body font-semibold">{c.symbol}</span>
            <span className="flex min-h-[52px] flex-1 items-center border-b-[0.5px] border-well pr-4 group-last:border-b-0">
              <span className="flex-1 text-body">{c.name}</span>
              <span className="mr-3 text-footnote text-sub">{c.code}</span>
              <CheckIcon size={18} className={value === c.code ? 'text-ink' : 'invisible'} />
            </span>
          </button>
        ))}
      </div>
    </BottomSheet>
  )
}
