import { MongoClient } from 'mongodb'

// One client per warm serverless instance, reused across invocations.
const g = globalThis
let indexesReady = null

export async function getDb() {
  if (!process.env.MONGODB_URI) throw Object.assign(new Error('MONGODB_URI is not set'), { status: 500 })
  if (!g.__expyMongo) {
    g.__expyMongo = new MongoClient(process.env.MONGODB_URI, {
      maxPoolSize: 5,
      serverSelectionTimeoutMS: 8000,
    }).connect()
  }
  const client = await g.__expyMongo
  const db = client.db(process.env.MONGODB_DB || 'expy')
  if (!indexesReady) indexesReady = ensureIndexes(db).catch((e) => ((indexesReady = null), Promise.reject(e)))
  await indexesReady
  return db
}

async function ensureIndexes(db) {
  await Promise.all([
    db.collection('transactions').createIndexes([
      { key: { date: -1 } },
      { key: { categoryId: 1 } },
      { key: { syncedAt: 1 } },
    ]),
    db.collection('categories').createIndexes([{ key: { syncedAt: 1 } }]),
    db.collection('budgets').createIndexes([{ key: { syncedAt: 1 } }, { key: { categoryId: 1 } }]),
    db.collection('settings').createIndexes([{ key: { syncedAt: 1 } }]),
    db.collection('ratelimits').createIndexes([{ key: { expiresAt: 1 }, expireAfterSeconds: 0 }]),
  ])
}
