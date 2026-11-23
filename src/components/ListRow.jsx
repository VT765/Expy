import { cn } from '../lib/cn'
import { ChevronRight } from './Icons'

// Table row for grouped lists inside a Card. Hairline under the text column,
// except on the last row.
export default function ListRow({
  leading,
  title,
  subtitle,
  value,
  chevron = false,
  destructive = false,
  onClick,
  className,
}) {
  const Tag = onClick ? 'button' : 'div'

  return (
    <Tag
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={cn('group relative flex w-full items-center gap-3 pl-4 text-left', className)}
    >
      {onClick && (
        <span className="pointer-events-none absolute inset-0 bg-white/[0.06] opacity-0 transition-opacity duration-150 group-active:opacity-100 group-active:duration-0" />
      )}
      {leading}
      <span className="flex min-h-[54px] min-w-0 flex-1 items-center gap-3 border-b-[0.5px] border-well py-2.5 pr-4 group-last:border-b-0">
        <span className="min-w-0 flex-1">
          <span className={cn('block truncate text-body', destructive ? 'text-danger' : 'text-ink')}>{title}</span>
          {subtitle && <span className="mt-0.5 block truncate text-footnote text-sub">{subtitle}</span>}
        </span>
        {value != null && <span className="shrink-0 text-body tabular-nums text-sub">{value}</span>}
        {chevron && <ChevronRight size={16} className="shrink-0 text-sub" />}
      </span>
    </Tag>
  )
}
