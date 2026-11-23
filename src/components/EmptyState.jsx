export default function EmptyState({ emoji = '🧾', title, message, action }) {
  return (
    <div className="flex flex-col items-center px-8 py-16 text-center">
      <span className="text-[44px]" aria-hidden="true">
        {emoji}
      </span>
      <h3 className="mt-3 text-headline font-semibold">{title}</h3>
      {message && <p className="mt-1 text-footnote text-sub">{message}</p>}
      {action && <div className="mt-5">{action}</div>}
    </div>
  )
}
