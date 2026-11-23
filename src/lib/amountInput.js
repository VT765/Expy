// Pure helpers for the numpad amount string ("1234.5").

const MAX_INT_DIGITS = 9

export function pressKey(current, key) {
  if (key === '.') {
    if (current.includes('.')) return current
    return (current || '0') + '.'
  }
  const [int, dec] = current.split('.')
  if (dec !== undefined) return dec.length >= 2 ? current : current + key
  if (int === '0' || int === '') return key
  if (int.length >= MAX_INT_DIGITS) return current
  return current + key
}

export const backspace = (current) => current.slice(0, -1)

// "1234567.5" → "12,34,567.5" (keeps the trailing "." / zeros as typed)
export function displayAmount(current) {
  if (!current) return '0'
  const [int, dec] = current.split('.')
  const grouped = new Intl.NumberFormat('en-IN').format(Number(int || 0))
  return dec === undefined ? grouped : `${grouped}.${dec}`
}

export const parseAmount = (current) => Math.round((parseFloat(current) || 0) * 100) / 100
