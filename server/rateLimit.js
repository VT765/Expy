import { HttpError, clientIp } from './http.js'

// Fixed-window limiter stored in Mongo so it holds across serverless instances.
export async function rateLimit(db, req, { name, limit, windowMs }) {
  const window = Math.floor(Date.now() / windowMs)
  const _id = `${name}:${clientIp(req)}:${window}`
  const bump = () =>
    db.collection('ratelimits').findOneAndUpdate(
      { _id },
      { $inc: { count: 1 }, $setOnInsert: { expiresAt: new Date((window + 1) * windowMs) } },
      { upsert: true, returnDocument: 'after' },
    )
  let doc
  try {
    doc = await bump()
  } catch (e) {
    if (e.code !== 11000) throw e
    doc = await bump() // lost an upsert race; the doc exists now
  }
  if ((doc?.count ?? 1) > limit) {
    const retry = Math.ceil(((window + 1) * windowMs - Date.now()) / 1000)
    throw new HttpError(429, `Too many requests. Try again in ${retry}s.`, { retryAfter: retry })
  }
}
