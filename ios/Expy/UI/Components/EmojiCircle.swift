import SwiftUI

/// Category emoji on a tinted circle (decorative; rows supply the label).
struct EmojiCircle: View {
    let emoji: String
    let colorHex: String
    var size = 46.0

    var body: some View {
        Text(emoji)
            .font(.app(size * 0.5))
            .frame(width: size, height: size)
            .background(Circle().fill(Color(hex: colorHex).tint()))
            .accessibilityHidden(true)
    }
}
