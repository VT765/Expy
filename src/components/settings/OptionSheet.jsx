import BottomSheet from '../BottomSheet'
import { CheckIcon } from '../Icons'

// Single-choice list in a sheet: options = [{ value, label, subtitle? }]
export default function OptionSheet({ open, title, options, value, onSelect, onClose }) {
  return (
    <BottomSheet open={open} onClose={onClose} title={title}>
      <div className="overflow-hidden rounded-card bg-raised">
        {options.map((o) => (
          <button
            key={o.value}
            type="button"
            onClick={() => {
              onSelect(o.value)
              onClose()
            }}
            className="group relative flex w-full items-center pl-4 text-left"
          >
            <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 group-active:opacity-100" />
            <span className="flex min-h-[52px] flex-1 items-center border-b-[0.5px] border-well pr-4 group-last:border-b-0">
              <span className="flex-1">
                <span className="block text-body">{o.label}</span>
                {o.subtitle && <span className="block text-footnote text-sub">{o.subtitle}</span>}
              </span>
              <CheckIcon size={18} className={value === o.value ? 'text-ink' : 'invisible'} />
            </span>
          </button>
        ))}
      </div>
    </BottomSheet>
  )
}
