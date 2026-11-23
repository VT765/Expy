enum RecurrenceFrequency: String, CaseIterable, Codable, Sendable {
    case weekly, monthly, yearly
}

extension RecurrenceFrequency {
    var label: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}
