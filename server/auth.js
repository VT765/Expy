import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { randomBytes, timingSafeEqual } from 'node:crypto'
import { z } from 'zod'
import { HttpError } from './http.js'

// The single user's credentials live in settings/_id:'auth' (never synced).
const AUTH_ID = 'auth'
const TOKEN_TTL = '30d'

const passwordSchema = z.string().min(8, 'Use at least 8 characters').max(200)

const secret = () => {
  const s = process.env.JWT_SECRET
  if (!s || s.length < 32) throw new HttpError(500, 'JWT_SECRET must be set (32+ chars)')
  return s
}

export const getAuthDoc = (db) => db.collection('settings').findOne({ _id: AUTH_ID })

export const safeEqual = (a, b) => {
  const x = Buffer.from(String(a))
  const y = Buffer.from(String(b))
  return x.length === y.length && timingSafeEqual(x, y)
}

const sign = (doc) => jwt.sign({ sub: 'owner', v: doc.tokenVersion }, secret(), { expiresIn: TOKEN_TTL })

export async function setup(db, body) {
  // First visitor sets the password; afterwards setup is closed for good.
  if (await getAuthDoc(db)) throw new HttpError(409, 'Already set up. Sign in instead.')
  const password = passwordSchema.parse(body.password)
  const doc = {
    _id: AUTH_ID,
    passwordHash: await bcrypt.hash(password, 12),
    tokenVersion: 1,
    apiKey: process.env.API_KEY || `expy_${randomBytes(24).toString('base64url')}`,
    createdAt: Date.now(),
  }
  try {
    await db.collection('settings').insertOne(doc)
  } catch (e) {
    if (e.code === 11000) throw new HttpError(409, 'Already set up. Sign in instead.')
    throw e
  }
  return { token: sign(doc) }
}

export async function login(db, body) {
  const doc = await getAuthDoc(db)
  if (!doc) throw new HttpError(404, 'Not set up yet')
  const ok = typeof body.password === 'string' && (await bcrypt.compare(body.password, doc.passwordHash))
  if (!ok) throw new HttpError(401, 'Wrong password')
  return { token: sign(doc) }
}

export async function changePassword(db, body) {
  const doc = await getAuthDoc(db)
  if (!(await bcrypt.compare(String(body.current ?? ''), doc.passwordHash))) throw new HttpError(401, 'Current password is wrong')
  const next = passwordSchema.parse(body.next)
  const tokenVersion = doc.tokenVersion + 1 // signs out every other device
  await db.collection('settings').updateOne({ _id: AUTH_ID }, { $set: { passwordHash: await bcrypt.hash(next, 12), tokenVersion } })
  return { token: sign({ ...doc, tokenVersion }) }
}

export async function requireJwt(db, req) {
  const header = req.headers.authorization || ''
  const token = header.startsWith('Bearer ') ? header.slice(7) : null
  if (!token) throw new HttpError(401, 'Sign in required')
  let payload
  try {
    payload = jwt.verify(token, secret())
  } catch {
    throw new HttpError(401, 'Session expired. Sign in again.')
  }
  const doc = await getAuthDoc(db)
  if (!doc || doc.tokenVersion !== payload.v) throw new HttpError(401, 'Session expired. Sign in again.')
  return doc
}

// Shortcut key: the stored key once set up, else the API_KEY env var.
export async function requireApiKey(db, req) {
  const key = req.headers['x-api-key']
  if (!key) throw new HttpError(401, 'Missing x-api-key header')
  const doc = await getAuthDoc(db)
  const expected = doc?.apiKey || process.env.API_KEY
  if (!expected || !safeEqual(key, expected)) throw new HttpError(401, 'Invalid API key')
}

export async function regenerateApiKey(db) {
  const apiKey = `expy_${randomBytes(24).toString('base64url')}`
  await db.collection('settings').updateOne({ _id: AUTH_ID }, { $set: { apiKey } })
  return { apiKey }
}
