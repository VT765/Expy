import { create } from 'zustand'
import { tabIndex } from '../lib/tabs'

let toastSeq = 0
let toastTimer

export const EMPTY_FILTERS = {
  categoryIds: [],
  type: 'all', // all | expense | credit
  minAmount: '',
  maxAmount: '',
  from: '', // yyyy-mm-dd
  to: '',
  query: '',
}

export const useUIStore = create((set, get) => ({
  tab: 'tap',
  // +1 when moving right, -1 when moving left; drives the slide direction.
  tabDir: 0,
  setTab: (tab) => {
    const cur = get().tab
    if (tab === cur) return
    set({ tab, tabDir: tabIndex(tab) > tabIndex(cur) ? 1 : -1 })
  },

  settingsOpen: false,
  openSettings: () => set({ settingsOpen: true }),
  closeSettings: () => set({ settingsOpen: false }),

  // { message, icon?, tone?: 'error', action?: { label, onClick } }
  toast: null,
  showToast: (message, opts = {}) => {
    const id = ++toastSeq
    clearTimeout(toastTimer)
    set({ toast: { id, message, ...opts } })
    toastTimer = setTimeout(() => {
      if (get().toast?.id === id) set({ toast: null })
    }, opts.duration ?? (opts.action ? 4500 : 2200))
  },
  showError: (message) => get().showToast(message, { tone: 'error', duration: 3500 }),
  hideToast: () => set({ toast: null }),

  // Promise-based confirm dialog: await confirm({ title, message, confirmLabel, destructive })
  dialog: null,
  confirm: (opts) =>
    new Promise((resolve) => {
      set({ dialog: { ...opts, resolve } })
    }),
  resolveDialog: (value) => {
    get().dialog?.resolve(value)
    set({ dialog: null })
  },

  // History
  historyRange: 'month', // today | week | month | all
  setHistoryRange: (historyRange) => set({ historyRange }),
  filters: EMPTY_FILTERS,
  setFilters: (filters) => set({ filters }),

  // Analytics
  period: { kind: 'month', offset: 0, from: '', to: '' },
  setPeriod: (period) => set({ period: { ...get().period, ...period } }),

  // Open edit sheet for a transaction id
  editingId: null,
  setEditingId: (editingId) => set({ editingId }),
}))
