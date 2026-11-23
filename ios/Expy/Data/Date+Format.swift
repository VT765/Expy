import Foundation

extension Date {
    var epochMs: Int64 { Int64((timeIntervalSince1970 * 1000).rounded()) }
    init(epochMs: Int64) { self.init(timeIntervalSince1970: Double(epochMs) / 1000) }
}
