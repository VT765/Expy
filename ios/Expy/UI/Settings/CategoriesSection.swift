import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Debit and credit categories, switched with pills. "Tap a category to
/// edit, drag to reorder." Emoji, name, red ✕, ≡ handle.
struct CategoriesSection: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @State private var editing: EditTarget?
    @State private var deleting: ExpenseCategory?
    @State private var isDeleting = false
    @State private var dragging: String?
    @State private var kind = TransactionKind.expense

    enum EditTarget: Identifiable {
        case new(TransactionKind), existing(ExpenseCategory)
        var id: String {
            switch self {
            case .new(let k): "new-\(k.rawValue)"
            case .existing(let c): c.id
            }
        }
        var category: ExpenseCategory? { if case .existing(let c) = self { return c }; return nil }
        var kind: TransactionKind {
            switch self {
            case .new(let k): k
            case .existing(let c): c.kind
            }
        }
    }

    /// The list being shown and reordered.
    private var shown: [ExpenseCategory] { categories.filter { $0.kind == kind } }

    var body: some View {
        SettingsSection(title: "Categories", hint: "Debits and credits have their own categories. Tap to edit, drag to reorder.") {
            Pills(options: [(TransactionKind.expense, "Debit"), (.credit, "Credit")], selection: $kind)
                .padding(.bottom, 6)
            VStack(spacing: 0) {
                ForEach(shown) { c in
                    CategoryListRow(category: c, isDragging: dragging == c.id,
                                    edit: { edit(c) }, delete: { confirmDelete(c) },
                                    dragStarted: { dragging = c.id }, dropped: { move($0, to: c.id) },
                                    moveUp: { shift(c, by: -1) }, moveDown: { shift(c, by: 1) })
                    Rectangle().fill(Theme.well).frame(height: 0.5)
                }
                Button(action: addCategory) {
                    HStack(spacing: 16) {
                        Image(systemName: "plus").font(.app(18, .semibold)).frame(width: 30)
                        Text(kind == .credit ? "Add credit category" : "Add debit category").font(.app(16, .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(minHeight: 58)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .sheet(item: $editing) { t in CategoryEditor(category: t.category, kind: t.kind) }
        .alert("Delete \(deleting?.name ?? "category")?", isPresented: $isDeleting, presenting: deleting) { c in
            Button("Delete", role: .destructive) { DataStore.shared.deleteCategory(c) }
            Button("Cancel", role: .cancel) {}
        } message: { c in
            Text(movedEntriesMessage(for: c))
        }
    }

    private func confirmDelete(_ c: ExpenseCategory) {
        deleting = c
        isDeleting = true
    }

    private func movedEntriesMessage(for c: ExpenseCategory) -> String {
        let n = DataStore.shared.fetch(Entry.self).count { $0.categoryId == c.id && $0.deletedAt == nil }
        let fallback = c.isCredit ? "Other income" : "Other"
        return n > 0 ? "\(n) \(n == 1 ? "entry moves" : "entries move") to \(fallback)." : "No entries use this category."
    }

    private func edit(_ c: ExpenseCategory) { editing = .existing(c) }
    private func addCategory() { editing = .new(kind) }

    /// Moves `id` to the position of `target` and saves the new order.
    private func move(_ id: String, to target: String) -> Bool {
        defer { dragging = nil }
        guard id != target else { return false }
        var ordered = shown
        guard let from = ordered.firstIndex(where: { $0.id == id }), let to = ordered.firstIndex(where: { $0.id == target }) else { return false }
        ordered.insert(ordered.remove(at: from), at: to)
        withAnimation(.spring(response: 0.3)) { DataStore.shared.reorderCategories(ordered) }
        Haptics.success()
        return true
    }

    /// VoiceOver "Move up/down" for people who can't drag.
    private func shift(_ c: ExpenseCategory, by delta: Int) {
        let list = shown
        guard let i = list.firstIndex(where: { $0.id == c.id }), list.indices.contains(i + delta) else { return }
        _ = move(c.id, to: list[i + delta].id)
    }
}
