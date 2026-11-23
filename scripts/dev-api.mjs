// Local stand-in for Vercel Functions: serves api/index.js on :3001 with
// .env.local loaded. Vite proxies /api here (see vite.config.js).
import http from 'node:http'
import { readFileSync, existsSync } from 'node:fs'

for (const file of ['.env.local', '.env']) {
  if (!existsSync(file)) continue
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?(.*?)"?\s*$/)
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2]
  }
}

const { default: handler } = await import('../api/index.js')
const PORT = Number(process.env.API_PORT || 3001)

http
  .createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost')
    req.query = Object.fromEntries(url.searchParams)
    req.query.__path = url.pathname.replace(/^\/api\/?/, '')
    handler(req, res).catch((err) => {
      console.error(err)
      res.statusCode = 500
      res.end('Server error')
    })
  })
  .listen(PORT, () => console.log(`API ready on http://localhost:${PORT}/api`))
