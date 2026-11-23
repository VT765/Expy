import SwiftUI

/// White when on, dark when off ("Credit", "Transfer").
struct KindPill: View {
    let title: String
    let on: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.app(13, .semibold))
                .padding(.horizontal, 16).frame(minHeight: 44)
                .foregroundStyle(on ? .black : Theme.faint)
                .background(RoundedRectangle(cornerRadius: 16).fill(on ? .white : Theme.raised))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
