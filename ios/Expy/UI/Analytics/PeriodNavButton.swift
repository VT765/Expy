import SwiftUI

/// Round ‹ / › button.
struct PeriodNavButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(title, systemImage: icon, action: tap)
            .labelStyle(.iconOnly)
            .font(.app(15, .bold))
            .frame(width: 44, height: 44)
            .background(Circle().fill(Theme.raised))
            .foregroundStyle(.white)
            .opacity(isEnabled ? 1 : 0.25)
    }

    private func tap() {
        Haptics.selection()
        action()
    }
}
