import SwiftUI

/// One numpad key: a digit/"." label or an SF Symbol.
struct NumPadKey: View {
    var label: String?
    var systemImage: String?
    var accessibilityName: String?
    let height: Double
    let action: () -> Void

    var body: some View {
        Button(action: press) {
            ZStack {
                if let systemImage {
                    Image(systemName: systemImage).font(.app(22, .medium))
                } else {
                    Text(label ?? "").font(.app(25, .medium))
                }
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.raised))
        }
        .buttonStyle(NumPadKeyStyle())
        .accessibilityLabel(accessibilityName ?? label ?? "")
    }

    private func press() {
        Haptics.tap()
        action()
    }
}
