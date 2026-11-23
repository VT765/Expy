export const TABS = [
  { id: 'history', label: 'History' },
  { id: 'tap', label: 'Tap' },
  { id: 'analytics', label: 'Analytics' },
]

export const tabIndex = (id) => TABS.findIndex((t) => t.id === id)
