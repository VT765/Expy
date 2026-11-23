import { CloudIcon } from './Icons'
import { useSyncStatus } from '../hooks/useSyncStatus'
import { syncNow } from '../lib/sync'
import { cn } from '../lib/cn'

// Small status pill (Tap screen, top-left). Tap to sync now.
export default function SyncIndicator() {
  const { state, label } = useSyncStatus()
  if (state === 'local') return null
  return (
    <button
      type="button"
      onClick={() => syncNow()}
      aria-label={`Sync status: ${label}`}
      className="flex h-8 items-center gap-1.5 rounded-chip px-2 text-caption font-medium text-faint active:opacity-50"
    >
      <span className="relative">
        <CloudIcon size={18} />
        <span
          className={cn(
            'absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full ring-2 ring-canvas',
            state === 'synced' && 'bg-[#5FD38D]',
            state === 'pending' && 'bg-[#FFB340]',
            state === 'syncing' && 'animate-pulse bg-sub',
            (state === 'offline' || state === 'error') && 'bg-danger',
          )}
        />
      </span>
      {state !== 'synced' && <span>{label}</span>}
    </button>
  )
}
