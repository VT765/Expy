import SwiftUI

/// The app-icon mark: a bold "E" over a rounded underline, built from its
/// five strokes so each can animate on its own. Proportions are measured
/// from the 1024 pt icon (underline 360 wide, mark 492 tall).
struct ExpyMark: View {
    var width = 120.0
    /// 0…1 reveal of the upright stroke, the three bars and the underline.
    var stem = 1.0
    var bars = [1.0, 1.0, 1.0]
    var line = 1.0
    var lineColor = Color.white

    private var s: Double { width / 360 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MarkStroke(x: 48, y: 0, w: 81, h: 372, unit: s, scaleY: stem, anchor: .bottom)
            MarkStroke(x: 48, y: 0, w: 277, h: 69, unit: s, scaleX: bars[0], anchor: .leading)
            MarkStroke(x: 48, y: 149, w: 261, h: 64, unit: s, scaleX: bars[1], anchor: .leading)
            MarkStroke(x: 48, y: 303, w: 282, h: 69, unit: s, scaleX: bars[2], anchor: .leading)
            Capsule().fill(lineColor)
                .frame(width: 360 * s, height: 36 * s)
                .scaleEffect(x: line, y: 1, anchor: .center)
                .offset(y: 456 * s)
        }
        .frame(width: width, height: 492 * s, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}
