import { useEffect, useMemo, useRef, useState } from 'react'
import { AnimatePresence, motion, useAnimationControls } from 'framer-motion'
import Button from '../components/Button'
import CategoryChip from '../components/CategoryChip'
import NumPad from '../components/NumPad'
import CurrencySheet from '../components/CurrencySheet'
import SyncIndicator from '../components/SyncIndicator'
import { CheckIcon, GearIcon } from '../components/Icons'
import { useUIStore } from '../store/useUIStore'
import { useDataStore } from '../store/useDataStore'
import { useCategories } from '../hooks/useCategories'
import { backspace, displayAmount, parseAmount, pressKey } from '../lib/amountInput'
import { addDays, fromDateInput, startOfDay, toDateInput, withTimeOf } from '../lib/dates'
import { currencySymbol } from '../lib/currencies'
import { formatMoney, formatShortDate } from '../lib/format'
import { consumePrefill, sanitizeAmount } from '../lib/prefill'
import { ensureRates } from '../lib/rates'
import { cn } from '../lib/cn'

const LAST_CAT_KEY = 'expy:lastCategory'

const readLastCategory = () => {
  try {
    return localStorage.getItem(LAST_CAT_KEY)
  } catch {
    return null
  }
}

export default function TapScreen() {
  const openSettings = useUIStore((s) => s.openSettings)
  const showToast = useUIStore((s) => s.showToast)
  const showError = useUIStore((s) => s.showError)
  const addTransaction = useDataStore((s) => s.addTransaction)
  const baseCurrency = useDataStore((s) => s.settings.baseCurrency)
  const toBase = useDataStore((s) => s.toBase)
  const { list: categories, get: getCategory } = useCategories()

  const [amount, setAmount] = useState('')
  const [categoryId, setCategoryId] = useState(() => readLastCategory())
  const [dateMode, setDateMode] = useState('today') // today | yesterday | pick
  const [pickedDay, setPickedDay] = useState(null)
  const [note, setNote] = useState('')
  const [noteOpen, setNoteOpen] = useState(false)
  const [credit, setCredit] = useState(false)
  const [currency, setCurrency] = useState(null) // null = base currency
  const [currencyOpen, setCurrencyOpen] = useState(false)
  const amountControls = useAnimationControls()
  const chipRefs = useRef({})

  const activeCurrency = currency ?? baseCurrency
  const value = parseAmount(amount)
  const valid = value > 0
  const selected = categories.find((c) => c.id === categoryId) ?? categories[0]

  // Prefill from URL (?amount=&cat=&type=&note=) once on mount.
  useEffect(() => {
    const p = consumePrefill()
    if (!p) return
    const amt = sanitizeAmount(p.amount)
    if (amt) setAmount(amt)
    if (p.type) setCredit(p.type.toLowerCase().startsWith('c'))
    if (p.note) {
      setNote(p.note.slice(0, 500))
      setNoteOpen(true)
    }
    if (p.cat) {
      const q = p.cat.trim().toLowerCase()
      const match = categories.find((c) => c.id === p.cat || c.name.toLowerCase() === q)
      if (match) setCategoryId(match.id)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Keep the selected chip visible.
  useEffect(() => {
    chipRefs.current[selected?.id]?.scrollIntoView({ behavior: 'smooth', inline: 'nearest', block: 'nearest' })
  }, [selected?.id])

  // Hardware keyboard support (desktop testing, iPad keyboards).
  useEffect(() => {
    const onKey = (e) => {
      if (e.target.closest?.('input, textarea')) return
      if (/^[0-9.]$/.test(e.key)) setAmount((a) => pressKey(a, e.key))
      else if (e.key === 'Backspace') setAmount(backspace)
      else if (e.key === 'Enter') save()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  })

  const dayTs = useMemo(() => {
    const today = startOfDay(Date.now())
    if (dateMode === 'yesterday') return addDays(today, -1)
    if (dateMode === 'pick' && pickedDay) return pickedDay
    return today
  }, [dateMode, pickedDay])

  function save() {
    if (!valid || !selected) return
    const date = dateMode === 'today' ? Date.now() : withTimeOf(dayTs)
    const { missingRate } = toBase(value, activeCurrency)
    const tx = addTransaction({
      type: credit ? 'credit' : 'expense',
      amount: value,
      currency: activeCurrency,
      categoryId: selected.id,
      note,
      date,
    })
    try {
      localStorage.setItem(LAST_CAT_KEY, selected.id)
    } catch {
      /* private mode */
    }
    amountControls.start({ y: [0, -18, 0], opacity: [1, 0, 1], transition: { duration: 0.45, times: [0, 0.45, 1] } })
    const cat = getCategory(tx.categoryId)
    showToast(`Saved ${credit ? '+' : ''}${formatMoney(tx.amount, tx.currency)} · ${cat.name}`, { icon: <CheckIcon size={16} /> })
    if (missingRate) showError(`No ${activeCurrency} rate yet. Set one in Settings → Currency.`)
    setTimeout(() => {
      setAmount('')
      setNote('')
      setNoteOpen(false)
      setCredit(false)
      setDateMode('today')
      setPickedDay(null)
      setCurrency(null)
    }, 180)
  }

  const shown = displayAmount(amount)
  const amountSize = shown.length > 10 ? 34 : shown.length > 7 ? 40 : 46
  const converted = activeCurrency !== baseCurrency && valid ? toBase(value, activeCurrency) : null

  return (
    <div className="flex h-full flex-col pt-safe-t">
      <div className="relative flex min-h-0 flex-1 flex-col items-center justify-center px-gutter">
        <div className="absolute left-3 top-3">
          <SyncIndicator />
        </div>
        <button
          type="button"
          onClick={openSettings}
          aria-label="Settings"
          className="absolute right-3 top-2 flex h-10 w-10 items-center justify-center text-faint active:opacity-50"
        >
          <GearIcon size={22} />
        </button>
        <p className="text-body text-sub">{credit ? 'How much came in?' : 'How much?'}</p>
        <motion.div animate={amountControls} className="mt-1.5 flex items-baseline gap-3 font-bold tracking-tight">
          <button
            type="button"
            onClick={() => {
              setCurrencyOpen(true)
              ensureRates().catch(() => {})
            }}
            aria-label={`Currency: ${activeCurrency}. Tap to change`}
            className="active:opacity-50"
            style={{ fontSize: activeCurrency === 'INR' ? amountSize : amountSize * 0.6 }}
          >
            {currencySymbol(activeCurrency)}
          </button>
          <span className="tabular-nums" style={{ fontSize: amountSize, lineHeight: 1.1 }} aria-live="polite">
            {credit && valid ? '+' : ''}
            {shown}
          </span>
        </motion.div>
        <p className={cn('h-5 text-footnote text-sub transition-opacity', converted ? 'opacity-100' : 'opacity-0')}>
          {converted && `≈ ${formatMoney(converted.amountInBase, baseCurrency)}`}
        </p>
      </div>

      <div className="mx-gutter h-px shrink-0 bg-well" />

      <div className="shrink-0">
        <div className="scroll-area flex gap-2.5 overflow-x-auto overflow-y-hidden px-gutter py-[18px]">
          {categories.map((c) => (
            <CategoryChip
              key={c.id}
              ref={(el) => (chipRefs.current[c.id] = el)}
              category={c}
              selected={c.id === selected?.id}
              onClick={() => setCategoryId(c.id)}
            />
          ))}
        </div>

        <div className="flex justify-center gap-2.5 px-gutter">
          {[
            ['today', 'Today'],
            ['yesterday', 'Yesterday'],
          ].map(([mode, label]) => (
            <DatePill key={mode} active={dateMode === mode} onClick={() => setDateMode(mode)}>
              {label}
            </DatePill>
          ))}
          <DatePill active={dateMode === 'pick'}>
            {dateMode === 'pick' && pickedDay ? formatShortDate(pickedDay) : 'Pick date'}
            {/* Native picker: an invisible date input covering the pill. */}
            <input
              type="date"
              aria-label="Pick date"
              max={toDateInput(Date.now())}
              value={pickedDay ? toDateInput(pickedDay) : ''}
              onChange={(e) => {
                if (!e.target.value) return
                setPickedDay(fromDateInput(e.target.value))
                setDateMode('pick')
              }}
              className="absolute inset-0 h-full w-full opacity-0"
            />
          </DatePill>
        </div>

        <div className="flex h-[52px] items-center gap-3 px-gutter">
          <AnimatePresence initial={false} mode="wait">
            {noteOpen ? (
              <motion.input
                key="note"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.12 }}
                autoFocus
                value={note}
                maxLength={500}
                onChange={(e) => setNote(e.target.value)}
                onBlur={() => !note.trim() && setNoteOpen(false)}
                onKeyDown={(e) => e.key === 'Enter' && e.currentTarget.blur()}
                placeholder="Add a note"
                enterKeyHint="done"
                className="h-10 min-w-0 flex-1 rounded-[14px] bg-raised px-3.5 text-body text-ink outline-none placeholder:text-faint"
              />
            ) : (
              <motion.button
                key="add"
                type="button"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.12 }}
                onClick={() => setNoteOpen(true)}
                className="min-w-0 flex-1 truncate text-left text-body text-sub active:opacity-50"
              >
                + add note
              </motion.button>
            )}
          </AnimatePresence>
          <motion.button
            type="button"
            onClick={() => setCredit((c) => !c)}
            whileTap={{ scale: 0.95 }}
            transition={{ duration: 0.12 }}
            aria-pressed={credit}
            className={cn(
              'h-10 shrink-0 rounded-[16px] px-4 text-body font-semibold',
              credit ? 'bg-ink text-canvas' : 'bg-raised text-faint',
            )}
          >
            Credit
          </motion.button>
        </div>

        <NumPad
          className="px-4 pt-2"
          onKey={(k) => setAmount((a) => pressKey(a, k))}
          onBackspace={() => setAmount(backspace)}
          onClear={() => setAmount('')}
        />

        <div className="px-gutter pb-[calc(58px+env(safe-area-inset-bottom)+12px)] pt-[18px]">
          <Button block disabled={!valid} onClick={save}>
            Save
          </Button>
        </div>
      </div>

      <CurrencySheet
        open={currencyOpen}
        value={activeCurrency}
        onClose={() => setCurrencyOpen(false)}
        onSelect={(code) => {
          setCurrency(code === baseCurrency ? null : code)
          setCurrencyOpen(false)
        }}
      />
    </div>
  )
}

function DatePill({ active, onClick, children }) {
  return (
    <motion.div
      role="button"
      tabIndex={0}
      onClick={onClick}
      whileTap={{ scale: 0.95 }}
      transition={{ duration: 0.12 }}
      aria-pressed={active}
      className={cn(
        'relative flex h-[32px] items-center overflow-hidden rounded-chip px-[15px] text-body font-semibold',
        active ? 'bg-raised text-ink' : 'text-faint',
      )}
    >
      {children}
    </motion.div>
  )
}
