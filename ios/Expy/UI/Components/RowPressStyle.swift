import SwiftUI

/// Card press highlight for settings rows.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(.white.opacity(configuration.isPressed ? 0.06 : 0))
        }
    }
}
