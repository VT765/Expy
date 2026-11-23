import SwiftUI

// Tokens sampled from the reference screenshots (same as the PWA).
enum Theme {
    static let canvas = Color.black
    static let card = Color(hex: "#111111")
    static let raised = Color(hex: "#1C1C1E")
    static let well = Color(hex: "#2C2C2E")
    static let ink = Color.white
    static let sub = Color(hex: "#8E8E93")
    static let faint = Color(hex: "#58585C")
    static let danger = Color(hex: "#FF453A")
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 20
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let v = UInt64(s, radix: 16) ?? 0x9DB0C4
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255,
                  opacity: 1)
    }

    /// Category tint used behind emoji and on selected chips.
    func tint(_ opacity: Double = 0.16) -> Color { self.opacity(opacity) }
}

extension Font {
    static let tTitle = Font.system(size: 25, weight: .bold)
    static let tHeadline = Font.system(size: 16, weight: .bold)
    static let tBody = Font.system(size: 15)
    static let tBodySemibold = Font.system(size: 15, weight: .semibold)
    static let tFootnote = Font.system(size: 13)
    static let tLabel = Font.system(size: 13, weight: .semibold)
}

/// Grey uppercase section label with wide tracking.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.tLabel)
            .tracking(1)
            .foregroundStyle(Theme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
