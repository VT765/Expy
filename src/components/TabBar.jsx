import { motion } from 'framer-motion'
import { useUIStore } from '../store/useUIStore'
import { TABS } from '../lib/tabs'
import { cn } from '../lib/cn'
import { AnalyticsIcon, HistoryIcon, TapIcon } from './Icons'

const ICONS = { history: HistoryIcon, tap: TapIcon, analytics: AnalyticsIcon }

export default function TabBar() {
  const tab = useUIStore((s) => s.tab)
  const setTab = useUIStore((s) => s.setTab)

  return (
    <nav className="hairline-t absolute inset-x-0 bottom-0 z-20 bg-card pb-safe-b">
      <ul className="flex h-tabbar items-stretch">
        {TABS.map(({ id, label }) => {
          const Icon = ICONS[id]
          const active = tab === id
          return (
            <li key={id} className="flex-1">
              <motion.button
                type="button"
                onClick={() => setTab(id)}
                whileTap={{ scale: 0.9 }}
                transition={{ duration: 0.12 }}
                aria-current={active ? 'page' : undefined}
                className={cn(
                  'flex h-full w-full flex-col items-center justify-center gap-[3px] pt-1',
                  active ? 'text-ink' : 'text-sub',
                )}
              >
                <Icon size={id === 'tap' ? 27 : 24} strokeWidth={id === 'tap' ? 2 : 1.9} />
                <span className="text-[13px] font-semibold leading-4">{label}</span>
              </motion.button>
            </li>
          )
        })}
      </ul>
    </nav>
  )
}
