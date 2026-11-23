import SwiftUI

/// Emoji + name pill. Selected: tinted fill, 2pt accent border, accent label.
struct CategoryChip: View {
    let category: ExpenseCategory
    let selected: Bool
    var action: () -> Void

    var body: some View {
        let color = Color(hex: category.colorHex)
        Button(action: choose) {
            HStack(spacing: 8) {
                Text(category.emoji).font(.app(16)).accessibilityHidden(true)
                Text(category.name).font(.app(13, .semibold)).lineLimit(1)
            }
            .padding(.leading, 16).padding(.trailing, 18)
            .frame(minHeight: 44)
            .foregroundStyle(selected ? color : Theme.faint)
            .background(Capsule().fill(selected ? color.opacity(0.14) : Theme.raised))
            .overlay(Capsule().strokeBorder(selected ? color : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func choose() {
        Haptics.selection()
        action()
    }
}
