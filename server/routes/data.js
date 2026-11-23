import { COLLECTIONS, settingsSchema } from '../../shared/schemas.js'
import { DEFAULT_SETTINGS, mergeWithDefaults } from '../../shared/defaults.js'
import { HttpError } from '../http.js'

// Documents are stored with _id = id plus a server `syncedAt` timestamp that
// drives incremental pulls. Writes are last-write-wins on `updatedAt`.

const SETTINGS_ID = 'app'
const strip = ({ _id, syncedAt, ...doc }) => doc

export function validate(collection, doc) {
  const schema = COLLECTIONS[collection]
  if (!schema) throw new HttpError(404, `Unknown collection ${collection}`)
  const parsed = schema.safeParse(doc)
  if (!parsed.success) {
    const i = parsed.error.issues[0]
    throw new HttpError(400, `Invalid ${collection}: ${i.path.join('.')} ${i.message}`)
  }
  return parsed.data
}

// Upserts many docs with LWW. Returns counts.
export async function upsertMany(db, collection, docs, now = Date.now()) {
  if (!docs.length) return { applied: 0, stale: 0 }
  const ops = docs.map((doc) => ({
    updateOne: {
      filter: { _id: doc.id, $or: [{ updatedAt: { $lte: doc.updatedAt } }, { updatedAt: { $exists: false } }] },
      update: { $set: { ...doc, syncedAt: now } },
      upsert: true,
    },
  }))
  try {
    const r = await db.collection(collection).bulkWrite(ops, { ordered: false })
    return { applied: r.upsertedCount + r.matchedCount, stale: 0 }
  } catch (e) {
    // Duplicate-key errors mean the stored doc is newer: the incoming write lost LWW.
    const errors = e.writeErrors ?? []
    if (errors.length && errors.every((w) => w.code === 11000)) {
      return { applied: docs.length - errors.length, stale: errors.length }
    }
    throw e
  }
}

const filterFor = (collection, extra = {}) => (collection === 'settings' ? { _id: SETTINGS_ID, ...extra } : extra)

export async function listDocs(db, collection, { since } = {}) {
  const q = filterFor(collection, since != null ? { syncedAt: { $gt: Number(since) } } : {})
  const docs = (await db.collection(collection).find(q).toArray()).map(strip)
  return docs
}

// REST: /api/:collection[/:id]
export async function crud(db, req, collection, id, body) {
  if (!COLLECTIONS[collection]) throw new HttpError(404, 'Not found')
  const col = db.collection(collection)
  const now = Date.now()
  if (collection === 'settings' && id && id !== SETTINGS_ID) throw new HttpError(404, 'Not found')

  switch (req.method) {
    case 'GET': {
      if (!id) {
        const since = req.query.since
        const includeDeleted = req.query.includeDeleted === '1' || since != null
        const docs = await listDocs(db, collection, { since })
        return { items: includeDeleted ? docs : docs.filter((d) => !d.deletedAt) }
      }
      const doc = await col.findOne(filterFor(collection, { _id: id }))
      if (!doc) throw new HttpError(404, 'Not found')
      return strip(doc)
    }
    case 'POST':
    case 'PUT': {
      const doc = validate(collection, { ...body, id: id ?? body.id, updatedAt: body.updatedAt ?? now })
      const r = await upsertMany(db, collection, [doc], now)
      if (r.stale) throw new HttpError(409, 'A newer version exists on the server')
      return doc
    }
    case 'DELETE': {
      if (!id || collection === 'settings') throw new HttpError(400, 'Specify an id')
      const r = await col.updateOne({ _id: id }, { $set: { deletedAt: now, updatedAt: now, syncedAt: now } })
      if (!r.matchedCount) throw new HttpError(404, 'Not found')
      return { id, deletedAt: now }
    }
    default:
      throw new HttpError(405, 'Method not allowed')
  }
}

// POST /api/sync — push local changes in one round trip.
export async function pushChanges(db, body) {
  const changes = body?.changes ?? {}
  const now = Date.now()
  const result = {}
  for (const collection of Object.keys(COLLECTIONS)) {
    const docs = Array.isArray(changes[collection]) ? changes[collection] : []
    if (docs.length > 2000) throw new HttpError(413, 'Too many changes in one request')
    const valid = []
    const rejected = []
    for (const d of docs) {
      const r = COLLECTIONS[collection].safeParse(d)
      if (r.success) valid.push(r.data)
      else rejected.push({ id: d?.id, error: r.error.issues[0]?.message })
    }
    result[collection] = { ...(await upsertMany(db, collection, valid, now)), rejected }
  }
  return result
}

// GET /api/sync?since= — everything changed after `since` (server time).
export async function pullChanges(db, since) {
  // Overlap by a second: tolerates clock skew between instances; merges are idempotent.
  const serverTime = Date.now() - 1000
  const s = Number(since) || 0
  const [transactions, categories, budgets, settings] = await Promise.all(
    ['transactions', 'categories', 'budgets', 'settings'].map((c) => listDocs(db, c, { since: s })),
  )
  return { serverTime, transactions, categories, budgets, settings: settings[0] ?? null }
}

export async function exportAll(db) {
  const [transactions, categories, budgets, settings] = await Promise.all(
    ['transactions', 'categories', 'budgets', 'settings'].map((c) => listDocs(db, c)),
  )
  const parsedSettings = settingsSchema.safeParse(settings[0] ?? DEFAULT_SETTINGS)
  return {
    app: 'expy',
    version: 1,
    exportedAt: Date.now(),
    transactions: transactions.filter((t) => !t.deletedAt),
    categories: mergeWithDefaults(categories).filter((c) => !c.deletedAt),
    budgets: budgets.filter((b) => !b.deletedAt),
    settings: parsedSettings.success ? parsedSettings.data : DEFAULT_SETTINGS,
  }
}
