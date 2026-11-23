import { tint } from '../lib/colors'

export default function EmojiCircle({ emoji, color, size = 46 }) {
  return (
    <span
      className="flex shrink-0 items-center justify-center rounded-full"
      style={{ width: size, height: size, background: tint(color, 0.16), fontSize: size * 0.5 }}
      aria-hidden="true"
    >
      {emoji}
    </span>
  )
}
