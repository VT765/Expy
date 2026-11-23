// Reads ?amount=&cat=&type=&note= (from the "Log Expense" home-screen
// shortcut or a link) once, then strips it from the URL.
export function consumePrefill() {
  const params = new URLSearchParams(window.location.search)
  if (![...params.keys()].length) return null
  const out = {
    amount: params.get('amount'),
    cat: params.get('cat'),
    type: params.get('type'),
    note: params.get('note'),
  }
  window.history.replaceState(null, '', window.location.pathname)
  return out
}

export function sanitizeAmount(raw) {
  const n = parseFloat(String(raw ?? '').replace(/[^0-9.]/g, ''))
  if (!(n > 0)) return ''
  const fixed = (Math.round(n * 100) / 100).toString()
  return fixed.length > 12 ? '' : fixed
}
