import { cn } from '../lib/cn'

// Settings list primitives matching the reference: grey uppercase section
// label, each row its own rounded card, title left, grey value + › right.
export function Section({ title, hint, children, className }) {
  return (
    <section className={cn('mt-8 first:mt-2', className)}>
      {title && <h2 className="mb-2.5 px-0 text-footnote font-semibold uppercase tracking-label text-faint">{title}</h2>}
      {hint && <p className="-mt-1 mb-3 text-footnote text-sub">{hint}</p>}
      <div className="space-y-[6px]">{children}</div>
    </section>
  )
}

export function Row({ title, subtitle, value, chevron = true, destructive, onClick, trailing, className }) {
  const Tag = onClick ? 'button' : 'div'
  return (
    <Tag
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={cn(
        'group relative flex min-h-[58px] w-full items-center gap-3 overflow-hidden rounded-card bg-card px-4 py-3 text-left',
        className,
      )}
    >
      {onClick && (
        <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 transition-opacity duration-150 group-active:opacity-100 group-active:duration-0" />
      )}
      <span className="min-w-0 flex-1">
        <span className={cn('block text-headline font-semibold', destructive ? 'text-danger' : 'text-ink')}>{title}</span>
        {subtitle && <span className="mt-0.5 block text-footnote text-sub">{subtitle}</span>}
      </span>
      {trailing}
      {value != null && (
        <span className="max-w-[55%] shrink-0 truncate text-body text-sub">
          {value}
          {chevron && onClick && ' ›'}
        </span>
      )}
      {value == null && chevron && onClick && !trailing && <span className="text-[22px] leading-none text-sub">›</span>}
    </Tag>
  )
}
