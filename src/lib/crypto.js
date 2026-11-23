// PIN hashing with PBKDF2-SHA256 via Web Crypto. Only the salted hash is stored.

const ITERATIONS = 210_000
const enc = new TextEncoder()

export const toB64 = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf)))
export const fromB64 = (s) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))
export const toB64Url = (buf) => toB64(buf).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
export const fromB64Url = (s) => fromB64(s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4))

export const randomBytes = (n) => crypto.getRandomValues(new Uint8Array(n))

export async function hashPin(pin, saltB64, iterations = ITERATIONS) {
  const key = await crypto.subtle.importKey('raw', enc.encode(pin), 'PBKDF2', false, ['deriveBits'])
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt: fromB64(saltB64), iterations },
    key,
    256,
  )
  return toB64(bits)
}

export async function createPinRecord(pin) {
  const salt = toB64(randomBytes(16))
  return { pinHash: await hashPin(pin, salt), salt, iterations: ITERATIONS }
}

// Constant-time string comparison.
export function safeEqual(a, b) {
  if (a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return diff === 0
}
