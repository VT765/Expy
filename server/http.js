export class HttpError extends Error {
  constructor(status, message, extra) {
    super(message)
    this.status = status
    this.extra = extra
  }
}

export function sendJson(res, status, body) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json; charset=utf-8')
  res.setHeader('Cache-Control', 'no-store')
  res.end(JSON.stringify(body))
}

export function sendText(res, status, text) {
  res.statusCode = status
  res.setHeader('Content-Type', 'text/plain; charset=utf-8')
  res.setHeader('Cache-Control', 'no-store')
  res.end(text)
}

export async function readBody(req) {
  if (req.body !== undefined && req.body !== null) {
    if (typeof req.body === 'string') return parse(req.body)
    if (Buffer.isBuffer(req.body)) return parse(req.body.toString('utf8'))
    return req.body
  }
  const chunks = []
  let size = 0
  for await (const c of req) {
    size += c.length
    if (size > 5 * 1024 * 1024) throw new HttpError(413, 'Body too large')
    chunks.push(c)
  }
  return parse(Buffer.concat(chunks).toString('utf8'))
}

function parse(text) {
  if (!text) return {}
  try {
    return JSON.parse(text)
  } catch {
    // iOS Shortcuts may send form-encoded bodies.
    return Object.fromEntries(new URLSearchParams(text))
  }
}

export const clientIp = (req) =>
  String(req.headers['x-forwarded-for'] || req.socket?.remoteAddress || 'unknown')
    .split(',')[0]
    .trim()

// Same-host requests and ALLOWED_ORIGINS get CORS headers; any other browser
// Origin is rejected. Requests without an Origin (iOS Shortcuts, curl) pass.
export function applyCors(req, res) {
  const origin = req.headers.origin
  if (!origin) return true
  const allowed = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
  let sameHost = false
  try {
    sameHost = new URL(origin).host === req.headers.host
  } catch {
    /* malformed origin */
  }
  if (!sameHost && !allowed.includes(origin)) return false
  res.setHeader('Access-Control-Allow-Origin', origin)
  res.setHeader('Vary', 'Origin')
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization,x-api-key')
  res.setHeader('Access-Control-Expose-Headers', 'X-Entry-Id')
  res.setHeader('Access-Control-Max-Age', '600')
  return true
}
