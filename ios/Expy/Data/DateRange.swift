import Foundation

struct DateRange: Equatable {
    var start: Date
    var end: Date // exclusive
    var label: String
    func contains(_ d: Date) -> Bool { d >= start && d < end }
    static let allTime = DateRange(start: .distantPast, end: .distantFuture, label: "All time")
}
