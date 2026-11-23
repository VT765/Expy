import Foundation

/// Spending in one past period, for the trend chart.
struct TrendPoint: Identifiable {
    let start: Date
    let label: String
    let total: Double
    let isCurrent: Bool
    var id: Date { start }
}
