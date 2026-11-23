import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { createIdbStorage } from '../lib/idbStorage'
import { uid } from '../lib/id'
import { DEFAULT_CATEGORIES, DEFAULT_SETTINGS, OTHER_CATEGORY_ID } from '../../shared/defaults'
import { useSyncStore } from './useSyncStore'

const initialData = () => ({
  transactions: [],
  categories: DEFAULT_CATEGORIES,
  budgets: [],
  settings: DEFAULT_SETTINGS,
  // Local-only cache of exchange rates: units of `base` per 1 unit of each currency.
  rates: { base: 'INR', perUnit: {}, fetchedAt: 0 },
})

// Last-write-wins merge of incoming docs into a list.
function mergeDocs(list, incoming) {
  if (!incoming?.length) return list
  const byId = new Map(list.map((d) => [d.id, d]))
  for (const doc of incoming) {
    const cur = byId.get(doc.id)
    if (!cur || (doc.updatedAt ?? 0) >= (cur.updatedAt ?? 0)) byId.set(doc.id, doc)
  }
  return [...byId.values()]
}

export function rateFor(state, currency) {
  const { settings, rates } = state
  if (currency === settings.baseCurrency) return 1
  const override = settings.rateOverrides?.[currency]
  if (override) return override
  if (rates.base === settings.baseCurrency && rates.perUnit[currency]) return rates.perUnit[currency]
  return null
}

const round2 = (n) => Math.round(n * 100) / 100

export const useDataStore = create(
  persist(
    (set, get) => {
      // Writes docs locally in one state update and queues them for sync.
      const putMany = (collection, docs) => {
        if (!docs.length) return
        set((s) => {
          if (collection === 'settings') return { settings: docs[docs.length - 1] }
          const byId = new Map(docs.map((d) => [d.id, d]))
          const next = s[collection].map((d) => {
            const repl = byId.get(d.id)
            if (repl) byId.delete(d.id)
            return repl ?? d
          })
          return { [collection]: byId.size ? [...next, ...byId.values()] : next }
        })
        useSyncStore.getState().enqueueMany(collection, docs)
      }
      const put = (collection, doc) => {
        putMany(collection, [doc])
        return doc
      }

      return {
        ...initialData(),

        // Returns { amountInBase, missingRate }.
        toBase: (amount, currency) => {
          const rate = rateFor(get(), currency)
          return { amountInBase: round2(amount * (rate ?? 1)), missingRate: rate == null }
        },

        addTransaction: ({ type = 'expense', amount, currency, categoryId, note = '', date }) => {
          const now = Date.now()
          const cur = currency || get().settings.baseCurrency
          const { amountInBase } = get().toBase(amount, cur)
          return put('transactions', {
            id: uid('tx_'),
            type,
            amount: round2(amount),
            currency: cur,
            amountInBase,
            categoryId: categoryId || OTHER_CATEGORY_ID,
            note: note.trim(),
            date: date ?? now,
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          })
        },

        updateTransaction: (id, patch) => {
          const tx = get().transactions.find((t) => t.id === id)
          if (!tx) return null
          const next = { ...tx, ...patch, updatedAt: Date.now() }
          if ('amount' in patch || 'currency' in patch) {
            next.amount = round2(next.amount)
            next.amountInBase = get().toBase(next.amount, next.currency).amountInBase
          }
          if (typeof next.note === 'string') next.note = next.note.trim()
          return put('transactions', next)
        },

        deleteTransaction: (id) => get().updateTransaction(id, { deletedAt: Date.now() }),
        restoreTransaction: (id) => get().updateTransaction(id, { deletedAt: null }),

        saveCategory: ({ id, name, emoji, color }) => {
          const now = Date.now()
          const existing = id && get().categories.find((c) => c.id === id)
          const order = existing ? existing.order : Math.max(-1, ...get().categories.map((c) => c.order)) + 1
          return put('categories', {
            ...(existing || {}),
            id: existing?.id ?? uid('cat_'),
            name: name.trim(),
            emoji,
            color,
            order,
            updatedAt: now,
            deletedAt: null,
          })
        },

        // Soft-deletes a category and moves its transactions to "Other".
        deleteCategory: (id) => {
          if (id === OTHER_CATEGORY_ID) return
          const now = Date.now()
          const cat = get().categories.find((c) => c.id === id)
          if (!cat) return
          put('categories', { ...cat, deletedAt: now, updatedAt: now })
          putMany(
            'transactions',
            get()
              .transactions.filter((tx) => tx.categoryId === id && !tx.deletedAt)
              .map((tx) => ({ ...tx, categoryId: OTHER_CATEGORY_ID, updatedAt: now })),
          )
          const budget = get().budgets.find((b) => b.categoryId === id && !b.deletedAt)
          if (budget) put('budgets', { ...budget, deletedAt: now, updatedAt: now })
        },

        reorderCategories: (orderedIds) => {
          const now = Date.now()
          const byId = new Map(get().categories.map((c) => [c.id, c]))
          const changed = []
          orderedIds.forEach((id, order) => {
            const c = byId.get(id)
            if (c && c.order !== order) changed.push({ ...c, order, updatedAt: now })
          })
          putMany('categories', changed)
        },

        // categoryId null = overall monthly budget. Amount 0 removes it.
        setBudget: (categoryId, amount) => {
          const now = Date.now()
          const id = categoryId ? `budget_${categoryId}` : 'budget_total'
          put('budgets', {
            id,
            categoryId: categoryId ?? null,
            amount: round2(amount || 0),
            updatedAt: now,
            deletedAt: amount > 0 ? null : now,
          })
        },

        updateSettings: (patch) => put('settings', { ...get().settings, ...patch, updatedAt: Date.now() }),

        // Re-prices every transaction in the (new) base currency.
        rebaseTransactions: () => {
          const now = Date.now()
          const changed = []
          for (const tx of get().transactions) {
            const { amountInBase } = get().toBase(tx.amount, tx.currency)
            if (amountInBase !== tx.amountInBase) changed.push({ ...tx, amountInBase, updatedAt: now })
          }
          putMany('transactions', changed)
        },

        setRates: (rates) => set({ rates }),

        // Applies docs pulled from the server (no outbox).
        applyRemote: ({ transactions, categories, budgets, settings }) =>
          set((s) => ({
            transactions: mergeDocs(s.transactions, transactions),
            categories: mergeDocs(s.categories, categories),
            budgets: mergeDocs(s.budgets, budgets),
            settings: settings && (settings.updatedAt ?? 0) >= (s.settings.updatedAt ?? 0) ? settings : s.settings,
          })),

        // Restores a validated backup: everything in it becomes a fresh local write.
        importBackup: (backup) => {
          const now = Date.now()
          const stamp = (d) => ({ ...d, updatedAt: now })
          putMany('categories', backup.categories.map(stamp))
          putMany('transactions', backup.transactions.map(stamp))
          putMany('budgets', backup.budgets.map(stamp))
          if (backup.settings) put('settings', stamp(backup.settings))
        },

        // Soft-deletes all records (so the deletion syncs) and resets categories.
        eraseAll: () => {
          const now = Date.now()
          const s = get()
          const gone = (d) => ({ ...d, deletedAt: now, updatedAt: now })
          putMany('transactions', s.transactions.filter((t) => !t.deletedAt).map(gone))
          putMany('budgets', s.budgets.filter((b) => !b.deletedAt).map(gone))
          putMany(
            'categories',
            s.categories.map((c) => {
              const def = DEFAULT_CATEGORIES.find((d) => d.id === c.id)
              return def ? { ...def, updatedAt: now } : gone(c)
            }),
          )
          put('settings', { ...DEFAULT_SETTINGS, updatedAt: now })
        },

        // Wipes the device copy (logout / forgot PIN). Nothing is queued.
        resetLocal: () => set(initialData()),
      }
    },
    {
      name: 'expy-data',
      version: 1,
      storage: createIdbStorage(),
      partialize: ({ transactions, categories, budgets, settings, rates }) => ({
        transactions,
        categories,
        budgets,
        settings,
        rates,
      }),
      // Add a case per schema bump; each step upgrades one version.
      migrate: (state, version) => {
        let s = { ...initialData(), ...state }
        if (version < 1) {
          s.transactions = (s.transactions || []).map((t) => ({
            deletedAt: null,
            amountInBase: t.amount,
            currency: 'INR',
            ...t,
          }))
        }
        return s
      },
    },
  ),
)

// ---- Selectors -------------------------------------------------------------

export const selectActiveTransactions = (s) => s.transactions.filter((t) => !t.deletedAt)

export const selectCategories = (s) =>
  s.categories.filter((c) => !c.deletedAt).sort((a, b) => a.order - b.order)

export const signedBase = (tx) => (tx.type === 'credit' ? -tx.amountInBase : tx.amountInBase)
