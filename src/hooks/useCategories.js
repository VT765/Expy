import { useMemo } from 'react'
import { selectCategories, useDataStore } from '../store/useDataStore'
import { OTHER_CATEGORY_ID } from '../../shared/defaults'

// Active categories in display order, plus an id → category lookup that also
// resolves deleted ids (old transactions keep rendering).
export function useCategories() {
  const all = useDataStore((s) => s.categories)
  return useMemo(() => {
    const list = selectCategories({ categories: all })
    const byId = new Map(all.map((c) => [c.id, c]))
    const get = (id) => byId.get(id) ?? byId.get(OTHER_CATEGORY_ID) ?? { id, name: 'Other', emoji: '✨', color: '#9DB0C4' }
    return { list, get }
  }, [all])
}
