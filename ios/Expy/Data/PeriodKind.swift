import Foundation

enum PeriodKind: String, CaseIterable, Identifiable {
    case today, week, month, year, all, custom
    var id: String { rawValue }
}
