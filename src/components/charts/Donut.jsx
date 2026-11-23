import { useMemo } from 'react'
import { formatMoney } from '../../lib/format'

// Greyscale donut. Largest slice is white, then progressively darker greys.
// Tap a slice (or its legend row) to highlight it; the centre shows its value.
export const GREYS = ['#FFFFFF', '#C7C7CC', '#9A9AA0', '#76767C', '#56565B', '#3D3D41', '#2C2C2E']
const MAX_SLICES = 6

// Keeps the top six categories and folds the rest into one "Other" slice.
export function foldSlices(categories) {
  if (categories.length <= MAX_SLICES + 1) return categories
  const head = categories.slice(0, MAX_SLICES)
  const rest = categories.slice(MAX_SLICES)
  const total = rest.reduce((s, c) => s + c.total, 0)
  const pct = rest.reduce((s, c) => s + c.pct, 0)
  return [...head, { categoryId: '__rest', total, pct, folded: rest.length }]
}

export default function Donut({ slices, total, currency, selected, onSelect, labelFor, size = 200, stroke = 26 }) {
  const r = (size - stroke) / 2
  const c = 2 * Math.PI * r
  const GAP = slices.length > 1 ? 2 : 0 // px of surface between segments

  const arcs = useMemo(() => {
    let acc = 0
    return slices.map((s, i) => {
      const len = Math.max(0, s.pct * c - GAP)
      const arc = { ...s, dash: `${len} ${c - len}`, offset: -acc, color: GREYS[i] ?? GREYS[GREYS.length - 1] }
      acc += s.pct * c
      return arc
    })
  }, [slices, c, GAP])

  const active = arcs.find((a) => a.categoryId === selected)

  return (
    <div className="relative mx-auto" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90" role="img" aria-label="Spending by category">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#1C1C1E" strokeWidth={stroke} />
        {arcs.map((a) => (
          <circle
            key={a.categoryId}
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            stroke={a.color}
            strokeWidth={stroke}
            strokeDasharray={a.dash}
            strokeDashoffset={a.offset}
            onClick={() => onSelect(selected === a.categoryId ? null : a.categoryId)}
            style={{ opacity: selected && selected !== a.categoryId ? 0.25 : 1, transition: 'opacity 200ms', cursor: 'pointer' }}
          />
        ))}
      </svg>
      <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center text-center">
        <span className="max-w-[60%] truncate text-footnote text-sub">{active ? labelFor(active) : 'Spent'}</span>
        <CenterValue text={formatMoney(active ? active.total : total, currency)} />
        {active && <span className="text-footnote text-sub">{Math.round(active.pct * 100)}%</span>}
      </div>
    </div>
  )
}

// Shrinks long amounts so they stay inside the ring.
function CenterValue({ text }) {
  const size = text.length > 12 ? 15 : text.length > 9 ? 18 : 22
  return (
    <span className="font-bold tabular-nums" style={{ fontSize: size, lineHeight: 1.25 }}>
      {text}
    </span>
  )
}
