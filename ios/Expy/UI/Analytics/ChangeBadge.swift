import SwiftUI

/// "▲ 12% vs previous" (red when spending rose).
struct ChangeBadge: View {
    let change: Double

    var body: some View {
        let up = change > 0
        Text("\(up ? "▲" : "▼") \(abs(change), format: .percent.precision(.fractionLength(0))) vs previous")
            .font(.app(13, .semibold))
            .foregroundStyle(up ? Theme.danger : .white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(up ? Theme.danger.opacity(0.15) : .white.opacity(0.1)))
            .accessibilityLabel("\(up ? "Up" : "Down") \(Int(abs(change * 100).rounded())) percent versus previous period")
    }
}
