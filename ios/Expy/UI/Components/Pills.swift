import SwiftUI

/// Range pills ("Today / This Week…"). Solid: white selected, grey others.
struct Pills<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var quiet = false

    var body: some View {
        HStack(spacing: quiet ? 10 : 8) {
            ForEach(options.indices, id: \.self) { i in
                let (value, label) = options[i]
                let on = value == selection
                Button { select(value) } label: {
                    Text(label)
                        .font(.app(13, .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: quiet ? 32 : 43)
                        .foregroundStyle(on ? (quiet ? .white : .black) : Theme.faint)
                        .background(Capsule().fill(on ? (quiet ? Theme.raised : .white) : (quiet ? .clear : Theme.raised)))
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableStyle())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private func select(_ value: T) {
        Haptics.selection()
        withAnimation(.easeOut(duration: 0.15)) { selection = value }
    }
}
