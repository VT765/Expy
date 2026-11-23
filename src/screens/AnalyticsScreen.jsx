import { useMemo, useState } from 'react'
import Screen from '../components/Screen'
import Card from '../components/Card'
import Pills from '../components/Pills'
import Button from '../components/Button'
import EmptyState from '../components/EmptyState'
import EmojiCircle from '../components/EmojiCircle'
import Donut, { GREYS, foldSlices } from '../components/charts/Donut'
import BarChart from '../components/charts/BarChart'
import { ChevronLeft, ChevronRight, ShareIcon } from '../components/Icons'
import { useDataStore } from '../store/useDataStore'
import { useUIStore } from '../store/useUIStore'
import { useCategories } from '../hooks/useCategories'
import { useExport } from '../hooks/useExport'
import { periodRange, previousRange } from '../lib/periods'
import { budgetStatus, computeStats } from '../lib/analytics'
import { formatMoney, formatShortDate, formatTime } from '../lib/format'
import { toDateInput } from '../lib/dates'
import { cn } from '../lib/cn'

const KINDS = [
  { value: 'week', label: 'Week' },
  { value: 'month', label: 'Month' },
  { value: 'year', label: 'Year' },
  { value: 'custom', label: 'Custom' },
]
const dateInputCls = 'h-11 min-w-0 flex-1 rounded-[14px] bg-raised px-3 text-body text-ink outline-none'

export default function AnalyticsScreen() {
  const transactions = useDataStore((s) => s.transactions)
  const budgets = useDataStore((s) => s.budgets)
  const currency = useDataStore((s) => s.settings.baseCurrency)
  const cycleDay = useDataStore((s) => s.settings.cycleStartDay)
  const period = useUIStore((s) => s.period)
  const setPeriod = useUIStore((s) => s.setPeriod)
  const openSettings = useUIStore((s) => s.openSettings)
  const { get: getCategory } = useCategories()
  const { run: runExport, busy } = useExport()
  const [selCat, setSelCat] = useState(null)
  const [selBar, setSelBar] = useState(null)

  const range = useMemo(() => periodRange(period, cycleDay), [period, cycleDay])
  const stats = useMemo(() => computeStats(transactions, range, period.kind), [transactions, range, period.kind])
  const prev = useMemo(
    () => computeStats(transactions, previousRange(period, cycleDay), period.kind),
    [transactions, period, cycleDay],
  )
  const budget = useMemo(
    () => (period.kind === 'month' && period.offset === 0 ? budgetStatus({ budgets, stats, range }) : null),
    [period, budgets, stats, range],
  )
  const slices = useMemo(() => foldSlices(stats.categories), [stats.categories])

  const change = prev.spent > 0 ? (stats.spent - prev.spent) / prev.spent : null
  const step = (d) => {
    setSelBar(null)
    setSelCat(null)
    setPeriod({ offset: period.offset + d })
  }
  const labelFor = (s) => (s.categoryId === '__rest' ? `${s.folded} others` : getCategory(s.categoryId).name)

  return (
    <Screen title="Analytics">
      <div className="-mx-gutter scroll-area overflow-x-auto px-gutter pt-1">
        <Pills
          options={KINDS}
          value={period.kind}
          onChange={(kind) => {
            setSelBar(null)
            setSelCat(null)
            setPeriod({ kind, offset: 0 })
          }}
        />
      </div>

      {period.kind === 'custom' ? (
        <div className="mt-4 flex items-center gap-2">
          <input
            type="date"
            aria-label="From"
            value={period.from || toDateInput(range.start)}
            max={period.to || undefined}
            onChange={(e) => setPeriod({ from: e.target.value })}
            className={dateInputCls}
          />
          <span className="text-sub">–</span>
          <input
            type="date"
            aria-label="To"
            value={period.to || toDateInput(range.end - 1)}
            min={period.from || undefined}
            onChange={(e) => setPeriod({ to: e.target.value })}
            className={dateInputCls}
          />
        </div>
      ) : (
        <div className="mt-4 flex items-center justify-between">
          <NavButton label="Previous period" onClick={() => step(-1)}>
            <ChevronLeft size={20} />
          </NavButton>
          <span className="text-headline font-semibold">{range.label}</span>
          <NavButton label="Next period" onClick={() => step(1)} disabled={period.offset >= 0}>
            <ChevronRight size={20} />
          </NavButton>
        </div>
      )}

      {/* Stat tiles */}
      <div className="mt-5 grid grid-cols-2 gap-[6px]">
        <Stat label="Spent" value={formatMoney(stats.spent, currency)} big className="col-span-2">
          {change != null && (
            <span className={cn('rounded-chip px-2 py-0.5 text-footnote font-semibold', change > 0 ? 'bg-danger/15 text-danger' : 'bg-white/10 text-ink')}>
              {change > 0 ? '▲' : '▼'} {Math.abs(Math.round(change * 100))}% vs previous
            </span>
          )}
        </Stat>
        <Stat label="Credit" value={formatMoney(stats.credit, currency)} />
        <Stat label="Net" value={formatMoney(stats.net, currency)} />
        <Stat label="Avg / day" value={formatMoney(stats.avgPerDay, currency)} />
        <Stat label="Entries" value={String(stats.count)} />
      </div>

      {budget && (budget.total || budget.categories.length > 0) && (
        <Card title="Budget" className="mt-8">
          {budget.total && <BudgetBar b={budget.total} currency={currency} label="Monthly budget" />}
          {budget.categories.map((b) => {
            const c = getCategory(b.categoryId)
            return <BudgetBar key={b.id} b={b} currency={currency} label={`${c.emoji} ${c.name}`} small />
          })}
          <p className="mt-3 text-footnote text-sub">{budget.daysLeft} days left in this cycle</p>
        </Card>
      )}

      {stats.count === 0 ? (
        <EmptyState emoji="📊" title="No data for this period" message="Entries you log will show up here." />
      ) : (
        <>
          {stats.buckets.length > 0 && (
            <Card title="Spending over time" className="mt-8">
              <BarChart buckets={stats.buckets} currency={currency} selected={selBar} onSelect={setSelBar} />
            </Card>
          )}

          {stats.categories.length > 0 && (
            <Card title="By category" className="mt-8">
              <Donut slices={slices} total={stats.spent} currency={currency} selected={selCat} onSelect={setSelCat} labelFor={labelFor} />
              <ul className="mt-5">
                {stats.categories.map((c) => {
                  const cat = getCategory(c.categoryId)
                  const sliceIndex = slices.findIndex((s) => s.categoryId === c.categoryId)
                  const swatch = GREYS[sliceIndex === -1 ? slices.length - 1 : sliceIndex]
                  const key = sliceIndex === -1 ? '__rest' : c.categoryId
                  return (
                    <li key={c.categoryId}>
                      <button
                        type="button"
                        onClick={() => setSelCat(selCat === key ? null : key)}
                        className={cn('flex w-full items-center gap-3 py-2 text-left transition-opacity', selCat && selCat !== key && 'opacity-40')}
                      >
                        <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: swatch }} />
                        <span className="text-[18px]">{cat.emoji}</span>
                        <span className="min-w-0 flex-1">
                          <span className="flex justify-between gap-2 text-body">
                            <span className="truncate font-semibold">{cat.name}</span>
                            <span className="shrink-0 tabular-nums">{formatMoney(c.total, currency)}</span>
                          </span>
                          <span className="mt-1.5 flex items-center gap-2">
                            <span className="h-1 flex-1 overflow-hidden rounded-full bg-raised">
                              <span className="block h-full origin-left rounded-full bg-sub" style={{ transform: `scaleX(${c.pct})` }} />
                            </span>
                            <span className="w-10 text-right text-footnote tabular-nums text-sub">{Math.round(c.pct * 100)}%</span>
                          </span>
                        </span>
                      </button>
                    </li>
                  )
                })}
              </ul>
            </Card>
          )}

          {stats.top.length > 0 && (
            <Card title="Top expenses" className="mt-8" padded={false}>
              {stats.top.map((t) => {
                const cat = getCategory(t.categoryId)
                return (
                  <div key={t.id} className="flex items-center gap-3 border-b-[0.5px] border-well px-4 py-3 last:border-b-0">
                    <EmojiCircle emoji={cat.emoji} color={cat.color} size={38} />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-body font-semibold">{t.note || cat.name}</p>
                      <p className="text-footnote text-sub">
                        {cat.name} · {formatShortDate(t.date)}, {formatTime(t.date)}
                      </p>
                    </div>
                    <span className="text-body font-bold tabular-nums">{formatMoney(t.amountInBase, currency)}</span>
                  </div>
                )
              })}
            </Card>
          )}

          <div className="mt-8 grid grid-cols-2 gap-[6px]">
            <Button variant="secondary" size="md" loading={busy === 'xlsx'} onClick={() => runExport('xlsx', { range, label: range.label })}>
              <ShareIcon size={18} /> Excel
            </Button>
            <Button variant="secondary" size="md" loading={busy === 'csv'} onClick={() => runExport('csv', { range, label: range.label })}>
              <ShareIcon size={18} /> CSV
            </Button>
          </div>
        </>
      )}

      {!budget?.total && period.kind === 'month' && period.offset === 0 && (
        <button type="button" onClick={openSettings} className="mt-6 w-full text-center text-footnote text-sub active:opacity-50">
          Set a monthly budget in Settings ›
        </button>
      )}
    </Screen>
  )
}

function NavButton({ label, onClick, disabled, children }) {
  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      disabled={disabled}
      className="flex h-10 w-10 items-center justify-center rounded-full bg-raised active:opacity-60 disabled:opacity-25"
    >
      {children}
    </button>
  )
}

function Stat({ label, value, big, className, children }) {
  return (
    <div className={cn('rounded-card bg-card px-4 py-3.5', className)}>
      <p className="text-footnote text-sub">{label}</p>
      <p
        className={cn(
          'mt-0.5 truncate font-bold tabular-nums tracking-tight',
          big ? 'text-[32px] leading-10' : value.length > 12 ? 'text-[16px] leading-[26px]' : value.length > 10 ? 'text-headline leading-[26px]' : 'text-title',
        )}
      >
        {value}
      </p>
      {children && <div className="mt-2">{children}</div>}
    </div>
  )
}

function BudgetBar({ b, currency, label, small }) {
  const pct = Math.min(1, b.pct)
  return (
    <div className={small ? 'mt-4' : ''}>
      <div className="flex items-baseline justify-between gap-2">
        <span className={cn('truncate font-semibold', small ? 'text-body' : 'text-headline')}>{label}</span>
        <span className={cn('shrink-0 text-footnote tabular-nums', b.over ? 'text-danger' : 'text-sub')}>
          {formatMoney(b.spent, currency)} / {formatMoney(b.amount, currency)}
        </span>
      </div>
      <div className={cn('mt-2 overflow-hidden rounded-full bg-raised', small ? 'h-1.5' : 'h-2.5')}>
        <div
          className={cn('h-full origin-left rounded-full transition-transform duration-500', b.over ? 'bg-danger' : 'bg-ink')}
          style={{ transform: `scaleX(${pct})` }}
        />
      </div>
      <p className={cn('mt-1.5 text-footnote', b.over ? 'font-semibold text-danger' : 'text-sub')}>
        {b.over
          ? `⚠︎ Over budget by ${formatMoney(-b.remaining, currency)}`
          : `${formatMoney(b.remaining, currency)} left · ${formatMoney(b.perDay, currency)}/day`}
      </p>
    </div>
  )
}
