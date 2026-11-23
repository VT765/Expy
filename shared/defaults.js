// Seed data shared by the client and the API. Stable ids keep devices from
// creating duplicate copies of the defaults.

export const OTHER_CATEGORY_ID = 'cat_other'

export const DEFAULT_CATEGORIES = [
  ['cat_food', 'Food', '🍔', '#FF6B6B'],
  ['cat_transport', 'Transport', '🚕', '#FFB340'],
  ['cat_shopping', 'Shopping', '🛍️', '#E8D25A'],
  ['cat_subscriptions', 'Subscriptions', '😎', '#FF7A59'],
  ['cat_bills', 'Bills', '🧾', '#8AB4F8'],
  ['cat_groceries', 'Groceries', '🛒', '#5FD38D'],
  ['cat_health', 'Health', '💊', '#FF5C8A'],
  ['cat_entertainment', 'Entertainment', '🎬', '#B48CFF'],
  ['cat_personal_care', 'Personal Care', '💇', '#FF9F7A'],
  ['cat_travel', 'Travel', '✈️', '#5AC8FA'],
  [OTHER_CATEGORY_ID, 'Other', '✨', '#9DB0C4'],
].map(([id, name, emoji, color], order) => ({
  id,
  name,
  emoji,
  color,
  order,
  updatedAt: 0,
  deletedAt: null,
}))

export const DEFAULT_SETTINGS = {
  id: 'app',
  baseCurrency: 'INR',
  cycleStartDay: 1,
  rateOverrides: {},
  updatedAt: 0,
}

// Merges stored categories over the defaults (by id), newest updatedAt wins.
export function mergeWithDefaults(stored = []) {
  const byId = new Map(DEFAULT_CATEGORIES.map((c) => [c.id, c]))
  for (const c of stored) {
    const cur = byId.get(c.id)
    if (!cur || (c.updatedAt ?? 0) >= (cur.updatedAt ?? 0)) byId.set(c.id, c)
  }
  return [...byId.values()]
}
