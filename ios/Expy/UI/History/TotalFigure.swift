import SwiftUI

/// Small grey label over a coloured amount ("Spent / -₹3,000").
struct TotalFigure: View {
    let label: String
    let value: String
    let color: Color
    var alignment = HorizontalAlignment.leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label).font(.app(13)).foregroundStyle(Theme.sub)
            Text(value).font(.app(15, .semibold)).monospacedDigit().foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
    }
}
