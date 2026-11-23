import SwiftUI

/// Toggleable chip in the History quick-view bar.
struct FilterChip: View {
    let title: String
    let icon: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: tap) {
            FilterChipLabel(title: title, icon: icon, on: on)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func tap() {
        Haptics.selection()
        action()
    }
}
