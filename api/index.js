// Single serverless entry point (keeps the deployment under Vercel Hobby's
// function limit). vercel.json rewrites /api/* here with ?__path=<rest>.
import { HttpError, applyCors, readBody, sendJson, sendText } from '../server/http.js'
import { getDb } from '../server/db.js'
import { rateLimit } from '../server/rateLimit.js'
import { changePassword, getAuthDoc, login, regenerateApiKey, requireApiKey, requireJwt, setup } from '../server/auth.js'
import { crud, exportAll, pullChanges, pushChanges } from '../server/routes/data.js'
import { categoriesForShortcut, quickAdd } from '../server/routes/shortcut.js'

const AUTH_LIMIT = { limit: 10, windowMs: 15 * 60_000 }
const SHORTCUT_LIMIT = { limit: 30, windowMs: 60_000 }

function routePath(req) {
  const q = req.query?.__path
  if (q) return Array.isArray(q) ? q.join('/') : q
  return new URL(req.url, 'http://x').pathname.replace(/^\/api\/?/, '')
}

export default async function handler(req, res) {
  if (!req.query) req.query = Object.fromEntries(new URL(req.url, 'http://x').searchParams)
  if (!applyCors(req, res)) return sendJson(res, 403, { error: 'Origin not allowed' })
  if (req.method === 'OPTIONS') {
    res.statusCode = 204
    return res.end()
  }

  const path = routePath(req).replace(/\/+$/, '')
  const [head, second, third] = path.split('/')
  const textReply = path === 'quick-add' || head === 'shortcut'

  try {
    const db = await getDb()
    const body = ['POST', 'PUT'].includes(req.method) ? await readBody(req) : {}
    const method = req.method

    // --- public auth -------------------------------------------------------
    if (head === 'auth') {
      if (second === 'status' && method === 'GET') return sendJson(res, 200, { configured: Boolean(await getAuthDoc(db)) })
      if (second === 'setup' && method === 'POST') {
        await rateLimit(db, req, { name: 'auth', ...AUTH_LIMIT })
        return sendJson(res, 201, await setup(db, body))
      }
      if (second === 'login' && method === 'POST') {
        await rateLimit(db, req, { name: 'auth', ...AUTH_LIMIT })
        return sendJson(res, 200, await login(db, body))
      }
      if (second === 'password' && method === 'POST') {
        await rateLimit(db, req, { name: 'auth', ...AUTH_LIMIT })
        await requireJwt(db, req)
        return sendJson(res, 200, await changePassword(db, body))
      }
      throw new HttpError(404, 'Not found')
    }

    // --- iOS Shortcuts (x-api-key) -------------------------------------------
    if (path === 'quick-add' && method === 'POST') {
      await rateLimit(db, req, { name: 'shortcut', ...SHORTCUT_LIMIT })
      await requireApiKey(db, req)
      const { id, text } = await quickAdd(db, body)
      res.setHeader('X-Entry-Id', id)
      return sendText(res, 201, text)
    }
    if (head === 'shortcut' && second === 'categories' && method === 'GET') {
      await rateLimit(db, req, { name: 'shortcut', ...SHORTCUT_LIMIT })
      await requireApiKey(db, req)
      return sendJson(res, 200, await categoriesForShortcut(db))
    }

    // --- everything else requires the JWT -----------------------------------
    const auth = await requireJwt(db, req)

    if (head === 'shortcut' && second === 'key') {
      if (method === 'GET' && !third) return sendJson(res, 200, { apiKey: auth.apiKey || process.env.API_KEY })
      if (method === 'POST' && third === 'regenerate') return sendJson(res, 200, await regenerateApiKey(db))
      throw new HttpError(404, 'Not found')
    }
    if (head === 'sync') {
      if (method === 'GET') return sendJson(res, 200, await pullChanges(db, req.query.since))
      if (method === 'POST') return sendJson(res, 200, await pushChanges(db, body))
      throw new HttpError(405, 'Method not allowed')
    }
    if (head === 'export' && method === 'GET') {
      res.setHeader('Content-Disposition', `attachment; filename="expy-export-${new Date().toISOString().slice(0, 10)}.json"`)
      return sendJson(res, 200, await exportAll(db))
    }
    if (['transactions', 'categories', 'budgets', 'settings'].includes(head)) {
      return sendJson(res, 200, await crud(db, req, head, second, body))
    }
    throw new HttpError(404, 'Not found')
  } catch (err) {
    const status = err.status ?? (err.name === 'ZodError' ? 400 : 500)
    const message = err.name === 'ZodError' ? err.issues?.[0]?.message ?? 'Invalid request' : status === 500 ? 'Server error' : err.message
    if (status === 500) console.error(err)
    if (err.extra?.retryAfter) res.setHeader('Retry-After', String(err.extra.retryAfter))
    return textReply ? sendText(res, status, `Error: ${message}`) : sendJson(res, status, { error: message })
  }
}
