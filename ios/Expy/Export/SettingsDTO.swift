import Foundation

/// Version 1 files also carry baseCurrency and rateOverrides; they're ignored.
struct SettingsDTO: Codable {
    var id: String = "app"
    var cycleStartDay: Int
    var updatedAt: Int64

    init(_ s: AppSettings) {
        cycleStartDay = s.cycleStartDay
        updatedAt = max(0, s.updatedAt.epochMs)
    }

    func apply(to s: AppSettings) {
        s.cycleStartDay = cycleStartDay
        s.updatedAt = Date(epochMs: updatedAt)
    }
}
