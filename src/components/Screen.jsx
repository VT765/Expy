import { cn } from '../lib/cn'

// Tab page shell: centered bold title (as in the reference), optional
// trailing action, scrollable body that clears the tab bar.
export default function Screen({ title, trailing, leading, footerSpace = 0, className, children, scrollRef }) {
  return (
    <div ref={scrollRef} className="scroll-area h-full pt-safe-t">
      <header className="relative flex h-[68px] items-center justify-center px-gutter">
        {leading && <div className="absolute left-gutter">{leading}</div>}
        <h1 className="text-large font-bold tracking-tight">{title}</h1>
        {trailing && <div className="absolute right-gutter">{trailing}</div>}
      </header>
      <div
        className={cn('px-gutter', className)}
        style={{ paddingBottom: `calc(58px + env(safe-area-inset-bottom) + ${24 + footerSpace}px)` }}
      >
        {children}
      </div>
    </div>
  )
}
