import { cn } from '../lib/cn'

export default function Card({ title, action, padded = true, className, bodyClassName, children }) {
  return (
    <section className={className}>
      {(title || action) && (
        <header className="mb-2.5 flex items-center justify-between">
          {title && <h2 className="text-footnote font-semibold uppercase tracking-label text-faint">{title}</h2>}
          {action}
        </header>
      )}
      <div className={cn('overflow-hidden rounded-card bg-card', padded && 'p-4', bodyClassName)}>{children}</div>
    </section>
  )
}
