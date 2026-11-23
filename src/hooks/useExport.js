import { useState } from 'react'
import { useDataStore } from '../store/useDataStore'
import { useUIStore } from '../store/useUIStore'
import { useCategories } from './useCategories'

// Runs an export ('xlsx' | 'csv' | 'backup'), lazy-loading the exporter code
// (and ExcelJS) on first use, then opens the share sheet.
export function useExport() {
  const [busy, setBusy] = useState(null)
  const { get: getCategory, list } = useCategories()

  const run = async (kind, { range = { start: 0, end: Infinity }, label = 'All time' } = {}) => {
    const { showToast, showError } = useUIStore.getState()
    setBusy(kind)
    try {
      const ex = await import('../lib/exporters')
      const s = useDataStore.getState()
      let blob
      let name
      if (kind === 'backup') {
        blob = ex.buildBackup(s)
        name = `expy-backup-${new Date().toISOString().slice(0, 10)}.json`
      } else {
        const rows = ex.exportRows(s.transactions, range, getCategory)
        if (!rows.length) {
          showError('Nothing to export in this period')
          return
        }
        if (kind === 'csv') {
          blob = ex.buildCsv(rows, s.settings.baseCurrency)
          name = ex.csvFilename(label)
        } else {
          const order = list.map((c) => c.name)
          blob = await ex.buildWorkbook({
            rows,
            label,
            range,
            baseCurrency: s.settings.baseCurrency,
            getCategoryNames: (rs) => {
              const used = new Set(rs.map((r) => r.category))
              return [...order.filter((n) => used.has(n)), ...[...used].filter((n) => !order.includes(n))]
            },
          })
          name = ex.xlsxFilename(label)
        }
      }
      try {
        const result = await ex.shareOrDownload(blob, name)
        if (result === 'downloaded') showToast(`Saved ${name}`)
      } catch (err) {
        if (err instanceof ex.ShareNeedsGesture) {
          showToast('Export ready', { action: { label: 'Share', onClick: () => ex.shareFile(err.file).catch(() => {}) }, duration: 8000 })
        } else throw err
      }
    } catch (err) {
      console.warn(err)
      showError(err.message || 'Export failed')
    } finally {
      setBusy(null)
    }
  }

  return { run, busy }
}
