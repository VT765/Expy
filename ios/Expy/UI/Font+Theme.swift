import SwiftUI

extension Font {
    /// Design-size font that still follows Dynamic Type: renders at `size`
    /// with the default text size and scales like the nearest text style.
    static func app(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("System", size: size, relativeTo: textStyle(for: size)).weight(weight)
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<13: .caption
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<17: .callout
        case ..<18: .body
        case ..<21: .title3
        case ..<24: .title2
        case ..<30: .title
        default: .largeTitle
        }
    }

    static let tTitle = Font.app(25, .bold)
    static let tHeadline = Font.app(16, .bold)
    static let tBody = Font.app(15)
    static let tBodySemibold = Font.app(15, .semibold)
    static let tFootnote = Font.app(13)
    static let tLabel = Font.app(13, .semibold)
}
