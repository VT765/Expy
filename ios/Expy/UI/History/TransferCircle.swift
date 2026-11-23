import SwiftUI

/// ⇄ on a grey circle: the transfer counterpart of `EmojiCircle`.
struct TransferCircle: View {
    var size = 46.0

    var body: some View {
        Image(systemName: "arrow.left.arrow.right")
            .font(.app(size * 0.36, .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.raised))
            .accessibilityHidden(true)
    }
}
