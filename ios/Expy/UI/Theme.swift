import SwiftUI

enum Theme {
    static let canvas = Color.black
    static let card = Color(hex: "#111111")
    static let raised = Color(hex: "#1C1C1E")
    static let well = Color(hex: "#2C2C2E")
    static let ink = Color.white
    static let sub = Color(hex: "#8E8E93")
    static let faint = Color(hex: "#58585C")
    static let danger = Color(hex: "#FF453A")
    static let positive = Color(hex: "#5FD38D")
    /// De-emphasised chart marks beside a white highlight: 3.4:1 on the card,
    /// white stays 5.5:1 against it (checked with the dataviz validator).
    static let chartMuted = Color(hex: "#68686D")
    static let gutter: CGFloat = 20
    static let cardRadius: CGFloat = 20
}
