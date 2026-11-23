import { useMemo } from 'react'
import { formatCompact, formatMoney } from '../../lib/format'

// Spending per bucket. Thin rounded-top bars, recessive grid, tap a bar for
// its value. Hit areas span the full column, wider than the bar.
export default function BarChart({ buckets, currency, selected, onSelect, height = 168 }) {
  const W = 340
  const top = 8
  const bottom = 22
  const plotH = height - top - bottom
  const max = useMemo(() => Math.max(1, ...buckets.map((b) => b.total)), [buckets])
  const nice = niceMax(max)
  const n = buckets.length || 1
  const col = W / n
  const barW = Math.max(2, Math.min(18, col - 2))
  const labelEvery = n <= 12 ? 1 : n <= 31 ? 5 : Math.ceil(n / 6)
  const sel = selected != null ? buckets[selected] : null

  return (
    <div>
      <div className="mb-2 flex h-10 items-end justify-between">
        <div>
          <p className="text-footnote text-sub">{sel ? sel.long : 'Tap a bar for details'}</p>
          <p className="text-headline font-bold tabular-nums">{sel ? formatMoney(sel.total, currency) : ' '}</p>
        </div>
        <span className="text-caption text-faint">max {formatCompact(nice)}</span>
      </div>
      <svg viewBox={`0 0 ${W} ${height}`} className="w-full" role="img" aria-label="Spending over time">
        {[0, 0.5, 1].map((f) => (
          <line
            key={f}
            x1={0}
            x2={W}
            y1={top + plotH * (1 - f)}
            y2={top + plotH * (1 - f)}
            stroke="#2C2C2E"
            strokeWidth="0.5"
            strokeDasharray={f === 0 ? undefined : '2 4'}
          />
        ))}
        {buckets.map((b, i) => {
          const h = b.total > 0 ? Math.max(3, (b.total / nice) * plotH) : 0
          const x = i * col + (col - barW) / 2
          const y = top + plotH - h
          const r = Math.min(4, barW / 2, h)
          const dim = selected != null && selected !== i
          return (
            <g key={b.start} onClick={() => onSelect(selected === i ? null : i)} style={{ cursor: 'pointer' }}>
              <rect x={i * col} y={0} width={col} height={height} fill="transparent" />
              {h > 0 && (
                <path
                  d={`M${x},${y + h} V${y + r} Q${x},${y} ${x + r},${y} H${x + barW - r} Q${x + barW},${y} ${x + barW},${y + r} V${y + h} Z`}
                  fill={selected === i ? '#FFFFFF' : '#8E8E93'}
                  style={{ opacity: dim ? 0.35 : 1, transition: 'opacity 150ms' }}
                />
              )}
              {i % labelEvery === 0 && b.short && (
                <text x={i * col + col / 2} y={height - 6} textAnchor="middle" fontSize="10" fill="#8E8E93">
                  {b.short}
                </text>
              )}
            </g>
          )
        })}
      </svg>
    </div>
  )
}

function niceMax(v) {
  const p = 10 ** Math.floor(Math.log10(v))
  const m = v / p
  return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p
}
