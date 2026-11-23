import SwiftUI

/// Scale-down press feedback used across the app.
struct PressableStyle: ButtonStyle {
    var scale = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
