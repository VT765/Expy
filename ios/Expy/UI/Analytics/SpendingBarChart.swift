import Charts
import SwiftUI

/// Spending per bucket with a daily-budget rule; tap a bar for its value.
struct SpendingBarChart: View {
    let buckets: [Bucket]
    let kind: PeriodKind
    let dailyBudget: Double?
    @Binding var selectedBar: Date?

    private var selected: Bucket? {
        guard let selectedBar else { return nil }
        return buckets.first { selectedBar >= $0.start && selectedBar < $0.end }
    }

    private var labelEvery: Int {
        buckets.count <= 12 ? 1 : buckets.count <= 31 ? 5 : Int((Double(buckets.count) / 6).rounded(.up))
    }

    private var unit: Calendar.Component { buckets.count > 45 || kind == .year ? .month : .day }

    var body: some View {
        let sel = selected
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sel?.long ?? "Tap a bar for details").font(.tFootnote).foregroundStyle(Theme.sub)
                Text(sel.map { Fmt.money($0.total) } ?? " ").font(.tHeadline)
            }
            Chart {
                ForEach(buckets) { b in
                    BarMark(x: .value("Period", b.start, unit: unit), y: .value("Spent", b.total), width: barWidth)
                        .cornerRadius(4, style: .continuous)
                        .foregroundStyle(color(for: b, selected: sel))
                        .annotation(position: .top, spacing: 4) { BarValueBadge(total: b.total, visible: sel?.id == b.id) }
                        .accessibilityLabel(b.long)
                        .accessibilityValue(isOver(b) ? "\(Fmt.money(b.total)), over daily budget" : Fmt.money(b.total))
                }
                if let dailyBudget, dailyBudget > 0 {
                    // A threshold, so dashed; neutral ink, since the line itself isn't good or bad.
                    RuleMark(y: .value("Daily budget", dailyBudget))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.sub)
                        .accessibilityHidden(true)
                }
            }
            .chartXSelection(value: $selectedBar)
            .excludedFromPageSwipe()
            .chartXAxis {
                AxisMarks(values: buckets.enumerated().filter { $0.offset % labelEvery == 0 }.map(\.element.start)) { v in
                    AxisValueLabel {
                        if let d = v.as(Date.self), let b = buckets.first(where: { $0.start == d }) {
                            Text(b.short).font(.app(10)).foregroundStyle(Theme.sub)
                        }
                    }
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
            .frame(height: 170)
            // Legend below the plot, so labels never sit on the bars.
            if let dailyBudget, dailyBudget > 0, unit == .day {
                HStack(spacing: 16) {
                    ReferenceLineKey(title: "Daily budget \(Fmt.money(dailyBudget.rounded()))", dashed: true)
                    if buckets.contains(where: isOver) {
                        Label("Over budget", systemImage: "exclamationmark.triangle.fill")
                            .font(.tFootnote).foregroundStyle(Theme.sub)
                            .labelStyle(OverBudgetLegendStyle())
                    }
                }
            }
        }
    }

    /// At most 24 pt wide; thinner when there are many bars.
    private var barWidth: MarkDimension { buckets.count <= 12 ? .fixed(20) : .ratio(0.62) }

    private func isOver(_ b: Bucket) -> Bool { (dailyBudget ?? 0) > 0 && b.total > (dailyBudget ?? 0) && unit == .day }

    /// Over-budget days wear the status red (with the legend's icon); a tap
    /// highlights one bar in white and mutes the rest.
    private func color(for b: Bucket, selected: Bucket?) -> Color {
        if let selected { return selected.id == b.id ? .white : Theme.chartMuted }
        return isOver(b) ? Theme.danger : Theme.sub
    }
}
