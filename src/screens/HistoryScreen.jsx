import { useCallback, useMemo, useRef, useState } from 'react'
import Screen from '../components/Screen'
import Pills from '../components/Pills'
import EmptyState from '../components/EmptyState'
import FilterSheet from '../components/FilterSheet'
import TransactionRow from '../components/TransactionRow'
import Button from '../components/Button'
import { SlidersIcon } from '../components/Icons'
import { selectActiveTransactions, signedBase, useDataStore } from '../store/useDataStore'
import { EMPTY_FILTERS, useUIStore } from '../store/useUIStore'
import { useCategories } from '../hooks/useCategories'
import { useDeleteWithUndo } from '../hooks/useDeleteWithUndo'
import { useVirtualList } from '../hooks/useVirtualList'
import { periodRange, inRange } from '../lib/periods'
import { applyFilters, hasActiveFilters } from '../lib/filters'
import { dayHeader, startOfDay } from '../lib/dates'
import { formatMoney } from '../lib/format'

const RANGES = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: 'This Week' },
  { value: 'month', label: 'This Month' },
  { value: 'all', label: 'All' },
]
const HEADER_H = 52
const ROW_H = 72
const VIRTUALIZE_AFTER = 200
const heightOf = (item) => (item.kind === 'header' ? HEADER_H : ROW_H)

export default function HistoryScreen() {
  const transactions = useDataStore((s) => s.transactions)
  const baseCurrency = useDataStore((s) => s.settings.baseCurrency)
  const cycleDay = useDataStore((s) => s.settings.cycleStartDay)
  const range = useUIStore((s) => s.historyRange)
  const setRange = useUIStore((s) => s.setHistoryRange)
  const filters = useUIStore((s) => s.filters)
  const setFilters = useUIStore((s) => s.setFilters)
  const setEditingId = useUIStore((s) => s.setEditingId)
  const setTab = useUIStore((s) => s.setTab)
  const { get: getCategory } = useCategories()
  const deleteWithUndo = useDeleteWithUndo()
  const [filterOpen, setFilterOpen] = useState(false)
  const scrollRef = useRef(null)
  const listRef = useRef(null)

  const filtering = hasActiveFilters(filters)

  const { items, total, count } = useMemo(() => {
    const period = periodRange({ kind: range }, cycleDay)
    const list = applyFilters(
      selectActiveTransactions({ transactions }).filter((t) => inRange(t, period)),
      filters,
      getCategory,
    ).sort((a, b) => b.date - a.date)

    // Flatten into [header, row, row, header, …] with per-day totals.
    const items = []
    let total = 0
    let header = null
    for (const tx of list) {
      const day = startOfDay(tx.date)
      if (!header || header.day !== day) {
        header = { kind: 'header', key: `h${day}`, day, total: 0 }
        items.push(header)
      }
      const v = signedBase(tx)
      header.total += v
      total += v
      items.push({ kind: 'row', key: tx.id, tx })
    }
    return { items, total, count: list.length }
  }, [transactions, range, cycleDay, filters, getCategory])

  const { visible, total: height, virtual } = useVirtualList({
    items,
    heightOf,
    scrollRef,
    listRef,
    enabled: count > VIRTUALIZE_AFTER,
  })

  const openTx = useCallback((tx) => setEditingId(tx.id), [setEditingId])

  return (
    <div className="relative h-full">
      <Screen
        title="Expenses"
        scrollRef={scrollRef}
        footerSpace={count ? 76 : 0}
        trailing={
          <button
            type="button"
            onClick={() => setFilterOpen(true)}
            aria-label="Filters"
            className="relative flex h-10 w-10 items-center justify-center active:opacity-50"
          >
            <SlidersIcon size={26} />
            {filtering && <span className="absolute right-0.5 top-1 h-2.5 w-2.5 rounded-full bg-danger ring-2 ring-canvas" />}
          </button>
        }
      >
        <div className="-mx-gutter scroll-area overflow-x-auto px-gutter pb-1 pt-1">
          <Pills options={RANGES} value={range} onChange={setRange} />
        </div>

        {count === 0 ? (
          filtering ? (
            <EmptyState
              emoji="🔍"
              title="No matches"
              message="Nothing fits these filters in this range."
              action={
                <Button size="sm" variant="secondary" onClick={() => setFilters(EMPTY_FILTERS)}>
                  Clear filters
                </Button>
              }
            />
          ) : (
            <EmptyState
              emoji="🧾"
              title={range === 'all' ? 'No expenses yet' : 'Nothing here yet'}
              message="Log your first expense from the Tap tab."
              action={
                <Button size="sm" variant="secondary" onClick={() => setTab('tap')}>
                  Add expense
                </Button>
              }
            />
          )
        ) : (
          <div ref={listRef} className="relative mt-3" style={virtual ? { height } : undefined}>
            {visible.map(({ item, top }) =>
              item.kind === 'header' ? (
                <div
                  key={item.key}
                  className="flex items-end justify-between pb-3 text-footnote uppercase tracking-label text-faint"
                  style={virtual ? { position: 'absolute', top, left: 0, right: 0, height: HEADER_H } : { height: HEADER_H }}
                >
                  <span>{dayHeader(item.day)}</span>
                  <span className="normal-case tracking-normal tabular-nums">{formatMoney(item.total, baseCurrency)}</span>
                </div>
              ) : (
                <div
                  key={item.key}
                  className="border-b-[0.5px] border-well"
                  style={virtual ? { position: 'absolute', top, left: 0, right: 0, height: ROW_H } : { height: ROW_H }}
                >
                  <TransactionRow
                    tx={item.tx}
                    category={getCategory(item.tx.categoryId)}
                    baseCurrency={baseCurrency}
                    onOpen={openTx}
                    onDelete={deleteWithUndo}
                  />
                </div>
              ),
            )}
          </div>
        )}
      </Screen>

      {count > 0 && (
        <div className="hairline-t absolute inset-x-0 z-10 flex h-[68px] items-center justify-between bg-card px-gutter"
          style={{ bottom: 'calc(58px + env(safe-area-inset-bottom))' }}
        >
          <span className="text-[18px] font-semibold text-faint">Total</span>
          <span className="text-[25px] font-bold tabular-nums tracking-tight">{formatMoney(total, baseCurrency)}</span>
        </div>
      )}

      <FilterSheet open={filterOpen} onClose={() => setFilterOpen(false)} />
    </div>
  )
}
