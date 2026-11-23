import SwiftUI

/// Key press highlight: an instant white wash that fades out.
struct NumPadKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(configuration.isPressed ? 0.12 : 0))
                .animation(.easeOut(duration: configuration.isPressed ? 0 : 0.2), value: configuration.isPressed)
        }
    }
}
