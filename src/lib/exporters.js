import { currencySymbol } from './currencies'
import { toDateInput } from './dates'
import { formatTime } from './format'
import { inRange } from './periods'
import { backupSchema } from '../../shared/schemas'

// ---- Sharing ----------------------------------------------------------------

export class ShareNeedsGesture extends Error {}

// Opens the iOS share sheet with the file, falling back to a download.
// iOS needs a fresh user gesture for share(); when a slow export consumed it,
// we throw ShareNeedsGesture so the caller can offer a "Share" button.
export async function shareOrDownload(blob, filename) {
  const file = new File([blob], filename, { type: blob.type })
  if (navigator.canShare?.({ files: [file] })) {
    try {
      await navigator.share({ files: [file], title: filename })
      return 'shared'
    } catch (err) {
      if (err.name === 'AbortError') return 'cancelled'
      if (err.name === 'NotAllowedError') throw Object.assign(new ShareNeedsGesture('Tap Share to continue'), { file })
    }
  }
  const url = URL.createObjectURL(blob)
  const a = Object.assign(document.createElement('a'), { href: url, download: filename })
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 10_000)
  return 'downloaded'
}

export const shareFile = (file) => navigator.share({ files: [file], title: file.name })

// ---- Shared helpers ---------------------------------------------------------

const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')

export function exportRows(transactions, range, getCategory) {
  return transactions
    .filter((t) => !t.deletedAt && inRange(t, range))
    .sort((a, b) => a.date - b.date)
    .map((t) => ({
      date: t.date,
      time: formatTime(t.date),
      type: t.type === 'credit' ? 'Credit' : 'Expense',
      category: getCategory(t.categoryId).name,
      note: t.note,
      amount: t.amount,
      currency: t.currency,
      amountInBase: t.amountInBase,
    }))
}

// ---- CSV --------------------------------------------------------------------

export function buildCsv(rows, baseCurrency) {
  const esc = (v) => {
    const s = String(v ?? '')
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
  }
  const header = ['Date', 'Time', 'Type', 'Category', 'Note', 'Amount', 'Currency', `Amount (${baseCurrency})`]
  const lines = rows.map((r) =>
    [toDateInput(r.date), r.time, r.type, r.category, r.note, r.amount, r.currency, r.amountInBase].map(esc).join(','),
  )
  // BOM so Excel opens UTF-8 (₹, emoji) correctly.
  return new Blob(['﻿' + [header.join(','), ...lines].join('\n')], { type: 'text/csv;charset=utf-8' })
}

export const csvFilename = (label) => `expy-${slug(label)}.csv`

// ---- JSON backup ------------------------------------------------------------

export function buildBackup({ transactions, categories, budgets, settings }) {
  const data = { app: 'expy', version: 1, exportedAt: Date.now(), transactions, categories, budgets, settings }
  return new Blob([JSON.stringify(data)], { type: 'application/json' })
}

// Parses and validates a backup file. Throws a readable Error on failure.
export async function readBackup(file) {
  let json
  try {
    json = JSON.parse(await file.text())
  } catch {
    throw new Error('That file is not valid JSON')
  }
  const parsed = backupSchema.safeParse(json)
  if (!parsed.success) {
    const issue = parsed.error.issues[0]
    throw new Error(`Invalid backup: ${issue.path.join('.') || 'file'} – ${issue.message}`)
  }
  return parsed.data
}

// ---- Excel ------------------------------------------------------------------

// Indian digit grouping (12,34,567.00) for INR; standard grouping otherwise.
function moneyFormat(currency) {
  const sym = currencySymbol(currency).replace(/"/g, '')
  if (currency === 'INR') return `[>=10000000]"${sym}"##\\,##\\,##\\,##0.00;[>=100000]"${sym}"##\\,##\\,##0.00;"${sym}"#,##0.00`
  return `"${sym}"#,##0.00`
}

// Excel stores dates as UTC serials; pass the local calendar day as UTC midnight.
const excelDay = (ts) => {
  const d = new Date(ts)
  return new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
}

const HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF000000' } }
const HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' } }
const TOTAL_FONT = { bold: true }

function styleHeader(ws) {
  const row = ws.getRow(1)
  row.font = HEADER_FONT
  row.fill = HEADER_FILL
  row.height = 22
  row.alignment = { vertical: 'middle' }
  ws.views = [{ state: 'frozen', ySplit: 1 }]
}

export async function buildWorkbook({ rows, label, range, baseCurrency, getCategoryNames }) {
  const { default: ExcelJS } = await import('exceljs')
  const wb = new ExcelJS.Workbook()
  wb.creator = 'Expy'
  wb.created = new Date()
  // Cached results are written for previews; ask Excel/Numbers to recalc anyway.
  wb.calcProperties.fullCalcOnLoad = true
  const money = moneyFormat(baseCurrency)
  const n = rows.length
  const last = n + 1 // last data row on Transactions
  const T = (col) => `Transactions!$${col}$2:$${col}$${Math.max(2, last)}`

  // Transactions
  const tx = wb.addWorksheet('Transactions')
  tx.columns = [
    { header: 'Date', key: 'date', width: 13, style: { numFmt: 'dd-mmm-yyyy' } },
    { header: 'Time', key: 'time', width: 10 },
    { header: 'Type', key: 'type', width: 10 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Note', key: 'note', width: 36 },
    { header: 'Amount', key: 'amount', width: 13, style: { numFmt: '#,##0.00' } },
    { header: 'Currency', key: 'currency', width: 10 },
    { header: `Amount (${baseCurrency})`, key: 'amountInBase', width: 16, style: { numFmt: money } },
  ]
  rows.forEach((r) => tx.addRow({ ...r, date: excelDay(r.date) }))
  styleHeader(tx)
  tx.autoFilter = { from: 'A1', to: `H${Math.max(1, last)}` }

  const spent = rows.filter((r) => r.type === 'Expense').reduce((s, r) => s + r.amountInBase, 0)
  const credit = rows.filter((r) => r.type === 'Credit').reduce((s, r) => s + r.amountInBase, 0)
  const days = Number.isFinite(range.end)
    ? Math.max(1, Math.round((Math.min(range.end, Date.now()) - range.start) / 86400000))
    : Math.max(1, n ? Math.round((rows[n - 1].date - rows[0].date) / 86400000) + 1 : 1)

  // Summary (formulas carry cached results so previews show values)
  const sum = wb.addWorksheet('Summary')
  sum.columns = [
    { header: 'Metric', key: 'k', width: 22 },
    { header: 'Value', key: 'v', width: 20 },
  ]
  sum.addRows([
    ['Period', label],
    ['Generated', new Date().toLocaleString('en-IN')],
    ['Total expenses', { formula: `SUMIFS(${T('H')},${T('C')},"Expense")`, result: spent }],
    ['Total credits', { formula: `SUMIFS(${T('H')},${T('C')},"Credit")`, result: credit }],
    ['Net spent', { formula: 'B4-B5', result: spent - credit }],
    ['Entries', { formula: `COUNTA(${T('A')})`, result: n }],
    ['Days', days],
    ['Average per day', { formula: 'B4/B8', result: spent / days }],
  ])
  ;[4, 5, 6, 9].forEach((r) => (sum.getCell(`B${r}`).numFmt = money))
  styleHeader(sum)

  // By Category
  const byCat = wb.addWorksheet('By Category')
  byCat.columns = [
    { header: 'Category', key: 'c', width: 20 },
    { header: 'Expenses', key: 'e', width: 16, style: { numFmt: money } },
    { header: '% of total', key: 'p', width: 12, style: { numFmt: '0.0%' } },
    { header: 'Entries', key: 'n', width: 10 },
  ]
  const names = getCategoryNames(rows)
  const catTotals = names.map((name) => rows.filter((r) => r.type === 'Expense' && r.category === name).reduce((s, r) => s + r.amountInBase, 0))
  const catEnd = names.length + 1
  names.forEach((name, i) => {
    const r = i + 2
    byCat.addRow([
      name,
      { formula: `SUMIFS(${T('H')},${T('C')},"Expense",${T('D')},A${r})`, result: catTotals[i] },
      { formula: `IF($B$${catEnd + 1}=0,0,B${r}/$B$${catEnd + 1})`, result: spent ? catTotals[i] / spent : 0 },
      { formula: `COUNTIFS(${T('C')},"Expense",${T('D')},A${r})`, result: rows.filter((x) => x.type === 'Expense' && x.category === name).length },
    ])
  })
  const catTotalRow = byCat.addRow(['Total', { formula: `SUM(B2:B${catEnd})`, result: spent }, { formula: `SUM(C2:C${catEnd})`, result: spent ? 1 : 0 }, { formula: `SUM(D2:D${catEnd})`, result: rows.filter((x) => x.type === 'Expense').length }])
  catTotalRow.font = TOTAL_FONT
  styleHeader(byCat)

  // Daily (≤ 92 days) or Monthly
  const span = n ? rows[n - 1].date - rows[0].date : 0
  const daily = span <= 92 * 86400000
  const per = wb.addWorksheet(daily ? 'Daily' : 'Monthly')
  per.columns = [
    { header: daily ? 'Date' : 'Month', key: 'd', width: 14, style: { numFmt: daily ? 'dd-mmm-yyyy' : 'mmm yyyy' } },
    { header: 'Expenses', key: 'e', width: 16, style: { numFmt: money } },
    { header: 'Credits', key: 'c', width: 16, style: { numFmt: money } },
    { header: 'Net', key: 'n', width: 16, style: { numFmt: money } },
  ]
  const keyOf = (ts) => {
    const d = new Date(ts)
    return daily ? Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) : Date.UTC(d.getFullYear(), d.getMonth(), 1)
  }
  const groups = new Map()
  for (const r of rows) {
    const k = keyOf(r.date)
    const g = groups.get(k) ?? { e: 0, c: 0 }
    if (r.type === 'Expense') g.e += r.amountInBase
    else g.c += r.amountInBase
    groups.set(k, g)
  }
  const keys = [...groups.keys()].sort((a, b) => a - b)
  keys.forEach((k, i) => {
    const r = i + 2
    const g = groups.get(k)
    const match = daily ? `${T('A')},A${r}` : `${T('A')},">="&A${r},${T('A')},"<"&EDATE(A${r},1)`
    per.addRow([
      new Date(k),
      { formula: `SUMIFS(${T('H')},${T('C')},"Expense",${match})`, result: g.e },
      { formula: `SUMIFS(${T('H')},${T('C')},"Credit",${match})`, result: g.c },
      { formula: `B${r}-C${r}`, result: g.e - g.c },
    ])
  })
  const pEnd = keys.length + 1
  const pTotal = per.addRow([
    'Total',
    { formula: `SUM(B2:B${pEnd})`, result: spent },
    { formula: `SUM(C2:C${pEnd})`, result: credit },
    { formula: `SUM(D2:D${pEnd})`, result: spent - credit },
  ])
  pTotal.font = TOTAL_FONT
  styleHeader(per)

  const buffer = await wb.xlsx.writeBuffer()
  return new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
}

export const xlsxFilename = (label) => `expy-${slug(label)}.xlsx`
