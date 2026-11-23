import { cn } from '../lib/cn'

// Opacity-pulsing placeholder block (animates opacity only).
export default function Skeleton({ className, style }) {
  return <div className={cn('animate-pulse rounded-xl bg-raised', className)} style={style} />
}
