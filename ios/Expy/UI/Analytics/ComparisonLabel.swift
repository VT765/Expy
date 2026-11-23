import SwiftUI

/// "▲ 12% above average" in red (spending up) or "▼ 8% below average" in
/// green, always with the arrow icon so it never relies on colour alone.
struct ComparisonLabel: View {
    /// Fractional change; positive = spent more.
    let change: Double
    let against: String

    var body: some View {
        let up = change > 0.005
        let down = change < -0.005
        Label {
            Text(up || down
                 ? "\(abs(change), format: .percent.precision(.fractionLength(0))) \(up ? "above" : "below") \(against)"
                 : "Same as \(against)")
        } icon: {
            Image(systemName: up ? "arrow.up.right" : down ? "arrow.down.right" : "equal")
        }
        .font(.app(13, .semibold))
        .foregroundStyle(up ? Theme.danger : down ? Theme.positive : Theme.sub)
    }
}
