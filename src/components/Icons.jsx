// Stroke icons drawn on a 24px grid; size and color follow the parent text.
const Svg = ({ children, size = 24, strokeWidth = 1.8, ...rest }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={strokeWidth}
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden="true"
    {...rest}
  >
    {children}
  </svg>
)

// Tab bar
export const HistoryIcon = (p) => (
  <Svg {...p}>
    <path d="M5 7h2M10 7h9M5 12h2M10 12h9M5 17h2M10 17h9" />
  </Svg>
)
export const TapIcon = (p) => (
  <Svg {...p}>
    <circle cx="12" cy="12" r="9.5" />
    <circle cx="12" cy="12" r="4.5" />
    <circle cx="12" cy="12" r="1.2" fill="currentColor" />
  </Svg>
)
export const AnalyticsIcon = (p) => (
  <Svg {...p}>
    <path d="M3 3v18h18" />
    <path d="M6.5 15.5l4-5 3.5 3 5.5-7" />
    <path d="M16 6.5h3.5V10" />
  </Svg>
)

export const SlidersIcon = (p) => (
  <Svg strokeWidth={2} {...p}>
    <path d="M3 7h18M3 17h18" />
    <circle cx="9" cy="7" r="2.2" fill="currentColor" />
    <circle cx="15" cy="17" r="2.2" fill="currentColor" />
  </Svg>
)
export const GearIcon = (p) => (
  <Svg {...p}>
    <path d="M12.2 2h-.4a2 2 0 0 0-2 2v.2a2 2 0 0 1-1 1.7l-.4.3a2 2 0 0 1-2 0l-.2-.1a2 2 0 0 0-2.7.7l-.2.4a2 2 0 0 0 .7 2.7l.2.1a2 2 0 0 1 1 1.7v.6a2 2 0 0 1-1 1.7l-.2.1a2 2 0 0 0-.7 2.7l.2.4a2 2 0 0 0 2.7.7l.2-.1a2 2 0 0 1 2 0l.4.3a2 2 0 0 1 1 1.7v.2a2 2 0 0 0 2 2h.4a2 2 0 0 0 2-2v-.2a2 2 0 0 1 1-1.7l.4-.3a2 2 0 0 1 2 0l.2.1a2 2 0 0 0 2.7-.7l.2-.4a2 2 0 0 0-.7-2.7l-.2-.1a2 2 0 0 1-1-1.7v-.6a2 2 0 0 1 1-1.7l.2-.1a2 2 0 0 0 .7-2.7l-.2-.4a2 2 0 0 0-2.7-.7l-.2.1a2 2 0 0 1-2 0l-.4-.3a2 2 0 0 1-1-1.7V4a2 2 0 0 0-2-2z" />
    <circle cx="12" cy="12" r="3" />
  </Svg>
)
export const ChevronLeft = (p) => (
  <Svg strokeWidth={2.4} {...p}>
    <path d="M15 18l-6-6 6-6" />
  </Svg>
)
export const ChevronRight = (p) => (
  <Svg strokeWidth={2} {...p}>
    <path d="M9 18l6-6-6-6" />
  </Svg>
)
export const ChevronDown = (p) => (
  <Svg strokeWidth={2} {...p}>
    <path d="M6 9l6 6 6-6" />
  </Svg>
)
export const CheckIcon = (p) => (
  <Svg strokeWidth={2.4} {...p}>
    <path d="M20 6L9 17l-5-5" />
  </Svg>
)
export const BackArrow = (p) => (
  <Svg strokeWidth={2} {...p}>
    <path d="M20 12H4M10 6l-6 6 6 6" />
  </Svg>
)
export const XIcon = (p) => (
  <Svg strokeWidth={2.2} {...p}>
    <path d="M18 6L6 18M6 6l12 12" />
  </Svg>
)
export const GripIcon = (p) => (
  <Svg strokeWidth={2} {...p}>
    <path d="M5 8h14M5 12h14M5 16h14" />
  </Svg>
)
export const PlusIcon = (p) => (
  <Svg strokeWidth={2.2} {...p}>
    <path d="M12 5v14M5 12h14" />
  </Svg>
)
export const ShareIcon = (p) => (
  <Svg {...p}>
    <path d="M12 3v12M7.5 7.5L12 3l4.5 4.5" />
    <path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7" />
  </Svg>
)
export const SearchIcon = (p) => (
  <Svg strokeWidth={2} {...p}>
    <circle cx="11" cy="11" r="7" />
    <path d="M20 20l-3.5-3.5" />
  </Svg>
)
export const LockIcon = (p) => (
  <Svg {...p}>
    <rect x="4.5" y="10.5" width="15" height="10" rx="2.5" />
    <path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" />
  </Svg>
)
export const FaceIdIcon = (p) => (
  <Svg {...p}>
    <path d="M3 8V5.5A2.5 2.5 0 0 1 5.5 3H8M16 3h2.5A2.5 2.5 0 0 1 21 5.5V8M21 16v2.5a2.5 2.5 0 0 1-2.5 2.5H16M8 21H5.5A2.5 2.5 0 0 1 3 18.5V16" />
    <path d="M8.5 9v1.5M15.5 9v1.5M12 9v4h-1M9 16a4.5 4.5 0 0 0 6 0" />
  </Svg>
)
export const CopyIcon = (p) => (
  <Svg {...p}>
    <rect x="8" y="8" width="12" height="12" rx="2.5" />
    <path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" />
  </Svg>
)
export const CloudIcon = (p) => (
  <Svg {...p}>
    <path d="M7 18a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A3.75 3.75 0 0 1 17.5 18z" />
  </Svg>
)
