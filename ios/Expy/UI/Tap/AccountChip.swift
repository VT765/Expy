import SwiftUI

/// Account icon and name in a capsule; white outline when selected.
struct AccountChip: View {
    let account: Account
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(account.name, systemImage: account.symbol)
                .font(.app(15, .semibold))
                .padding(.horizontal, 16).frame(minHeight: 44)
                .foregroundStyle(selected ? .white : Theme.sub)
                .background(Capsule().fill(Theme.raised))
                .overlay(Capsule().strokeBorder(selected ? .white : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("To \(account.name)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
