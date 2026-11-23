import { useEffect, useState } from 'react'
import BottomSheet from '../BottomSheet'
import Button from '../Button'
import EmojiCircle from '../EmojiCircle'
import { CATEGORY_COLORS } from '../../lib/colors'
import { cn } from '../../lib/cn'

const EMOJIS = [
  '🍔', '🍕', '🍜', '☕', '🍺', '🍰', '🥗', '🍱', '🛒', '🥦', '🍎', '🥛',
  '🚕', '🚗', '⛽', '🚌', '🚇', '🛵', '✈️', '🏨', '🧳', '🏖️', '🗺️', '🚲',
  '🛍️', '👕', '👟', '💄', '🎁', '💍', '📱', '💻', '🎧', '📦', '🪑', '🛋️',
  '🧾', '💡', '💧', '🔥', '📶', '🏠', '🔑', '🧹', '🧺', '🛠️', '🐶', '🌱',
  '💊', '🏥', '🦷', '🧘', '🏋️', '💇', '💅', '🧴', '👶', '🎓', '📚', '✏️',
  '🎬', '🎮', '🎵', '🎟️', '⚽', '🎨', '📺', '😎', '🎉', '💳', '🏦', '📈',
  '💰', '💸', '🤝', '❤️', '🙏', '🎗️', '🚬', '🍷', '👤', '⭐', '✨', '📌',
]

const firstGrapheme = (s) => {
  const seg = typeof Intl.Segmenter === 'function' ? new Intl.Segmenter(undefined, { granularity: 'grapheme' }) : null
  return seg ? ([...seg.segment(s)][0]?.segment ?? '') : [...s][0] ?? ''
}

// Create / edit a category: name, emoji (grid or emoji keyboard), accent color.
export default function CategoryEditorSheet({ open, category, onSave, onClose }) {
  const [name, setName] = useState('')
  const [emoji, setEmoji] = useState('✨')
  const [color, setColor] = useState(CATEGORY_COLORS[0])

  useEffect(() => {
    if (!open) return
    setName(category?.name ?? '')
    setEmoji(category?.emoji ?? '✨')
    setColor(category?.color ?? CATEGORY_COLORS[Math.floor(Math.random() * CATEGORY_COLORS.length)])
  }, [open, category])

  const valid = name.trim().length > 0 && emoji

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title={category ? 'Edit category' : 'New category'}
      tall
      footer={
        <Button
          block
          disabled={!valid}
          onClick={() => {
            onSave({ id: category?.id, name: name.trim().slice(0, 40), emoji, color })
            onClose()
          }}
        >
          {category ? 'Save' : 'Add category'}
        </Button>
      }
    >
      <div className="flex items-center gap-3 pt-1">
        <EmojiCircle emoji={emoji} color={color} size={52} />
        <input
          value={name}
          maxLength={40}
          onChange={(e) => setName(e.target.value)}
          placeholder="Category name"
          className="h-12 min-w-0 flex-1 rounded-[14px] bg-raised px-4 text-body text-ink outline-none placeholder:text-faint"
        />
      </div>

      <p className="mb-2.5 mt-6 text-footnote font-semibold uppercase tracking-label text-faint">Color</p>
      <div className="flex flex-wrap gap-2.5">
        {CATEGORY_COLORS.map((c) => (
          <button
            key={c}
            type="button"
            aria-label={`Color ${c}`}
            onClick={() => setColor(c)}
            className="h-8 w-8 rounded-full"
            style={{ background: c, boxShadow: color === c ? `0 0 0 2px #111, 0 0 0 4px ${c}` : undefined }}
          />
        ))}
      </div>

      <div className="mb-2.5 mt-6 flex items-center justify-between">
        <p className="text-footnote font-semibold uppercase tracking-label text-faint">Emoji</p>
        <input
          aria-label="Type any emoji"
          placeholder="Type any 🙂"
          value=""
          onChange={(e) => {
            const g = firstGrapheme(e.target.value.trim())
            if (g) setEmoji(g)
          }}
          className="h-9 w-32 rounded-chip bg-raised px-3 text-center text-body outline-none placeholder:text-faint"
        />
      </div>
      <div className="grid grid-cols-8 gap-1">
        {EMOJIS.map((e) => (
          <button
            key={e}
            type="button"
            onClick={() => setEmoji(e)}
            className={cn('flex aspect-square items-center justify-center rounded-xl text-[24px]', emoji === e ? 'bg-well' : 'active:bg-raised')}
          >
            {e}
          </button>
        ))}
      </div>
    </BottomSheet>
  )
}
