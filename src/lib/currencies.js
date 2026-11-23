// Currencies supported by frankfurter.app, plus INR as the default base.
export const CURRENCIES = [
  ['INR', 'Indian Rupee', '₹'],
  ['USD', 'US Dollar', '$'],
  ['EUR', 'Euro', '€'],
  ['GBP', 'British Pound', '£'],
  ['AED', 'UAE Dirham', 'AED'],
  ['AUD', 'Australian Dollar', 'A$'],
  ['CAD', 'Canadian Dollar', 'C$'],
  ['CHF', 'Swiss Franc', 'CHF'],
  ['CNY', 'Chinese Yuan', '¥'],
  ['HKD', 'Hong Kong Dollar', 'HK$'],
  ['IDR', 'Indonesian Rupiah', 'Rp'],
  ['JPY', 'Japanese Yen', '¥'],
  ['KRW', 'South Korean Won', '₩'],
  ['MYR', 'Malaysian Ringgit', 'RM'],
  ['NZD', 'New Zealand Dollar', 'NZ$'],
  ['PHP', 'Philippine Peso', '₱'],
  ['SGD', 'Singapore Dollar', 'S$'],
  ['THB', 'Thai Baht', '฿'],
  ['TRY', 'Turkish Lira', '₺'],
  ['ZAR', 'South African Rand', 'R'],
].map(([code, name, symbol]) => ({ code, name, symbol }))

const byCode = Object.fromEntries(CURRENCIES.map((c) => [c.code, c]))

export const currencyInfo = (code) => byCode[code] ?? { code, name: code, symbol: code }
export const currencySymbol = (code) => currencyInfo(code).symbol
