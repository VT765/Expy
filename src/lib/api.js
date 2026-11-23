import { useSyncStore } from '../store/useSyncStore'

export class ApiError extends Error {
  constructor(status, message) {
    super(message)
    this.status = status
  }
}

// fetch wrapper for /api. Adds the JWT; a 401 drops the token (data stays on
// device and the outbox keeps waiting) so the login screen appears.
export async function api(path, { method = 'GET', body, auth = true, headers = {}, raw = false, timeout = 15000 } = {}) {
  const token = useSyncStore.getState().token
  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), timeout)
  let res
  try {
    res = await fetch(`/api/${path}`, {
      method,
      headers: {
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...(auth && token ? { Authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: ctrl.signal,
    })
  } catch (err) {
    throw new ApiError(0, err.name === 'AbortError' ? 'Server took too long to respond' : "Can't reach the server")
  } finally {
    clearTimeout(timer)
  }
  if (raw) return res
  const text = await res.text()
  let data
  try {
    data = text ? JSON.parse(text) : null
  } catch {
    data = null
  }
  if (!res.ok) {
    if (res.status === 401 && auth && token) useSyncStore.setState({ token: null })
    throw new ApiError(res.status, data?.error || (res.status === 404 ? 'API not found. Is the backend deployed?' : `Request failed (${res.status})`))
  }
  return data
}
