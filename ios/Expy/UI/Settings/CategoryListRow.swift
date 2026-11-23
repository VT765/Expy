import SwiftUI

/// Emoji + name (tap to edit), red ✕ (delete), ≡ handle (drag to reorder).
struct CategoryListRow: View {
    let category: ExpenseCategory
    let isDragging: Bool
    let edit: () -> Void
    let delete: () -> Void
    let dragStarted: () -> Void
    let dropped: (String) -> Bool
    let moveUp: () -> Void
    let moveDown: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: edit) {
                HStack(spacing: 16) {
                    Text(category.emoji).font(.app(24)).frame(width: 30).accessibilityHidden(true)
                    Text(category.name).font(.app(16, .semibold)).lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 16).frame(minHeight: 60)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit category")
            if !Defaults.isFallback(category.id) {
                Button("Delete \(category.name)", systemImage: "xmark", action: delete)
                    .labelStyle(.iconOnly)
                    .font(.app(17, .semibold))
                    .foregroundStyle(Theme.danger)
                    .frame(width: 48, height: 60)
            }
            Image(systemName: "line.3.horizontal").font(.app(18, .medium)).foregroundStyle(Theme.sub)
                .frame(width: 52, height: 60)
                .contentShape(.rect)
                .draggable(category.id) {
                    HStack { Text(category.emoji); Text(category.name).bold() }
                        .padding(12).background(Capsule().fill(Theme.raised))
                        .onAppear(perform: dragStarted)
                }
                .accessibilityLabel("Reorder \(category.name)")
                .accessibilityAction(named: "Move up", moveUp)
                .accessibilityAction(named: "Move down", moveDown)
        }
        .background(Theme.card)
        .opacity(isDragging ? 0.4 : 1)
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            return dropped(id)
        }
    }
}
