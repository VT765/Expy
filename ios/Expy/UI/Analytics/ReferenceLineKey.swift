import SwiftUI

/// Legend entry for a reference line: a short line sample (dashed for a
/// limit, solid for an average) and its label.
struct ReferenceLineKey: View {
    let title: String
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 1))
                p.addLine(to: CGPoint(x: 14, y: 1))
            }
            .stroke(Theme.sub, style: StrokeStyle(lineWidth: 1.5, dash: dashed ? [3, 2] : []))
            .frame(width: 14, height: 2)
            .accessibilityHidden(true)
            Text(title)
        }
        .font(.tFootnote)
        .foregroundStyle(Theme.sub)
    }
}
