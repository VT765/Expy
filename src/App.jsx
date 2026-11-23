import { Suspense, lazy, useEffect } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useUIStore } from './store/useUIStore'
import { useLockStore } from './store/useLockStore'
import { useSyncStore } from './store/useSyncStore'
import { useIOSGuards } from './hooks/useIOSGuards'
import { useHydrated } from './hooks/useHydrated'
import { useAutoLock } from './hooks/useAutoLock'
import { spring, tabTransition, tabVariants } from './lib/motion'
import { ensureRates } from './lib/rates'
import { startSync } from './lib/sync'
import TabBar from './components/TabBar'
import Toast from './components/Toast'
import ConfirmDialog from './components/ConfirmDialog'
import EditTransactionSheet from './components/EditTransactionSheet'
import ErrorBoundary from './components/ErrorBoundary'
import ScreenSkeleton from './components/ScreenSkeleton'
import TapScreen from './screens/TapScreen'
import HistoryScreen from './screens/HistoryScreen'
import LockScreen from './screens/LockScreen'
import LoginScreen from './screens/LoginScreen'

// Heavier, less-used screens load on demand and are prefetched when idle.
const loadAnalytics = () => import('./screens/AnalyticsScreen')
const loadSettings = () => import('./screens/SettingsScreen')
const AnalyticsScreen = lazy(loadAnalytics)
const SettingsScreen = lazy(loadSettings)

const SCREENS = { history: HistoryScreen, tap: TapScreen, analytics: AnalyticsScreen }

const whenIdle = (fn) => (window.requestIdleCallback ? requestIdleCallback(fn, { timeout: 3000 }) : setTimeout(fn, 1500))

export default function App() {
  useIOSGuards()
  const hydrated = useHydrated([useLockStore])
  const locked = useLockStore((s) => s.locked)
  const obscured = useAutoLock()
  const needsLogin = useSyncStore((s) => !s.token && !s.offlineMode)

  useEffect(() => {
    if (!hydrated) return
    ensureRates().catch(() => {})
    whenIdle(() => {
      loadAnalytics()
      loadSettings()
    })
    return startSync()
  }, [hydrated])

  if (!hydrated) return <div className="h-full bg-canvas" />

  return (
    <ErrorBoundary>
      <div className="relative h-full overflow-hidden bg-canvas">
        {/* Nothing sensitive is mounted while locked or hidden. */}
        {!locked && !obscured && !needsLogin && <MainApp />}
        <Suspense fallback={null}>
          <AnimatePresence>
            {needsLogin && !locked && <LoginScreen key="login" />}
            {locked && <LockScreen key="lock" />}
          </AnimatePresence>
        </Suspense>
        <Toast />
        <ConfirmDialog />
      </div>
    </ErrorBoundary>
  )
}

function MainApp() {
  const tab = useUIStore((s) => s.tab)
  const dir = useUIStore((s) => s.tabDir)
  const settingsOpen = useUIStore((s) => s.settingsOpen)
  const Current = SCREENS[tab]

  return (
    <>
      {/* The app recedes behind the Settings page sheet, like iOS. */}
      <motion.div
        className="gpu absolute inset-0 origin-top overflow-hidden"
        animate={settingsOpen ? { scale: 0.93, y: 8, opacity: 0.6 } : { scale: 1, y: 0, opacity: 1 }}
        transition={spring}
      >
        <AnimatePresence initial={false} custom={dir}>
          <motion.main
            key={tab}
            className="gpu absolute inset-0"
            custom={dir}
            variants={tabVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={tabTransition}
          >
            <Suspense fallback={<ScreenSkeleton title={tab === 'analytics' ? 'Analytics' : null} />}>
              <Current />
            </Suspense>
          </motion.main>
        </AnimatePresence>
        <TabBar />
      </motion.div>
      <EditTransactionSheet />
      <Suspense fallback={null}>
        <SettingsScreen />
      </Suspense>
    </>
  )
}
