import { randomUUID } from 'node:crypto'
import { quickAddSchema } from '../../shared/schemas.js'
import { DEFAULT_SETTINGS, OTHER_CATEGORY_ID, mergeWithDefaults } from '../../shared/defaults.js'
import { HttpError } from '../http.js'
import { listDocs, upsertMany } from './data.js'

// Endpoints for iOS Shortcuts (x-api-key auth, plain-text responses).

const normalize = (s) =>
  String(s ?? '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N} ]/gu, '')
    .replace(/\s+/g, ' ')
    .trim()

async function activeCategories(db) {
  const stored = await listDocs(db, 'categories')
  return mergeWithDefaults(stored)
    .filter((c) => !c.deletedAt)
    .sort((a, b) => a.order - b.order)
}

// GET /api/shortcut/categories → ["🍔 Food", "🚕 Transport", …] for "Choose from List".
export async function categoriesForShortcut(db) {
  return (await activeCategories(db)).map((c) => `${c.emoji} ${c.name}`)
}

const money = (amount, currency) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency,
    currencyDisplay: 'narrowSymbol',
    minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
    maximumFractionDigits: 2,
  }).format(amount)

async function toBase(amount, currency, settings) {
  if (currency === settings.baseCurrency) return amount
  const override = settings.rateOverrides?.[currency]
  if (override) return amount * override
  try {
    const r = await fetch(`https://api.frankfurter.dev/v1/latest?base=${currency}&symbols=${settings.baseCurrency}`)
    const data = await r.json()
    const rate = data?.rates?.[settings.baseCurrency]
    if (rate > 0) return amount * rate
  } catch {
    /* fall through */
  }
  throw new HttpError(502, `Couldn't get a ${currency} rate right now`)
}

function parseDate(value) {
  if (value == null || value === '') return Date.now()
  const n = typeof value === 'number' ? value : Number(value)
  if (Number.isFinite(n) && n > 1e11) return n // epoch ms
  if (Number.isFinite(n) && n > 1e8) return n * 1000 // epoch s
  const t = Date.parse(String(value))
  return Number.isFinite(t) ? t : Date.now()
}

// POST /api/quick-add { amount, category, type, note, date? } → "Saved ₹80 · Food"
export async function quickAdd(db, body) {
  const parsed = quickAddSchema.safeParse(body)
  if (!parsed.success) {
    const i = parsed.error.issues[0]
    throw new HttpError(400, `Invalid ${i.path.join('.') || 'request'}: ${i.message}`)
  }
  const { amount, category, type, note, date, currency: cur } = parsed.data
  const [cats, settingsDoc] = await Promise.all([activeCategories(db), db.collection('settings').findOne({ _id: 'app' })])
  const settings = { ...DEFAULT_SETTINGS, ...(settingsDoc ?? {}) }
  const wanted = normalize(category)
  const match =
    (wanted && cats.find((c) => normalize(c.name) === wanted)) ||
    (wanted && cats.find((c) => normalize(`${c.emoji} ${c.name}`) === wanted)) ||
    cats.find((c) => c.id === OTHER_CATEGORY_ID) ||
    cats[0]

  const currency = cur || settings.baseCurrency
  const rounded = Math.round(amount * 100) / 100
  const now = Date.now()
  const tx = {
    id: `tx_${randomUUID()}`,
    type,
    amount: rounded,
    currency,
    amountInBase: Math.round((await toBase(rounded, currency, settings)) * 100) / 100,
    categoryId: match.id,
    note: note.trim(),
    date: parseDate(date),
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
  }
  await upsertMany(db, 'transactions', [tx], now)
  const sign = type === 'credit' ? '+' : ''
  return { id: tx.id, text: `Saved ${sign}${money(rounded, currency)} · ${match.name}${type === 'credit' ? ' (credit)' : ''}` }
}
