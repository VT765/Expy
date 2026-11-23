import Skeleton from './Skeleton'

// Placeholder while a lazily-loaded screen's code arrives.
export default function ScreenSkeleton({ title }) {
  return (
    <div className="h-full px-gutter pt-safe-t">
      <div className="flex h-[68px] items-center justify-center">
        {title ? <h1 className="text-large font-bold tracking-tight">{title}</h1> : <Skeleton className="h-7 w-32" />}
      </div>
      <div className="flex gap-2">
        {[64, 72, 64, 84].map((w, i) => (
          <Skeleton key={i} className="h-[43px] rounded-chip" style={{ width: w }} />
        ))}
      </div>
      <Skeleton className="mt-6 h-32 rounded-card" />
      <div className="mt-[6px] grid grid-cols-2 gap-[6px]">
        <Skeleton className="h-20 rounded-card" />
        <Skeleton className="h-20 rounded-card" />
      </div>
      <Skeleton className="mt-8 h-56 rounded-card" />
    </div>
  )
}
