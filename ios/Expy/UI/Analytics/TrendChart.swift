import Charts
import SwiftUI

/// This period against the ones before it: one series, the current period
/// in white and the rest muted, with the average of the earlier periods as
/// a hairline reference. Tap a bar for its value.
struct TrendChart: View {
    let points: [TrendPoint]
    let unitName: String
    @State private var selectedLabel: String?

    private var current: TrendPoint? { points.last }
    private var earlier: [TrendPoint] { points.dropLast().filter { $0.total > 0 } }
    private var average: Double? { earlier.isEmpty ? nil : earlier.map(\.total).reduce(0, +) / Double(earlier.count) }
    private var selected: TrendPoint? { points.first { $0.label == selectedLabel } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TrendHeadline(current: current, selected: selected, average: average, unitName: unitName)
            Chart {
                ForEach(points) { p in
                    BarMark(x: .value("Period", p.label), y: .value("Spent", p.total), width: .fixed(22))
                        .cornerRadius(4, style: .continuous)
                        .foregroundStyle(color(for: p))
                        .annotation(position: .top, spacing: 4) {
                            // The current value is the headline; only a tapped bar gets a label.
                            if p.id == selected?.id {
                                Text(Fmt.compact(p.total)).font(.app(11, .semibold)).foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel(p.isCurrent ? "\(p.label), current" : p.label)
                        .accessibilityValue(Fmt.money(p.total))
                }
                if let average {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Theme.sub)
                        .accessibilityHidden(true)
                }
            }
            .chartXSelection(value: $selectedLabel)
            .excludedFromPageSwipe()
            .chartXAxis {
                AxisMarks { v in
                    AxisValueLabel { if let s = v.as(String.self) { Text(s).font(.app(10)).foregroundStyle(Theme.sub) } }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.well)
                    AxisValueLabel {
                        if let d = v.as(Double.self) { Text(Fmt.compact(d)).font(.app(10)).foregroundStyle(Theme.faint) }
                    }
                }
            }
            .frame(height: 160)
            if let average {
                ReferenceLineKey(title: "Average of earlier \(unitName)s \(Fmt.money(average.rounded()))")
            }
        }
    }

    private func color(for p: TrendPoint) -> Color {
        if let selected { return selected.id == p.id ? .white : Theme.chartMuted }
        return p.isCurrent ? .white : Theme.chartMuted
    }
}
