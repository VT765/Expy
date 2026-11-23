import { useEffect, useMemo, useState } from 'react'

// Windowed rendering for a list of fixed-height items living inside a
// scrolling ancestor. Returns the visible slice plus absolute offsets.
export function useVirtualList({ items, heightOf, scrollRef, listRef, enabled, overscan = 600 }) {
  const { offsets, total } = useMemo(() => {
    const offsets = new Array(items.length)
    let y = 0
    for (let i = 0; i < items.length; i++) {
      offsets[i] = y
      y += heightOf(items[i])
    }
    return { offsets, total: y }
  }, [items, heightOf])

  const [view, setView] = useState({ top: 0, height: 1000 })

  useEffect(() => {
    if (!enabled) return
    const el = scrollRef.current
    if (!el) return
    let frame = 0
    const update = () => {
      frame = 0
      const listTop = listRef.current ? listRef.current.offsetTop : 0
      setView({ top: el.scrollTop - listTop, height: el.clientHeight })
    }
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(update)
    }
    update()
    el.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    return () => {
      el.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
      cancelAnimationFrame(frame)
    }
  }, [enabled, scrollRef, listRef])

  if (!enabled) return { visible: items.map((item, i) => ({ item, index: i, top: offsets[i] })), total, virtual: false }

  const from = view.top - overscan
  const to = view.top + view.height + overscan
  // Binary search for the first visible index.
  let lo = 0
  let hi = items.length - 1
  while (lo < hi) {
    const mid = (lo + hi) >> 1
    if (offsets[mid] + heightOf(items[mid]) < from) lo = mid + 1
    else hi = mid
  }
  const visible = []
  for (let i = lo; i < items.length && offsets[i] < to; i++) visible.push({ item: items[i], index: i, top: offsets[i] })
  return { visible, total, virtual: true }
}
