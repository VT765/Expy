import { useEffect, useState } from 'react'
import { Reorder, useDragControls } from 'framer-motion'
import { Section } from '../SettingsRow'
import { GripIcon, PlusIcon, XIcon } from '../Icons'
import CategoryEditorSheet from './CategoryEditorSheet'
import { useDataStore } from '../../store/useDataStore'
import { useUIStore } from '../../store/useUIStore'
import { useCategories } from '../../hooks/useCategories'
import { OTHER_CATEGORY_ID } from '../../../shared/defaults'

export default function CategoriesSection() {
  const { list } = useCategories()
  const saveCategory = useDataStore((s) => s.saveCategory)
  const deleteCategory = useDataStore((s) => s.deleteCategory)
  const reorderCategories = useDataStore((s) => s.reorderCategories)
  const confirm = useUIStore((s) => s.confirm)
  const [order, setOrder] = useState(() => list.map((c) => c.id))
  const [editing, setEditing] = useState(null) // category | 'new' | null

  useEffect(() => setOrder(list.map((c) => c.id)), [list])

  const byId = new Map(list.map((c) => [c.id, c]))
  const remove = async (c) => {
    const count = useDataStore.getState().transactions.filter((t) => t.categoryId === c.id && !t.deletedAt).length
    const ok = await confirm({
      title: `Delete ${c.name}?`,
      message: count ? `${count} ${count === 1 ? 'entry moves' : 'entries move'} to Other.` : undefined,
      confirmLabel: 'Delete',
      destructive: true,
    })
    if (ok) deleteCategory(c.id)
  }

  return (
    <Section title="Categories" hint="Tap a category to edit, drag to reorder.">
      <div className="overflow-hidden rounded-card bg-card">
        <Reorder.Group axis="y" values={order} onReorder={setOrder} as="div">
          {order.map((id) =>
            byId.get(id) ? (
              <CategoryItem
                key={id}
                category={byId.get(id)}
                onEdit={() => setEditing(byId.get(id))}
                onDelete={() => remove(byId.get(id))}
                onDrop={() => reorderCategories(order)}
              />
            ) : null,
          )}
        </Reorder.Group>
        <button
          type="button"
          onClick={() => setEditing('new')}
          className="flex h-[58px] w-full items-center gap-4 border-t-[0.5px] border-well px-4 text-headline font-semibold active:bg-white/5"
        >
          <PlusIcon size={22} className="ml-1" /> Add category
        </button>
      </div>
      <CategoryEditorSheet
        open={editing != null}
        category={editing === 'new' ? null : editing}
        onSave={saveCategory}
        onClose={() => setEditing(null)}
      />
    </Section>
  )
}

function CategoryItem({ category, onEdit, onDelete, onDrop }) {
  const controls = useDragControls()
  return (
    <Reorder.Item
      as="div"
      value={category.id}
      dragListener={false}
      dragControls={controls}
      onDragEnd={onDrop}
      className="relative flex h-[60px] items-center border-b-[0.5px] border-well bg-card last:border-b-0"
      whileDrag={{ scale: 1.02, boxShadow: '0 8px 24px rgba(0,0,0,0.6)', zIndex: 1 }}
    >
      <button type="button" onClick={onEdit} className="flex h-full min-w-0 flex-1 items-center gap-4 pl-4 text-left active:opacity-60">
        <span className="text-[24px]">{category.emoji}</span>
        <span className="truncate text-headline font-semibold">{category.name}</span>
      </button>
      {category.id !== OTHER_CATEGORY_ID && (
        <button type="button" aria-label={`Delete ${category.name}`} onClick={onDelete} className="flex h-full w-12 items-center justify-center text-danger active:opacity-50">
          <XIcon size={20} />
        </button>
      )}
      <span
        aria-label="Drag to reorder"
        onPointerDown={(e) => controls.start(e)}
        className="flex h-full w-14 touch-none items-center justify-center text-sub"
      >
        <GripIcon size={22} />
      </span>
    </Reorder.Item>
  )
}
