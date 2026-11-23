import SwiftUI

/// A quiet pill: raised background only when selected; 44pt hit area.
struct DatePill: View {
    let title: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: tap) {
            Text(title).font(.app(13, .semibold))
                .padding(.horizontal, 14).frame(height: 32)
                .foregroundStyle(on ? .white : Theme.faint)
                .background(Capsule().fill(on ? Theme.raised : .clear))
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func tap() {
        Haptics.selection()
        action()
    }
}
