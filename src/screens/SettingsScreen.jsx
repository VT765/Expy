import { useRef, useState } from 'react'
import { AnimatePresence, motion, useDragControls } from 'framer-motion'
import { Row, Section } from '../components/SettingsRow'
import { ChevronLeft } from '../components/Icons'
import CurrencySheet from '../components/CurrencySheet'
import AmountSheet from '../components/settings/AmountSheet'
import OptionSheet from '../components/settings/OptionSheet'
import ExchangeRatesSheet from '../components/settings/ExchangeRatesSheet'
import CategoriesSection from '../components/settings/CategoriesSection'
import CategoryBudgetsSheet from '../components/settings/CategoryBudgetsSheet'
import SecuritySection from '../components/settings/SecuritySection'
import AccountSection from '../components/settings/AccountSection'
import QuickLoggingSection from '../components/settings/QuickLoggingSection'
import SyncSection from '../components/settings/SyncSection'
import { useDataStore } from '../store/useDataStore'
import { useUIStore } from '../store/useUIStore'
import { useExport } from '../hooks/useExport'
import { currencyInfo } from '../lib/currencies'
import { ensureRates } from '../lib/rates'
import { formatMoney, ordinal } from '../lib/format'
import { periodRange } from '../lib/periods'
import { spring } from '../lib/motion'

// Settings is presented as an iOS page sheet: slides up, drag the header down
// (or tap ‹) to dismiss.
export default function SettingsScreen() {
  const open = useUIStore((s) => s.settingsOpen)
  const close = useUIStore((s) => s.closeSettings)
  const controls = useDragControls()

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            className="fixed inset-0 z-30 bg-black/60"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            onClick={close}
          />
          <motion.div
            role="dialog"
            aria-modal="true"
            aria-label="Settings"
            className="gpu fixed inset-x-0 bottom-0 z-30 flex flex-col overflow-hidden rounded-t-[38px] bg-canvas shadow-[0_-0.5px_0_#2C2C2E]"
            style={{ top: 'calc(env(safe-area-inset-top) + 10px)' }}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={spring}
            drag="y"
            dragListener={false}
            dragControls={controls}
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0.02, bottom: 0.9 }}
            onDragEnd={(_, info) => (info.offset.y > 140 || info.velocity.y > 700) && close()}
          >
            <header
              className="relative flex h-[76px] shrink-0 touch-none items-center justify-center"
              onPointerDown={(e) => controls.start(e)}
            >
              <button
                type="button"
                onClick={close}
                onPointerDown={(e) => e.stopPropagation()}
                aria-label="Close settings"
                className="absolute left-3 flex h-11 w-11 items-center justify-center active:opacity-50"
              >
                <ChevronLeft size={26} />
              </button>
              <h1 className="text-large font-bold tracking-tight">Settings</h1>
            </header>
            <SettingsBody />
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

function SettingsBody() {
  const settings = useDataStore((s) => s.settings)
  const budgets = useDataStore((s) => s.budgets)
  const updateSettings = useDataStore((s) => s.updateSettings)
  const setBudget = useDataStore((s) => s.setBudget)
  const rebaseTransactions = useDataStore((s) => s.rebaseTransactions)
  const { confirm, showToast, showError } = useUIStore.getState()
  const { run: runExport, busy } = useExport()
  const [sheet, setSheet] = useState(null)
  const fileRef = useRef(null)

  const base = currencyInfo(settings.baseCurrency)
  const total = budgets.find((b) => b.id === 'budget_total' && !b.deletedAt)
  const catBudgets = budgets.filter((b) => b.categoryId && !b.deletedAt && b.amount > 0).length
  const closeSheet = () => setSheet(null)

  const changeBase = async (code) => {
    closeSheet()
    if (code === settings.baseCurrency) return
    const ok = await confirm({
      title: `Switch to ${currencyInfo(code).name}?`,
      message: 'Totals and existing entries will be re-priced using current exchange rates.',
      confirmLabel: 'Switch',
    })
    if (!ok) return
    const previous = settings.baseCurrency
    updateSettings({ baseCurrency: code, rateOverrides: {} })
    try {
      await ensureRates({ force: true })
      rebaseTransactions()
      showToast(`Base currency is now ${code}`)
    } catch {
      updateSettings({ baseCurrency: previous })
      showError('Connect to the internet to change base currency')
    }
  }

  const exportData = (kind) => async (range) => {
    closeSheet()
    const period = range === 'month' ? periodRange({ kind: 'month' }, settings.cycleStartDay) : { start: 0, end: Infinity, label: 'All time' }
    runExport(kind, { range: period, label: period.label })
  }

  const restore = async (file) => {
    if (!file) return
    try {
      const { readBackup } = await import('../lib/exporters')
      const backup = await readBackup(file)
      const ok = await confirm({
        title: `Restore ${backup.transactions.length} entries?`,
        message: 'Entries and categories from the backup will be added. Matching entries are overwritten.',
        confirmLabel: 'Restore',
      })
      if (!ok) return
      useDataStore.getState().importBackup(backup)
      showToast('Backup restored')
    } catch (err) {
      showError(err.message)
    } finally {
      fileRef.current.value = ''
    }
  }

  const erase = async () => {
    const first = await confirm({
      title: 'Erase all data?',
      message: 'Every entry, budget and custom category will be deleted on all your devices.',
      confirmLabel: 'Erase',
      destructive: true,
    })
    if (!first) return
    const second = await confirm({
      title: 'Are you absolutely sure?',
      message: 'This cannot be undone. Consider exporting a backup first.',
      confirmLabel: 'Erase everything',
      destructive: true,
    })
    if (!second) return
    useDataStore.getState().eraseAll()
    showToast('All data erased')
  }

  return (
    <div className="scroll-area flex-1 px-gutter pb-[calc(env(safe-area-inset-bottom)+40px)]">
      <AccountSection />

      <QuickLoggingSection />

      <Section title="Currency">
        <Row title="Currency" value={`${base.symbol} ${base.name}`} onClick={() => setSheet('currency')} />
        <Row title="Exchange rates" subtitle="Live rates with manual overrides" onClick={() => setSheet('rates')} />
      </Section>

      <SecuritySection />

      <Section title="Budget">
        <Row title="Monthly Budget" value={total ? formatMoney(total.amount, settings.baseCurrency) : 'Not set'} onClick={() => setSheet('budget')} />
        <Row title="Category budgets" value={catBudgets ? `${catBudgets} set` : 'None'} onClick={() => setSheet('catBudgets')} />
        <Row
          title="Cycle starts on"
          subtitle="Budget and monthly totals reset on this day"
          value={ordinal(settings.cycleStartDay)}
          onClick={() => setSheet('cycle')}
        />
      </Section>

      <CategoriesSection />

      <Section title="Data">
        <Row title="Export to Excel" value={busy === 'xlsx' ? 'Preparing…' : null} onClick={() => setSheet('xlsx')} />
        <Row title="Export CSV" value={busy === 'csv' ? 'Preparing…' : null} onClick={() => setSheet('csv')} />
        <Row title="Back up (JSON)" subtitle="Everything, for restoring later" onClick={() => runExport('backup')} />
        <Row title="Restore from backup" onClick={() => fileRef.current.click()} />
        <Row title="Erase all data" destructive chevron={false} onClick={erase} />
        <input ref={fileRef} type="file" accept="application/json,.json" className="hidden" onChange={(e) => restore(e.target.files[0])} />
      </Section>

      <SyncSection />

      <p className="mt-10 text-center text-footnote text-faint">Expy · everything unlocked</p>

      <CurrencySheet open={sheet === 'currency'} value={settings.baseCurrency} title="Base currency" onSelect={changeBase} onClose={closeSheet} />
      <ExchangeRatesSheet open={sheet === 'rates'} onClose={closeSheet} />
      <AmountSheet
        open={sheet === 'budget'}
        title="Monthly budget"
        hint="Spending across all categories per cycle."
        currency={settings.baseCurrency}
        value={total?.amount ?? 0}
        onSave={(v) => setBudget(null, v)}
        onClose={closeSheet}
      />
      <CategoryBudgetsSheet open={sheet === 'catBudgets'} onClose={closeSheet} />
      <OptionSheet
        open={sheet === 'cycle'}
        title="Cycle starts on"
        value={settings.cycleStartDay}
        options={Array.from({ length: 28 }, (_, i) => ({ value: i + 1, label: `${ordinal(i + 1)} of the month` }))}
        onSelect={(d) => updateSettings({ cycleStartDay: d })}
        onClose={closeSheet}
      />
      {['xlsx', 'csv'].map((kind) => (
        <OptionSheet
          key={kind}
          open={sheet === kind}
          title={kind === 'xlsx' ? 'Export to Excel' : 'Export CSV'}
          options={[
            { value: 'month', label: 'Current cycle', subtitle: periodRange({ kind: 'month' }, settings.cycleStartDay).label },
            { value: 'all', label: 'All time' },
          ]}
          onSelect={exportData(kind)}
          onClose={closeSheet}
        />
      ))}
    </div>
  )
}
